using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Integration;

public class EmailVerificationEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public EmailVerificationEndpointsTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SendEmailOtp_ValidRequest_Returns200WithMaskedEmailAndNoSecretLeakage()
    {
        var uniqueEmail = $"partner_{Random.Shared.Next(10000, 99999)}@connexab2b.test";
        var flowId = $"flow-integ-{Guid.NewGuid():N}";
        var request = new SendEmailOtpRequestDto(uniqueEmail, flowId);

        var response = await _client.PostAsJsonAsync("/api/v1/verification/email/send", request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<SendEmailOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.True(content.Success);
        Assert.NotNull(content.Data);
        Assert.True(content.Data.ChallengeId > 0);
        Assert.Contains("@connexab2b.test", content.Data.MaskedEmail);
        Assert.True(content.Data.CooldownSeconds > 0);
        Assert.True(content.Data.ExpiresAtUtc > DateTime.UtcNow);

        // Raw response body must NEVER contain 6-digit OTP code or secret hash
        var rawJson = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("otpCode", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("otpHash", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("otpHashingSalt", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("appPassword", rawJson, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendEmailOtp_InvalidEmail_Returns400BadRequest()
    {
        var request = new SendEmailOtpRequestDto("not_a_valid_email", "flow-bad-email");

        var response = await _client.PostAsJsonAsync("/api/v1/verification/email/send", request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<SendEmailOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.False(content.Success);
        Assert.Contains("invalid", content.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ResendEmailOtp_WithinCooldown_Returns429TooManyRequests()
    {
        var uniqueEmail = $"cooldown_{Random.Shared.Next(10000, 99999)}@connexa.test";
        var flowId = $"flow-cooldown-{Guid.NewGuid():N}";
        var sendRequest = new SendEmailOtpRequestDto(uniqueEmail, flowId);

        var sendResponse = await _client.PostAsJsonAsync("/api/v1/verification/email/send", sendRequest);
        Assert.Equal(HttpStatusCode.OK, sendResponse.StatusCode);

        var sendContent = await sendResponse.Content.ReadFromJsonAsync<ApiResponse<SendEmailOtpResponseDto>>(JsonOptions);
        var challengeId = sendContent!.Data!.ChallengeId;

        // Immediate resend must trigger 429 cooldown
        var resendRequest = new ResendEmailOtpRequestDto(challengeId, flowId);
        var resendResponse = await _client.PostAsJsonAsync("/api/v1/verification/email/resend", resendRequest);

        Assert.Equal(HttpStatusCode.TooManyRequests, resendResponse.StatusCode);
    }

    [Fact]
    public async Task VerifyEmailOtp_FullFlow_ValidatesCorrectCodeAndIssuesGrant()
    {
        var uniqueEmail = $"verify_{Random.Shared.Next(10000, 99999)}@connexa.test";
        var flowId = $"flow-verify-{Guid.NewGuid():N}";
        var sendRequest = new SendEmailOtpRequestDto(uniqueEmail, flowId);

        var sendResponse = await _client.PostAsJsonAsync("/api/v1/verification/email/send", sendRequest);
        var sendContent = await sendResponse.Content.ReadFromJsonAsync<ApiResponse<SendEmailOtpResponseDto>>(JsonOptions);
        var challengeId = sendContent!.Data!.ChallengeId;

        // Fetch stored challenge from in-memory / local test DbContext to obtain test OTP code
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var challenge = await db.OtpChallenges.FindAsync(challengeId);
        Assert.NotNull(challenge);

        // 1. Incorrect OTP attempt
        var wrongVerify = new VerifyEmailOtpRequestDto(challengeId, flowId, "999999");
        var wrongResponse = await _client.PostAsJsonAsync("/api/v1/verification/email/verify", wrongVerify);
        Assert.Equal(HttpStatusCode.BadRequest, wrongResponse.StatusCode);

        // 2. Correct OTP attempt (using either stored code or direct match)
        var otpCode = !string.IsNullOrEmpty(challenge.OtpCode) ? challenge.OtpCode : "123456";
        // If empty in prod mode, we can use the salt and crypto to find or set
        if (string.IsNullOrEmpty(challenge.OtpCode))
        {
            var crypto = scope.ServiceProvider.GetRequiredService<IOtpCryptographyService>();
            challenge.OtpCode = "654321";
            challenge.OtpHash = crypto.HashEmailOtp("654321", challenge.OtpHashingSalt, challenge.Email!);
            await db.SaveChangesAsync();
            otpCode = "654321";
        }

        var correctVerify = new VerifyEmailOtpRequestDto(challengeId, flowId, otpCode);
        var verifyResponse = await _client.PostAsJsonAsync("/api/v1/verification/email/verify", correctVerify);
        Assert.Equal(HttpStatusCode.OK, verifyResponse.StatusCode);

        var verifyContent = await verifyResponse.Content.ReadFromJsonAsync<ApiResponse<VerifyEmailOtpResponseDto>>(JsonOptions);
        Assert.NotNull(verifyContent);
        Assert.True(verifyContent.Success);
        Assert.True(verifyContent.Data!.Verified);
        Assert.NotEmpty(verifyContent.Data.VerificationGrant);
        Assert.Equal(64, verifyContent.Data.VerificationGrant.Length);

        // 3. Validate grant via Unified Verification Policy endpoint
        var grantToken = verifyContent.Data.VerificationGrant;
        var validateReq = new ValidateVerificationGrantRequestDto(grantToken, flowId);
        var validateResponse = await _client.PostAsJsonAsync("/api/v1/verification/validate-grant", validateReq);
        Assert.Equal(HttpStatusCode.OK, validateResponse.StatusCode);

        var validateContent = await validateResponse.Content.ReadFromJsonAsync<ApiResponse<ValidateVerificationGrantResponseDto>>(JsonOptions);
        Assert.NotNull(validateContent);
        Assert.True(validateContent.Data!.IsValid);
        Assert.Equal("Email", validateContent.Data.VerifiedMethod);

        // 4. Consume grant atomically
        var consumeResponse = await _client.PostAsJsonAsync("/api/v1/verification/consume-grant", validateReq);
        Assert.Equal(HttpStatusCode.OK, consumeResponse.StatusCode);

        // 5. Subsequent validation or consumption must fail (single-use guarantee)
        var secondConsume = await _client.PostAsJsonAsync("/api/v1/verification/consume-grant", validateReq);
        Assert.Equal(HttpStatusCode.BadRequest, secondConsume.StatusCode);
    }
}

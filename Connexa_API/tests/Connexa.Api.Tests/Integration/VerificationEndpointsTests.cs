using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Integration;

public class VerificationEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public VerificationEndpointsTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SendOtp_ValidRequest_Returns200WithMaskedPhoneAndNoPlaintextOtp()
    {
        var uniquePhone = $"+9198{Random.Shared.Next(10000000, 99999999)}";
        var flowId = $"flow-integ-{Guid.NewGuid():N}";
        var request = new SendOtpRequestDto(uniquePhone, flowId);

        var response = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/send", request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<SendOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.True(content.Success);
        Assert.NotNull(content.Data);
        Assert.True(content.Data.ChallengeId > 0);
        Assert.Contains("+91", content.Data.MaskedPhoneNumber);
        Assert.True(content.Data.CooldownSeconds > 0);
        Assert.True(content.Data.ExpiresAtUtc > DateTime.UtcNow);

        // Raw response body must NEVER contain 6-digit OTP code or secret hash
        var rawJson = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("otpCode", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("otpHash", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("otpHashingSalt", rawJson, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendOtp_InvalidPhone_Returns400BadRequest()
    {
        var request = new SendOtpRequestDto("invalid_phone_123", "flow-bad-phone");

        var response = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/send", request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<SendOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.False(content.Success);
        Assert.NotEmpty(content.Message ?? "");
    }

    [Fact]
    public async Task VerifyOtp_NonExistentChallenge_Returns404NotFound()
    {
        var request = new VerifyOtpRequestDto(999999, "flow-missing", "123456");

        var response = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/verify", request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<VerifyOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.False(content.Success);
    }

    [Fact]
    public async Task ResendOtp_NonExistentChallenge_Returns404NotFound()
    {
        var request = new ResendOtpRequestDto(999999, "flow-missing");

        var response = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/resend", request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task FullVerificationFlow_CanBeVerifiedUsingServerHashedChallenge()
    {
        var uniquePhone = $"+9197{Random.Shared.Next(10000000, 99999999)}";
        var flowId = $"flow-full-{Guid.NewGuid():N}";
        var sendRequest = new SendOtpRequestDto(uniquePhone, flowId);

        var sendResponse = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/send", sendRequest);
        Assert.Equal(HttpStatusCode.OK, sendResponse.StatusCode);

        var sendContent = await sendResponse.Content.ReadFromJsonAsync<ApiResponse<SendOtpResponseDto>>(JsonOptions);
        var challengeId = sendContent!.Data.ChallengeId;

        // Verify with invalid OTP first
        var wrongVerify = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/verify",
            new VerifyOtpRequestDto(challengeId, flowId, "000000"));
        Assert.Equal(HttpStatusCode.BadRequest, wrongVerify.StatusCode);

        // Fetch challenge from DB and compute valid OTP test hash match
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var crypto = scope.ServiceProvider.GetRequiredService<IOtpCryptographyService>();

        var challenge = await db.OtpChallenges.FindAsync(challengeId);
        Assert.NotNull(challenge);

        // Overwrite with a known test code for deterministic verification test
        var knownOtp = "482619";
        challenge.OtpHashingSalt = crypto.GenerateSalt();
        challenge.OtpHash = crypto.HashOtp(knownOtp, challenge.OtpHashingSalt, challenge.PhoneNumber);
        await db.SaveChangesAsync();

        // Verify with known OTP
        var correctVerify = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/verify",
            new VerifyOtpRequestDto(challengeId, flowId, knownOtp));
        Assert.Equal(HttpStatusCode.OK, correctVerify.StatusCode);

        var verifyContent = await correctVerify.Content.ReadFromJsonAsync<ApiResponse<VerifyOtpResponseDto>>(JsonOptions);
        Assert.NotNull(verifyContent);
        Assert.True(verifyContent.Success);
        Assert.True(verifyContent.Data.Verified);
        Assert.NotEmpty(verifyContent.Data.VerificationGrant);
        Assert.Equal(64, verifyContent.Data.VerificationGrant.Length);

        // Verification must be single-use: repeating verify on the same challenge must be rejected
        var repeatVerify = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/verify",
            new VerifyOtpRequestDto(challengeId, flowId, knownOtp));
        Assert.Equal(HttpStatusCode.BadRequest, repeatVerify.StatusCode);
    }

    [Fact]
    public async Task SendOtp_WhenUnconfiguredOrDevelopment_ReturnsIsLiveDeliveryFalse()
    {
        var uniquePhone = $"+9196{Random.Shared.Next(10000000, 99999999)}";
        var flowId = $"flow-unconf-{Guid.NewGuid():N}";
        var sendRequest = new SendOtpRequestDto(uniquePhone, flowId);

        var response = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/send", sendRequest);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<ApiResponse<SendOtpResponseDto>>(JsonOptions);
        Assert.NotNull(content);
        Assert.True(content.Success);
        Assert.False(content.Data.IsLiveDelivery, "Expected IsLiveDelivery to be false when real WhatsApp credentials are not configured.");
        Assert.Contains("Development mode", content.Data.Message ?? "");
    }

    [Fact]
    public async Task VerifyOtp_ValidatesDirectPlaintextOtpStoredInDatabase()
    {
        var uniquePhone = $"+9195{Random.Shared.Next(10000000, 99999999)}";
        var flowId = $"flow-direct-{Guid.NewGuid():N}";
        var sendRequest = new SendOtpRequestDto(uniquePhone, flowId);

        var sendResponse = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/send", sendRequest);
        var sendContent = await sendResponse.Content.ReadFromJsonAsync<ApiResponse<SendOtpResponseDto>>(JsonOptions);
        var challengeId = sendContent!.Data.ChallengeId;

        // Fetch challenge directly from DB and inspect OtpCode
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var challenge = await db.OtpChallenges.FindAsync(challengeId);

        Assert.NotNull(challenge);
        Assert.NotEmpty(challenge.OtpCode);
        Assert.Equal(6, challenge.OtpCode.Length);

        // Verify using the exact direct OtpCode saved in the database
        var verifyResponse = await _client.PostAsJsonAsync("/api/v1/verification/whatsapp/verify",
            new VerifyOtpRequestDto(challengeId, flowId, challenge.OtpCode));

        Assert.Equal(HttpStatusCode.OK, verifyResponse.StatusCode);
        var verifyContent = await verifyResponse.Content.ReadFromJsonAsync<ApiResponse<VerifyOtpResponseDto>>(JsonOptions);
        Assert.NotNull(verifyContent);
        Assert.True(verifyContent.Success);
        Assert.True(verifyContent.Data.Verified);
    }
}

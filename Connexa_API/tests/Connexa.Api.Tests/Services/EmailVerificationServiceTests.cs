using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Email;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Services;

public class MockEmailProvider : IEmailProvider
{
    public string ProviderName => "MockEmailProvider";
    public bool IsConfigured => true;
    public bool ShouldSucceed { get; set; } = true;
    public string? LastDispatchedOtp { get; private set; }
    public string? LastDispatchedEmail { get; private set; }
    public int DispatchCallCount { get; private set; }

    public Task<EmailDispatchResult> SendOtpEmailAsync(
        string toEmail,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken)
    {
        DispatchCallCount++;
        LastDispatchedOtp = otpCode;
        LastDispatchedEmail = toEmail;

        if (ShouldSucceed)
        {
            return Task.FromResult(new EmailDispatchResult(
                Accepted: true,
                ProviderMessageId: $"mock_mail_msg_{Guid.NewGuid():N}",
                IsSimulated: true,
                ErrorMessage: null
            ));
        }

        return Task.FromResult(new EmailDispatchResult(
            Accepted: false,
            ProviderMessageId: null,
            IsSimulated: false,
            ErrorMessage: "Mock SMTP provider simulated transport failure."
        ));
    }
}

public class MockTestWebHostEnvironment : IWebHostEnvironment
{
    public string EnvironmentName { get; set; } = Environments.Development;
    public string ApplicationName { get; set; } = "Connexa.Api";
    public string WebRootPath { get; set; } = AppContext.BaseDirectory;
    public IFileProvider WebRootFileProvider { get; set; } = null!;
    public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
    public IFileProvider ContentRootFileProvider { get; set; } = null!;
}

public class EmailVerificationServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly MockEmailProvider _emailProvider;
    private readonly OtpSecurityOptions _securityOptions;
    private readonly MockTestWebHostEnvironment _hostEnvironment;
    private readonly EmailVerificationService _service;

    public EmailVerificationServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaEmailTestDb_{Guid.NewGuid()}")
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);

        _securityOptions = new OtpSecurityOptions
        {
            HmacSecretKey = "Connexa_Test_Key_For_Unit_Testing_32_Bytes_Long_Minimum",
            OtpLifetimeSeconds = 300,
            ResendCooldownSeconds = 60,
            MaxAttempts = 5,
            MaxResends = 3,
            MaxChallengesPerHourPerEmail = 5,
            MaxRequestsPerTenMinutesPerIp = 20,
            VerificationGrantLifetimeMinutes = 60
        };

        var optionsWrapper = Options.Create(_securityOptions);
        _crypto = new OtpCryptographyService(optionsWrapper);
        _emailProvider = new MockEmailProvider();
        _hostEnvironment = new MockTestWebHostEnvironment { EnvironmentName = Environments.Development };

        _service = new EmailVerificationService(
            _dbContext,
            _emailProvider,
            _crypto,
            optionsWrapper,
            _hostEnvironment,
            NullLogger<EmailVerificationService>.Instance);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }

    [Fact]
    public async Task SendOtpAsync_ValidEmail_CreatesPendingChallengeAndDispatches()
    {
        var request = new SendEmailOtpRequestDto("partner@company.com", "flow_123");

        var (success, response, errorMessage, statusCode) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.True(success);
        Assert.Equal(200, statusCode);
        Assert.Null(errorMessage);
        Assert.NotNull(response);
        Assert.True(response.Accepted);
        Assert.Equal("Pending", response.Status);
        Assert.Equal("p•••r@company.com", response.MaskedEmail);
        Assert.Equal(60, response.CooldownSeconds);

        var challenge = await _dbContext.OtpChallenges.FindAsync(response.ChallengeId);
        Assert.NotNull(challenge);
        Assert.Equal("partner@company.com", challenge.Email);
        Assert.Equal(OtpChallengeStatus.Pending, challenge.Status);
        Assert.Equal("flow_123", challenge.RegistrationFlowId);
        Assert.Equal("RegistrationVerification_Email", challenge.Purpose);
        Assert.Equal(_emailProvider.LastDispatchedOtp, challenge.OtpCode); // In Dev mode plaintext is saved
        Assert.NotEmpty(challenge.OtpHash);
    }

    [Fact]
    public async Task SendOtpAsync_ProductionEnvironment_DoesNotStorePlaintextOtp()
    {
        _hostEnvironment.EnvironmentName = Environments.Production;
        var request = new SendEmailOtpRequestDto("produser@enterprise.org", "flow_prod");

        var (success, response, _, _) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.True(success);
        var challenge = await _dbContext.OtpChallenges.FindAsync(response!.ChallengeId);
        Assert.NotNull(challenge);
        Assert.Equal(string.Empty, challenge.OtpCode); // Never store plaintext OTP in Production
        Assert.NotEmpty(challenge.OtpHash); // Hash is present
    }

    [Fact]
    public async Task SendOtpAsync_InvalidEmail_ReturnsBadRequest()
    {
        var request = new SendEmailOtpRequestDto("not-an-email", "flow_err");

        var (success, response, errorMessage, statusCode) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.False(success);
        Assert.Null(response);
        Assert.Equal(400, statusCode);
        Assert.Contains("invalid", errorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendOtpAsync_IpRateLimitExceeded_Returns429()
    {
        var clientIp = "192.168.1.100";
        var now = DateTime.UtcNow;

        for (int i = 0; i < 20; i++)
        {
            _dbContext.OtpChallenges.Add(new OtpChallenge
            {
                Email = $"user{i}@test.com",
                RegistrationFlowId = $"flow_{i}",
                RequestIpAddress = clientIp,
                CreatedAtUtc = now.AddMinutes(-2),
                ExpiresAtUtc = now.AddMinutes(3),
                OtpHashingSalt = "salt",
                OtpHash = "hash"
            });
        }
        await _dbContext.SaveChangesAsync();

        var request = new SendEmailOtpRequestDto("target@test.com", "flow_rate_limit");
        var (success, _, errorMessage, statusCode) = await _service.SendOtpAsync(request, clientIp);

        Assert.False(success);
        Assert.Equal(429, statusCode);
        Assert.Contains("network", errorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SendOtpAsync_EmailHourlyLimitExceeded_Returns429()
    {
        var targetEmail = "busy@connexa.com";
        var now = DateTime.UtcNow;

        for (int i = 0; i < 5; i++)
        {
            _dbContext.OtpChallenges.Add(new OtpChallenge
            {
                Email = targetEmail,
                RegistrationFlowId = $"flow_{i}",
                CreatedAtUtc = now.AddMinutes(-10 * i),
                ExpiresAtUtc = now.AddMinutes(5),
                OtpHashingSalt = "salt",
                OtpHash = "hash"
            });
        }
        await _dbContext.SaveChangesAsync();

        var request = new SendEmailOtpRequestDto(targetEmail, "flow_hourly_limit");
        var (success, _, errorMessage, statusCode) = await _service.SendOtpAsync(request, "10.0.0.1");

        Assert.False(success);
        Assert.Equal(429, statusCode);
        Assert.Contains("Hourly", errorMessage);
    }

    [Fact]
    public async Task SendOtpAsync_ResendCooldownActive_Returns429()
    {
        var targetEmail = "cooldown@connexa.com";
        var request = new SendEmailOtpRequestDto(targetEmail, "flow_cd");

        var (firstSuccess, _, _, _) = await _service.SendOtpAsync(request, "127.0.0.1");
        Assert.True(firstSuccess);

        // Immediate second attempt within 60s cooldown
        var (secondSuccess, _, errorMessage, statusCode) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.False(secondSuccess);
        Assert.Equal(429, statusCode);
        Assert.Contains("Please wait", errorMessage);
    }

    [Fact]
    public async Task SendOtpAsync_ProviderFails_ExpiresChallengeAndReturns502()
    {
        _emailProvider.ShouldSucceed = false;
        var request = new SendEmailOtpRequestDto("fail@connexa.com", "flow_fail");

        var (success, response, errorMessage, statusCode) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.False(success);
        Assert.Null(response);
        Assert.Equal(502, statusCode);
        Assert.Contains("transport failure", errorMessage);

        var challenge = await _dbContext.OtpChallenges.FirstOrDefaultAsync(c => c.Email == "fail@connexa.com");
        Assert.NotNull(challenge);
        Assert.Equal(OtpChallengeStatus.Expired, challenge.Status); // Failed send is expired immediately
    }

    [Fact]
    public async Task ResendOtpAsync_ValidChallenge_GeneratesNewOtpAndDispatches()
    {
        var sendReq = new SendEmailOtpRequestDto("resend@connexa.com", "flow_resend");
        var (_, sendResp, _, _) = await _service.SendOtpAsync(sendReq, "127.0.0.1");
        var challengeId = sendResp!.ChallengeId;

        // Advance activity time past 60s cooldown
        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        challenge!.CreatedAtUtc = DateTime.UtcNow.AddSeconds(-70);
        await _dbContext.SaveChangesAsync();

        var resendReq = new ResendEmailOtpRequestDto(challengeId, "flow_resend");
        var (success, resendResp, errorMessage, statusCode) = await _service.ResendOtpAsync(resendReq, "127.0.0.1");

        Assert.True(success);
        Assert.Equal(200, statusCode);
        Assert.Null(errorMessage);
        Assert.NotNull(resendResp);
        Assert.Equal(challengeId, resendResp.ChallengeId);
        Assert.Equal(1, challenge.ResendCount);
    }

    [Fact]
    public async Task VerifyOtpAsync_CorrectCode_IssuesVerificationGrant()
    {
        var sendReq = new SendEmailOtpRequestDto("verify@connexa.com", "flow_verify");
        var (_, sendResp, _, _) = await _service.SendOtpAsync(sendReq, "127.0.0.1");
        var challengeId = sendResp!.ChallengeId;

        var dispatchedOtp = _emailProvider.LastDispatchedOtp!;
        var verifyReq = new VerifyEmailOtpRequestDto(challengeId, "flow_verify", dispatchedOtp);

        var (success, verifyResp, errorMessage, statusCode) = await _service.VerifyOtpAsync(verifyReq, "127.0.0.1");

        Assert.True(success);
        Assert.Equal(200, statusCode);
        Assert.Null(errorMessage);
        Assert.NotNull(verifyResp);
        Assert.True(verifyResp.Verified);
        Assert.NotEmpty(verifyResp.VerificationGrant);
        Assert.True(verifyResp.VerificationGrantExpiresAtUtc > DateTime.UtcNow);

        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        Assert.Equal(OtpChallengeStatus.Verified, challenge!.Status);
        Assert.Equal(verifyResp.VerificationGrant, challenge.VerificationGrantToken);
    }

    [Fact]
    public async Task VerifyOtpAsync_IncorrectCode_DecrementsAttemptsAndPermanentInvalidationOnMax()
    {
        var sendReq = new SendEmailOtpRequestDto("wrong@connexa.com", "flow_wrong");
        var (_, sendResp, _, _) = await _service.SendOtpAsync(sendReq, "127.0.0.1");
        var challengeId = sendResp!.ChallengeId;

        for (int i = 1; i <= 4; i++)
        {
            var wrongReq = new VerifyEmailOtpRequestDto(challengeId, "flow_wrong", "000000");
            var (success, _, errorMsg, status) = await _service.VerifyOtpAsync(wrongReq, "127.0.0.1");

            Assert.False(success);
            Assert.Equal(400, status);
            Assert.Contains($"Attempts remaining: {5 - i}", errorMsg);
        }

        // 5th attempt invalidates challenge permanently
        var finalWrongReq = new VerifyEmailOtpRequestDto(challengeId, "flow_wrong", "000000");
        var (finalSuccess, _, finalError, finalStatus) = await _service.VerifyOtpAsync(finalWrongReq, "127.0.0.1");

        Assert.False(finalSuccess);
        Assert.Equal(400, finalStatus);
        Assert.Contains("Maximum verification attempts exceeded", finalError);

        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        Assert.Equal(OtpChallengeStatus.MaxAttemptsExceeded, challenge!.Status);
    }
}

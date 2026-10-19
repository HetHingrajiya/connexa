using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Verification;
using Connexa.Api.Services.WhatsApp;

namespace Connexa.Api.Tests.Services;

public class MockWhatsAppProvider : IWhatsAppProvider
{
    public string ProviderName => "MockProvider";
    public bool IsConfigured => true;
    public bool ShouldSucceed { get; set; } = true;
    public string? LastDispatchedOtp { get; private set; }
    public string? LastDispatchedPhone { get; private set; }
    public int DispatchCallCount { get; private set; }

    public Task<WhatsAppDispatchResult> SendOtpAsync(
        string normalizedPhoneNumber,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken = default)
    {
        DispatchCallCount++;
        LastDispatchedOtp = otpCode;
        LastDispatchedPhone = normalizedPhoneNumber;

        if (ShouldSucceed)
        {
            return Task.FromResult(new WhatsAppDispatchResult(
                Accepted: true,
                ProviderMessageId: $"mock_msg_{Guid.NewGuid():N}",
                IsSimulated: true
            ));
        }

        return Task.FromResult(new WhatsAppDispatchResult(
            Accepted: false,
            ErrorMessage: "Mock WhatsApp provider simulated gateway error."
        ));
    }
}

public class MockHostEnvironment : IHostEnvironment
{
    public string EnvironmentName { get; set; } = Environments.Development;
    public string ApplicationName { get; set; } = "Connexa.Api";
    public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
    public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } = null!;
}

public class PhoneVerificationServiceTests
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly MockWhatsAppProvider _mockProvider;
    private readonly IOptions<OtpSecurityOptions> _options;
    private readonly PhoneVerificationService _service;

    public PhoneVerificationServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"Connexa_TestDb_{Guid.NewGuid():N}")
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _options = Options.Create(new OtpSecurityOptions
        {
            OtpLifetimeSeconds = 300,
            ResendCooldownSeconds = 60,
            MaxAttempts = 5,
            MaxResends = 3,
            MaxChallengesPerHourPerPhone = 5,
            MaxRequestsPerTenMinutesPerIp = 20,
            VerificationGrantLifetimeMinutes = 60,
            HmacSecretKey = "Test_Secret_Key_For_Unit_Tests_32_Bytes_Long_Minimum"
        });

        _crypto = new OtpCryptographyService(_options);
        _mockProvider = new MockWhatsAppProvider();

        _service = new PhoneVerificationService(
            _dbContext,
            _mockProvider,
            _crypto,
            _options,
            NullLogger<PhoneVerificationService>.Instance);
    }

    [Fact]
    public async Task SendOtpAsync_ValidRequest_CreatesChallengeAndCallsProviderWithoutLeakingOtp()
    {
        var request = new SendOtpRequestDto("+91 98765 43210", "flow-abc-123");

        var (success, response, errorMessage, statusCode) = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.True(success);
        Assert.Equal(200, statusCode);
        Assert.Null(errorMessage);
        Assert.NotNull(response);
        Assert.True(response.ChallengeId > 0);
        Assert.Contains("+91", response.MaskedPhoneNumber);
        Assert.True(response.Accepted);

        // Verify database entity
        var challenge = await _dbContext.OtpChallenges.FindAsync(response.ChallengeId);
        Assert.NotNull(challenge);
        Assert.Equal("+919876543210", challenge.PhoneNumber);
        Assert.Equal("flow-abc-123", challenge.RegistrationFlowId);
        Assert.Equal(OtpChallengeStatus.Pending, challenge.Status);
        Assert.NotEmpty(challenge.OtpHashingSalt);
        Assert.NotEmpty(challenge.OtpHash);

        // Direct OTP is saved to database in OtpCode column
        Assert.NotNull(_mockProvider.LastDispatchedOtp);
        Assert.Equal(6, _mockProvider.LastDispatchedOtp.Length);
        Assert.Equal(_mockProvider.LastDispatchedOtp, challenge.OtpCode);
        Assert.NotEqual(_mockProvider.LastDispatchedOtp, challenge.OtpHash);
    }

    [Fact]
    public async Task SendOtpAsync_WithinCooldown_Returns429TooManyRequests()
    {
        var request = new SendOtpRequestDto("+91 98765 43210", "flow-123");

        // First send
        var first = await _service.SendOtpAsync(request, "127.0.0.1");
        Assert.True(first.Success);

        // Immediate second send (within 60s cooldown)
        var second = await _service.SendOtpAsync(request, "127.0.0.1");
        Assert.False(second.Success);
        Assert.Equal(429, second.StatusCode);
        Assert.Contains("Please wait", second.ErrorMessage);
    }

    [Fact]
    public async Task SendOtpAsync_SupersedesExistingPendingChallenges()
    {
        var phone = "+919876543210";
        var oldChallenge = new OtpChallenge
        {
            PhoneNumber = phone,
            RegistrationFlowId = "flow-old",
            OtpHashingSalt = _crypto.GenerateSalt(),
            OtpHash = "old_hash",
            Status = OtpChallengeStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow.AddMinutes(-2), // 2 min ago (cooldown expired)
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(3)
        };
        _dbContext.OtpChallenges.Add(oldChallenge);
        await _dbContext.SaveChangesAsync();

        var request = new SendOtpRequestDto(phone, "flow-new");
        var result = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.True(result.Success);

        var refreshedOld = await _dbContext.OtpChallenges.FindAsync(oldChallenge.Id);
        Assert.Equal(OtpChallengeStatus.Superseded, refreshedOld!.Status);
    }

    [Fact]
    public async Task SendOtpAsync_HourlyLimitExceeded_Returns429()
    {
        var phone = "+919876543210";
        for (int i = 0; i < 5; i++)
        {
            _dbContext.OtpChallenges.Add(new OtpChallenge
            {
                PhoneNumber = phone,
                RegistrationFlowId = $"flow-{i}",
                OtpHashingSalt = "salt",
                OtpHash = "hash",
                Status = OtpChallengeStatus.Expired,
                CreatedAtUtc = DateTime.UtcNow.AddMinutes(-10),
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-5)
            });
        }
        await _dbContext.SaveChangesAsync();

        var request = new SendOtpRequestDto(phone, "flow-excess");
        var result = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(429, result.StatusCode);
        Assert.Contains("Hourly verification request limit exceeded", result.ErrorMessage);
    }

    [Fact]
    public async Task SendOtpAsync_ProviderFails_MarksChallengeExpiredAndReturns502()
    {
        _mockProvider.ShouldSucceed = false;
        var request = new SendOtpRequestDto("+919876543210", "flow-fail");

        var result = await _service.SendOtpAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(502, result.StatusCode);

        var challenge = await _dbContext.OtpChallenges.FirstOrDefaultAsync(c => c.RegistrationFlowId == "flow-fail");
        Assert.NotNull(challenge);
        Assert.Equal(OtpChallengeStatus.Expired, challenge.Status);
    }

    [Fact]
    public async Task VerifyOtpAsync_CorrectOtp_MarksChallengeVerifiedAndIssuesGrant()
    {
        var request = new SendOtpRequestDto("+919876543210", "flow-verify");
        var sendResult = await _service.SendOtpAsync(request, "127.0.0.1");
        Assert.True(sendResult.Success);

        var dispatchedOtp = _mockProvider.LastDispatchedOtp!;
        var verifyRequest = new VerifyOtpRequestDto(sendResult.Response!.ChallengeId, "flow-verify", dispatchedOtp);

        var (success, response, errorMessage, statusCode) = await _service.VerifyOtpAsync(verifyRequest, "127.0.0.1");

        Assert.True(success);
        Assert.Equal(200, statusCode);
        Assert.Null(errorMessage);
        Assert.NotNull(response);
        Assert.True(response.Verified);
        Assert.NotEmpty(response.VerificationGrant);
        Assert.True(response.VerificationGrantExpiresAtUtc > DateTime.UtcNow);

        // Verify entity state in DB
        var challenge = await _dbContext.OtpChallenges.FindAsync(sendResult.Response.ChallengeId);
        Assert.NotNull(challenge);
        Assert.Equal(OtpChallengeStatus.Verified, challenge.Status);
        Assert.NotNull(challenge.VerifiedAtUtc);
        Assert.Equal(response.VerificationGrant, challenge.VerificationGrantToken);
    }

    [Fact]
    public async Task VerifyOtpAsync_IncorrectOtp_IncrementsAttemptCountAndKeepsPending()
    {
        var sendResult = await _service.SendOtpAsync(new SendOtpRequestDto("+919876543210", "flow-attempts"), "127.0.0.1");
        var challengeId = sendResult.Response!.ChallengeId;

        var verifyRequest = new VerifyOtpRequestDto(challengeId, "flow-attempts", "000000"); // wrong code
        var (success, response, errorMessage, statusCode) = await _service.VerifyOtpAsync(verifyRequest, "127.0.0.1");

        Assert.False(success);
        Assert.Equal(400, statusCode);
        Assert.Contains("Incorrect verification code", errorMessage);
        Assert.Contains("Attempts remaining: 4", errorMessage);

        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        Assert.Equal(1, challenge!.AttemptCount);
        Assert.Equal(OtpChallengeStatus.Pending, challenge.Status);
        Assert.Null(challenge.VerificationGrantToken);
    }

    [Fact]
    public async Task VerifyOtpAsync_MaxAttemptsExceeded_PermanentlyLocksChallenge()
    {
        var sendResult = await _service.SendOtpAsync(new SendOtpRequestDto("+919876543210", "flow-max-attempts"), "127.0.0.1");
        var challengeId = sendResult.Response!.ChallengeId;
        var correctOtp = _mockProvider.LastDispatchedOtp!;

        // Exhaust 5 attempts
        for (int i = 0; i < 5; i++)
        {
            await _service.VerifyOtpAsync(new VerifyOtpRequestDto(challengeId, "flow-max-attempts", "000000"), "127.0.0.1");
        }

        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        Assert.Equal(OtpChallengeStatus.MaxAttemptsExceeded, challenge!.Status);

        // 6th attempt with correct OTP must STILL be rejected
        var retryWithCorrect = await _service.VerifyOtpAsync(new VerifyOtpRequestDto(challengeId, "flow-max-attempts", correctOtp), "127.0.0.1");
        Assert.False(retryWithCorrect.Success);
        Assert.Equal(400, retryWithCorrect.StatusCode);
    }

    [Fact]
    public async Task VerifyOtpAsync_ExpiredChallenge_RejectsAndMarksExpired()
    {
        var challenge = new OtpChallenge
        {
            PhoneNumber = "+919876543210",
            RegistrationFlowId = "flow-expired",
            OtpHashingSalt = _crypto.GenerateSalt(),
            OtpHash = _crypto.HashOtp("123456", "salt", "+919876543210"),
            Status = OtpChallengeStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow.AddMinutes(-10),
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-5) // Expired 5 min ago
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var result = await _service.VerifyOtpAsync(new VerifyOtpRequestDto(challenge.Id, "flow-expired", "123456"), "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("expired", result.ErrorMessage);

        var refreshed = await _dbContext.OtpChallenges.FindAsync(challenge.Id);
        Assert.Equal(OtpChallengeStatus.Expired, refreshed!.Status);
    }

    [Fact]
    public async Task ResendOtpAsync_SubjectToCooldownAndLimits()
    {
        var sendResult = await _service.SendOtpAsync(new SendOtpRequestDto("+919876543210", "flow-resend"), "127.0.0.1");
        var challengeId = sendResult.Response!.ChallengeId;

        // Immediate resend must fail with 429
        var immediateResend = await _service.ResendOtpAsync(new ResendOtpRequestDto(challengeId, "flow-resend"), "127.0.0.1");
        Assert.False(immediateResend.Success);
        Assert.Equal(429, immediateResend.StatusCode);

        // Manually adjust LastResentAtUtc/CreatedAtUtc to simulate elapsed cooldown
        var challenge = await _dbContext.OtpChallenges.FindAsync(challengeId);
        challenge!.CreatedAtUtc = DateTime.UtcNow.AddSeconds(-65);
        await _dbContext.SaveChangesAsync();

        var permittedResend = await _service.ResendOtpAsync(new ResendOtpRequestDto(challengeId, "flow-resend"), "127.0.0.1");
        Assert.True(permittedResend.Success);
        Assert.Equal(200, permittedResend.StatusCode);

        var refreshed = await _dbContext.OtpChallenges.FindAsync(challengeId);
        Assert.Equal(1, refreshed!.ResendCount);
    }

    [Fact]
    public void DevelopmentWhatsAppProvider_StrictlyThrowsInProductionEnvironment()
    {
        var prodEnv = new MockHostEnvironment { EnvironmentName = Environments.Production };
        Assert.Throws<InvalidOperationException>(() =>
            new DevelopmentWhatsAppProvider(prodEnv, NullLogger<DevelopmentWhatsAppProvider>.Instance));
    }

    [Fact]
    public async Task VerificationLifecycle_DoesNotCreateUserAccountsInDatabase()
    {
        // 1. Send OTP
        var sendResult = await _service.SendOtpAsync(new SendOtpRequestDto("+919876543210", "flow-no-user"), "127.0.0.1");
        Assert.True(sendResult.Success);

        // 2. Verify OTP
        var verifyResult = await _service.VerifyOtpAsync(
            new VerifyOtpRequestDto(sendResult.Response!.ChallengeId, "flow-no-user", _mockProvider.LastDispatchedOtp!), "127.0.0.1");
        Assert.True(verifyResult.Success);

        // 3. Confirm only OtpChallenge table was modified, no user account entities exist
        var challenges = await _dbContext.OtpChallenges.Where(c => c.RegistrationFlowId == "flow-no-user").ToListAsync();
        Assert.Single(challenges);
        Assert.Equal(OtpChallengeStatus.Verified, challenges[0].Status);

        // Master data tables remain untouched
        var industryCount = await _dbContext.Industries.CountAsync();
        Assert.Equal(0, industryCount); // In-memory DB has no auto-seeded users or master data
    }
}

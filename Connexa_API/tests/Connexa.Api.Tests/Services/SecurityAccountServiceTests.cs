namespace Connexa.Api.Tests.Services;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Auth;
using Connexa.Api.Services.Verification;

public class SecurityAccountServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly PasswordHasher _passwordHasher;
    private readonly TokenService _tokenService;
    private readonly AuthService _authService;
    private readonly FakeEmailVerificationService _emailService;
    private readonly FakePhoneVerificationService _phoneService;

    public SecurityAccountServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaSecurityTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _passwordHasher = new PasswordHasher();

        var jwtOptions = Options.Create(new JwtOptions
        {
            SigningKey = "ConnexaSecurityTestSecretKeyWithAtLeast32BytesLength!",
            Issuer = "Connexa.Api.Test",
            Audience = "Connexa.App.Test",
            AccessTokenExpirationMinutes = 15,
            RefreshTokenExpirationDays = 30
        });

        _tokenService = new TokenService(jwtOptions);
        _emailService = new FakeEmailVerificationService(_dbContext);
        _phoneService = new FakePhoneVerificationService(_dbContext);

        _authService = new AuthService(
            _dbContext,
            _passwordHasher,
            _tokenService,
            _emailService,
            _phoneService,
            jwtOptions,
            NullLogger<AuthService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var (hash, salt) = _passwordHasher.HashPassword("CurrentPassword123!");

        var member = new Member
        {
            Id = 1,
            FullName = "Rajesh Shah",
            Email = "rajesh.shah@enterprise.test",
            PhoneNumber = "+919876543210",
            CountryCode = "+91",
            Role = "Member",
            IsActive = true,
            PasswordHash = hash,
            PasswordSalt = salt,
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany
        };

        _dbContext.Members.Add(member);

        // Add 2 active refresh tokens
        var (_, rt1) = _tokenService.GenerateRefreshToken(1, "127.0.0.1");
        rt1.Id = 101;
        rt1.DeviceName = "Windows PC";
        rt1.UserAgent = "Mozilla/5.0 Windows NT 10.0";
        rt1.LastActiveAtUtc = DateTime.UtcNow.AddHours(-1);

        var (_, rt2) = _tokenService.GenerateRefreshToken(1, "192.168.1.5");
        rt2.Id = 102;
        rt2.DeviceName = "Android Phone";
        rt2.UserAgent = "Dart/3.8 (dart:io)";
        rt2.LastActiveAtUtc = DateTime.UtcNow;

        _dbContext.RefreshTokens.AddRange(rt1, rt2);
        _dbContext.SaveChanges();
    }

    [Fact]
    public void PasswordPolicy_RequiresUppercaseLowercaseDigitAndSpecialChar()
    {
        var (valid1, _) = _passwordHasher.ValidatePasswordPolicy("Short1!");
        Assert.False(valid1);

        var (valid2, _) = _passwordHasher.ValidatePasswordPolicy("alllowercase123!");
        Assert.False(valid2);

        var (valid3, _) = _passwordHasher.ValidatePasswordPolicy("ALLUPPERCASE123!");
        Assert.False(valid3);

        var (valid4, _) = _passwordHasher.ValidatePasswordPolicy("NoSpecialChar123");
        Assert.False(valid4);

        var (valid5, error5) = _passwordHasher.ValidatePasswordPolicy("ValidPassword123!");
        Assert.True(valid5);
        Assert.Null(error5);
    }

    [Fact]
    public async Task ForgotPassword_ExistingMember_DispatchesOtpSuccessfully()
    {
        var request = new ForgotPasswordRequestDto("rajesh.shah@enterprise.test", "Email");
        var result = await _authService.ForgotPasswordAsync(request, "127.0.0.1");

        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal("Email", result.Data.Channel);
        Assert.True(result.Data.ChallengeId > 0);
    }

    [Fact]
    public async Task ForgotPassword_NonExistentMember_ReturnsNotFound()
    {
        var request = new ForgotPasswordRequestDto("nonexistent@domain.test", "Email");
        var result = await _authService.ForgotPasswordAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(404, result.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_CorrectCurrentPassword_UpdatesPasswordSuccessfully()
    {
        var request = new ChangePasswordRequestDto(
            CurrentPassword: "CurrentPassword123!",
            NewPassword: "BrandNewPassword2026@",
            ConfirmPassword: "BrandNewPassword2026@",
            RevokeOtherSessions: true
        );

        var result = await _authService.ChangePasswordAsync(1, request, "127.0.0.1");

        Assert.True(result.Success);
        Assert.True(result.Data);

        var member = await _dbContext.Members.FindAsync(1);
        Assert.NotNull(member);
        Assert.True(_passwordHasher.VerifyPassword("BrandNewPassword2026@", member.PasswordHash!, member.PasswordSalt!));
    }

    [Fact]
    public async Task ChangePassword_IncorrectCurrentPassword_Fails()
    {
        var request = new ChangePasswordRequestDto(
            CurrentPassword: "WrongPassword999!",
            NewPassword: "BrandNewPassword2026@",
            ConfirmPassword: "BrandNewPassword2026@"
        );

        var result = await _authService.ChangePasswordAsync(1, request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("Current password is incorrect", result.ErrorMessage);
    }

    [Fact]
    public async Task GetActiveSessions_ReturnsOnlyActiveSessions()
    {
        var result = await _authService.GetActiveSessionsAsync(1, null);

        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal(2, result.Data.Count);
    }

    [Fact]
    public async Task RevokeSession_ValidSession_MarksRevoked()
    {
        var result = await _authService.RevokeSessionAsync(1, 101, "127.0.0.1");

        Assert.True(result.Success);

        var session = await _dbContext.RefreshTokens.FindAsync(101);
        Assert.NotNull(session);
        Assert.NotNull(session.RevokedAtUtc);
        Assert.Equal("Manually revoked by member", session.ReasonRevoked);
    }

    [Fact]
    public async Task RevokeAllOtherSessions_LeavesCurrentSessionActive()
    {
        var currentToken = await _dbContext.RefreshTokens.FindAsync(102);
        Assert.NotNull(currentToken);

        var result = await _authService.RevokeAllOtherSessionsAsync(1, currentToken.TokenHash, "127.0.0.1");

        Assert.True(result.Success);
        Assert.Equal(1, result.Data); // 1 other session was revoked

        var s101 = await _dbContext.RefreshTokens.FindAsync(101);
        Assert.NotNull(s101!.RevokedAtUtc);

        var s102 = await _dbContext.RefreshTokens.FindAsync(102);
        Assert.Null(s102!.RevokedAtUtc); // Current session remains active
    }

    [Fact]
    public async Task DeactivateAccount_CorrectPassword_DeactivatesAndRevokesTokens()
    {
        var request = new DeactivateAccountRequestDto("CurrentPassword123!", "Temporarily pausing business operations");
        var result = await _authService.DeactivateAccountAsync(1, request, "127.0.0.1");

        Assert.True(result.Success);

        var member = await _dbContext.Members.FindAsync(1);
        Assert.NotNull(member);
        Assert.False(member.IsActive);
        Assert.NotNull(member.DeactivatedAtUtc);
        Assert.Equal("Temporarily pausing business operations", member.DeactivationReason);

        // All active tokens must be revoked
        var activeTokens = await _dbContext.RefreshTokens.Where(rt => rt.MemberId == 1 && rt.RevokedAtUtc == null).ToListAsync();
        Assert.Empty(activeTokens);
    }

    [Fact]
    public async Task RequestAccountDeletion_CorrectPassword_CreatesRequestAndDeactivates()
    {
        var request = new DeleteAccountRequestDto("CurrentPassword123!", "Closing down manufacturing firm");
        var result = await _authService.RequestAccountDeletionAsync(1, request, "127.0.0.1");

        Assert.True(result.Success);

        var member = await _dbContext.Members.FindAsync(1);
        Assert.NotNull(member);
        Assert.False(member.IsActive);

        var deletionReq = await _dbContext.AccountDeletionRequests.FirstOrDefaultAsync(d => d.MemberId == 1);
        Assert.NotNull(deletionReq);
        Assert.Equal("Closing down manufacturing firm", deletionReq.Reason);
        Assert.Equal("PendingReview", deletionReq.Status);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }
}

// Mock verification services for unit tests
public class FakeEmailVerificationService : IEmailVerificationService
{
    private readonly ConnexaDbContext _db;
    public FakeEmailVerificationService(ConnexaDbContext db) => _db = db;

    public Task<(bool Success, SendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendEmailOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        var challenge = new OtpChallenge
        {
            Id = Random.Shared.Next(1000, 9999),
            Email = request.Email,
            OtpCode = "123456",
            OtpHash = "hash",
            OtpHashingSalt = "salt",
            Purpose = "PasswordReset",
            RegistrationFlowId = request.RegistrationFlowId,
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(10),
            Status = OtpChallengeStatus.Pending
        };
        _db.OtpChallenges.Add(challenge);
        _db.SaveChanges();

        var resp = new SendEmailOtpResponseDto(
            ChallengeId: challenge.Id,
            MaskedEmail: "r***@enterprise.test",
            ExpiresAtUtc: challenge.ExpiresAtUtc,
            CooldownSeconds: 60,
            Accepted: true,
            Status: "Delivered",
            Message: "OTP sent"
        );
        return Task.FromResult((true, (SendEmailOtpResponseDto?)resp, (string?)null, 200));
    }

    public Task<(bool Success, ResendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendEmailOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        return Task.FromResult((true, (ResendEmailOtpResponseDto?)null, (string?)null, 200));
    }

    public Task<(bool Success, VerifyEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyEmailOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        var resp = new VerifyEmailOtpResponseDto(
            Verified: true,
            MaskedEmail: "r***@enterprise.test",
            VerificationGrant: "grant_token",
            VerificationGrantExpiresAtUtc: DateTime.UtcNow.AddMinutes(30),
            Message: "Verified"
        );
        return Task.FromResult((true, (VerifyEmailOtpResponseDto?)resp, (string?)null, 200));
    }
}

public class FakePhoneVerificationService : IPhoneVerificationService
{
    private readonly ConnexaDbContext _db;
    public FakePhoneVerificationService(ConnexaDbContext db) => _db = db;

    public Task<(bool Success, SendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        var challenge = new OtpChallenge
        {
            Id = Random.Shared.Next(1000, 9999),
            PhoneNumber = request.PhoneNumber,
            OtpCode = "123456",
            OtpHash = "hash",
            OtpHashingSalt = "salt",
            Purpose = "PasswordReset",
            RegistrationFlowId = request.RegistrationFlowId,
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(10),
            Status = OtpChallengeStatus.Pending
        };
        _db.OtpChallenges.Add(challenge);
        _db.SaveChanges();

        var resp = new SendOtpResponseDto(
            ChallengeId: challenge.Id,
            MaskedPhoneNumber: "+91 98765 *****",
            ExpiresAtUtc: challenge.ExpiresAtUtc,
            CooldownSeconds: 60,
            Accepted: true,
            Status: "Delivered",
            Message: "OTP sent"
        );
        return Task.FromResult((true, (SendOtpResponseDto?)resp, (string?)null, 200));
    }

    public Task<(bool Success, ResendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        return Task.FromResult((true, (ResendOtpResponseDto?)null, (string?)null, 200));
    }

    public Task<(bool Success, VerifyOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default)
    {
        var resp = new VerifyOtpResponseDto(
            Verified: true,
            MaskedPhoneNumber: "+91 98765 *****",
            VerificationGrant: "grant_token",
            VerificationGrantExpiresAtUtc: DateTime.UtcNow.AddMinutes(30),
            Message: "Verified"
        );
        return Task.FromResult((true, (VerifyOtpResponseDto?)resp, (string?)null, 200));
    }
}

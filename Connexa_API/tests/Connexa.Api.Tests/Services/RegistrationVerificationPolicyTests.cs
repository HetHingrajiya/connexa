using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.Entities;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Services;

public class RegistrationVerificationPolicyTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly RegistrationVerificationPolicyService _policyService;

    public RegistrationVerificationPolicyTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaPolicyTestDb_{Guid.NewGuid()}")
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);

        var secOptions = Options.Create(new OtpSecurityOptions
        {
            HmacSecretKey = "Connexa_Test_Policy_Key_For_Testing_Purposes_32_Bytes"
        });
        _crypto = new OtpCryptographyService(secOptions);

        _policyService = new RegistrationVerificationPolicyService(
            _dbContext,
            _crypto,
            NullLogger<RegistrationVerificationPolicyService>.Instance);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }

    [Fact]
    public async Task ValidateGrantAsync_PhoneVerifiedGrant_SatisfiesPolicy()
    {
        var challenge = new OtpChallenge
        {
            PhoneNumber = "+919876543210",
            Email = null,
            RegistrationFlowId = "flow_phone_1",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_phone_token_1234567890",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var (isValid, method, destination, expiresAt, errorMessage) = await _policyService.ValidateGrantAsync(
            "grant_phone_token_1234567890",
            "flow_phone_1");

        Assert.True(isValid);
        Assert.Equal("WhatsApp", method);
        Assert.Contains("+91", destination);
        Assert.NotNull(expiresAt);
        Assert.Null(errorMessage);
    }

    [Fact]
    public async Task ValidateGrantAsync_EmailVerifiedGrant_SatisfiesPolicy()
    {
        var challenge = new OtpChallenge
        {
            PhoneNumber = null,
            Email = "enterprise@connexa.com",
            RegistrationFlowId = "flow_email_1",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_email_token_1234567890",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var (isValid, method, destination, expiresAt, errorMessage) = await _policyService.ValidateGrantAsync(
            "grant_email_token_1234567890",
            "flow_email_1");

        Assert.True(isValid);
        Assert.Equal("Email", method);
        Assert.Equal("e•••e@connexa.com", destination);
        Assert.NotNull(expiresAt);
        Assert.Null(errorMessage);
    }

    [Fact]
    public async Task ValidateGrantAsync_MismatchedFlowId_IsRejected()
    {
        var challenge = new OtpChallenge
        {
            Email = "user@connexa.com",
            RegistrationFlowId = "flow_original",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_flow_mismatch",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var (isValid, _, _, _, errorMessage) = await _policyService.ValidateGrantAsync(
            "grant_flow_mismatch",
            "flow_spoofed_session");

        Assert.False(isValid);
        Assert.Contains("does not belong to this registration session", errorMessage);
    }

    [Fact]
    public async Task ValidateGrantAsync_ExpiredGrant_IsRejected()
    {
        var challenge = new OtpChallenge
        {
            Email = "expired@connexa.com",
            RegistrationFlowId = "flow_expired",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_expired_token",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(-5), // Expired 5 minutes ago
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var (isValid, _, _, _, errorMessage) = await _policyService.ValidateGrantAsync(
            "grant_expired_token",
            "flow_expired");

        Assert.False(isValid);
        Assert.Contains("expired", errorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ConsumeGrantAsync_AtomicallyConsumesGrant_AndPreventsReuse()
    {
        var challenge = new OtpChallenge
        {
            Email = "singleuse@connexa.com",
            RegistrationFlowId = "flow_single_use",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_single_use_token",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        // First consume succeeds
        var (firstConsumed, method, destination, firstErr) = await _policyService.ConsumeGrantAsync(
            "grant_single_use_token",
            "flow_single_use");

        Assert.True(firstConsumed);
        Assert.Equal("Email", method);
        Assert.Null(firstErr);

        // Verification challenge in database should be updated
        var updatedChallenge = await _dbContext.OtpChallenges.FindAsync(challenge.Id);
        Assert.Null(updatedChallenge!.VerificationGrantToken);
        Assert.Equal(OtpChallengeStatus.Superseded, updatedChallenge.Status);

        // Second consume attempt with the same token must be rejected (single-use guarantee)
        var (secondConsumed, _, _, secondErr) = await _policyService.ConsumeGrantAsync(
            "grant_single_use_token",
            "flow_single_use");

        Assert.False(secondConsumed);
        Assert.Contains("Invalid verification grant", secondErr);
    }
}

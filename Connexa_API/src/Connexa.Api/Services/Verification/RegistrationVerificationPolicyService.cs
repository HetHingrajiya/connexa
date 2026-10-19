using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Connexa.Api.Data;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Verification;

public class RegistrationVerificationPolicyService : IRegistrationVerificationPolicyService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly ILogger<RegistrationVerificationPolicyService> _logger;

    public RegistrationVerificationPolicyService(
        ConnexaDbContext dbContext,
        IOtpCryptographyService crypto,
        ILogger<RegistrationVerificationPolicyService> logger)
    {
        _dbContext = dbContext;
        _crypto = crypto;
        _logger = logger;
    }

    public async Task<(bool IsValid, string? VerifiedMethod, string? MaskedDestination, DateTime? ExpiresAtUtc, string? ErrorMessage)> ValidateGrantAsync(
        string verificationGrant,
        string registrationFlowId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(verificationGrant))
        {
            return (false, null, null, null, "Verification grant token is required.");
        }

        if (string.IsNullOrWhiteSpace(registrationFlowId))
        {
            return (false, null, null, null, "RegistrationFlowId is required.");
        }

        var cleanGrant = verificationGrant.Trim();
        var cleanFlowId = registrationFlowId.Trim();

        var challenge = await _dbContext.OtpChallenges
            .FirstOrDefaultAsync(c => c.VerificationGrantToken == cleanGrant, cancellationToken);

        if (challenge == null)
        {
            _logger.LogWarning("[Policy] Verification grant not found: {Grant}", cleanGrant[..Math.Min(8, cleanGrant.Length)] + "...");
            return (false, null, null, null, "Invalid verification grant token.");
        }

        if (!challenge.RegistrationFlowId.Equals(cleanFlowId, StringComparison.Ordinal))
        {
            _logger.LogWarning("[Policy] Flow mismatch for grant {Grant}. Expected: {ExpectedFlow}, Actual: {ActualFlow}",
                cleanGrant[..Math.Min(8, cleanGrant.Length)], challenge.RegistrationFlowId, cleanFlowId);
            return (false, null, null, null, "Verification grant does not belong to this registration session.");
        }

        if (challenge.Status != OtpChallengeStatus.Verified)
        {
            _logger.LogWarning("[Policy] Grant challenge is not in verified state ({Status})", challenge.Status);
            return (false, null, null, null, $"Verification grant is invalid ({challenge.Status}).");
        }

        var now = DateTime.UtcNow;
        if (challenge.VerificationGrantExpiresAtUtc == null || now > challenge.VerificationGrantExpiresAtUtc.Value)
        {
            _logger.LogWarning("[Policy] Verification grant expired at {ExpiresAtUtc}", challenge.VerificationGrantExpiresAtUtc);
            return (false, null, null, null, "Verification grant token has expired. Please verify your contact information again.");
        }

        // Determine method and masked destination strictly from server-side state
        string method;
        string maskedDestination;

        if (!string.IsNullOrWhiteSpace(challenge.Email))
        {
            method = "Email";
            maskedDestination = _crypto.MaskEmail(challenge.Email);
        }
        else if (!string.IsNullOrWhiteSpace(challenge.PhoneNumber))
        {
            method = "WhatsApp";
            maskedDestination = _crypto.MaskPhoneNumber(challenge.PhoneNumber);
        }
        else
        {
            return (false, null, null, null, "Corrupt challenge destination state.");
        }

        return (true, method, maskedDestination, challenge.VerificationGrantExpiresAtUtc, null);
    }

    public async Task<(bool Consumed, string? VerifiedMethod, string? MaskedDestination, string? ErrorMessage)> ConsumeGrantAsync(
        string verificationGrant,
        string registrationFlowId,
        CancellationToken cancellationToken = default)
    {
        var (isValid, method, destination, _, errorMessage) = await ValidateGrantAsync(verificationGrant, registrationFlowId, cancellationToken);
        if (!isValid)
        {
            return (false, null, null, errorMessage);
        }

        var cleanGrant = verificationGrant.Trim();
        var challenge = await _dbContext.OtpChallenges
            .FirstOrDefaultAsync(c => c.VerificationGrantToken == cleanGrant, cancellationToken);

        if (challenge == null)
        {
            return (false, null, null, "Verification grant token not found during atomic consumption.");
        }

        // Invalidate grant atomically so it can never be consumed again
        challenge.VerificationGrantToken = null;
        challenge.VerificationGrantExpiresAtUtc = null;
        challenge.Status = OtpChallengeStatus.Superseded;

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Policy] Verification grant consumed successfully for method: {Method}, destination: {Destination}.",
            method, destination);

        return (true, method, destination, null);
    }
}

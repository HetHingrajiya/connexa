namespace Connexa.Api.Services.Verification;

public interface IRegistrationVerificationPolicyService
{
    /// <summary>
    /// Validates an opaque server-issued verification grant against the single-source-of-truth database state.
    /// Determines whether either Email OR Phone was verified, without consuming the grant.
    /// </summary>
    Task<(bool IsValid, string? VerifiedMethod, string? MaskedDestination, DateTime? ExpiresAtUtc, string? ErrorMessage)> ValidateGrantAsync(
        string verificationGrant,
        string registrationFlowId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Atomically consumes a verification grant so it cannot be reused for another registration attempt.
    /// </summary>
    Task<(bool Consumed, string? VerifiedMethod, string? MaskedDestination, string? ErrorMessage)> ConsumeGrantAsync(
        string verificationGrant,
        string registrationFlowId,
        CancellationToken cancellationToken = default);
}

using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Auth;

public record AuthResult<T>(
    bool Success,
    T? Data,
    string? ErrorMessage,
    int StatusCode = 200
);

public interface IAuthService
{
    /// <summary>
    /// Sets password for an existing verified member using a server-validated credential setup authorization
    /// (either single-use CredentialSetupToken from registration or verified OTP grant).
    /// </summary>
    Task<AuthResult<AuthResponseDto>> SetupPasswordAsync(SetupPasswordRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Authenticates a member by email or normalized phone number and password.
    /// Rate limits attempts and locks account on repeated failures. Never grants Admin privileges.
    /// </summary>
    Task<AuthResult<AuthResponseDto>> LoginAsync(LoginRequestDto request, string? clientIp, string? userAgent = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Rotates refresh token, detecting replay attacks, and issues a new access token and refresh token.
    /// </summary>
    Task<AuthResult<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request, string? clientIp, string? userAgent = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Revokes active refresh token.
    /// </summary>
    Task<AuthResult<bool>> LogoutAsync(LogoutRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves current member profile and typed details from database based on authenticated member ID claim.
    /// </summary>
    Task<AuthResult<MemberProfileResponseDto>> GetMemberProfileAsync(int memberId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates profile information for the authenticated member with server-side validation and ownership checks.
    /// </summary>
    Task<AuthResult<MemberProfileResponseDto>> UpdateMemberProfileAsync(int authenticatedMemberId, UpdateMemberProfileRequestDto request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Dispatches an OTP to a registered member's verified contact (email or WhatsApp) to authorize password setup.
    /// </summary>
    Task<AuthResult<RequestSetupOtpResponseDto>> RequestSetupOtpAsync(RequestSetupOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Verifies OTP challenge and generates a fresh, single-use, 30-minute CredentialSetupToken for the registered member.
    /// </summary>
    Task<AuthResult<VerifySetupOtpResponseDto>> VerifySetupOtpAsync(VerifySetupOtpRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    // --- Step 29: Security & Account Management ---

    /// <summary>
    /// Initiates password recovery by dispatching an OTP to the member's verified email or WhatsApp.
    /// </summary>
    Task<AuthResult<ForgotPasswordResponseDto>> ForgotPasswordAsync(ForgotPasswordRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Verifies password reset OTP, validates new password complexity, updates member password, and revokes all active sessions.
    /// </summary>
    Task<AuthResult<bool>> ResetPasswordAsync(ResetPasswordRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Authenticated password change requiring current password verification and password policy compliance.
    /// </summary>
    Task<AuthResult<bool>> ChangePasswordAsync(int memberId, ChangePasswordRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves list of active sessions (refresh tokens) for the member.
    /// </summary>
    Task<AuthResult<List<ActiveSessionDto>>> GetActiveSessionsAsync(int memberId, string? currentTokenHash, CancellationToken cancellationToken = default);

    /// <summary>
    /// Revokes a specific active session owned by the member.
    /// </summary>
    Task<AuthResult<bool>> RevokeSessionAsync(int memberId, int sessionId, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Revokes all active sessions for the member except the current session.
    /// </summary>
    Task<AuthResult<int>> RevokeAllOtherSessionsAsync(int memberId, string? currentTokenHash, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deactivates member account, requiring password verification, and revokes all sessions.
    /// </summary>
    Task<AuthResult<bool>> DeactivateAccountAsync(int memberId, DeactivateAccountRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Submits a formal account deletion request, requiring password verification, and deactivates the account.
    /// </summary>
    Task<AuthResult<bool>> RequestAccountDeletionAsync(int memberId, DeleteAccountRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns account security and status summary (active status, pending deletion request).
    /// </summary>
    Task<AuthResult<AccountStatusResponseDto>> GetAccountStatusAsync(int memberId, CancellationToken cancellationToken = default);
}

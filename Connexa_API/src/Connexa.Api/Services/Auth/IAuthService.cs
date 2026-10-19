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
    Task<AuthResult<AuthResponseDto>> LoginAsync(LoginRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

    /// <summary>
    /// Rotates refresh token, detecting replay attacks, and issues a new access token and refresh token.
    /// </summary>
    Task<AuthResult<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request, string? clientIp, CancellationToken cancellationToken = default);

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
}

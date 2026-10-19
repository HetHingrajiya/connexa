using System.Security.Claims;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Auth;

public interface ITokenService
{
    /// <summary>
    /// Generates a short-lived JWT access token signed with HMAC-SHA256 containing member claims.
    /// Public registration and standard logins strictly issue "Member" role.
    /// </summary>
    string GenerateAccessToken(Member member);

    /// <summary>
    /// Generates a cryptographically secure random refresh token and its corresponding entity with hashed token.
    /// </summary>
    (string PlainRefreshToken, RefreshToken Entity) GenerateRefreshToken(int memberId, string? clientIp);

    /// <summary>
    /// Produces the SHA-256 hash of a plain refresh token for safe database lookups.
    /// </summary>
    string HashRefreshToken(string rawToken);

    /// <summary>
    /// Validates an access token and returns claims principal, ignoring token expiration (for refresh flows).
    /// </summary>
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}

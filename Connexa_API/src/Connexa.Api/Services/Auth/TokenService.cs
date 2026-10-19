using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Connexa.Api.Configuration;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Auth;

public class TokenService : ITokenService
{
    private readonly JwtOptions _jwtOptions;

    public TokenService(IOptions<JwtOptions> jwtOptions)
    {
        _jwtOptions = jwtOptions.Value;
    }

    public string GenerateAccessToken(Member member)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_jwtOptions.SigningKey);

        // Public registration and login must never grant Admin privileges. Enforce Member role.
        var effectiveRole = string.Equals(member.Role, "Member", StringComparison.OrdinalIgnoreCase)
            ? "Member"
            : "Member";

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, member.Id.ToString()),
            new(ClaimTypes.NameIdentifier, member.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, member.Email),
            new(JwtRegisteredClaimNames.Name, member.FullName),
            new(ClaimTypes.Role, effectiveRole),
            new("phone", member.PhoneNumber),
            new("profile_type", member.PrimaryProfileType.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Issuer = _jwtOptions.Issuer,
            Audience = _jwtOptions.Audience,
            Expires = DateTime.UtcNow.AddMinutes(_jwtOptions.AccessTokenExpirationMinutes),
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key),
                SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    public (string PlainRefreshToken, RefreshToken Entity) GenerateRefreshToken(int memberId, string? clientIp)
    {
        // 32 cryptographically random bytes = 64 hex characters
        byte[] randomBytes = RandomNumberGenerator.GetBytes(32);
        string plainToken = Convert.ToHexString(randomBytes);
        string tokenHash = HashRefreshToken(plainToken);

        var entity = new RefreshToken
        {
            MemberId = memberId,
            TokenHash = tokenHash,
            ExpiresAtUtc = DateTime.UtcNow.AddDays(_jwtOptions.RefreshTokenExpirationDays),
            CreatedAtUtc = DateTime.UtcNow,
            CreatedByIp = clientIp
        };

        return (plainToken, entity);
    }

    public string HashRefreshToken(string rawToken)
    {
        if (string.IsNullOrWhiteSpace(rawToken))
            throw new ArgumentException("Refresh token cannot be empty.", nameof(rawToken));

        byte[] hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken.Trim()));
        return Convert.ToHexString(hashBytes);
    }

    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidAudience = _jwtOptions.Audience,
            ValidateIssuer = true,
            ValidIssuer = _jwtOptions.Issuer,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtOptions.SigningKey)),
            ValidateLifetime = false // Here we don't care about token's expiration
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        try
        {
            var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);
            if (securityToken is not JwtSecurityToken jwtSecurityToken ||
                !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            {
                return null;
            }

            return principal;
        }
        catch
        {
            return null;
        }
    }
}

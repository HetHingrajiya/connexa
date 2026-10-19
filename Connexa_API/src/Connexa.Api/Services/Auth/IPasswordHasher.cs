namespace Connexa.Api.Services.Auth;

public interface IPasswordHasher
{
    /// <summary>
    /// Generates a cryptographically secure salt and hashes the password using PBKDF2-HMAC-SHA256 (100,000 iterations).
    /// </summary>
    (string Hash, string Salt) HashPassword(string password);

    /// <summary>
    /// Verifies the plain password against the stored hash and salt using constant-time comparison.
    /// </summary>
    bool VerifyPassword(string password, string storedHash, string storedSalt);

    /// <summary>
    /// Validates password complexity policy: minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 digit, 1 special character.
    /// </summary>
    (bool IsValid, string? ErrorMessage) ValidatePasswordPolicy(string password);
}

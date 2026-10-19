using System.Security.Cryptography;
using System.Text;

namespace Connexa.Api.Services.Auth;

public class PasswordHasher : IPasswordHasher
{
    private const int SaltSizeBytes = 16;      // 128 bits
    private const int HashSizeBytes = 32;      // 256 bits
    private const int Iterations = 100_000;    // OWASP recommendation for PBKDF2-HMAC-SHA256

    public (string Hash, string Salt) HashPassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
            throw new ArgumentException("Password cannot be empty.", nameof(password));

        byte[] saltBytes = RandomNumberGenerator.GetBytes(SaltSizeBytes);
        byte[] hashBytes = Rfc2898DeriveBytes.Pbkdf2(
            Encoding.UTF8.GetBytes(password),
            saltBytes,
            Iterations,
            HashAlgorithmName.SHA256,
            HashSizeBytes);

        return (Convert.ToHexString(hashBytes), Convert.ToHexString(saltBytes));
    }

    public bool VerifyPassword(string password, string storedHash, string storedSalt)
    {
        if (string.IsNullOrWhiteSpace(password) ||
            string.IsNullOrWhiteSpace(storedHash) ||
            string.IsNullOrWhiteSpace(storedSalt))
        {
            return false;
        }

        try
        {
            byte[] saltBytes = Convert.FromHexString(storedSalt);
            byte[] storedHashBytes = Convert.FromHexString(storedHash);

            byte[] computedHashBytes = Rfc2898DeriveBytes.Pbkdf2(
                Encoding.UTF8.GetBytes(password),
                saltBytes,
                Iterations,
                HashAlgorithmName.SHA256,
                HashSizeBytes);

            return CryptographicOperations.FixedTimeEquals(computedHashBytes, storedHashBytes);
        }
        catch
        {
            return false;
        }
    }

    public (bool IsValid, string? ErrorMessage) ValidatePasswordPolicy(string password)
    {
        if (string.IsNullOrEmpty(password))
        {
            return (false, "Password is required.");
        }

        if (password.Length < 8)
        {
            return (false, "Password must be at least 8 characters long.");
        }

        if (password.Length > 128)
        {
            return (false, "Password must not exceed 128 characters.");
        }

        bool hasUpper = false;
        bool hasLower = false;
        bool hasDigit = false;
        bool hasSpecial = false;

        foreach (char c in password)
        {
            if (char.IsUpper(c)) hasUpper = true;
            else if (char.IsLower(c)) hasLower = true;
            else if (char.IsDigit(c)) hasDigit = true;
            else if (!char.IsWhiteSpace(c)) hasSpecial = true;
        }

        if (!hasUpper)
        {
            return (false, "Password must contain at least one uppercase letter (A-Z).");
        }

        if (!hasLower)
        {
            return (false, "Password must contain at least one lowercase letter (a-z).");
        }

        if (!hasDigit)
        {
            return (false, "Password must contain at least one numerical digit (0-9).");
        }

        if (!hasSpecial)
        {
            return (false, "Password must contain at least one special character (!@#$%^&* etc.).");
        }

        return (true, null);
    }
}

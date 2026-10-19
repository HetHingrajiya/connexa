namespace Connexa.Api.Services.Verification;

/// <summary>
/// Cryptographic operations for OTP generation, salting, HMAC hashing,
/// constant-time verification, and opaque verification grant generation.
/// </summary>
public interface IOtpCryptographyService
{
    /// <summary>
    /// Generates a cryptographically secure 6-digit numeric OTP code.
    /// </summary>
    string GenerateOtpCode();

    /// <summary>
    /// Generates a 16-byte cryptographically secure random salt formatted in Base64.
    /// </summary>
    string GenerateSalt();

    /// <summary>
    /// Computes an HMAC-SHA256 hash using the server secret key over salt, OTP code, and normalized phone.
    /// </summary>
    string HashOtp(string otpCode, string salt, string normalizedPhoneNumber);

    /// <summary>
    /// Performs a constant-time comparison to verify user-entered OTP against the stored hash.
    /// </summary>
    bool VerifyOtp(string inputOtpCode, string storedSalt, string normalizedPhoneNumber, string storedHash);

    /// <summary>
    /// Generates a 256-bit (32-byte) cryptographically secure opaque hexadecimal grant token.
    /// </summary>
    string GenerateVerificationGrant();

    /// <summary>
    /// Normalizes and validates a phone number into strict E.164 format.
    /// </summary>
    string NormalizePhoneNumber(string input);

    /// <summary>
    /// Masks a phone number for safe presentation in logs, responses, and UI.
    /// </summary>
    string MaskPhoneNumber(string phoneNumber);

    /// <summary>
    /// Computes an HMAC-SHA256 hash using the server secret key over salt, OTP code, and normalized email.
    /// </summary>
    string HashEmailOtp(string otpCode, string salt, string normalizedEmail);

    /// <summary>
    /// Performs a constant-time comparison to verify user-entered OTP against the stored email hash.
    /// </summary>
    bool VerifyEmailOtp(string inputOtpCode, string storedSalt, string normalizedEmail, string storedHash);

    /// <summary>
    /// Normalizes and validates an email address.
    /// </summary>
    string NormalizeEmail(string input);

    /// <summary>
    /// Masks an email address for safe presentation in logs, responses, and UI (e.g. j***e@domain.com).
    /// </summary>
    string MaskEmail(string email);
}

using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;

namespace Connexa.Api.Services.Verification;

public partial class OtpCryptographyService : IOtpCryptographyService
{
    private readonly OtpSecurityOptions _options;
    private readonly byte[] _hmacKeyBytes;

    public OtpCryptographyService(IOptions<OtpSecurityOptions> options)
    {
        _options = options.Value;
        var key = !string.IsNullOrWhiteSpace(_options.HmacSecretKey)
            ? _options.HmacSecretKey
            : "Connexa_Secure_Otp_Hmac_Secret_Key_Default_ChangeInProd";
        _hmacKeyBytes = Encoding.UTF8.GetBytes(key);
    }

    public string GenerateOtpCode()
    {
        // Generate a 6-digit number uniformly distributed in [100000, 999999]
        var code = RandomNumberGenerator.GetInt32(100000, 1000000);
        return code.ToString("D6");
    }

    public string GenerateSalt()
    {
        var saltBytes = RandomNumberGenerator.GetBytes(16);
        return Convert.ToBase64String(saltBytes);
    }

    public string HashOtp(string otpCode, string salt, string normalizedPhoneNumber)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(otpCode);
        ArgumentException.ThrowIfNullOrWhiteSpace(salt);
        ArgumentException.ThrowIfNullOrWhiteSpace(normalizedPhoneNumber);

        // Bind hash to salt, OTP code, and normalized destination number to prevent cross-number attack
        var payload = $"{salt}:{otpCode}:{normalizedPhoneNumber}";
        var payloadBytes = Encoding.UTF8.GetBytes(payload);

        using var hmac = new HMACSHA256(_hmacKeyBytes);
        var hashBytes = hmac.ComputeHash(payloadBytes);
        return Convert.ToBase64String(hashBytes);
    }

    public bool VerifyOtp(string inputOtpCode, string storedSalt, string normalizedPhoneNumber, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(inputOtpCode) ||
            string.IsNullOrWhiteSpace(storedSalt) ||
            string.IsNullOrWhiteSpace(normalizedPhoneNumber) ||
            string.IsNullOrWhiteSpace(storedHash))
        {
            return false;
        }

        try
        {
            var computedHash = HashOtp(inputOtpCode.Trim(), storedSalt, normalizedPhoneNumber);
            var computedBytes = Convert.FromBase64String(computedHash);
            var storedBytes = Convert.FromBase64String(storedHash);

            return CryptographicOperations.FixedTimeEquals(computedBytes, storedBytes);
        }
        catch
        {
            return false;
        }
    }

    public string GenerateVerificationGrant()
    {
        // 256-bit opaque random token
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    public string NormalizePhoneNumber(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            throw new ArgumentException("Phone number cannot be empty.");
        }

        var trimmed = input.Trim();
        var hasPlus = trimmed.StartsWith('+');

        // Extract only numeric digits
        var digitsOnly = DigitsRegex().Replace(trimmed, "");

        if (string.IsNullOrEmpty(digitsOnly))
        {
            throw new ArgumentException("Phone number must contain numeric digits.");
        }

        // If phone has 10 digits without leading country code, default to Indian (+91)
        if (!hasPlus && digitsOnly.Length == 10)
        {
            return $"+91{digitsOnly}";
        }

        // If starting with 00 (international call prefix), replace with +
        if (trimmed.StartsWith("00"))
        {
            digitsOnly = digitsOnly.Substring(2);
            hasPlus = true;
        }

        if (digitsOnly.Length < 7 || digitsOnly.Length > 15)
        {
            throw new ArgumentException("Phone number length must be between 7 and 15 digits according to E.164 standard.");
        }

        return $"+{digitsOnly}";
    }

    public string MaskPhoneNumber(string phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(phoneNumber))
            return "***";

        var clean = phoneNumber.Trim();
        if (clean.Length <= 5)
            return $"{clean[0]}•••{clean[^1]}";

        var prefixLen = clean.StartsWith('+') ? 3 : 2;
        var prefix = clean[..Math.Min(prefixLen, clean.Length)];
        var suffix = clean[Math.Max(0, clean.Length - 3)..];

        return $"{prefix} ••••• ••{suffix}";
    }

    public string HashEmailOtp(string otpCode, string salt, string normalizedEmail)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(otpCode);
        ArgumentException.ThrowIfNullOrWhiteSpace(salt);
        ArgumentException.ThrowIfNullOrWhiteSpace(normalizedEmail);

        // Bind hash to salt, OTP code, and normalized destination email with domain separator
        var payload = $"email:{salt}:{otpCode}:{normalizedEmail.Trim().ToLowerInvariant()}";
        var payloadBytes = Encoding.UTF8.GetBytes(payload);

        using var hmac = new HMACSHA256(_hmacKeyBytes);
        var hashBytes = hmac.ComputeHash(payloadBytes);
        return Convert.ToBase64String(hashBytes);
    }

    public bool VerifyEmailOtp(string inputOtpCode, string storedSalt, string normalizedEmail, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(inputOtpCode) ||
            string.IsNullOrWhiteSpace(storedSalt) ||
            string.IsNullOrWhiteSpace(normalizedEmail) ||
            string.IsNullOrWhiteSpace(storedHash))
        {
            return false;
        }

        try
        {
            var computedHash = HashEmailOtp(inputOtpCode.Trim(), storedSalt, normalizedEmail);
            var computedBytes = Convert.FromBase64String(computedHash);
            var storedBytes = Convert.FromBase64String(storedHash);

            return CryptographicOperations.FixedTimeEquals(computedBytes, storedBytes);
        }
        catch
        {
            return false;
        }
    }

    public string NormalizeEmail(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            throw new ArgumentException("Email address cannot be empty.");
        }

        var trimmed = input.Trim().ToLowerInvariant();

        try
        {
            var mailAddress = new System.Net.Mail.MailAddress(trimmed);
            if (mailAddress.Address != trimmed)
            {
                throw new ArgumentException("Email address format is invalid.");
            }
            if (!trimmed.Contains('.') || trimmed.StartsWith('.') || trimmed.EndsWith('.'))
            {
                throw new ArgumentException("Email address must contain a valid domain name.");
            }
            return trimmed;
        }
        catch (FormatException)
        {
            throw new ArgumentException("Email address format is invalid.");
        }
    }

    public string MaskEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return "***@***";

        var clean = email.Trim().ToLowerInvariant();
        var atIndex = clean.IndexOf('@');
        if (atIndex <= 0 || atIndex >= clean.Length - 1)
            return "***@***";

        var localPart = clean[..atIndex];
        var domain = clean[(atIndex + 1)..];

        string maskedLocal;
        if (localPart.Length <= 2)
        {
            maskedLocal = $"{localPart[0]}*";
        }
        else
        {
            maskedLocal = $"{localPart[0]}•••{localPart[^1]}";
        }

        return $"{maskedLocal}@{domain}";
    }

    [GeneratedRegex(@"[^\d]")]
    private static partial Regex DigitsRegex();
}

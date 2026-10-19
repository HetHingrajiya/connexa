namespace Connexa.Api.Entities;

public enum OtpChallengeStatus
{
    Pending = 0,
    Verified = 1,
    Expired = 2,
    MaxAttemptsExceeded = 3,
    Superseded = 4
}

/// <summary>
/// Dedicated entity recording OTP verification challenges with hashed codes, attempt tracking,
/// rate limiting metadata, and short-lived verification grants.
/// </summary>
public class OtpChallenge
{
    public int Id { get; set; }

    /// <summary>
    /// E.164 formatted phone number with leading + (e.g., +919876543210).
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Normalized email address (e.g., user@example.com).
    /// </summary>
    public string? Email { get; set; }

    /// <summary>
    /// Direct 6-digit OTP code stored in plaintext (no encryption) for direct database inspection.
    /// </summary>
    public string OtpCode { get; set; } = string.Empty;

    /// <summary>
    /// Cryptographic random salt (Base64) unique to this challenge.
    /// </summary>
    public string OtpHashingSalt { get; set; } = string.Empty;

    /// <summary>
    /// HMAC-SHA256 hash (Base64) of the OTP, salt, and destination phone number.
    /// Never stores the plaintext OTP.
    /// </summary>
    public string OtpHash { get; set; } = string.Empty;

    /// <summary>
    /// Verification domain / purpose (default: "RegistrationVerification").
    /// </summary>
    public string Purpose { get; set; } = "RegistrationVerification";

    /// <summary>
    /// Client-side registration session / flow correlation identifier.
    /// </summary>
    public string RegistrationFlowId { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAtUtc { get; set; }
    public DateTime? VerifiedAtUtc { get; set; }

    public int AttemptCount { get; set; } = 0;
    public int MaxAttempts { get; set; } = 5;

    public int ResendCount { get; set; } = 0;
    public DateTime? LastResentAtUtc { get; set; }

    public OtpChallengeStatus Status { get; set; } = OtpChallengeStatus.Pending;

    /// <summary>
    /// Opaque, single-use, cryptographically random grant token returned to the client upon successful verification.
    /// </summary>
    public string? VerificationGrantToken { get; set; }

    public DateTime? VerificationGrantExpiresAtUtc { get; set; }

    /// <summary>
    /// IP address of the requesting client for abuse prevention.
    /// </summary>
    public string? RequestIpAddress { get; set; }

    /// <summary>
    /// Upstream message identifier returned by the WhatsApp provider (excludes any secret or OTP).
    /// </summary>
    public string? ProviderMessageId { get; set; }
}

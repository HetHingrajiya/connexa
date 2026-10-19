namespace Connexa.Api.Configuration;

/// <summary>
/// Security settings for OTP generation, hashing, rate limiting, and verification grants.
/// </summary>
public class OtpSecurityOptions
{
    public const string SectionName = "OtpSecurity";

    /// <summary>
    /// OTP validity duration in seconds (default: 300 seconds = 5 minutes).
    /// </summary>
    public int OtpLifetimeSeconds { get; set; } = 300;

    /// <summary>
    /// Enforced resend cooldown duration in seconds (default: 60 seconds).
    /// </summary>
    public int ResendCooldownSeconds { get; set; } = 60;

    /// <summary>
    /// Maximum verification attempts allowed per challenge before permanent invalidation (default: 5).
    /// </summary>
    public int MaxAttempts { get; set; } = 5;

    /// <summary>
    /// Maximum resends allowed per challenge lifecycle (default: 3).
    /// </summary>
    public int MaxResends { get; set; } = 3;

    /// <summary>
    /// Maximum active challenges created per destination phone number within 1 hour (default: 5).
    /// </summary>
    public int MaxChallengesPerHourPerPhone { get; set; } = 5;

    /// <summary>
    /// Maximum active challenges created per destination email address within 1 hour (default: 5).
    /// </summary>
    public int MaxChallengesPerHourPerEmail { get; set; } = 5;

    /// <summary>
    /// Maximum OTP dispatch requests per IP address within 10 minutes (default: 20).
    /// </summary>
    public int MaxRequestsPerTenMinutesPerIp { get; set; } = 20;

    /// <summary>
    /// Lifetime of the opaque server-issued verification grant in minutes (default: 60 minutes).
    /// </summary>
    public int VerificationGrantLifetimeMinutes { get; set; } = 60;

    /// <summary>
    /// Cryptographic server secret key used for HMAC-SHA256 OTP hashing.
    /// Loaded from environment / secret manager or securely derived.
    /// </summary>
    public string HmacSecretKey { get; set; } = "Connexa_Secure_Otp_Hmac_Secret_Key_Default_ChangeInProd";
}

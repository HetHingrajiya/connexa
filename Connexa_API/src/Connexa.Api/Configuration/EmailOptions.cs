namespace Connexa.Api.Configuration;

/// <summary>
/// Configuration options for Gmail SMTP email OTP dispatch.
/// Sensitive credentials must be provided via .NET User Secrets or environment variables.
/// </summary>
public class EmailOptions
{
    public const string SectionName = "Email";

    /// <summary>
    /// SMTP Server Host (default: smtp.gmail.com).
    /// </summary>
    public string SmtpHost { get; set; } = "smtp.gmail.com";

    /// <summary>
    /// SMTP Server Port (default: 587 for STARTTLS).
    /// </summary>
    public int SmtpPort { get; set; } = 587;

    /// <summary>
    /// Whether to enforce STARTTLS connection encryption.
    /// </summary>
    public bool UseStartTls { get; set; } = true;

    /// <summary>
    /// Sender Gmail address used for authenticating with Gmail SMTP and composing the From header.
    /// Never commit this to source control.
    /// </summary>
    public string SenderAddress { get; set; } = string.Empty;

    /// <summary>
    /// Sender display name displayed to email recipients (default: "Connexa").
    /// </summary>
    public string SenderDisplayName { get; set; } = "Connexa";

    /// <summary>
    /// 16-character Google App Password used for SMTP authentication.
    /// Strictly kept in User Secrets / environment variables, never logged, exposed, or committed.
    /// </summary>
    public string AppPassword { get; set; } = string.Empty;

    /// <summary>
    /// Whether the email provider has valid SMTP credentials configured.
    /// </summary>
    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(SenderAddress) &&
        !string.IsNullOrWhiteSpace(AppPassword);
}

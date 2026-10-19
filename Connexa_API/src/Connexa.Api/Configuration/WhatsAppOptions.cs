namespace Connexa.Api.Configuration;

/// <summary>
/// Configuration settings for WhatsApp message dispatch.
/// </summary>
public class WhatsAppOptions
{
    public const string SectionName = "WhatsApp";

    private string _provider = "Development";

    /// <summary>
    /// Active provider: "Development" (simulated, strictly for dev/test) or "MetaCloudApi".
    /// Can be overridden via WHATSAPP_PROVIDER environment variable.
    /// </summary>
    public string Provider
    {
        get => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("WHATSAPP_PROVIDER"))
            ? Environment.GetEnvironmentVariable("WHATSAPP_PROVIDER")!
            : _provider;
        set => _provider = value;
    }

    /// <summary>
    /// Official Meta WhatsApp Business Platform Cloud API configuration.
    /// </summary>
    public MetaCloudApiOptions MetaCloudApi { get; set; } = new();
}

public class MetaCloudApiOptions
{
    /// <summary>
    /// Base Graph API URL (default: "https://graph.facebook.com").
    /// </summary>
    public string BaseUrl { get; set; } = "https://graph.facebook.com";

    /// <summary>
    /// Graph API version (default: "v21.0").
    /// </summary>
    public string ApiVersion { get; set; } = "v21.0";

    private string? _phoneNumberId;

    /// <summary>
    /// WhatsApp Business Phone Number ID from Meta App Dashboard.
    /// Can be overridden via WHATSAPP_PHONE_NUMBER_ID environment variable or dotnet user-secrets.
    /// </summary>
    public string? PhoneNumberId
    {
        get => !string.IsNullOrWhiteSpace(_phoneNumberId)
            ? _phoneNumberId
            : Environment.GetEnvironmentVariable("WHATSAPP_PHONE_NUMBER_ID");
        set => _phoneNumberId = value;
    }

    private string? _businessAccountId;

    /// <summary>
    /// WhatsApp Business Account ID (WABA ID).
    /// Can be overridden via WHATSAPP_BUSINESS_ACCOUNT_ID environment variable or dotnet user-secrets.
    /// </summary>
    public string? BusinessAccountId
    {
        get => !string.IsNullOrWhiteSpace(_businessAccountId)
            ? _businessAccountId
            : Environment.GetEnvironmentVariable("WHATSAPP_BUSINESS_ACCOUNT_ID");
        set => _businessAccountId = value;
    }

    private string? _accessToken;

    /// <summary>
    /// System User Access Token with 'whatsapp_business_messaging' permission.
    /// Can be overridden via WHATSAPP_ACCESS_TOKEN environment variable or dotnet user-secrets.
    /// Stored securely; NEVER committed to Git or returned from APIs.
    /// </summary>
    public string? AccessToken
    {
        get => !string.IsNullOrWhiteSpace(_accessToken)
            ? _accessToken
            : Environment.GetEnvironmentVariable("WHATSAPP_ACCESS_TOKEN");
        set => _accessToken = value;
    }

    private string _authenticationTemplateName = "connexa_auth_code";

    /// <summary>
    /// Approved authentication template name in Meta WhatsApp Business Manager (e.g., "connexa_auth_code" or "otp_verification").
    /// Can be overridden via WHATSAPP_TEMPLATE_NAME environment variable.
    /// </summary>
    public string AuthenticationTemplateName
    {
        get => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("WHATSAPP_TEMPLATE_NAME"))
            ? Environment.GetEnvironmentVariable("WHATSAPP_TEMPLATE_NAME")!
            : _authenticationTemplateName;
        set => _authenticationTemplateName = value;
    }

    private string _templateLanguageCode = "en_US";

    /// <summary>
    /// Template language code (e.g., "en_US").
    /// </summary>
    public string TemplateLanguageCode
    {
        get => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("WHATSAPP_TEMPLATE_LANGUAGE"))
            ? Environment.GetEnvironmentVariable("WHATSAPP_TEMPLATE_LANGUAGE")!
            : _templateLanguageCode;
        set => _templateLanguageCode = value;
    }

    /// <summary>
    /// Whether all mandatory prerequisites are configured for Meta Cloud API live dispatch.
    /// </summary>
    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(PhoneNumberId) &&
        !string.IsNullOrWhiteSpace(AccessToken) &&
        !string.IsNullOrWhiteSpace(AuthenticationTemplateName);
}

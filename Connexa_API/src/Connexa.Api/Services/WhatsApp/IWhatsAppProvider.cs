namespace Connexa.Api.Services.WhatsApp;

/// <summary>
/// Abstraction for sending OTP messages over WhatsApp.
/// </summary>
public interface IWhatsAppProvider
{
    /// <summary>
    /// Identifier name of the active provider (e.g. "MetaCloudApi", "Development").
    /// </summary>
    string ProviderName { get; }

    /// <summary>
    /// Whether the provider has all mandatory credentials and templates configured.
    /// </summary>
    bool IsConfigured { get; }

    /// <summary>
    /// Dispatches an OTP verification message to the specified E.164 phone number.
    /// Implementations must NEVER log or persist the plaintext OTP.
    /// </summary>
    Task<WhatsAppDispatchResult> SendOtpAsync(
        string normalizedPhoneNumber,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken = default);
}

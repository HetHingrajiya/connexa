namespace Connexa.Api.Services.WhatsApp;

/// <summary>
/// Result of an OTP dispatch attempt through a WhatsApp provider.
/// </summary>
public record WhatsAppDispatchResult(
    bool Accepted,
    string? ProviderMessageId = null,
    string? ErrorMessage = null,
    bool IsSimulated = false
);

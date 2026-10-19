using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Connexa.Api.Services.WhatsApp;

/// <summary>
/// Safe development and testing WhatsApp provider.
/// Strictly prohibited in production environments. Never sends real messages.
/// Never logs or leaks plaintext OTPs.
/// </summary>
public class DevelopmentWhatsAppProvider : IWhatsAppProvider
{
    private readonly IHostEnvironment _environment;
    private readonly ILogger<DevelopmentWhatsAppProvider> _logger;

    public DevelopmentWhatsAppProvider(
        IHostEnvironment environment,
        ILogger<DevelopmentWhatsAppProvider> logger)
    {
        _environment = environment;
        _logger = logger;

        if (_environment.IsProduction())
        {
            throw new InvalidOperationException(
                "CRITICAL SECURITY VIOLATION: DevelopmentWhatsAppProvider is strictly prohibited from running in Production.");
        }
    }

    public string ProviderName => "Development";

    public bool IsConfigured => true;

    public Task<WhatsAppDispatchResult> SendOtpAsync(
        string normalizedPhoneNumber,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken = default)
    {
        if (_environment.IsProduction())
        {
            throw new InvalidOperationException(
                "CRITICAL SECURITY VIOLATION: Attempted to invoke DevelopmentWhatsAppProvider in Production.");
        }

        // Mask phone number for logging: keep country code and last 3 digits
        var masked = MaskPhone(normalizedPhoneNumber);

        _logger.LogInformation(
            "===============================================================\n" +
            "[DEV-MODE-ONLY] WhatsApp OTP for destination {MaskedPhone}: >>> {OtpCode} <<<\n" +
            "Session Flow: {FlowId} (Live WhatsApp delivery disabled in Development)\n" +
            "===============================================================",
            masked, otpCode, registrationFlowId);

        var simulatedMessageId = $"dev_msg_{Guid.NewGuid():N}";
        return Task.FromResult(new WhatsAppDispatchResult(
            Accepted: true,
            ProviderMessageId: simulatedMessageId,
            IsSimulated: true
        ));
    }

    private static string MaskPhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone) || phone.Length < 6)
            return "***";

        var prefix = phone.Substring(0, Math.Min(3, phone.Length));
        var suffix = phone.Substring(Math.Max(0, phone.Length - 3));
        return $"{prefix}•••••{suffix}";
    }
}

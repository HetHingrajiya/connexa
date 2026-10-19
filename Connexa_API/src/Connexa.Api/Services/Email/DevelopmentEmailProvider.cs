using Microsoft.Extensions.Logging;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Services.Email;

public class DevelopmentEmailProvider : IEmailProvider
{
    private readonly IOtpCryptographyService _crypto;
    private readonly ILogger<DevelopmentEmailProvider> _logger;

    public string ProviderName => "DevelopmentSimulated";
    public bool IsConfigured => true;

    public DevelopmentEmailProvider(
        IOtpCryptographyService crypto,
        ILogger<DevelopmentEmailProvider> logger)
    {
        _crypto = crypto;
        _logger = logger;
    }

    public Task<EmailDispatchResult> SendOtpEmailAsync(
        string toEmail,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken)
    {
        var maskedEmail = _crypto.MaskEmail(toEmail);
        _logger.LogInformation("[DevelopmentEmailProvider] Simulation: Email OTP dispatched for {MaskedEmail} (Flow: {FlowId}). Live SMTP disabled.",
            maskedEmail, registrationFlowId);

        var result = new EmailDispatchResult(
            Accepted: true,
            IsSimulated: true,
            ProviderMessageId: $"sim_mail_{Guid.NewGuid():N}",
            ErrorMessage: null
        );

        return Task.FromResult(result);
    }
}

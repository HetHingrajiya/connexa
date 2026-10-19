namespace Connexa.Api.Services.Email;

public interface IEmailProvider
{
    string ProviderName { get; }
    bool IsConfigured { get; }
    Task<EmailDispatchResult> SendOtpEmailAsync(string toEmail, string otpCode, string registrationFlowId, CancellationToken cancellationToken);
}

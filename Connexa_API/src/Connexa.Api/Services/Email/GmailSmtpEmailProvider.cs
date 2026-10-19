using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;
using Connexa.Api.Configuration;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Services.Email;

public class GmailSmtpEmailProvider : IEmailProvider
{
    private readonly EmailOptions _options;
    private readonly IOtpCryptographyService _crypto;
    private readonly ILogger<GmailSmtpEmailProvider> _logger;

    public string ProviderName => "GmailSmtp";
    public bool IsConfigured => _options.IsConfigured;

    public GmailSmtpEmailProvider(
        IOptions<EmailOptions> options,
        IOtpCryptographyService crypto,
        ILogger<GmailSmtpEmailProvider> logger)
    {
        _options = options.Value;
        _crypto = crypto;
        _logger = logger;
    }

    public async Task<EmailDispatchResult> SendOtpEmailAsync(
        string toEmail,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken)
    {
        var maskedEmail = _crypto.MaskEmail(toEmail);

        if (!IsConfigured)
        {
            _logger.LogWarning("[GmailSmtp] Dispatch aborted: Gmail SMTP credentials (SenderAddress/AppPassword) are not configured.");
            return new EmailDispatchResult(
                Accepted: false,
                IsSimulated: false,
                ProviderMessageId: null,
                ErrorMessage: "Gmail SMTP provider is not configured. Please supply Email:SenderAddress and Email:AppPassword.");
        }

        try
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(_options.SenderDisplayName, _options.SenderAddress));
            message.To.Add(new MailboxAddress(toEmail, toEmail));
            message.Subject = $"{otpCode} is your Connexa verification code";

            var bodyBuilder = new BodyBuilder
            {
                TextBody = $"Your Connexa verification code is: {otpCode}\n\nThis code will expire in 5 minutes.\nDo not share this code with anyone.",
                HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""utf-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Connexa Verification Code</title>
</head>
<body style=""font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b;"">
    <div style=""max-width: 520px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);"">
        <div style=""background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%); padding: 28px 24px; text-align: center;"">
            <h1 style=""color: #ffffff; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px;"">Connexa</h1>
            <p style=""color: #93c5fd; margin: 6px 0 0 0; font-size: 14px;"">One Network for Every Business</p>
        </div>
        <div style=""padding: 32px 24px; text-align: center;"">
            <h2 style=""margin: 0 0 12px 0; font-size: 20px; color: #0f172a;"">Verify Your Email Address</h2>
            <p style=""margin: 0 0 24px 0; color: #64748b; font-size: 15px; line-height: 1.5;"">
                Use the following 6-digit verification code to complete your Connexa registration.
            </p>
            <div style=""display: inline-block; background-color: #f1f5f9; border: 2px dashed #94a3b8; border-radius: 8px; padding: 16px 32px; margin: 0 0 24px 0;"">
                <span style=""font-size: 32px; font-weight: 800; letter-spacing: 10px; color: #1e3a8a; font-family: monospace;"">{otpCode}</span>
            </div>
            <p style=""margin: 0 0 16px 0; font-size: 13px; color: #ef4444; font-weight: 600;"">
                ⏱ This code expires in 5 minutes.
            </p>
            <div style=""background-color: #f8fafc; border-radius: 8px; padding: 12px 16px; margin: 24px 0 0 0; text-align: left; border: 1px solid #e2e8f0;"">
                <p style=""margin: 0; font-size: 12px; color: #64748b; line-height: 1.4;"">
                    <strong>Security Notice:</strong> Never share your verification code with anyone. Connexa employees will never ask for your code. If you did not request this code, you can safely ignore this email.
                </p>
            </div>
        </div>
        <div style=""background-color: #f1f5f9; padding: 16px 24px; text-align: center; border-top: 1px solid #e2e8f0;"">
            <p style=""margin: 0; font-size: 12px; color: #94a3b8;"">
                &copy; 2026 Connexa B2B Platform. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>"
            };

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();

            // Set timeout for fast failure if network is unreachable
            client.Timeout = 15000;

            var secureOptions = _options.UseStartTls
                ? SecureSocketOptions.StartTls
                : SecureSocketOptions.Auto;

            await client.ConnectAsync(_options.SmtpHost, _options.SmtpPort, secureOptions, cancellationToken);

            var cleanPassword = _options.AppPassword.Replace(" ", "");
            await client.AuthenticateAsync(_options.SenderAddress, cleanPassword, cancellationToken);

            var messageId = await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation("[GmailSmtp] Verification email dispatched successfully to {MaskedEmail} (MessageId: {MessageId}).",
                maskedEmail, messageId);

            return new EmailDispatchResult(
                Accepted: true,
                IsSimulated: false,
                ProviderMessageId: messageId ?? $"msg_{Guid.NewGuid():N}",
                ErrorMessage: null);
        }
        catch (AuthenticationException ex)
        {
            _logger.LogError("[GmailSmtp] Authentication failed while sending to {MaskedEmail}: {Error}",
                maskedEmail, ex.Message);
            return new EmailDispatchResult(
                Accepted: false,
                IsSimulated: false,
                ProviderMessageId: null,
                ErrorMessage: "Gmail SMTP authentication failed. Please verify the sender Gmail address and Google App Password.");
        }
        catch (SmtpCommandException ex)
        {
            _logger.LogError("[GmailSmtp] SMTP command rejected for {MaskedEmail} (StatusCode: {StatusCode}): {Error}",
                maskedEmail, ex.StatusCode, ex.Message);
            return new EmailDispatchResult(
                Accepted: false,
                IsSimulated: false,
                ProviderMessageId: null,
                ErrorMessage: $"Gmail SMTP server rejected the dispatch command ({ex.StatusCode}).");
        }
        catch (Exception ex)
        {
            _logger.LogError("[GmailSmtp] Unexpected error delivering email to {MaskedEmail}: {Error}",
                maskedEmail, ex.Message);
            return new EmailDispatchResult(
                Accepted: false,
                IsSimulated: false,
                ProviderMessageId: null,
                ErrorMessage: "Failed to deliver verification code via Gmail SMTP. Please check your network and try again.");
        }
    }
}

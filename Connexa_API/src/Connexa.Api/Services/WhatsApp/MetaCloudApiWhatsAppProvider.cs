using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;

namespace Connexa.Api.Services.WhatsApp;

/// <summary>
/// Production WhatsApp provider integrating with the official Meta WhatsApp Business Platform Cloud API.
/// Never logs or exposes credentials or plaintext OTPs.
/// </summary>
public class MetaCloudApiWhatsAppProvider : IWhatsAppProvider
{
    private readonly HttpClient _httpClient;
    private readonly WhatsAppOptions _options;
    private readonly ILogger<MetaCloudApiWhatsAppProvider> _logger;

    public MetaCloudApiWhatsAppProvider(
        HttpClient httpClient,
        IOptions<WhatsAppOptions> options,
        ILogger<MetaCloudApiWhatsAppProvider> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public string ProviderName => "MetaCloudApi";

    public bool IsConfigured => _options.MetaCloudApi.IsConfigured;

    public async Task<WhatsAppDispatchResult> SendOtpAsync(
        string normalizedPhoneNumber,
        string otpCode,
        string registrationFlowId,
        CancellationToken cancellationToken = default)
    {
        var metaOptions = _options.MetaCloudApi;

        if (!IsConfigured)
        {
            _logger.LogWarning(
                "[MetaCloudApi] Cannot dispatch OTP: Meta Cloud API prerequisites are incomplete (PhoneNumberId: {HasPhoneId}, AccessToken: {HasToken}, Template: {HasTemplate}).",
                !string.IsNullOrWhiteSpace(metaOptions.PhoneNumberId),
                !string.IsNullOrWhiteSpace(metaOptions.AccessToken),
                !string.IsNullOrWhiteSpace(metaOptions.AuthenticationTemplateName));

            return new WhatsAppDispatchResult(
                Accepted: false,
                ErrorMessage: "WhatsApp Cloud API is not configured. Missing Meta Phone Number ID, Access Token, or Template Name."
            );
        }

        // WhatsApp Cloud API expects numbers without leading '+' sign (E.164 digits)
        var recipientDigits = normalizedPhoneNumber.TrimStart('+');
        var endpoint = $"{metaOptions.BaseUrl.TrimEnd('/')}/{metaOptions.ApiVersion}/{metaOptions.PhoneNumberId}/messages";

        // Try primary authentication template payload (with body and copy-code button)
        var payloadWithButton = BuildPayload(recipientDigits, metaOptions.AuthenticationTemplateName, metaOptions.TemplateLanguageCode, otpCode, includeButton: true);

        var (success, messageId, errorMessage, rawError) = await ExecuteSendAsync(endpoint, metaOptions.AccessToken!, payloadWithButton, cancellationToken);
        if (success)
        {
            _logger.LogInformation("[MetaCloudApi] OTP dispatched via Meta Cloud API. Message ID: {MessageId}", messageId);
            return new WhatsAppDispatchResult(Accepted: true, ProviderMessageId: messageId, IsSimulated: false);
        }

        // If rejected because template has no button component, automatically retry with body-only payload
        if (rawError != null && rawError.Contains("button", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("[MetaCloudApi] Retrying with body-only template payload (template may not have a button component)...");
            var bodyOnlyPayload = BuildPayload(recipientDigits, metaOptions.AuthenticationTemplateName, metaOptions.TemplateLanguageCode, otpCode, includeButton: false);
            var retryResult = await ExecuteSendAsync(endpoint, metaOptions.AccessToken!, bodyOnlyPayload, cancellationToken);
            if (retryResult.Success)
            {
                _logger.LogInformation("[MetaCloudApi] OTP dispatched via body-only template. Message ID: {MessageId}", retryResult.MessageId);
                return new WhatsAppDispatchResult(Accepted: true, ProviderMessageId: retryResult.MessageId, IsSimulated: false);
            }
            errorMessage = retryResult.ErrorMessage;
        }

        _logger.LogError("[MetaCloudApi] Meta Cloud API rejected dispatch request: {Error}", errorMessage);
        return new WhatsAppDispatchResult(Accepted: false, ErrorMessage: errorMessage);
    }

    private static JsonObject BuildPayload(string recipientDigits, string templateName, string languageCode, string otpCode, bool includeButton)
    {
        var components = new JsonArray();

        if (templateName.Equals("hello_world", StringComparison.OrdinalIgnoreCase))
        {
            // hello_world template takes no parameters
        }
        else
        {
            // Body parameter
            components.Add(new JsonObject
            {
                ["type"] = "body",
                ["parameters"] = new JsonArray
                {
                    new JsonObject
                    {
                        ["type"] = "text",
                        ["text"] = otpCode
                    }
                }
            });

            if (includeButton)
            {
                // URL / Copy Code button parameter
                components.Add(new JsonObject
                {
                    ["type"] = "button",
                    ["sub_type"] = "url",
                    ["index"] = "0",
                    ["parameters"] = new JsonArray
                    {
                        new JsonObject
                        {
                            ["type"] = "text",
                            ["text"] = otpCode
                        }
                    }
                });
            }
        }

        return new JsonObject
        {
            ["messaging_product"] = "whatsapp",
            ["recipient_type"] = "individual",
            ["to"] = recipientDigits,
            ["type"] = "template",
            ["template"] = new JsonObject
            {
                ["name"] = templateName,
                ["language"] = new JsonObject
                {
                    ["code"] = languageCode
                },
                ["components"] = components
            }
        };
    }

    private async Task<(bool Success, string? MessageId, string? ErrorMessage, string? RawError)> ExecuteSendAsync(
        string endpoint,
        string accessToken,
        JsonObject payload,
        CancellationToken cancellationToken)
    {
        var requestJson = payload.ToJsonString();
        using var requestMessage = new HttpRequestMessage(HttpMethod.Post, endpoint);
        requestMessage.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        requestMessage.Content = new StringContent(requestJson, Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.SendAsync(requestMessage, cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                var doc = JsonNode.Parse(responseContent);
                var messageId = doc?["messages"]?[0]?["id"]?.GetValue<string>();
                return (true, messageId, null, null);
            }

            string userFriendlyError = $"WhatsApp provider returned HTTP {(int)response.StatusCode}";
            try
            {
                var errDoc = JsonNode.Parse(responseContent);
                var metaMsg = errDoc?["error"]?["message"]?.GetValue<string>();
                if (!string.IsNullOrWhiteSpace(metaMsg))
                {
                    userFriendlyError = $"Meta WhatsApp API: {metaMsg}";
                }
            }
            catch
            {
                // fallback to default
            }

            return (false, null, userFriendlyError, responseContent);
        }
        catch (Exception ex)
        {
            return (false, null, $"Communication error contacting WhatsApp gateway: {ex.Message}", ex.Message);
        }
    }
}

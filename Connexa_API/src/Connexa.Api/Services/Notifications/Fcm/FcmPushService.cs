using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Notifications.Fcm;

/// <summary>
/// Implementation of FCM push notification delivery using the official Firebase Admin SDK.
/// Manages FirebaseApp lifecycle, credential resolution from environment/configuration,
/// multicast messaging, and automatic invalid token cleanup.
/// </summary>
public class FcmPushService : IFcmPushService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FcmPushService> _logger;
    private readonly object _initLock = new();
    private bool _initAttempted = false;
    private FirebaseApp? _firebaseApp;

    public FcmPushService(
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        ILogger<FcmPushService> logger)
    {
        _scopeFactory = scopeFactory;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Safely resolves and initializes FirebaseApp if credentials are provided.
    /// Never crashes or throws if credentials are not configured or file not found.
    /// </summary>
    private FirebaseApp? GetOrInitializeFirebaseApp()
    {
        if (_firebaseApp != null)
        {
            return _firebaseApp;
        }

        lock (_initLock)
        {
            if (_initAttempted)
            {
                return _firebaseApp;
            }

            _initAttempted = true;

#pragma warning disable CS0618 // GoogleCredential.FromJson/FromFile and MulticastMessage.Tokens
            try
            {
                GoogleCredential? credential = null;

                // 1. Check environment variable for raw JSON
                var envJson = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON");
                if (!string.IsNullOrWhiteSpace(envJson))
                {
                    credential = GoogleCredential.FromJson(envJson);
                    _logger.LogInformation("Loaded Firebase credentials from FIREBASE_CREDENTIALS_JSON environment variable.");
                }

                // 2. Check configuration for raw JSON
                if (credential == null)
                {
                    var configJson = _configuration["Firebase:CredentialsJson"];
                    if (!string.IsNullOrWhiteSpace(configJson))
                    {
                        credential = GoogleCredential.FromJson(configJson);
                        _logger.LogInformation("Loaded Firebase credentials from configuration (Firebase:CredentialsJson).");
                    }
                }

                // 3. Check environment variable for file path
                if (credential == null)
                {
                    var envPath = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_PATH");
                    var resolvedEnvPath = ResolveFilePath(envPath);
                    if (!string.IsNullOrWhiteSpace(resolvedEnvPath))
                    {
                        credential = GoogleCredential.FromFile(resolvedEnvPath);
                        _logger.LogInformation("Loaded Firebase credentials from file: {Path}", resolvedEnvPath);
                    }
                }

                // 4. Check configuration for file path
                if (credential == null)
                {
                    var configPath = _configuration["Firebase:CredentialsPath"];
                    var resolvedConfigPath = ResolveFilePath(configPath);
                    if (!string.IsNullOrWhiteSpace(resolvedConfigPath))
                    {
                        credential = GoogleCredential.FromFile(resolvedConfigPath);
                        _logger.LogInformation("Loaded Firebase credentials from configuration file: {Path}", resolvedConfigPath);
                    }
                }

                if (credential == null)
                {
                    _logger.LogInformation(
                        "Firebase credentials not found in configuration or environment (FIREBASE_CREDENTIALS_PATH / FIREBASE_CREDENTIALS_JSON). Push delivery will run in mock/unconfigured mode.");
                    return null;
                }

                _firebaseApp = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
                {
                    Credential = credential
                });

                _logger.LogInformation("FirebaseApp initialized successfully for FCM push delivery.");
                return _firebaseApp;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to initialize FirebaseApp for push notifications. Push delivery will be disabled.");
                return null;
            }
        }
    }

    private static string? ResolveFilePath(string? rawPath)
    {
        if (string.IsNullOrWhiteSpace(rawPath)) return null;
        if (System.IO.File.Exists(rawPath)) return System.IO.Path.GetFullPath(rawPath);

        // Check AppContext.BaseDirectory
        var candidate1 = System.IO.Path.Combine(AppContext.BaseDirectory, rawPath);
        if (System.IO.File.Exists(candidate1)) return candidate1;

        // Check CurrentDirectory
        var candidate2 = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), rawPath);
        if (System.IO.File.Exists(candidate2)) return candidate2;

        // Check parent directories up to 4 levels
        var dir = new System.IO.DirectoryInfo(System.IO.Directory.GetCurrentDirectory());
        for (int i = 0; i < 4 && dir != null; i++)
        {
            var candidate = System.IO.Path.Combine(dir.FullName, rawPath);
            if (System.IO.File.Exists(candidate)) return candidate;
            dir = dir.Parent;
        }

        return null;
    }

    public async Task<PushDeliveryResult> SendNotificationAsync(
        Entities.Notification notification,
        CancellationToken cancellationToken = default)
    {
        var app = GetOrInitializeFirebaseApp();
        if (app == null)
        {
            return new PushDeliveryResult(
                IsConfigured: false,
                SentCount: 0,
                FailureCount: 0,
                InvalidTokensCleanedCount: 0,
                ErrorMessage: "FCM is not configured. Persisted in-app notification successfully.");
        }

        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

            // Retrieve all registered device tokens for the recipient
            var tokens = await db.DeviceTokens
                .Where(t => t.MemberId == notification.RecipientMemberId)
                .Select(t => t.Token)
                .Distinct()
                .ToListAsync(cancellationToken);

            if (tokens.Count == 0)
            {
                _logger.LogDebug(
                    "No device tokens registered for recipient member #{MemberId}. Skipping push delivery.",
                    notification.RecipientMemberId);

                return new PushDeliveryResult(
                    IsConfigured: true,
                    SentCount: 0,
                    FailureCount: 0,
                    InvalidTokensCleanedCount: 0);
            }

            // Build sanitized FCM multicast message (never leak private contact details)
            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = notification.Title,
                    Body = notification.Message
                },
                Data = new Dictionary<string, string>
                {
                    ["notificationId"] = notification.Id.ToString(),
                    ["eventType"] = notification.EventType.ToString(),
                    ["referenceType"] = notification.ReferenceType ?? string.Empty,
                    ["referenceId"] = notification.ReferenceId?.ToString() ?? string.Empty,
                    ["actorMemberId"] = notification.ActorMemberId?.ToString() ?? string.Empty,
                    ["createdAtUtc"] = notification.CreatedAtUtc.ToString("o")
                }
            };

            var messaging = FirebaseMessaging.GetMessaging(app);
            var response = await messaging.SendEachForMulticastAsync(message, cancellationToken);

            _logger.LogInformation(
                "FCM multicast push dispatched for notification #{NotificationId}. Success: {SuccessCount}, Failures: {FailureCount}",
                notification.Id, response.SuccessCount, response.FailureCount);

            // Clean up invalid or unregistered tokens
            var invalidTokens = new List<string>();
            for (int i = 0; i < response.Responses.Count; i++)
            {
                var item = response.Responses[i];
                if (!item.IsSuccess && item.Exception != null)
                {
                    var errorCode = item.Exception.MessagingErrorCode;
                    if (errorCode == MessagingErrorCode.Unregistered ||
                        errorCode == MessagingErrorCode.InvalidArgument)
                    {
                        invalidTokens.Add(tokens[i]);
                    }
                }
            }

            int cleanedCount = 0;
            if (invalidTokens.Count > 0)
            {
                var toRemove = await db.DeviceTokens
                    .Where(d => d.MemberId == notification.RecipientMemberId && invalidTokens.Contains(d.Token))
                    .ToListAsync(cancellationToken);

                if (toRemove.Count > 0)
                {
                    db.DeviceTokens.RemoveRange(toRemove);
                    await db.SaveChangesAsync(cancellationToken);
                    cleanedCount = toRemove.Count;

                    _logger.LogInformation(
                        "Cleaned up {Count} expired or unregistered device tokens for recipient member #{MemberId}.",
                        cleanedCount, notification.RecipientMemberId);
                }
            }

            return new PushDeliveryResult(
                IsConfigured: true,
                SentCount: response.SuccessCount,
                FailureCount: response.FailureCount,
                InvalidTokensCleanedCount: cleanedCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Unexpected error occurred while dispatching FCM push for notification #{NotificationId}. In-app notification preserved.",
                notification.Id);

            return new PushDeliveryResult(
                IsConfigured: true,
                SentCount: 0,
                FailureCount: 1,
                InvalidTokensCleanedCount: 0,
                ErrorMessage: ex.Message);
        }
#pragma warning restore CS0618
    }
}

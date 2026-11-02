using Connexa.Api.Entities;

namespace Connexa.Api.Services.Notifications.Fcm;

/// <summary>
/// Service contract for dispatching push notifications via Firebase Cloud Messaging (FCM).
/// </summary>
public interface IFcmPushService
{
    /// <summary>
    /// Dispatches a push notification to all valid registered device tokens for the notification's recipient.
    /// Safely handles unconfigured states, invalid tokens, and delivery failures.
    /// </summary>
    Task<PushDeliveryResult> SendNotificationAsync(Notification notification, CancellationToken cancellationToken = default);
}

/// <summary>
/// Outcome details of a push notification delivery attempt.
/// </summary>
public record PushDeliveryResult(
    bool IsConfigured,
    int SentCount,
    int FailureCount,
    int InvalidTokensCleanedCount,
    string? ErrorMessage = null);

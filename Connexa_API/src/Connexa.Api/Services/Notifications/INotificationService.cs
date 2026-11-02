using Connexa.Api.DTOs;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Notifications;

public interface INotificationService
{
    Task<NotificationDto?> CreateNotificationAsync(
        int recipientMemberId,
        int? actorMemberId,
        NotificationEventType eventType,
        string title,
        string message,
        string? referenceType = null,
        int? referenceId = null,
        string? payloadJson = null,
        CancellationToken cancellationToken = default);

    Task<PaginatedNotificationsDto> GetNotificationsAsync(
        int memberId,
        int page = 1,
        int pageSize = 20,
        bool? unreadOnly = null,
        CancellationToken cancellationToken = default);

    Task<int> GetUnreadCountAsync(int memberId, CancellationToken cancellationToken = default);

    Task<int> MarkAsReadAsync(int memberId, MarkNotificationsReadRequestDto dto, CancellationToken cancellationToken = default);

    Task<bool> RegisterDeviceTokenAsync(int memberId, RegisterDeviceTokenDto dto, CancellationToken cancellationToken = default);

    Task<bool> UnregisterDeviceTokenAsync(int memberId, string token, CancellationToken cancellationToken = default);
}

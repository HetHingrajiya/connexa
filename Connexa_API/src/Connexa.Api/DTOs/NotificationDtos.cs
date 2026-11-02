namespace Connexa.Api.DTOs;

public record NotificationDto(
    int Id,
    int RecipientMemberId,
    int? ActorMemberId,
    string? ActorName,
    string? ActorCompanyName,
    string EventType,
    string Title,
    string Message,
    bool IsRead,
    DateTime? ReadAtUtc,
    string? ReferenceType,
    int? ReferenceId,
    string? PayloadJson,
    DateTime CreatedAtUtc
);

public record PaginatedNotificationsDto(
    List<NotificationDto> Items,
    int TotalCount,
    int UnreadCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record UnreadNotificationCountDto(
    int UnreadCount
);

public record MarkNotificationsReadRequestDto(
    List<int>? NotificationIds = null,
    bool MarkAll = false
);

public record RegisterDeviceTokenDto(
    string Token,
    string Platform = "android"
);

public record UnregisterDeviceTokenDto(
    string Token
);

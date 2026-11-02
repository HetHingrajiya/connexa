using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;

using Connexa.Api.Services.Notifications.Fcm;

namespace Connexa.Api.Services.Notifications;

public class NotificationService : INotificationService
{
    private readonly ConnexaDbContext _db;
    private readonly ILogger<NotificationService> _logger;
    private readonly IFcmPushService? _fcmPushService;

    public NotificationService(
        ConnexaDbContext db,
        ILogger<NotificationService> logger,
        IFcmPushService? fcmPushService = null)
    {
        _db = db;
        _logger = logger;
        _fcmPushService = fcmPushService;
    }

    public async Task<NotificationDto?> CreateNotificationAsync(
        int recipientMemberId,
        int? actorMemberId,
        NotificationEventType eventType,
        string title,
        string message,
        string? referenceType = null,
        int? referenceId = null,
        string? payloadJson = null,
        CancellationToken cancellationToken = default)
    {
        // A member does not get notified about their own actions
        if (actorMemberId.HasValue && actorMemberId.Value == recipientMemberId)
        {
            return null;
        }

        // Deduplication check: Avoid duplicate notifications for retried operations
        if (!string.IsNullOrWhiteSpace(referenceType) && referenceId.HasValue)
        {
            var existing = await _db.Notifications
                .Include(n => n.ActorMember)
                    .ThenInclude(m => m!.BusinessProfile)
                .FirstOrDefaultAsync(n =>
                    n.RecipientMemberId == recipientMemberId &&
                    n.ReferenceType == referenceType &&
                    n.ReferenceId == referenceId.Value &&
                    n.EventType == eventType,
                    cancellationToken);

            if (existing != null)
            {
                _logger.LogInformation("Duplicate notification prevented for recipient {RecipientId}, ref {RefType}:{RefId}, event {Event}",
                    recipientMemberId, referenceType, referenceId, eventType);
                return MapToDto(existing);
            }
        }

        var notification = new Notification
        {
            RecipientMemberId = recipientMemberId,
            ActorMemberId = actorMemberId,
            EventType = eventType,
            Title = title,
            Message = message,
            IsRead = false,
            ReadAtUtc = null,
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            PayloadJson = payloadJson,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync(cancellationToken);

        // Fetch actor details for complete DTO
        if (actorMemberId.HasValue)
        {
            await _db.Entry(notification)
                .Reference(n => n.ActorMember)
                .Query()
                .Include(m => m.BusinessProfile)
                .LoadAsync(cancellationToken);
        }

        _logger.LogInformation("Created notification #{NotificationId} for member {RecipientId} (Event: {Event})",
            notification.Id, recipientMemberId, eventType);

        // Attempt push delivery via FCM (isolated from database persistence)
        if (_fcmPushService != null)
        {
            try
            {
                await _fcmPushService.SendNotificationAsync(notification, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Push delivery attempt failed for notification #{NotificationId}. In-app notification preserved.", notification.Id);
            }
        }

        return MapToDto(notification);
    }

    public async Task<PaginatedNotificationsDto> GetNotificationsAsync(
        int memberId,
        int page = 1,
        int pageSize = 20,
        bool? unreadOnly = null,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 50) pageSize = 50;

        // Strict ownership enforcement
        var baseQuery = _db.Notifications
            .AsNoTracking()
            .Where(n => n.RecipientMemberId == memberId);

        var unreadCount = await baseQuery.CountAsync(n => !n.IsRead, cancellationToken);

        var query = baseQuery;
        if (unreadOnly == true)
        {
            query = query.Where(n => !n.IsRead);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var items = await query
            .Include(n => n.ActorMember)
                .ThenInclude(m => m!.BusinessProfile)
            .OrderByDescending(n => n.CreatedAtUtc)
            .ThenByDescending(n => n.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(MapToDto).ToList();

        return new PaginatedNotificationsDto(
            Items: dtos,
            TotalCount: totalCount,
            UnreadCount: unreadCount,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );
    }

    public async Task<int> GetUnreadCountAsync(int memberId, CancellationToken cancellationToken = default)
    {
        return await _db.Notifications
            .AsNoTracking()
            .CountAsync(n => n.RecipientMemberId == memberId && !n.IsRead, cancellationToken);
    }

    public async Task<int> MarkAsReadAsync(
        int memberId,
        MarkNotificationsReadRequestDto dto,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Notifications
            .Where(n => n.RecipientMemberId == memberId && !n.IsRead);

        if (!dto.MarkAll && dto.NotificationIds != null && dto.NotificationIds.Any())
        {
            query = query.Where(n => dto.NotificationIds.Contains(n.Id));
        }

        var unread = await query.ToListAsync(cancellationToken);
        if (!unread.Any())
        {
            return 0;
        }

        var now = DateTime.UtcNow;
        foreach (var item in unread)
        {
            item.IsRead = true;
            item.ReadAtUtc = now;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return unread.Count;
    }

    public async Task<bool> RegisterDeviceTokenAsync(
        int memberId,
        RegisterDeviceTokenDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Token))
        {
            return false;
        }

        var existing = await _db.DeviceTokens
            .FirstOrDefaultAsync(t => t.MemberId == memberId && t.Token == dto.Token, cancellationToken);

        if (existing == null)
        {
            _db.DeviceTokens.Add(new DeviceToken
            {
                MemberId = memberId,
                Token = dto.Token.Trim(),
                Platform = string.IsNullOrWhiteSpace(dto.Platform) ? "android" : dto.Platform.Trim().ToLowerInvariant(),
                CreatedAtUtc = DateTime.UtcNow,
                UpdatedAtUtc = DateTime.UtcNow
            });
        }
        else
        {
            existing.Platform = string.IsNullOrWhiteSpace(dto.Platform) ? existing.Platform : dto.Platform.Trim().ToLowerInvariant();
            existing.UpdatedAtUtc = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UnregisterDeviceTokenAsync(
        int memberId,
        string token,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return false;
        }

        var tokens = await _db.DeviceTokens
            .Where(t => t.MemberId == memberId && t.Token == token.Trim())
            .ToListAsync(cancellationToken);

        if (tokens.Any())
        {
            _db.DeviceTokens.RemoveRange(tokens);
            await _db.SaveChangesAsync(cancellationToken);
        }

        return true;
    }

    private static NotificationDto MapToDto(Notification n)
    {
        string? actorName = n.ActorMember?.FullName;
        string? actorCompany = n.ActorMember?.BusinessProfile?.CompanyName;

        return new NotificationDto(
            Id: n.Id,
            RecipientMemberId: n.RecipientMemberId,
            ActorMemberId: n.ActorMemberId,
            ActorName: actorName,
            ActorCompanyName: actorCompany,
            EventType: n.EventType.ToString(),
            Title: n.Title,
            Message: n.Message,
            IsRead: n.IsRead,
            ReadAtUtc: n.ReadAtUtc,
            ReferenceType: n.ReferenceType,
            ReferenceId: n.ReferenceId,
            PayloadJson: n.PayloadJson,
            CreatedAtUtc: n.CreatedAtUtc
        );
    }
}

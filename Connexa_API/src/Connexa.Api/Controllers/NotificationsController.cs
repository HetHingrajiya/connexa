using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(INotificationService notificationService, ILogger<NotificationsController> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    private int? GetCurrentMemberId()
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (int.TryParse(memberIdClaim, out var memberId))
        {
            return memberId;
        }

        return null;
    }

    /// <summary>
    /// Gets a paginated list of notifications for the authenticated member.
    /// GET /api/v1/notifications?page=1&pageSize=20&unreadOnly=false
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PaginatedNotificationsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaginatedNotificationsDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] bool? unreadOnly = null,
        CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<PaginatedNotificationsDto>.Fail("Invalid authentication claims."));
        }

        var result = await _notificationService.GetNotificationsAsync(
            currentMemberId.Value,
            page,
            pageSize,
            unreadOnly,
            cancellationToken);

        return Ok(ApiResponse<PaginatedNotificationsDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets the count of unread notifications for the authenticated member.
    /// GET /api/v1/notifications/unread-count
    /// </summary>
    [HttpGet("unread-count")]
    [ProducesResponseType(typeof(ApiResponse<UnreadNotificationCountDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<UnreadNotificationCountDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<UnreadNotificationCountDto>.Fail("Invalid authentication claims."));
        }

        var unreadCount = await _notificationService.GetUnreadCountAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<UnreadNotificationCountDto>.Ok(new UnreadNotificationCountDto(unreadCount), 1));
    }

    /// <summary>
    /// Marks specified notifications or all notifications as read for the authenticated member.
    /// POST /api/v1/notifications/mark-read
    /// </summary>
    [HttpPost("mark-read")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkAsRead(
        [FromBody] MarkNotificationsReadRequestDto dto,
        CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<object>.Fail("Invalid authentication claims."));
        }

        var markedCount = await _notificationService.MarkAsReadAsync(currentMemberId.Value, dto, cancellationToken);
        return Ok(ApiResponse<object>.Ok(new { markedCount }, 1));
    }

    /// <summary>
    /// Registers or refreshes a device push token for the authenticated member.
    /// POST /api/v1/notifications/device-tokens
    /// </summary>
    [HttpPost("device-tokens")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RegisterDeviceToken(
        [FromBody] RegisterDeviceTokenDto dto,
        CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        if (string.IsNullOrWhiteSpace(dto.Token))
        {
            return BadRequest(ApiResponse<bool>.Fail("Token is required."));
        }

        var success = await _notificationService.RegisterDeviceTokenAsync(currentMemberId.Value, dto, cancellationToken);
        return Ok(ApiResponse<bool>.Ok(success, 1));
    }

    /// <summary>
    /// Unregisters/removes a device push token for the authenticated member.
    /// DELETE /api/v1/notifications/device-tokens
    /// </summary>
    [HttpDelete("device-tokens")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UnregisterDeviceToken(
        [FromQuery] string token,
        CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        if (string.IsNullOrWhiteSpace(token))
        {
            return BadRequest(ApiResponse<bool>.Fail("Token query parameter is required."));
        }

        var success = await _notificationService.UnregisterDeviceTokenAsync(currentMemberId.Value, token, cancellationToken);
        return Ok(ApiResponse<bool>.Ok(success, 1));
    }
}

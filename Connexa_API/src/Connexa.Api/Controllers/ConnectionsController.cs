using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Connections;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/connections")]
[Authorize]
public class ConnectionsController : ControllerBase
{
    private readonly IConnectionService _connectionService;
    private readonly ILogger<ConnectionsController> _logger;

    public ConnectionsController(IConnectionService connectionService, ILogger<ConnectionsController> logger)
    {
        _connectionService = connectionService;
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
    /// Sends a connection request to another business member.
    /// POST /api/v1/connections/requests
    /// </summary>
    [HttpPost("requests")]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SendRequest([FromBody] CreateConnectionRequestDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ConnectionDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, connection) = await _connectionService.SendRequestAsync(currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return BadRequest(ApiResponse<ConnectionDto>.Fail(message));
        }

        return Ok(ApiResponse<ConnectionDto>.Ok(connection!, 1));
    }

    /// <summary>
    /// Retrieves incoming pending connection requests for the current member.
    /// GET /api/v1/connections/requests/received
    /// </summary>
    [HttpGet("requests/received")]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetReceivedRequests([FromQuery] int page = 1, [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _connectionService.GetReceivedRequestsAsync(currentMemberId.Value, page, pageSize, cancellationToken);
        return Ok(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Retrieves outgoing pending connection requests sent by the current member.
    /// GET /api/v1/connections/requests/sent
    /// </summary>
    [HttpGet("requests/sent")]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetSentRequests([FromQuery] int page = 1, [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _connectionService.GetSentRequestsAsync(currentMemberId.Value, page, pageSize, cancellationToken);
        return Ok(ApiResponse<PaginatedConnectionsDto<ConnectionRequestItemDto>>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Accepts a received pending connection request.
    /// POST /api/v1/connections/requests/{id}/accept
    /// </summary>
    [HttpPost("requests/{id:int}/accept")]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AcceptRequest(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ConnectionDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, connection) = await _connectionService.AcceptRequestAsync(currentMemberId.Value, id, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<ConnectionDto>.Fail(message));
            }

            return BadRequest(ApiResponse<ConnectionDto>.Fail(message));
        }

        return Ok(ApiResponse<ConnectionDto>.Ok(connection!, 1));
    }

    /// <summary>
    /// Rejects a received pending connection request.
    /// POST /api/v1/connections/requests/{id}/reject
    /// </summary>
    [HttpPost("requests/{id:int}/reject")]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RejectRequest(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ConnectionDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, connection) = await _connectionService.RejectRequestAsync(currentMemberId.Value, id, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<ConnectionDto>.Fail(message));
            }

            return BadRequest(ApiResponse<ConnectionDto>.Fail(message));
        }

        return Ok(ApiResponse<ConnectionDto>.Ok(connection!, 1));
    }

    /// <summary>
    /// Cancels a pending connection request sent by the current member.
    /// POST /api/v1/connections/requests/{id}/cancel
    /// </summary>
    [HttpPost("requests/{id:int}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CancelRequest(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ConnectionDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, connection) = await _connectionService.CancelRequestAsync(currentMemberId.Value, id, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<ConnectionDto>.Fail(message));
            }

            return BadRequest(ApiResponse<ConnectionDto>.Fail(message));
        }

        return Ok(ApiResponse<ConnectionDto>.Ok(connection!, 1));
    }

    /// <summary>
    /// Lists accepted connections (My Network) for the current member.
    /// GET /api/v1/connections
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectedMemberItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PaginatedConnectionsDto<ConnectedMemberItemDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetConnections([FromQuery] string? search = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<PaginatedConnectionsDto<ConnectedMemberItemDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _connectionService.GetMyConnectionsAsync(currentMemberId.Value, search, page, pageSize, cancellationToken);
        return Ok(ApiResponse<PaginatedConnectionsDto<ConnectedMemberItemDto>>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Removes an existing accepted connection with a member.
    /// DELETE /api/v1/connections/{memberId}
    /// </summary>
    [HttpDelete("{memberId:int}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveConnection(int memberId, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var (success, message) = await _connectionService.RemoveConnectionAsync(currentMemberId.Value, memberId, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(ApiResponse<bool>.Fail(message));
            }

            return BadRequest(ApiResponse<bool>.Fail(message));
        }

        return Ok(ApiResponse<bool>.Ok(true, 1));
    }

    /// <summary>
    /// Gets a summary count of connections and pending requests for the current member.
    /// GET /api/v1/connections/summary
    /// </summary>
    [HttpGet("summary")]
    [ProducesResponseType(typeof(ApiResponse<ConnectionsSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ConnectionsSummaryDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<ConnectionsSummaryDto>.Fail("Invalid authentication claims."));
        }

        var summary = await _connectionService.GetSummaryAsync(currentMemberId.Value, cancellationToken);
        return Ok(ApiResponse<ConnectionsSummaryDto>.Ok(summary, 1));
    }
}

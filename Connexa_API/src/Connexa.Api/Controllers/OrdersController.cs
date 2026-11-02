using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Orders;

namespace Connexa.Api.Controllers;

[ApiController]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(IOrderService orderService, ILogger<OrdersController> logger)
    {
        _orderService = orderService;
        _logger = logger;
    }

    /// <summary>
    /// Creates an Order from an accepted quotation.
    /// POST /api/v1/orders
    /// </summary>
    [HttpPost("api/v1/orders")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.CreateOrderAsync(currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Retrieves orders placed by the authenticated buyer member.
    /// GET /api/v1/orders/my
    /// </summary>
    [HttpGet("api/v1/orders/my")]
    [ProducesResponseType(typeof(ApiResponse<List<OrderDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<OrderDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyOrders([FromQuery] OrderFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<OrderDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _orderService.GetMyOrdersAsync(currentMemberId.Value, filter, cancellationToken);
        return Ok(ApiResponse<List<OrderDto>>.Ok(result.Items, result.TotalCount));
    }

    /// <summary>
    /// Retrieves orders received by the authenticated supplier member.
    /// GET /api/v1/orders/received
    /// </summary>
    [HttpGet("api/v1/orders/received")]
    [ProducesResponseType(typeof(ApiResponse<List<OrderDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<OrderDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetReceivedOrders([FromQuery] OrderFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<OrderDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _orderService.GetReceivedOrdersAsync(currentMemberId.Value, filter, cancellationToken);
        return Ok(ApiResponse<List<OrderDto>>.Ok(result.Items, result.TotalCount));
    }

    /// <summary>
    /// Retrieves details and audit history for a specific order.
    /// GET /api/v1/orders/{id}
    /// </summary>
    [HttpGet("api/v1/orders/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetOrderById([FromRoute] int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var isAdmin = User.IsInRole("Admin");
        var (success, message, order) = await _orderService.GetOrderByIdAsync(id, currentMemberId.Value, isAdmin, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Confirms an order (Supplier only).
    /// POST /api/v1/orders/{id}/confirm
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/confirm")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ConfirmOrder([FromRoute] int id, [FromBody] ConfirmOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.ConfirmOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Rejects an order with reason (Supplier only).
    /// POST /api/v1/orders/{id}/reject
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/reject")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RejectOrder([FromRoute] int id, [FromBody] RejectOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.RejectOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Marks an order as in processing/production (Supplier only).
    /// POST /api/v1/orders/{id}/process
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/process")]
    [HttpPost("api/v1/orders/{id:int}/processing")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ProcessOrder([FromRoute] int id, [FromBody] ProcessOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.ProcessOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Marks an order as shipped and records shipment carrier and tracking number (Supplier only).
    /// POST /api/v1/orders/{id}/ship
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/ship")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ShipOrder([FromRoute] int id, [FromBody] ShipOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.ShipOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Marks an order as delivered / completed when client receives the order.
    /// POST /api/v1/orders/{id}/deliver
    /// POST /api/v1/orders/{id}/complete
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/deliver")]
    [HttpPost("api/v1/orders/{id:int}/complete")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeliverOrder([FromRoute] int id, [FromBody] DeliverOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.DeliverOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Cancels an order before it has shipped with mandatory reason (Buyer or Supplier).
    /// POST /api/v1/orders/{id}/cancel
    /// </summary>
    [HttpPost("api/v1/orders/{id:int}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<OrderDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CancelOrder([FromRoute] int id, [FromBody] CancelOrderDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<OrderDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, order) = await _orderService.CancelOrderAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return MapErrorResult<OrderDto>(message);
        }

        return Ok(ApiResponse<OrderDto>.Ok(order!, 1));
    }

    // --- Helper Methods ---

    private int? GetCurrentMemberId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (int.TryParse(claim, out var memberId))
        {
            return memberId;
        }
        return null;
    }

    private IActionResult MapErrorResult<T>(string message)
    {
        if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(ApiResponse<T>.Fail(message));
        }
        if (message.Contains("not authorized", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("only the buyer", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("only the supplier", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<T>.Fail(message));
        }
        if (message.Contains("already exists", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("already been converted", StringComparison.OrdinalIgnoreCase))
        {
            return Conflict(ApiResponse<T>.Fail(message));
        }

        return BadRequest(ApiResponse<T>.Fail(message));
    }
}

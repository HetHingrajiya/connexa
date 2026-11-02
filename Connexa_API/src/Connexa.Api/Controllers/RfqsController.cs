using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Rfq;

namespace Connexa.Api.Controllers;

[ApiController]
[Authorize]
public class RfqsController : ControllerBase
{
    private readonly IRfqService _rfqService;
    private readonly ILogger<RfqsController> _logger;

    public RfqsController(IRfqService rfqService, ILogger<RfqsController> logger)
    {
        _rfqService = rfqService;
        _logger = logger;
    }

    /// <summary>
    /// Creates a formal Request for Quotation (RFQ) for a product.
    /// POST /api/v1/rfqs
    /// </summary>
    [HttpPost("api/v1/rfqs")]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateRfq([FromBody] CreateRfqDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<RfqDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, rfq) = await _rfqService.CreateRfqAsync(currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            return BadRequest(ApiResponse<RfqDto>.Fail(message));
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<RfqDto>.Ok(rfq!, 1));
    }

    /// <summary>
    /// Retrieves RFQs created by the authenticated buyer member.
    /// GET /api/v1/rfqs/my
    /// </summary>
    [HttpGet("api/v1/rfqs/my")]
    [ProducesResponseType(typeof(ApiResponse<List<RfqDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<RfqDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyRfqs([FromQuery] RfqFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<RfqDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _rfqService.GetMyRfqsAsync(currentMemberId.Value, filter, cancellationToken);
        return Ok(ApiResponse<List<RfqDto>>.Ok(result.Items, result.TotalCount));
    }

    /// <summary>
    /// Retrieves RFQs received by the authenticated supplier member.
    /// GET /api/v1/rfqs/received
    /// </summary>
    [HttpGet("api/v1/rfqs/received")]
    [ProducesResponseType(typeof(ApiResponse<List<RfqDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<RfqDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetReceivedRfqs([FromQuery] RfqFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<RfqDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _rfqService.GetReceivedRfqsAsync(currentMemberId.Value, filter, cancellationToken);
        return Ok(ApiResponse<List<RfqDto>>.Ok(result.Items, result.TotalCount));
    }

    /// <summary>
    /// Retrieves a specific RFQ by its identifier with access control.
    /// GET /api/v1/rfqs/{id}
    /// </summary>
    [HttpGet("api/v1/rfqs/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRfqById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<RfqDto>.Fail("Invalid authentication claims."));
        }

        bool isAdmin = User.IsInRole("Admin");
        var (success, message, rfq) = await _rfqService.GetRfqByIdAsync(id, currentMemberId.Value, isAdmin, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
                return NotFound(ApiResponse<RfqDto>.Fail(message));
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<RfqDto>.Fail(message));
        }

        return Ok(ApiResponse<RfqDto>.Ok(rfq!, 1));
    }

    /// <summary>
    /// Cancels an open RFQ. Only the buyer who created it can cancel it.
    /// POST /api/v1/rfqs/{id}/cancel
    /// </summary>
    [HttpPost("api/v1/rfqs/{id:int}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<RfqDto>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CancelRfq(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<RfqDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, rfq) = await _rfqService.CancelRfqAsync(id, currentMemberId.Value, cancellationToken);
        if (!success)
        {
            if (message.Contains("only the buyer", StringComparison.OrdinalIgnoreCase))
                return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<RfqDto>.Fail(message));
            return BadRequest(ApiResponse<RfqDto>.Fail(message));
        }

        return Ok(ApiResponse<RfqDto>.Ok(rfq!, 1));
    }

    /// <summary>
    /// Submits a quotation (or revision) for an RFQ. Only the intended supplier can submit.
    /// POST /api/v1/rfqs/{id}/quotations
    /// </summary>
    [HttpPost("api/v1/rfqs/{id:int}/quotations")]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SubmitQuotation(int id, [FromBody] SubmitQuotationDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<QuotationDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, quote) = await _rfqService.SubmitQuotationAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            if (message.Contains("only the intended supplier", StringComparison.OrdinalIgnoreCase))
                return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<QuotationDto>.Fail(message));
            return BadRequest(ApiResponse<QuotationDto>.Fail(message));
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<QuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Retrieves all quotation versions for a specific RFQ.
    /// GET /api/v1/rfqs/{id}/quotations
    /// </summary>
    [HttpGet("api/v1/rfqs/{id:int}/quotations")]
    [ProducesResponseType(typeof(ApiResponse<List<QuotationDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<QuotationDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetQuotationsForRfq(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<List<QuotationDto>>.Fail("Invalid authentication claims."));
        }

        bool isAdmin = User.IsInRole("Admin");
        var quotes = await _rfqService.GetQuotationsForRfqAsync(id, currentMemberId.Value, isAdmin, cancellationToken);
        return Ok(ApiResponse<List<QuotationDto>>.Ok(quotes, quotes.Count));
    }

    /// <summary>
    /// Retrieves a specific quotation by identifier.
    /// GET /api/v1/rfqs/quotations/{quotationId}
    /// </summary>
    [HttpGet("api/v1/rfqs/quotations/{quotationId:int}")]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetQuotationById(int quotationId, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<QuotationDto>.Fail("Invalid authentication claims."));
        }

        bool isAdmin = User.IsInRole("Admin");
        var (success, message, quote) = await _rfqService.GetQuotationByIdAsync(quotationId, currentMemberId.Value, isAdmin, cancellationToken);
        if (!success)
        {
            if (message.Contains("not found", StringComparison.OrdinalIgnoreCase))
                return NotFound(ApiResponse<QuotationDto>.Fail(message));
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<QuotationDto>.Fail(message));
        }

        return Ok(ApiResponse<QuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Decides on a quotation: "Accept", "Reject", or "RequestRevision".
    /// Only the buyer associated with the RFQ can decide.
    /// POST /api/v1/rfqs/quotations/{quotationId}/decide
    /// </summary>
    [HttpPost("api/v1/rfqs/quotations/{quotationId:int}/decide")]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<QuotationDto>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DecideQuotation(int quotationId, [FromBody] DecideQuotationDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<QuotationDto>.Fail("Invalid authentication claims."));
        }

        var (success, message, quote) = await _rfqService.DecideQuotationAsync(quotationId, currentMemberId.Value, dto, cancellationToken);
        if (!success)
        {
            if (message.Contains("only the buyer", StringComparison.OrdinalIgnoreCase))
                return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<QuotationDto>.Fail(message));
            return BadRequest(ApiResponse<QuotationDto>.Fail(message));
        }

        return Ok(ApiResponse<QuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Uploads an attachment document for an RFQ or Quotation.
    /// POST /api/v1/rfqs/attachments
    /// </summary>
    [HttpPost("api/v1/rfqs/attachments")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UploadAttachment(IFormFile file, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
        {
            return Unauthorized(ApiResponse<string>.Fail("Invalid authentication claims."));
        }

        var (success, message, url) = await _rfqService.UploadAttachmentAsync(currentMemberId.Value, file, cancellationToken);
        if (!success)
        {
            return BadRequest(ApiResponse<string>.Fail(message));
        }

        return Ok(ApiResponse<string>.WithMessage(url!, message));
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
}


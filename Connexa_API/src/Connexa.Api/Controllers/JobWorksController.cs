namespace Connexa.Api.Controllers;

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.JobWork;

[ApiController]
[Authorize]
public class JobWorksController : ControllerBase
{
    private readonly IJobWorkService _jobWorkService;
    private readonly ILogger<JobWorksController> _logger;

    public JobWorksController(IJobWorkService jobWorkService, ILogger<JobWorksController> logger)
    {
        _jobWorkService = jobWorkService;
        _logger = logger;
    }

    // ==========================================
    // 1. REQUIREMENTS ENDPOINTS
    // ==========================================

    /// <summary>
    /// Creates a new industrial job work requirement.
    /// POST /api/v1/job-works/requirements
    /// </summary>
    [HttpPost("api/v1/job-works/requirements")]
    [ProducesResponseType(typeof(ApiResponse<JobWorkRequirementDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<JobWorkRequirementDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateRequirement([FromBody] CreateJobWorkRequirementDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkRequirementDto>.Fail("Invalid authentication claims."));

        var (success, message, requirement) = await _jobWorkService.CreateRequirementAsync(currentMemberId.Value, dto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkRequirementDto>.Fail(message));

        return StatusCode(StatusCodes.Status201Created, ApiResponse<JobWorkRequirementDto>.Ok(requirement!, 1));
    }

    /// <summary>
    /// Updates an existing draft or active job work requirement.
    /// PUT /api/v1/job-works/requirements/{id}
    /// </summary>
    [HttpPut("api/v1/job-works/requirements/{id}")]
    [ProducesResponseType(typeof(ApiResponse<JobWorkRequirementDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<JobWorkRequirementDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateRequirement(int id, [FromBody] UpdateJobWorkRequirementDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkRequirementDto>.Fail("Invalid authentication claims."));

        var (success, message, requirement) = await _jobWorkService.UpdateRequirementAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkRequirementDto>.Fail(message));

        return Ok(ApiResponse<JobWorkRequirementDto>.Ok(requirement!, 1));
    }

    /// <summary>
    /// Cancels an active job work requirement.
    /// POST /api/v1/job-works/requirements/{id}/cancel
    /// </summary>
    [HttpPost("api/v1/job-works/requirements/{id}/cancel")]
    public async Task<IActionResult> CancelRequirement(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkRequirementDto>.Fail("Invalid authentication claims."));

        var (success, message, requirement) = await _jobWorkService.CancelRequirementAsync(id, currentMemberId.Value, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkRequirementDto>.Fail(message));

        return Ok(ApiResponse<JobWorkRequirementDto>.Ok(requirement!, 1));
    }

    /// <summary>
    /// Closes an active job work requirement.
    /// POST /api/v1/job-works/requirements/{id}/close
    /// </summary>
    [HttpPost("api/v1/job-works/requirements/{id}/close")]
    public async Task<IActionResult> CloseRequirement(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkRequirementDto>.Fail("Invalid authentication claims."));

        var (success, message, requirement) = await _jobWorkService.CloseRequirementAsync(id, currentMemberId.Value, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkRequirementDto>.Fail(message));

        return Ok(ApiResponse<JobWorkRequirementDto>.Ok(requirement!, 1));
    }

    /// <summary>
    /// Searches and filters active requirements on the public/authenticated marketplace.
    /// GET /api/v1/job-works/requirements/marketplace
    /// </summary>
    [HttpGet("api/v1/job-works/requirements/marketplace")]
    [AllowAnonymous]
    public async Task<IActionResult> GetMarketplace([FromQuery] JobWorkRequirementFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        var result = await _jobWorkService.GetMarketplaceRequirementsAsync(currentMemberId, filter, cancellationToken);
        return Ok(ApiResponse<JobWorkRequirementListResponseDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets requirements posted by the authenticated member.
    /// GET /api/v1/job-works/requirements/my
    /// </summary>
    [HttpGet("api/v1/job-works/requirements/my")]
    public async Task<IActionResult> GetMyRequirements([FromQuery] JobWorkRequirementFilterDto filter, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkRequirementListResponseDto>.Fail("Invalid authentication claims."));

        var result = await _jobWorkService.GetMyRequirementsAsync(currentMemberId.Value, filter, cancellationToken);
        return Ok(ApiResponse<JobWorkRequirementListResponseDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets full requirement details by ID.
    /// GET /api/v1/job-works/requirements/{id}
    /// </summary>
    [HttpGet("api/v1/job-works/requirements/{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetRequirementById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        var isAdmin = User.IsInRole("Admin");

        var (success, message, requirement) = await _jobWorkService.GetRequirementByIdAsync(id, currentMemberId, isAdmin, cancellationToken);
        if (!success)
            return NotFound(ApiResponse<JobWorkRequirementDto>.Fail(message));

        return Ok(ApiResponse<JobWorkRequirementDto>.Ok(requirement!, 1));
    }

    // ==========================================
    // 2. QUOTATIONS ENDPOINTS
    // ==========================================

    /// <summary>
    /// Submits a quotation for a job work requirement.
    /// POST /api/v1/job-works/requirements/{requirementId}/quotations
    /// </summary>
    [HttpPost("api/v1/job-works/requirements/{requirementId}/quotations")]
    [ProducesResponseType(typeof(ApiResponse<JobWorkQuotationDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> SubmitQuotation(int requirementId, [FromBody] SubmitJobWorkQuotationDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkQuotationDto>.Fail("Invalid authentication claims."));

        var submitDto = dto with { JobWorkRequirementId = requirementId };
        var (success, message, quote) = await _jobWorkService.SubmitQuotationAsync(currentMemberId.Value, submitDto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkQuotationDto>.Fail(message));

        return StatusCode(StatusCodes.Status201Created, ApiResponse<JobWorkQuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Gets all quotations for a requirement (requirement owner or contractor's own).
    /// GET /api/v1/job-works/requirements/{requirementId}/quotations
    /// </summary>
    [HttpGet("api/v1/job-works/requirements/{requirementId}/quotations")]
    public async Task<IActionResult> GetQuotationsForRequirement(int requirementId, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<List<JobWorkQuotationDto>>.Fail("Invalid authentication claims."));

        var isAdmin = User.IsInRole("Admin");
        var quotes = await _jobWorkService.GetQuotationsForRequirementAsync(requirementId, currentMemberId.Value, isAdmin, cancellationToken);
        return Ok(ApiResponse<List<JobWorkQuotationDto>>.Ok(quotes, quotes.Count));
    }

    /// <summary>
    /// Gets quotations submitted by the current authenticated contractor.
    /// GET /api/v1/job-works/quotations/my
    /// </summary>
    [HttpGet("api/v1/job-works/quotations/my")]
    public async Task<IActionResult> GetMyQuotations([FromQuery] int page = 1, [FromQuery] int pageSize = 10, CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkQuotationListResponseDto>.Fail("Invalid authentication claims."));

        var result = await _jobWorkService.GetMyQuotationsAsync(currentMemberId.Value, page, pageSize, cancellationToken);
        return Ok(ApiResponse<JobWorkQuotationListResponseDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets single quotation by ID.
    /// GET /api/v1/job-works/quotations/{id}
    /// </summary>
    [HttpGet("api/v1/job-works/quotations/{id}")]
    public async Task<IActionResult> GetQuotationById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkQuotationDto>.Fail("Invalid authentication claims."));

        var isAdmin = User.IsInRole("Admin");
        var (success, message, quote) = await _jobWorkService.GetQuotationByIdAsync(id, currentMemberId.Value, isAdmin, cancellationToken);
        if (!success)
            return NotFound(ApiResponse<JobWorkQuotationDto>.Fail(message));

        return Ok(ApiResponse<JobWorkQuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Updates or revises an existing quotation.
    /// PUT /api/v1/job-works/quotations/{id}
    /// </summary>
    [HttpPut("api/v1/job-works/quotations/{id}")]
    public async Task<IActionResult> UpdateQuotation(int id, [FromBody] UpdateJobWorkQuotationDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkQuotationDto>.Fail("Invalid authentication claims."));

        var (success, message, quote) = await _jobWorkService.UpdateQuotationAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkQuotationDto>.Fail(message));

        return Ok(ApiResponse<JobWorkQuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Withdraws an active quotation.
    /// POST /api/v1/job-works/quotations/{id}/withdraw
    /// </summary>
    [HttpPost("api/v1/job-works/quotations/{id}/withdraw")]
    public async Task<IActionResult> WithdrawQuotation(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkQuotationDto>.Fail("Invalid authentication claims."));

        var (success, message, quote) = await _jobWorkService.WithdrawQuotationAsync(id, currentMemberId.Value, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkQuotationDto>.Fail(message));

        return Ok(ApiResponse<JobWorkQuotationDto>.Ok(quote!, 1));
    }

    /// <summary>
    /// Decides on a quotation: Accept, Reject, or RequestRevision.
    /// If accepted, atomically closes requirement, rejects competing quotations, and generates JobWorkOrder.
    /// POST /api/v1/job-works/quotations/{id}/decide
    /// </summary>
    [HttpPost("api/v1/job-works/quotations/{id}/decide")]
    public async Task<IActionResult> DecideQuotation(int id, [FromBody] DecideJobWorkQuotationDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<object>.Fail("Invalid authentication claims."));

        var (success, message, quote, order) = await _jobWorkService.DecideQuotationAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<object>.Fail(message));

        return Ok(ApiResponse<object>.WithMessage(new { quotation = quote, order }, message));
    }

    // ==========================================
    // 3. ORDERS ENDPOINTS
    // ==========================================

    /// <summary>
    /// Gets orders list for the current member (as buyer or contractor).
    /// GET /api/v1/job-works/orders?role=buyer|contractor&amp;status=Confirmed&amp;page=1&amp;pageSize=10
    /// </summary>
    [HttpGet("api/v1/job-works/orders")]
    public async Task<IActionResult> GetOrders(
        [FromQuery] string role = "buyer",
        [FromQuery] JobWorkOrderStatus? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkOrderListResponseDto>.Fail("Invalid authentication claims."));

        var isBuyer = !string.Equals(role, "contractor", StringComparison.OrdinalIgnoreCase);
        var result = await _jobWorkService.GetOrdersAsync(currentMemberId.Value, isBuyer, page, pageSize, status, cancellationToken);
        return Ok(ApiResponse<JobWorkOrderListResponseDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets order details by ID.
    /// GET /api/v1/job-works/orders/{id}
    /// </summary>
    [HttpGet("api/v1/job-works/orders/{id}")]
    public async Task<IActionResult> GetOrderById(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkOrderDto>.Fail("Invalid authentication claims."));

        var isAdmin = User.IsInRole("Admin");
        var (success, message, order) = await _jobWorkService.GetOrderByIdAsync(id, currentMemberId.Value, isAdmin, cancellationToken);
        if (!success)
            return NotFound(ApiResponse<JobWorkOrderDto>.Fail(message));

        return Ok(ApiResponse<JobWorkOrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Updates order lifecycle status (Processing, Completed, Confirmed, Cancelled, Rejected).
    /// POST /api/v1/job-works/orders/{id}/status
    /// </summary>
    [HttpPost("api/v1/job-works/orders/{id}/status")]
    public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] UpdateJobWorkOrderStatusDto dto, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkOrderDto>.Fail("Invalid authentication claims."));

        var (success, message, order) = await _jobWorkService.UpdateOrderStatusAsync(id, currentMemberId.Value, dto, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkOrderDto>.Fail(message));

        return Ok(ApiResponse<JobWorkOrderDto>.Ok(order!, 1));
    }

    /// <summary>
    /// Cancels a job work order.
    /// POST /api/v1/job-works/orders/{id}/cancel
    /// </summary>
    [HttpPost("api/v1/job-works/orders/{id}/cancel")]
    public async Task<IActionResult> CancelOrder(int id, [FromBody] CancelOrderRequestDto body, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkOrderDto>.Fail("Invalid authentication claims."));

        var (success, message, order) = await _jobWorkService.CancelOrderAsync(id, currentMemberId.Value, body.Reason, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkOrderDto>.Fail(message));

        return Ok(ApiResponse<JobWorkOrderDto>.Ok(order!, 1));
    }

    // ==========================================
    // 4. ATTACHMENTS ENDPOINTS
    // ==========================================

    /// <summary>
    /// Uploads an engineering drawing or job work attachment (max 25MB).
    /// POST /api/v1/job-works/attachments/upload
    /// </summary>
    [HttpPost("api/v1/job-works/attachments/upload")]
    [RequestSizeLimit(30 * 1024 * 1024)]
    public async Task<IActionResult> UploadAttachment(IFormFile file, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<JobWorkAttachmentDto>.Fail("Invalid authentication claims."));

        var (success, message, attachment) = await _jobWorkService.UploadAttachmentAsync(currentMemberId.Value, file, cancellationToken);
        if (!success)
            return BadRequest(ApiResponse<JobWorkAttachmentDto>.Fail(message));

        return StatusCode(StatusCodes.Status201Created, ApiResponse<JobWorkAttachmentDto>.Ok(attachment!, 1));
    }

    /// <summary>
    /// Downloads an attachment securely.
    /// GET /api/v1/job-works/attachments/{id}/download
    /// </summary>
    [HttpGet("api/v1/job-works/attachments/{id}/download")]
    [AllowAnonymous]
    public async Task<IActionResult> DownloadAttachment(int id, CancellationToken cancellationToken)
    {
        var currentMemberId = GetCurrentMemberId() ?? 0;
        var isAdmin = User.IsInRole("Admin");

        var (success, message, filePath, contentType, originalFileName) =
            await _jobWorkService.GetAttachmentDownloadAsync(id, currentMemberId, isAdmin, cancellationToken);

        if (!success || filePath == null)
            return NotFound(ApiResponse<string>.Fail(message));

        return PhysicalFile(filePath, contentType ?? "application/octet-stream", originalFileName);
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

public record CancelOrderRequestDto(string Reason);


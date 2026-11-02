using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.BusinessVerification;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/admin/verifications")]
[Authorize(Roles = "Admin")]
public class AdminVerificationController : ControllerBase
{
    private readonly IBusinessVerificationService _verificationService;
    private readonly ILogger<AdminVerificationController> _logger;

    public AdminVerificationController(
        IBusinessVerificationService verificationService,
        ILogger<AdminVerificationController> logger)
    {
        _verificationService = verificationService;
        _logger = logger;
    }

    private int? GetCurrentAdminMemberId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;
        return int.TryParse(claim, out var memberId) ? memberId : null;
    }

    /// <summary>
    /// Lists all business verification requests with optional status filtering and pagination.
    /// Restricted to Admin role.
    /// GET /api/v1/admin/verifications?status=PendingReview&page=1&pageSize=20
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<AdminVerificationListResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetVerifications(
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await _verificationService.GetAdminVerificationsAsync(status, page, pageSize, cancellationToken);
        return StatusCode(result.StatusCode, ApiResponse<AdminVerificationListResponseDto>.Ok(result.Data!, result.Data?.TotalCount ?? 0));
    }

    /// <summary>
    /// Retrieves full details of a specific business verification request.
    /// GET /api/v1/admin/verifications/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVerificationById(int id, CancellationToken cancellationToken)
    {
        var result = await _verificationService.GetVerificationByIdAsync(id, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.Fail(result.ErrorMessage ?? "Not found."));
        }

        return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Approves a business verification request, granting official verified status.
    /// POST /api/v1/admin/verifications/{id}/approve
    /// </summary>
    [HttpPost("{id:int}/approve")]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ApproveVerification(int id, CancellationToken cancellationToken)
    {
        var adminId = GetCurrentAdminMemberId();
        if (adminId == null)
        {
            return Unauthorized(ApiResponse<BusinessVerificationRequestDto>.Fail("Invalid admin session."));
        }

        var result = await _verificationService.ApproveVerificationAsync(id, adminId.Value, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.Fail(result.ErrorMessage ?? "Approval failed."));
        }

        return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.WithMessage(result.Data!, "Verification approved successfully."));
    }

    /// <summary>
    /// Rejects a business verification request with mandatory rejection reasons.
    /// POST /api/v1/admin/verifications/{id}/reject
    /// </summary>
    [HttpPost("{id:int}/reject")]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RejectVerification(
        int id,
        [FromBody] RejectVerificationRequestDto request,
        CancellationToken cancellationToken)
    {
        var adminId = GetCurrentAdminMemberId();
        if (adminId == null)
        {
            return Unauthorized(ApiResponse<BusinessVerificationRequestDto>.Fail("Invalid admin session."));
        }

        if (string.IsNullOrWhiteSpace(request?.Reason))
        {
            return BadRequest(ApiResponse<BusinessVerificationRequestDto>.Fail("A valid rejection reason is strictly required."));
        }

        var result = await _verificationService.RejectVerificationAsync(id, adminId.Value, request.Reason, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.Fail(result.ErrorMessage ?? "Rejection failed."));
        }

        return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.WithMessage(result.Data!, "Verification rejected with remarks."));
    }
}

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.BusinessVerification;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/business-verification")]
[Authorize]
public class BusinessVerificationController : ControllerBase
{
    private readonly IBusinessVerificationService _verificationService;
    private readonly ILogger<BusinessVerificationController> _logger;

    public BusinessVerificationController(
        IBusinessVerificationService verificationService,
        ILogger<BusinessVerificationController> logger)
    {
        _verificationService = verificationService;
        _logger = logger;
    }

    private int? GetCurrentMemberId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;
        return int.TryParse(claim, out var memberId) ? memberId : null;
    }

    /// <summary>
    /// Submits a business verification application with uploaded supporting documents.
    /// POST /api/v1/business-verification/submit
    /// </summary>
    [HttpPost("submit")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<BusinessVerificationRequestDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SubmitVerification(
        [FromForm] SubmitBusinessVerificationForm form,
        CancellationToken cancellationToken)
    {
        var memberId = GetCurrentMemberId();
        if (memberId == null)
        {
            return Unauthorized(ApiResponse<BusinessVerificationRequestDto>.Fail("Invalid authentication claims."));
        }

        var requestDto = new SubmitBusinessVerificationRequestDto(
            BusinessRegistrationNumber: form.BusinessRegistrationNumber,
            RegisteredAddress: form.RegisteredAddress,
            City: form.City,
            State: form.State,
            Pincode: form.Pincode,
            Notes: form.Notes
        );

        var result = await _verificationService.SubmitVerificationAsync(
            memberId.Value,
            requestDto,
            form.Documents ?? new List<IFormFile>(),
            cancellationToken
        );

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.Fail(result.ErrorMessage ?? "Submission failed."));
        }

        return StatusCode(result.StatusCode, ApiResponse<BusinessVerificationRequestDto>.WithMessage(result.Data!, "Verification request submitted successfully."));
    }

    /// <summary>
    /// Retrieves current verification status and latest application for authenticated member.
    /// GET /api/v1/business-verification/status
    /// </summary>
    [HttpGet("status")]
    [ProducesResponseType(typeof(ApiResponse<VerificationStatusResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerificationStatusResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetStatus(CancellationToken cancellationToken)
    {
        var memberId = GetCurrentMemberId();
        if (memberId == null)
        {
            return Unauthorized(ApiResponse<VerificationStatusResponseDto>.Fail("Invalid authentication claims."));
        }

        var result = await _verificationService.GetVerificationStatusAsync(memberId.Value, cancellationToken);
        return StatusCode(result.StatusCode, ApiResponse<VerificationStatusResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Securely downloads a verification document. Restricted to owner or Admin role.
    /// GET /api/v1/business-verification/documents/{documentId}/download
    /// </summary>
    [HttpGet("documents/{documentId}/download")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DownloadDocument(int documentId, CancellationToken cancellationToken)
    {
        var memberId = GetCurrentMemberId();
        if (memberId == null)
        {
            return Unauthorized();
        }

        var isAdmin = User.IsInRole("Admin");
        var (success, stream, contentType, originalFileName, errorMessage, statusCode) =
            await _verificationService.DownloadDocumentAsync(documentId, memberId.Value, isAdmin, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, new { message = errorMessage });
        }

        return File(stream!, contentType ?? "application/octet-stream", originalFileName ?? $"document_{documentId}");
    }

    /// <summary>
    /// Uploads a business logo image for the authenticated member's business profile.
    /// POST /api/v1/business-verification/logo
    /// </summary>
    [HttpPost("logo")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UploadLogo(IFormFile file, CancellationToken cancellationToken)
    {
        var memberId = GetCurrentMemberId();
        if (memberId == null)
        {
            return Unauthorized(ApiResponse<string>.Fail("Invalid authentication claims."));
        }

        var result = await _verificationService.UploadLogoAsync(memberId.Value, file, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<string>.Fail(result.ErrorMessage ?? "Logo upload failed."));
        }

        return StatusCode(result.StatusCode, ApiResponse<string>.WithMessage(result.Data!, "Logo uploaded successfully."));
    }

    /// <summary>
    /// Uploads a gallery image for the authenticated member's business profile.
    /// POST /api/v1/business-verification/images
    /// </summary>
    [HttpPost("images")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<List<string>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<string>>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<List<string>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UploadBusinessImage(IFormFile file, CancellationToken cancellationToken)
    {
        var memberId = GetCurrentMemberId();
        if (memberId == null)
        {
            return Unauthorized(ApiResponse<List<string>>.Fail("Invalid authentication claims."));
        }

        var result = await _verificationService.UploadBusinessImageAsync(memberId.Value, file, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<List<string>>.Fail(result.ErrorMessage ?? "Image upload failed."));
        }

        return StatusCode(result.StatusCode, ApiResponse<List<string>>.WithMessage(result.Data!, "Image uploaded successfully.", result.Data?.Count ?? 0));
    }
}

public class SubmitBusinessVerificationForm
{
    public string BusinessRegistrationNumber { get; set; } = string.Empty;
    public string RegisteredAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public List<IFormFile> Documents { get; set; } = new();
}

using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.ServicesMarketplace;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/service-inquiries")]
[Authorize]
public class ServiceInquiriesController : ControllerBase
{
    private readonly IBusinessServiceService _serviceService;
    private readonly ILogger<ServiceInquiriesController> _logger;

    public ServiceInquiriesController(IBusinessServiceService serviceService, ILogger<ServiceInquiriesController> logger)
    {
        _serviceService = serviceService;
        _logger = logger;
    }

    /// <summary>
    /// Submits a new inquiry for a business service.
    /// POST /api/v1/service-inquiries
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateInquiry([FromBody] CreateServiceInquiryDto dto)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceInquiryDetailDto>.Fail("Invalid authentication claims."));

        var (success, inquiry, error) = await _serviceService.CreateInquiryAsync(memberId.Value, dto);
        if (!success || inquiry == null)
            return BadRequest(ApiResponse<ServiceInquiryDetailDto>.Fail(error ?? "Failed to create inquiry."));

        return StatusCode(StatusCodes.Status201Created, ApiResponse<ServiceInquiryDetailDto>.Ok(inquiry, 1));
    }

    /// <summary>
    /// Retrieves full details and status history of a service inquiry.
    /// GET /api/v1/service-inquiries/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetInquiryById(int id)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceInquiryDetailDto>.Fail("Invalid authentication claims."));

        var (success, inquiry, error) = await _serviceService.GetInquiryByIdAsync(memberId.Value, id);
        if (!success || inquiry == null)
            return NotFound(ApiResponse<ServiceInquiryDetailDto>.Fail(error ?? "Inquiry not found."));

        return Ok(ApiResponse<ServiceInquiryDetailDto>.Ok(inquiry, 1));
    }

    /// <summary>
    /// Retrieves all service inquiries sent by the authenticated member.
    /// GET /api/v1/service-inquiries/sent
    /// </summary>
    [HttpGet("sent")]
    [ProducesResponseType(typeof(ApiResponse<List<ServiceInquiryDetailDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMySentInquiries()
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<List<ServiceInquiryDetailDto>>.Fail("Invalid authentication claims."));

        var list = await _serviceService.GetMySentInquiriesAsync(memberId.Value);
        return Ok(ApiResponse<List<ServiceInquiryDetailDto>>.Ok(list, list.Count));
    }

    /// <summary>
    /// Retrieves all service inquiries received by the authenticated service provider.
    /// GET /api/v1/service-inquiries/received
    /// </summary>
    [HttpGet("received")]
    [ProducesResponseType(typeof(ApiResponse<List<ServiceInquiryDetailDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyReceivedInquiries()
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<List<ServiceInquiryDetailDto>>.Fail("Invalid authentication claims."));

        var list = await _serviceService.GetMyReceivedInquiriesAsync(memberId.Value);
        return Ok(ApiResponse<List<ServiceInquiryDetailDto>>.Ok(list, list.Count));
    }

    /// <summary>
    /// Responds to a service inquiry.
    /// POST /api/v1/service-inquiries/{id}/respond
    /// </summary>
    [HttpPost("{id:int}/respond")]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> RespondInquiry(int id, [FromBody] RespondServiceInquiryDto dto)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceInquiryDetailDto>.Fail("Invalid authentication claims."));

        var (success, inquiry, error) = await _serviceService.RespondInquiryAsync(memberId.Value, id, dto);
        if (!success || inquiry == null)
            return BadRequest(ApiResponse<ServiceInquiryDetailDto>.Fail(error ?? "Failed to respond to inquiry."));

        return Ok(ApiResponse<ServiceInquiryDetailDto>.Ok(inquiry, 1));
    }

    /// <summary>
    /// Updates the status of an ongoing service inquiry.
    /// POST /api/v1/service-inquiries/{id}/status
    /// </summary>
    [HttpPost("{id:int}/status")]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ServiceInquiryDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateInquiryStatus(int id, [FromBody] UpdateServiceInquiryStatusDto dto)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceInquiryDetailDto>.Fail("Invalid authentication claims."));

        var (success, inquiry, error) = await _serviceService.UpdateInquiryStatusAsync(memberId.Value, id, dto);
        if (!success || inquiry == null)
            return BadRequest(ApiResponse<ServiceInquiryDetailDto>.Fail(error ?? "Failed to update inquiry status."));

        return Ok(ApiResponse<ServiceInquiryDetailDto>.Ok(inquiry, 1));
    }

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


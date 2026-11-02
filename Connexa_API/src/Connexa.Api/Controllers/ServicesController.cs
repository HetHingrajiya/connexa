using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.ServicesMarketplace;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/services")]
public class ServicesController : ControllerBase
{
    private readonly IBusinessServiceService _serviceService;
    private readonly ILogger<ServicesController> _logger;

    public ServicesController(IBusinessServiceService serviceService, ILogger<ServicesController> logger)
    {
        _serviceService = serviceService;
        _logger = logger;
    }

    /// <summary>
    /// Searches active marketplace services with filtering, search query and pagination.
    /// GET /api/v1/services
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<ServiceSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SearchServices(
        [FromQuery] string? query,
        [FromQuery] string? category,
        [FromQuery] int? industryId,
        [FromQuery] string? location,
        [FromQuery] string? serviceType,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var searchQuery = new ServiceSearchQueryDto(query, category, industryId, location, serviceType, page, pageSize);
        var (services, totalCount, totalPages) = await _serviceService.SearchServicesAsync(searchQuery);

        return Ok(ApiResponse<List<ServiceSummaryDto>>.Ok(services, totalCount));
    }

    /// <summary>
    /// Retrieves list of popular and available service categories.
    /// GET /api/v1/services/categories
    /// </summary>
    [HttpGet("categories")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<string>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await _serviceService.GetPopularCategoriesAsync();
        return Ok(ApiResponse<List<string>>.Ok(categories, categories.Count));
    }

    /// <summary>
    /// Retrieves services published by the authenticated member.
    /// GET /api/v1/services/my
    /// </summary>
    [HttpGet("my")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<List<ServiceSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyServices()
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<List<ServiceSummaryDto>>.Fail("Invalid authentication claims."));

        var services = await _serviceService.GetMyServicesAsync(memberId.Value);
        return Ok(ApiResponse<List<ServiceSummaryDto>>.Ok(services, services.Count));
    }

    /// <summary>
    /// Retrieves details of a specific business service.
    /// GET /api/v1/services/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetServiceById(int id)
    {
        var currentMemberId = GetCurrentMemberId();
        var (success, service, error) = await _serviceService.GetServiceByIdAsync(id, currentMemberId);
        if (!success || service == null)
            return NotFound(ApiResponse<ServiceDetailDto>.Fail(error ?? "Service not found."));

        return Ok(ApiResponse<ServiceDetailDto>.Ok(service, 1));
    }

    /// <summary>
    /// Publishes a new business service.
    /// POST /api/v1/services
    /// </summary>
    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateService([FromBody] CreateServiceDto dto)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceDetailDto>.Fail("Invalid authentication claims."));

        var (success, service, error) = await _serviceService.CreateServiceAsync(memberId.Value, dto);
        if (!success || service == null)
            return BadRequest(ApiResponse<ServiceDetailDto>.Fail(error ?? "Failed to create service."));

        return StatusCode(StatusCodes.Status201Created, ApiResponse<ServiceDetailDto>.Ok(service, 1));
    }

    /// <summary>
    /// Updates an existing service owned by the authenticated member.
    /// PUT /api/v1/services/{id}
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ServiceDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateService(int id, [FromBody] UpdateServiceDto dto)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<ServiceDetailDto>.Fail("Invalid authentication claims."));

        var (success, service, error) = await _serviceService.UpdateServiceAsync(memberId.Value, id, dto);
        if (!success || service == null)
            return BadRequest(ApiResponse<ServiceDetailDto>.Fail(error ?? "Failed to update service."));

        return Ok(ApiResponse<ServiceDetailDto>.Ok(service, 1));
    }

    /// <summary>
    /// Deletes or deactivates a service owned by the authenticated member.
    /// DELETE /api/v1/services/{id}
    /// </summary>
    [HttpDelete("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> DeleteService(int id)
    {
        var memberId = GetCurrentMemberId();
        if (!memberId.HasValue)
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));

        var (success, error) = await _serviceService.DeleteServiceAsync(memberId.Value, id);
        if (!success)
            return BadRequest(ApiResponse<bool>.Fail(error ?? "Failed to delete service."));

        return Ok(ApiResponse<bool>.WithMessage(true, "Service deleted or deactivated successfully."));
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


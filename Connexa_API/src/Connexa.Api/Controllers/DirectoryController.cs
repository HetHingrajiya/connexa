using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Directory;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/directory")]
[Authorize]
public class DirectoryController : ControllerBase
{
    private readonly IDirectoryService _directoryService;
    private readonly ILogger<DirectoryController> _logger;

    public DirectoryController(IDirectoryService directoryService, ILogger<DirectoryController> logger)
    {
        _directoryService = directoryService;
        _logger = logger;
    }

    /// <summary>
    /// Searches and lists registered businesses with 4-tier hierarchy and capability filtering.
    /// Excludes internal credentials and unverified data.
    /// GET /api/v1/directory/businesses
    /// </summary>
    [HttpGet("businesses")]
    [ProducesResponseType(typeof(ApiResponse<BusinessDirectoryResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<BusinessDirectoryResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetBusinesses([FromQuery] BusinessDirectoryFilterDto filter, CancellationToken cancellationToken)
    {
        var result = await _directoryService.SearchBusinessesAsync(filter, cancellationToken);
        return Ok(ApiResponse<BusinessDirectoryResponseDto>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Retrieves a single business directory profile by member ID.
    /// GET /api/v1/directory/businesses/{memberId}
    /// </summary>
    [HttpGet("businesses/{memberId:int}")]
    [ProducesResponseType(typeof(ApiResponse<BusinessDirectoryItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<BusinessDirectoryItemDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<BusinessDirectoryItemDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetBusinessById(int memberId, CancellationToken cancellationToken)
    {
        var item = await _directoryService.GetBusinessByMemberIdAsync(memberId, cancellationToken);
        if (item == null)
        {
            return NotFound(ApiResponse<BusinessDirectoryItemDto>.Fail("Business directory entry not found."));
        }

        return Ok(ApiResponse<BusinessDirectoryItemDto>.Ok(item, 1));
    }
}

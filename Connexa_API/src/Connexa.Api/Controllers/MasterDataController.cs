using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/master")]
public class MasterDataController : ControllerBase
{
    private readonly IMasterDataService _masterDataService;
    private readonly ISqliteMigrationService _migrationService;
    private readonly ILogger<MasterDataController> _logger;

    public MasterDataController(
        IMasterDataService masterDataService,
        ISqliteMigrationService migrationService,
        ILogger<MasterDataController> logger)
    {
        _masterDataService = masterDataService;
        _migrationService = migrationService;
        _logger = logger;
    }

    /// <summary>
    /// Fetches all available industries ordered alphabetically.
    /// GET /api/v1/master/industries
    /// </summary>
    [HttpGet("industries")]
    public async Task<IActionResult> GetIndustries(CancellationToken cancellationToken)
    {
        var result = await _masterDataService.GetIndustriesAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Fetches business groups for a specific industry via path parameter.
    /// GET /api/v1/master/industries/{industryId}/business-groups
    /// </summary>
    [HttpGet("industries/{industryId}/business-groups")]
    public async Task<IActionResult> GetBusinessGroupsByPath(string industryId, CancellationToken cancellationToken)
    {
        return await HandleGetBusinessGroups(industryId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch business groups via query parameter.
    /// GET /api/v1/master/business-groups?industryId=...
    /// </summary>
    [HttpGet("business-groups")]
    public async Task<IActionResult> GetBusinessGroupsByQuery([FromQuery] string? industryId, [FromQuery(Name = "industry_id")] string? industry_id, CancellationToken cancellationToken)
    {
        var targetId = !string.IsNullOrWhiteSpace(industryId) ? industryId : industry_id;
        return await HandleGetBusinessGroups(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetBusinessGroups(string? industryId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(industryId))
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "industryId parameter is required"
            });
        }

        var result = await _masterDataService.GetBusinessGroupsAsync(industryId, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent Industry with id \"{industryId}\" not found"
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Fetches sub-groups for a specific business group via path parameter.
    /// GET /api/v1/master/business-groups/{businessGroupId}/sub-groups
    /// </summary>
    [HttpGet("business-groups/{businessGroupId}/sub-groups")]
    public async Task<IActionResult> GetSubGroupsByPath(string businessGroupId, CancellationToken cancellationToken)
    {
        return await HandleGetSubGroups(businessGroupId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch sub-groups via query parameter.
    /// GET /api/v1/master/sub-groups?businessGroupId=...
    /// </summary>
    [HttpGet("sub-groups")]
    public async Task<IActionResult> GetSubGroupsByQuery([FromQuery] string? businessGroupId, [FromQuery(Name = "business_group_id")] string? business_group_id, CancellationToken cancellationToken)
    {
        var targetId = !string.IsNullOrWhiteSpace(businessGroupId) ? businessGroupId : business_group_id;
        return await HandleGetSubGroups(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetSubGroups(string? businessGroupId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(businessGroupId))
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "businessGroupId parameter is required"
            });
        }

        var result = await _masterDataService.GetSubGroupsAsync(businessGroupId, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent Business Group with id \"{businessGroupId}\" not found"
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Fetches categories for a specific sub-group via path parameter.
    /// GET /api/v1/master/sub-groups/{subGroupId}/categories
    /// </summary>
    [HttpGet("sub-groups/{subGroupId}/categories")]
    public async Task<IActionResult> GetCategoriesByPath(string subGroupId, CancellationToken cancellationToken)
    {
        return await HandleGetCategories(subGroupId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch categories via query parameter.
    /// GET /api/v1/master/categories?subGroupId=...
    /// </summary>
    [HttpGet("categories")]
    public async Task<IActionResult> GetCategoriesByQuery([FromQuery] string? subGroupId, [FromQuery(Name = "sub_group_id")] string? sub_group_id, CancellationToken cancellationToken)
    {
        var targetId = !string.IsNullOrWhiteSpace(subGroupId) ? subGroupId : sub_group_id;
        return await HandleGetCategories(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetCategories(string? subGroupId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(subGroupId))
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "subGroupId parameter is required"
            });
        }

        var result = await _masterDataService.GetCategoriesAsync(subGroupId, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent SubGroup with id \"{subGroupId}\" not found"
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Explicit, repeatable data migration from SQLite to SQL Server.
    /// POST /api/v1/master/migrate-from-sqlite
    /// </summary>
    [HttpPost("migrate-from-sqlite")]
    public async Task<IActionResult> MigrateFromSqlite([FromQuery] string? sourcePath, CancellationToken cancellationToken)
    {
        var result = await _migrationService.MigrateFromSqliteAsync(sourcePath, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(500, result);
        }
        return Ok(result);
    }
}
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
    [HttpGet("industries/{industryId:int}/business-groups")]
    public async Task<IActionResult> GetBusinessGroupsByPath(int industryId, CancellationToken cancellationToken)
    {
        return await HandleGetBusinessGroups(industryId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch business groups via query parameter.
    /// GET /api/v1/master/business-groups?industryId=...
    /// </summary>
    [HttpGet("business-groups")]
    public async Task<IActionResult> GetBusinessGroupsByQuery([FromQuery] int? industryId, [FromQuery(Name = "industry_id")] int? industry_id, CancellationToken cancellationToken)
    {
        var targetId = industryId ?? industry_id;
        return await HandleGetBusinessGroups(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetBusinessGroups(int? industryId, CancellationToken cancellationToken)
    {
        if (!industryId.HasValue || industryId.Value <= 0)
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "industryId parameter is required and must be a positive integer"
            });
        }

        var result = await _masterDataService.GetBusinessGroupsAsync(industryId.Value, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent Industry with id {industryId.Value} not found"
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Fetches sub-groups for a specific business group via path parameter.
    /// GET /api/v1/master/business-groups/{businessGroupId}/sub-groups
    /// </summary>
    [HttpGet("business-groups/{businessGroupId:int}/sub-groups")]
    public async Task<IActionResult> GetSubGroupsByPath(int businessGroupId, CancellationToken cancellationToken)
    {
        return await HandleGetSubGroups(businessGroupId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch sub-groups via query parameter.
    /// GET /api/v1/master/sub-groups?businessGroupId=...
    /// </summary>
    [HttpGet("sub-groups")]
    public async Task<IActionResult> GetSubGroupsByQuery([FromQuery] int? businessGroupId, [FromQuery(Name = "business_group_id")] int? business_group_id, CancellationToken cancellationToken)
    {
        var targetId = businessGroupId ?? business_group_id;
        return await HandleGetSubGroups(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetSubGroups(int? businessGroupId, CancellationToken cancellationToken)
    {
        if (!businessGroupId.HasValue || businessGroupId.Value <= 0)
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "businessGroupId parameter is required and must be a positive integer"
            });
        }

        var result = await _masterDataService.GetSubGroupsAsync(businessGroupId.Value, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent Business Group with id {businessGroupId.Value} not found"
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Fetches categories for a specific sub-group via path parameter.
    /// GET /api/v1/master/sub-groups/{subGroupId}/categories
    /// </summary>
    [HttpGet("sub-groups/{subGroupId:int}/categories")]
    public async Task<IActionResult> GetCategoriesByPath(int subGroupId, CancellationToken cancellationToken)
    {
        return await HandleGetCategories(subGroupId, cancellationToken);
    }

    /// <summary>
    /// Fallback endpoint to fetch categories via query parameter.
    /// GET /api/v1/master/categories?subGroupId=...
    /// </summary>
    [HttpGet("categories")]
    public async Task<IActionResult> GetCategoriesByQuery([FromQuery] int? subGroupId, [FromQuery(Name = "sub_group_id")] int? sub_group_id, CancellationToken cancellationToken)
    {
        var targetId = subGroupId ?? sub_group_id;
        return await HandleGetCategories(targetId, cancellationToken);
    }

    private async Task<IActionResult> HandleGetCategories(int? subGroupId, CancellationToken cancellationToken)
    {
        if (!subGroupId.HasValue || subGroupId.Value <= 0)
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "subGroupId parameter is required and must be a positive integer"
            });
        }

        var result = await _masterDataService.GetCategoriesAsync(subGroupId.Value, cancellationToken);
        if (result == null)
        {
            return NotFound(new ErrorResponseDto
            {
                Success = false,
                Message = $"Parent SubGroup with id {subGroupId.Value} not found"
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
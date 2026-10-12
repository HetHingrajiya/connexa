using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;

namespace Connexa.Api.Services;

public class MasterDataService : IMasterDataService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ILogger<MasterDataService> _logger;

    public MasterDataService(ConnexaDbContext dbContext, ILogger<MasterDataService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<ApiResponse<IReadOnlyList<IndustryDto>>> GetIndustriesAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Fetching all industries ordered by name");

        var industries = await _dbContext.Industries
            .AsNoTracking()
            .OrderBy(i => i.Name)
            .Select(i => new IndustryDto(i.Id, i.Name, i.Code, i.Description))
            .ToListAsync(cancellationToken);

        return ApiResponse<IReadOnlyList<IndustryDto>>.Ok(industries, industries.Count);
    }

    public async Task<ApiResponse<IReadOnlyList<BusinessGroupDto>>?> GetBusinessGroupsAsync(string industryId, CancellationToken cancellationToken = default)
    {
        var trimmedId = industryId.Trim();
        _logger.LogInformation("Fetching business groups for IndustryId: {IndustryId}", trimmedId);

        // Verify parent industry exists
        var parent = await _dbContext.Industries
            .AsNoTracking()
            .Where(i => i.Id == trimmedId)
            .Select(i => new ParentRefDto(i.Id, i.Name, null, null))
            .FirstOrDefaultAsync(cancellationToken);

        if (parent == null)
        {
            _logger.LogWarning("Parent Industry with id {IndustryId} not found", trimmedId);
            return null;
        }

        var groups = await _dbContext.BusinessGroups
            .AsNoTracking()
            .Where(g => g.IndustryId == trimmedId)
            .OrderBy(g => g.Name)
            .Select(g => new BusinessGroupDto(g.Id, g.IndustryId, g.Name, g.Code, g.Description))
            .ToListAsync(cancellationToken);

        return ApiResponse<IReadOnlyList<BusinessGroupDto>>.Ok(groups, groups.Count, parent);
    }

    public async Task<ApiResponse<IReadOnlyList<SubGroupDto>>?> GetSubGroupsAsync(string businessGroupId, CancellationToken cancellationToken = default)
    {
        var trimmedId = businessGroupId.Trim();
        _logger.LogInformation("Fetching sub-groups for BusinessGroupId: {BusinessGroupId}", trimmedId);

        // Verify parent business group exists
        var parent = await _dbContext.BusinessGroups
            .AsNoTracking()
            .Where(g => g.Id == trimmedId)
            .Select(g => new ParentRefDto(g.Id, g.Name, g.IndustryId, null))
            .FirstOrDefaultAsync(cancellationToken);

        if (parent == null)
        {
            _logger.LogWarning("Parent Business Group with id {BusinessGroupId} not found", trimmedId);
            return null;
        }

        var subGroups = await _dbContext.SubGroups
            .AsNoTracking()
            .Where(sg => sg.BusinessGroupId == trimmedId)
            .OrderBy(sg => sg.Name)
            .Select(sg => new SubGroupDto(sg.Id, sg.BusinessGroupId, sg.Name, sg.Code, sg.Description))
            .ToListAsync(cancellationToken);

        return ApiResponse<IReadOnlyList<SubGroupDto>>.Ok(subGroups, subGroups.Count, parent);
    }

    public async Task<ApiResponse<IReadOnlyList<CategoryDto>>?> GetCategoriesAsync(string subGroupId, CancellationToken cancellationToken = default)
    {
        var trimmedId = subGroupId.Trim();
        _logger.LogInformation("Fetching categories for SubGroupId: {SubGroupId}", trimmedId);

        // Verify parent sub-group exists
        var parent = await _dbContext.SubGroups
            .AsNoTracking()
            .Where(sg => sg.Id == trimmedId)
            .Select(sg => new ParentRefDto(sg.Id, sg.Name, null, sg.BusinessGroupId))
            .FirstOrDefaultAsync(cancellationToken);

        if (parent == null)
        {
            _logger.LogWarning("Parent SubGroup with id {SubGroupId} not found", trimmedId);
            return null;
        }

        var categories = await _dbContext.Categories
            .AsNoTracking()
            .Where(c => c.SubGroupId == trimmedId)
            .OrderBy(c => c.Name)
            .Select(c => new CategoryDto(c.Id, c.SubGroupId, c.Name, c.Code, c.Description))
            .ToListAsync(cancellationToken);

        return ApiResponse<IReadOnlyList<CategoryDto>>.Ok(categories, categories.Count, parent);
    }
}
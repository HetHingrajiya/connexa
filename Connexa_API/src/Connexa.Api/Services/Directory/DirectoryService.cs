using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Directory;

public class DirectoryService : IDirectoryService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ILogger<DirectoryService> _logger;

    public DirectoryService(ConnexaDbContext dbContext, ILogger<DirectoryService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<BusinessDirectoryResponseDto> SearchBusinessesAsync(BusinessDirectoryFilterDto filter, CancellationToken cancellationToken = default)
    {
        var query = _dbContext.BusinessProfiles
            .AsNoTracking()
            .Where(b => b.Member.IsActive);

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim();
            query = query.Where(b =>
                b.CompanyName.Contains(search) ||
                b.Member.FullName.Contains(search) ||
                b.BusinessDescription.Contains(search) ||
                b.BusinessCapabilities.Contains(search));
        }

        if (filter.IndustryId.HasValue && filter.IndustryId.Value > 0)
        {
            query = query.Where(b => b.IndustryId == filter.IndustryId.Value);
        }

        if (filter.BusinessGroupId.HasValue && filter.BusinessGroupId.Value > 0)
        {
            query = query.Where(b => b.BusinessGroupId == filter.BusinessGroupId.Value);
        }

        if (filter.SubGroupId.HasValue && filter.SubGroupId.Value > 0)
        {
            query = query.Where(b => b.SubGroupId == filter.SubGroupId.Value);
        }

        if (filter.CategoryId.HasValue && filter.CategoryId.Value > 0)
        {
            query = query.Where(b => b.CategoryId == filter.CategoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(filter.Capability))
        {
            var cap = filter.Capability.Trim();
            query = query.Where(b => b.BusinessCapabilities.Contains(cap));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var page = filter.Page < 1 ? 1 : filter.Page;
        var pageSize = filter.PageSize < 1 ? 10 : (filter.PageSize > 50 ? 50 : filter.PageSize);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var rawItems = await query
            .OrderBy(b => b.CompanyName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new
            {
                b.MemberId,
                b.CompanyName,
                ContactPersonName = b.Member.FullName,
                b.Member.Email,
                PhoneNumber = b.Member.CountryCode + b.Member.PhoneNumber,
                b.BusinessCapabilities,
                b.BusinessDescription,
                b.IndustryId,
                IndustryName = b.Industry.Name,
                b.BusinessGroupId,
                BusinessGroupName = b.BusinessGroup.Name,
                b.SubGroupId,
                SubGroupName = b.SubGroup.Name,
                b.CategoryId,
                CategoryName = b.Category.Name,
                b.Member.VerifiedMethod,
                MemberSinceUtc = b.Member.CreatedAtUtc
            })
            .ToListAsync(cancellationToken);

        var items = rawItems.Select(r => new BusinessDirectoryItemDto(
            r.MemberId,
            r.CompanyName,
            r.ContactPersonName,
            r.Email,
            r.PhoneNumber,
            (r.BusinessCapabilities ?? string.Empty).Split(new[] { ", " }, StringSplitOptions.RemoveEmptyEntries).ToList(),
            r.BusinessDescription,
            r.IndustryId,
            r.IndustryName,
            r.BusinessGroupId,
            r.BusinessGroupName,
            r.SubGroupId,
            r.SubGroupName,
            r.CategoryId,
            r.CategoryName,
            r.VerifiedMethod,
            r.MemberSinceUtc
        )).ToList();

        _logger.LogInformation("[Directory] Query returned {Count} of {Total} businesses (Page {Page}/{TotalPages})",
            items.Count, totalCount, page, totalPages);

        return new BusinessDirectoryResponseDto(
            Items: items,
            TotalCount: totalCount,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );
    }

    public async Task<BusinessDirectoryItemDto?> GetBusinessByMemberIdAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var raw = await _dbContext.BusinessProfiles
            .AsNoTracking()
            .Where(b => b.MemberId == memberId && b.Member.IsActive)
            .Select(b => new
            {
                b.MemberId,
                b.CompanyName,
                ContactPersonName = b.Member.FullName,
                b.Member.Email,
                PhoneNumber = b.Member.CountryCode + b.Member.PhoneNumber,
                b.BusinessCapabilities,
                b.BusinessDescription,
                b.IndustryId,
                IndustryName = b.Industry.Name,
                b.BusinessGroupId,
                BusinessGroupName = b.BusinessGroup.Name,
                b.SubGroupId,
                SubGroupName = b.SubGroup.Name,
                b.CategoryId,
                CategoryName = b.Category.Name,
                b.Member.VerifiedMethod,
                MemberSinceUtc = b.Member.CreatedAtUtc
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (raw == null)
        {
            return null;
        }

        return new BusinessDirectoryItemDto(
            raw.MemberId,
            raw.CompanyName,
            raw.ContactPersonName,
            raw.Email,
            raw.PhoneNumber,
            (raw.BusinessCapabilities ?? string.Empty).Split(new[] { ", " }, StringSplitOptions.RemoveEmptyEntries).ToList(),
            raw.BusinessDescription,
            raw.IndustryId,
            raw.IndustryName,
            raw.BusinessGroupId,
            raw.BusinessGroupName,
            raw.SubGroupId,
            raw.SubGroupName,
            raw.CategoryId,
            raw.CategoryName,
            raw.VerifiedMethod,
            raw.MemberSinceUtc
        );
    }
}

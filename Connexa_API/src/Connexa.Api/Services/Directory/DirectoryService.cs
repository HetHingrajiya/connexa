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

    private sealed class DirectoryEntryInternal
    {
        public int MemberId { get; set; }
        public string CompanyName { get; set; } = string.Empty;
        public string ContactPersonName { get; set; } = string.Empty;
        public string RawEmail { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public string RawPhoneNumber { get; set; } = string.Empty;
        public string CapabilitiesRaw { get; set; } = string.Empty;
        public string? BusinessDescription { get; set; }
        public int IndustryId { get; set; }
        public string IndustryName { get; set; } = string.Empty;
        public int BusinessGroupId { get; set; }
        public string BusinessGroupName { get; set; } = string.Empty;
        public int SubGroupId { get; set; }
        public string SubGroupName { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string VerifiedMethod { get; set; } = string.Empty;
        public DateTime MemberSinceUtc { get; set; }
        public string BusinessType { get; set; } = string.Empty;
        public string? Location { get; set; }
    }

    private IQueryable<DirectoryEntryInternal> BuildCombinedDirectoryQuery()
    {
        // 1. Business Profiles (Manufacturer / Company)
        var bpQuery = _dbContext.BusinessProfiles
            .AsNoTracking()
            .Where(b => b.Member.IsActive)
            .Select(b => new DirectoryEntryInternal
            {
                MemberId = b.MemberId,
                CompanyName = b.CompanyName,
                ContactPersonName = b.Member.FullName,
                RawEmail = b.Member.Email,
                CountryCode = b.Member.CountryCode,
                RawPhoneNumber = b.Member.PhoneNumber,
                CapabilitiesRaw = b.BusinessCapabilities ?? string.Empty,
                BusinessDescription = b.BusinessDescription,
                IndustryId = b.IndustryId,
                IndustryName = b.Industry.Name,
                BusinessGroupId = b.BusinessGroupId,
                BusinessGroupName = b.BusinessGroup.Name,
                SubGroupId = b.SubGroupId,
                SubGroupName = b.SubGroup.Name,
                CategoryId = b.CategoryId,
                CategoryName = b.Category.Name,
                VerifiedMethod = b.Member.VerifiedMethod,
                MemberSinceUtc = b.Member.CreatedAtUtc,
                BusinessType = "Manufacturer / Company",
                Location = "Gujarat, India"
            });

        // 2. Contractor Profiles (Contractor / Job Worker)
        var cpQuery = _dbContext.ContractorProfiles
            .AsNoTracking()
            .Where(c => c.Member.IsActive)
            .Select(c => new DirectoryEntryInternal
            {
                MemberId = c.MemberId,
                CompanyName = c.WorkName,
                ContactPersonName = c.Member.FullName,
                RawEmail = c.Member.Email,
                CountryCode = c.Member.CountryCode,
                RawPhoneNumber = c.Member.PhoneNumber,
                CapabilitiesRaw = (c.WorkCapabilities ?? string.Empty) +
                    (string.IsNullOrEmpty(c.ProcessesSupported) ? "" : ", " + c.ProcessesSupported),
                BusinessDescription = c.ProcessesSupported,
                IndustryId = c.IndustryId,
                IndustryName = c.Industry.Name,
                BusinessGroupId = c.BusinessGroupId,
                BusinessGroupName = c.BusinessGroup.Name,
                SubGroupId = c.SubGroupId,
                SubGroupName = c.SubGroup.Name,
                CategoryId = c.CategoryId,
                CategoryName = c.Category.Name,
                VerifiedMethod = c.Member.VerifiedMethod,
                MemberSinceUtc = c.Member.CreatedAtUtc,
                BusinessType = "Contractor / Job Worker",
                Location = c.WorkCoverage
            });

        // 3. Trader Profiles (Trader / Supplier)
        var tpQuery = _dbContext.TraderProfiles
            .AsNoTracking()
            .Where(t => t.Member.IsActive)
            .Select(t => new DirectoryEntryInternal
            {
                MemberId = t.MemberId,
                CompanyName = t.TradingName,
                ContactPersonName = t.Member.FullName,
                RawEmail = t.Member.Email,
                CountryCode = t.Member.CountryCode,
                RawPhoneNumber = t.Member.PhoneNumber,
                CapabilitiesRaw = (t.Capabilities ?? string.Empty) +
                    (string.IsNullOrEmpty(t.ProductsSupplied) ? "" : ", " + t.ProductsSupplied),
                BusinessDescription = t.ProductsSupplied,
                IndustryId = 0,
                IndustryName = "Trading & Supplies",
                BusinessGroupId = 0,
                BusinessGroupName = "Industrial Trading",
                SubGroupId = 0,
                SubGroupName = "Supplies & Distribution",
                CategoryId = 0,
                CategoryName = "General Trading",
                VerifiedMethod = t.Member.VerifiedMethod,
                MemberSinceUtc = t.Member.CreatedAtUtc,
                BusinessType = "Trader / Supplier",
                Location = t.ServiceCoverage
            });

        return bpQuery.Concat(cpQuery).Concat(tpQuery);
    }

    public async Task<BusinessDirectoryResponseDto> SearchBusinessesAsync(BusinessDirectoryFilterDto filter, int? currentMemberId = null, CancellationToken cancellationToken = default)
    {
        var query = BuildCombinedDirectoryQuery();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim();
            query = query.Where(b =>
                b.CompanyName.Contains(search) ||
                b.ContactPersonName.Contains(search) ||
                (b.BusinessDescription != null && b.BusinessDescription.Contains(search)) ||
                b.CapabilitiesRaw.Contains(search) ||
                (b.Location != null && b.Location.Contains(search)));
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
            query = query.Where(b => b.CapabilitiesRaw.Contains(cap));
        }

        if (!string.IsNullOrWhiteSpace(filter.BusinessType) &&
            !filter.BusinessType.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            var bType = filter.BusinessType.Trim();
            query = query.Where(b => b.BusinessType.Contains(bType));
        }

        if (!string.IsNullOrWhiteSpace(filter.Location))
        {
            var loc = filter.Location.Trim();
            query = query.Where(b => b.Location != null && b.Location.Contains(loc));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var page = filter.Page < 1 ? 1 : filter.Page;
        var pageSize = filter.PageSize < 1 ? 10 : (filter.PageSize > 50 ? 50 : filter.PageSize);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var rawItems = await query
            .OrderBy(b => b.CompanyName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var items = rawItems.Select(r => MapToDto(r)).ToList();

        if (currentMemberId.HasValue && items.Count > 0)
        {
            var currentId = currentMemberId.Value;
            var memberIds = items.Select(i => i.MemberId).Distinct().ToList();
            var connections = await _dbContext.MemberConnections
                .AsNoTracking()
                .Where(c => (c.RequesterMemberId == currentId && memberIds.Contains(c.RecipientMemberId)) ||
                            (c.RecipientMemberId == currentId && memberIds.Contains(c.RequesterMemberId)))
                .ToListAsync(cancellationToken);

            for (int i = 0; i < items.Count; i++)
            {
                var item = items[i];
                if (item.MemberId == currentId)
                {
                    items[i] = item with { ConnectionStatus = "Self" };
                    continue;
                }

                var conn = connections.FirstOrDefault(c =>
                    (c.RequesterMemberId == currentId && c.RecipientMemberId == item.MemberId) ||
                    (c.RecipientMemberId == currentId && c.RequesterMemberId == item.MemberId));

                if (conn != null)
                {
                    var status = conn.Status switch
                    {
                        Entities.ConnectionStatusEnum.Accepted => "Connected",
                        Entities.ConnectionStatusEnum.Pending when conn.RequesterMemberId == currentId => "PendingSent",
                        Entities.ConnectionStatusEnum.Pending when conn.RecipientMemberId == currentId => "PendingReceived",
                        _ => "Not Connected"
                    };
                    items[i] = item with { ConnectionStatus = status };
                }
            }
        }

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

    public async Task<BusinessDirectoryItemDto?> GetBusinessByMemberIdAsync(int memberId, int? currentMemberId = null, CancellationToken cancellationToken = default)
    {
        var raw = await BuildCombinedDirectoryQuery()
            .FirstOrDefaultAsync(b => b.MemberId == memberId, cancellationToken);

        if (raw == null)
        {
            return null;
        }

        var item = MapToDto(raw);
        if (currentMemberId.HasValue)
        {
            var currentId = currentMemberId.Value;
            if (item.MemberId == currentId)
            {
                item = item with { ConnectionStatus = "Self" };
            }
            else
            {
                var conn = await _dbContext.MemberConnections
                    .AsNoTracking()
                    .FirstOrDefaultAsync(c =>
                        (c.RequesterMemberId == currentId && c.RecipientMemberId == item.MemberId) ||
                        (c.RecipientMemberId == currentId && c.RequesterMemberId == item.MemberId),
                        cancellationToken);

                if (conn != null)
                {
                    var status = conn.Status switch
                    {
                        Entities.ConnectionStatusEnum.Accepted => "Connected",
                        Entities.ConnectionStatusEnum.Pending when conn.RequesterMemberId == currentId => "PendingSent",
                        Entities.ConnectionStatusEnum.Pending when conn.RecipientMemberId == currentId => "PendingReceived",
                        _ => "Not Connected"
                    };
                    item = item with { ConnectionStatus = status };
                }
            }
        }

        return item;
    }

    private static BusinessDirectoryItemDto MapToDto(DirectoryEntryInternal r)
    {
        var maskedEmail = MaskEmail(r.RawEmail);
        var maskedPhone = MaskPhoneNumber(r.CountryCode, r.RawPhoneNumber);
        var caps = (r.CapabilitiesRaw ?? string.Empty)
            .Split(new[] { ", ", "," }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Distinct()
            .ToList();

        return new BusinessDirectoryItemDto(
            MemberId: r.MemberId,
            CompanyName: r.CompanyName,
            ContactPersonName: r.ContactPersonName,
            Email: maskedEmail, // Privacy-preserved
            PhoneNumber: maskedPhone, // Privacy-preserved
            BusinessCapabilities: caps,
            BusinessDescription: r.BusinessDescription,
            IndustryId: r.IndustryId,
            IndustryName: r.IndustryName,
            BusinessGroupId: r.BusinessGroupId,
            BusinessGroupName: r.BusinessGroupName,
            SubGroupId: r.SubGroupId,
            SubGroupName: r.SubGroupName,
            CategoryId: r.CategoryId,
            CategoryName: r.CategoryName,
            VerifiedMethod: r.VerifiedMethod,
            MemberSinceUtc: r.MemberSinceUtc,
            BusinessType: r.BusinessType,
            Location: r.Location ?? "Gujarat, India",
            MaskedEmail: maskedEmail,
            MaskedPhoneNumber: maskedPhone,
            ConnectionStatus: "Not Connected"
        );
    }

    private static string MaskEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
        {
            return "••••••";
        }

        var parts = email.Split('@');
        var username = parts[0];
        var domain = parts[1];

        if (username.Length <= 2)
        {
            return $"{username[0]}*@{domain}";
        }

        return $"{username[0]}***{username[^1]}@{domain}";
    }

    private static string MaskPhoneNumber(string countryCode, string phoneNumber)
    {
        var raw = (phoneNumber ?? string.Empty).Trim();
        var prefix = (countryCode ?? "+91").Trim();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return "••••••••••";
        }

        if (raw.Length <= 4)
        {
            return $"{prefix} ******";
        }

        var last2 = raw[^2..];
        return $"{prefix} ******{last2}";
    }
}


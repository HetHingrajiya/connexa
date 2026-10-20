using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;

namespace Connexa.Api.Services.Connections;

public class ConnectionService : IConnectionService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ILogger<ConnectionService> _logger;

    public ConnectionService(ConnexaDbContext dbContext, ILogger<ConnectionService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<(bool Success, string Message, ConnectionDto? Connection)> SendRequestAsync(
        int requesterMemberId,
        CreateConnectionRequestDto dto,
        CancellationToken cancellationToken = default)
    {
        if (requesterMemberId == dto.RecipientMemberId)
        {
            return (false, "You cannot send a connection request to yourself.", null);
        }

        var recipient = await _dbContext.Members
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == dto.RecipientMemberId && m.IsActive, cancellationToken);

        if (recipient == null)
        {
            return (false, "Recipient member was not found or the account is inactive.", null);
        }

        var existing = await _dbContext.MemberConnections
            .FirstOrDefaultAsync(c =>
                (c.RequesterMemberId == requesterMemberId && c.RecipientMemberId == dto.RecipientMemberId) ||
                (c.RequesterMemberId == dto.RecipientMemberId && c.RecipientMemberId == requesterMemberId),
                cancellationToken);

        if (existing != null)
        {
            if (existing.Status == ConnectionStatusEnum.Accepted)
            {
                return (false, "You are already connected with this member.", null);
            }

            if (existing.Status == ConnectionStatusEnum.Pending)
            {
                if (existing.RequesterMemberId == requesterMemberId)
                {
                    return (false, "A connection request is already pending for this member.", null);
                }
                else
                {
                    return (false, "This member has already sent you a connection request. Please check your received requests.", null);
                }
            }

            // If existing was Cancelled or Rejected, reuse and reactivate
            existing.RequesterMemberId = requesterMemberId;
            existing.RecipientMemberId = dto.RecipientMemberId;
            existing.Status = ConnectionStatusEnum.Pending;
            existing.Note = dto.Note?.Trim();
            existing.CreatedAtUtc = DateTime.UtcNow;
            existing.RespondedAtUtc = null;
            existing.UpdatedAtUtc = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync(cancellationToken);
            _logger.LogInformation("[Connections] Connection request #{Id} reactivated from Member {Req} to Member {Rec}.",
                existing.Id, requesterMemberId, dto.RecipientMemberId);

            return (true, "Connection request sent successfully.", MapToConnectionDto(existing));
        }

        var newConnection = new MemberConnection
        {
            RequesterMemberId = requesterMemberId,
            RecipientMemberId = dto.RecipientMemberId,
            Status = ConnectionStatusEnum.Pending,
            Note = dto.Note?.Trim(),
            CreatedAtUtc = DateTime.UtcNow
        };

        _dbContext.MemberConnections.Add(newConnection);
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Connections] New connection request #{Id} created from Member {Req} to Member {Rec}.",
            newConnection.Id, requesterMemberId, dto.RecipientMemberId);

        return (true, "Connection request sent successfully.", MapToConnectionDto(newConnection));
    }

    public async Task<PaginatedConnectionsDto<ConnectionRequestItemDto>> GetReceivedRequestsAsync(
        int currentMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = _dbContext.MemberConnections
            .AsNoTracking()
            .Where(c => c.RecipientMemberId == currentMemberId && c.Status == ConnectionStatusEnum.Pending);

        var totalCount = await query.CountAsync(cancellationToken);
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var rawList = await query
            .OrderByDescending(c => c.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(b => b!.Industry)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.ServiceEngineerProfile)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.EmployeeProfile)
            .ToListAsync(cancellationToken);

        var items = rawList.Select(c =>
        {
            var other = c.RequesterMember;
            var (companyName, businessType, industryId, industryName, location) = ResolveMemberDetails(other);

            return new ConnectionRequestItemDto(
                Id: c.Id,
                MemberId: other.Id,
                FullName: other.FullName,
                CompanyName: companyName,
                BusinessType: businessType,
                IndustryId: industryId,
                IndustryName: industryName,
                Location: location,
                Note: c.Note,
                CreatedAtUtc: c.CreatedAtUtc,
                Status: "Pending",
                Direction: "Received"
            );
        }).ToList();

        return new PaginatedConnectionsDto<ConnectionRequestItemDto>(
            Items: items,
            TotalCount: totalCount,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );
    }

    public async Task<PaginatedConnectionsDto<ConnectionRequestItemDto>> GetSentRequestsAsync(
        int currentMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = _dbContext.MemberConnections
            .AsNoTracking()
            .Where(c => c.RequesterMemberId == currentMemberId && c.Status == ConnectionStatusEnum.Pending);

        var totalCount = await query.CountAsync(cancellationToken);
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var rawList = await query
            .OrderByDescending(c => c.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(b => b!.Industry)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.ServiceEngineerProfile)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.EmployeeProfile)
            .ToListAsync(cancellationToken);

        var items = rawList.Select(c =>
        {
            var other = c.RecipientMember;
            var (companyName, businessType, industryId, industryName, location) = ResolveMemberDetails(other);

            return new ConnectionRequestItemDto(
                Id: c.Id,
                MemberId: other.Id,
                FullName: other.FullName,
                CompanyName: companyName,
                BusinessType: businessType,
                IndustryId: industryId,
                IndustryName: industryName,
                Location: location,
                Note: c.Note,
                CreatedAtUtc: c.CreatedAtUtc,
                Status: "Pending",
                Direction: "Sent"
            );
        }).ToList();

        return new PaginatedConnectionsDto<ConnectionRequestItemDto>(
            Items: items,
            TotalCount: totalCount,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );
    }

    public async Task<(bool Success, string Message, ConnectionDto? Connection)> AcceptRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default)
    {
        var conn = await _dbContext.MemberConnections
            .FirstOrDefaultAsync(c => c.Id == requestId, cancellationToken);

        if (conn == null)
        {
            return (false, "Connection request not found.", null);
        }

        if (conn.RecipientMemberId != currentMemberId)
        {
            return (false, "You are not authorized to accept this connection request.", null);
        }

        if (conn.Status != ConnectionStatusEnum.Pending)
        {
            return (false, $"Connection request cannot be accepted because its status is '{conn.Status}'.", null);
        }

        conn.Status = ConnectionStatusEnum.Accepted;
        conn.RespondedAtUtc = DateTime.UtcNow;
        conn.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("[Connections] Connection request #{Id} accepted by Member {MemberId}.", requestId, currentMemberId);

        return (true, "Connection request accepted successfully.", MapToConnectionDto(conn));
    }

    public async Task<(bool Success, string Message, ConnectionDto? Connection)> RejectRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default)
    {
        var conn = await _dbContext.MemberConnections
            .FirstOrDefaultAsync(c => c.Id == requestId, cancellationToken);

        if (conn == null)
        {
            return (false, "Connection request not found.", null);
        }

        if (conn.RecipientMemberId != currentMemberId)
        {
            return (false, "You are not authorized to reject this connection request.", null);
        }

        if (conn.Status != ConnectionStatusEnum.Pending)
        {
            return (false, $"Connection request cannot be rejected because its status is '{conn.Status}'.", null);
        }

        conn.Status = ConnectionStatusEnum.Rejected;
        conn.RespondedAtUtc = DateTime.UtcNow;
        conn.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("[Connections] Connection request #{Id} rejected by Member {MemberId}.", requestId, currentMemberId);

        return (true, "Connection request rejected.", MapToConnectionDto(conn));
    }

    public async Task<(bool Success, string Message, ConnectionDto? Connection)> CancelRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default)
    {
        var conn = await _dbContext.MemberConnections
            .FirstOrDefaultAsync(c => c.Id == requestId, cancellationToken);

        if (conn == null)
        {
            return (false, "Connection request not found.", null);
        }

        if (conn.RequesterMemberId != currentMemberId)
        {
            return (false, "You are not authorized to cancel this connection request.", null);
        }

        if (conn.Status != ConnectionStatusEnum.Pending)
        {
            return (false, $"Connection request cannot be cancelled because its status is '{conn.Status}'.", null);
        }

        conn.Status = ConnectionStatusEnum.Cancelled;
        conn.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("[Connections] Connection request #{Id} cancelled by Member {MemberId}.", requestId, currentMemberId);

        return (true, "Connection request cancelled successfully.", MapToConnectionDto(conn));
    }

    public async Task<PaginatedConnectionsDto<ConnectedMemberItemDto>> GetMyConnectionsAsync(
        int currentMemberId,
        string? search = null,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = _dbContext.MemberConnections
            .AsNoTracking()
            .Where(c => c.Status == ConnectionStatusEnum.Accepted &&
                        (c.RequesterMemberId == currentMemberId || c.RecipientMemberId == currentMemberId));

        var totalCount = await query.CountAsync(cancellationToken);

        var rawList = await query
            .OrderByDescending(c => c.RespondedAtUtc ?? c.CreatedAtUtc)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(b => b!.Industry)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.ServiceEngineerProfile)
            .Include(c => c.RequesterMember)
                .ThenInclude(m => m.EmployeeProfile)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(b => b!.Industry)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.ServiceEngineerProfile)
            .Include(c => c.RecipientMember)
                .ThenInclude(m => m.EmployeeProfile)
            .ToListAsync(cancellationToken);

        var mapped = rawList.Select(c =>
        {
            var other = c.RequesterMemberId == currentMemberId ? c.RecipientMember : c.RequesterMember;
            var (companyName, businessType, industryId, industryName, location) = ResolveMemberDetails(other);

            return new ConnectedMemberItemDto(
                ConnectionId: c.Id,
                MemberId: other.Id,
                FullName: other.FullName,
                CompanyName: companyName,
                BusinessType: businessType,
                IndustryId: industryId,
                IndustryName: industryName,
                Location: location,
                ConnectedSinceUtc: c.RespondedAtUtc ?? c.CreatedAtUtc,
                MaskedEmail: MaskEmail(other.Email),
                MaskedPhoneNumber: MaskPhoneNumber(other.CountryCode, other.PhoneNumber),
                ConnectionStatus: "Connected"
            );
        });

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            mapped = mapped.Where(m =>
                m.FullName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                m.CompanyName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                m.IndustryName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                m.Location.Contains(term, StringComparison.OrdinalIgnoreCase));
        }

        var allFiltered = mapped.ToList();
        var finalTotal = allFiltered.Count;
        var totalPages = (int)Math.Ceiling(finalTotal / (double)pageSize);

        var items = allFiltered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new PaginatedConnectionsDto<ConnectedMemberItemDto>(
            Items: items,
            TotalCount: finalTotal,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );
    }

    public async Task<(bool Success, string Message)> RemoveConnectionAsync(
        int currentMemberId,
        int targetMemberId,
        CancellationToken cancellationToken = default)
    {
        var conn = await _dbContext.MemberConnections
            .FirstOrDefaultAsync(c =>
                c.Status == ConnectionStatusEnum.Accepted &&
                ((c.RequesterMemberId == currentMemberId && c.RecipientMemberId == targetMemberId) ||
                 (c.RecipientMemberId == currentMemberId && c.RequesterMemberId == targetMemberId)),
                cancellationToken);

        if (conn == null)
        {
            return (false, "Active accepted connection not found with this member.");
        }

        _dbContext.MemberConnections.Remove(conn);
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Connections] Connection #{Id} removed between Member {M1} and Member {M2}.",
            conn.Id, currentMemberId, targetMemberId);

        return (true, "Connection removed successfully.");
    }

    public async Task<ConnectionsSummaryDto> GetSummaryAsync(
        int currentMemberId,
        CancellationToken cancellationToken = default)
    {
        var totalConnected = await _dbContext.MemberConnections
            .AsNoTracking()
            .CountAsync(c => c.Status == ConnectionStatusEnum.Accepted &&
                (c.RequesterMemberId == currentMemberId || c.RecipientMemberId == currentMemberId), cancellationToken);

        var receivedPending = await _dbContext.MemberConnections
            .AsNoTracking()
            .CountAsync(c => c.RecipientMemberId == currentMemberId && c.Status == ConnectionStatusEnum.Pending, cancellationToken);

        var sentPending = await _dbContext.MemberConnections
            .AsNoTracking()
            .CountAsync(c => c.RequesterMemberId == currentMemberId && c.Status == ConnectionStatusEnum.Pending, cancellationToken);

        return new ConnectionsSummaryDto(
            TotalConnected: totalConnected,
            ReceivedPendingCount: receivedPending,
            SentPendingCount: sentPending
        );
    }

    private static (string CompanyName, string BusinessType, int IndustryId, string IndustryName, string Location) ResolveMemberDetails(Member m)
    {
        if (m.BusinessProfile != null)
        {
            return (
                CompanyName: m.BusinessProfile.CompanyName,
                BusinessType: "Manufacturer / Company",
                IndustryId: m.BusinessProfile.IndustryId,
                IndustryName: m.BusinessProfile.Industry?.Name ?? "General",
                Location: "Gujarat, India"
            );
        }

        if (m.ContractorProfile != null)
        {
            return (
                CompanyName: m.ContractorProfile.WorkName,
                BusinessType: "Contractor / Job Worker",
                IndustryId: m.ContractorProfile.IndustryId,
                IndustryName: m.ContractorProfile.Industry?.Name ?? "General",
                Location: string.IsNullOrWhiteSpace(m.ContractorProfile.WorkCoverage) ? "Gujarat, India" : m.ContractorProfile.WorkCoverage
            );
        }

        if (m.TraderProfile != null)
        {
            return (
                CompanyName: string.IsNullOrWhiteSpace(m.TraderProfile.TradingName) ? m.FullName : m.TraderProfile.TradingName,
                BusinessType: "Trader / Supplier",
                IndustryId: 0,
                IndustryName: "Trading & Supplies",
                Location: string.IsNullOrWhiteSpace(m.TraderProfile.ServiceCoverage) ? "Gujarat, India" : m.TraderProfile.ServiceCoverage
            );
        }

        if (m.ServiceEngineerProfile != null)
        {
            return (
                CompanyName: string.IsNullOrWhiteSpace(m.ServiceEngineerProfile.Specialization) ? m.FullName : $"{m.FullName} ({m.ServiceEngineerProfile.Specialization})",
                BusinessType: "Service Engineer",
                IndustryId: 0,
                IndustryName: "Technical Services",
                Location: string.IsNullOrWhiteSpace(m.ServiceEngineerProfile.ServiceCoverage) ? "Gujarat, India" : m.ServiceEngineerProfile.ServiceCoverage
            );
        }

        if (m.EmployeeProfile != null)
        {
            return (
                CompanyName: string.IsNullOrWhiteSpace(m.EmployeeProfile.JobTitle) ? m.FullName : $"{m.FullName} - {m.EmployeeProfile.JobTitle}",
                BusinessType: "Employee / Job Seeker",
                IndustryId: 0,
                IndustryName: "Professional",
                Location: "Gujarat, India"
            );
        }

        return (
            CompanyName: m.FullName,
            BusinessType: "Member",
            IndustryId: 0,
            IndustryName: "General",
            Location: "Gujarat, India"
        );
    }

    private static ConnectionDto MapToConnectionDto(MemberConnection c) => new(
        Id: c.Id,
        RequesterMemberId: c.RequesterMemberId,
        RecipientMemberId: c.RecipientMemberId,
        Status: c.Status.ToString(),
        Note: c.Note,
        CreatedAtUtc: c.CreatedAtUtc,
        RespondedAtUtc: c.RespondedAtUtc,
        UpdatedAtUtc: c.UpdatedAtUtc
    );

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

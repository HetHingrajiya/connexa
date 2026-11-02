using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Services.ServicesMarketplace;

public class BusinessServiceService : IBusinessServiceService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly ILogger<BusinessServiceService> _logger;

    private static readonly string[] StandardCategories = new[]
    {
        "CNC Machining",
        "Industrial Maintenance",
        "Machine Repair",
        "Fabrication",
        "Industrial Design",
        "Installation",
        "Consultancy",
        "Automation Services",
        "Electrical Services",
        "Technical Support"
    };

    public BusinessServiceService(
        ConnexaDbContext db,
        INotificationService notificationService,
        ILogger<BusinessServiceService> logger)
    {
        _db = db;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> CreateServiceAsync(int memberId, CreateServiceDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            return (false, null, "Service title is required.");
        if (string.IsNullOrWhiteSpace(dto.Description))
            return (false, null, "Service description is required.");
        if (string.IsNullOrWhiteSpace(dto.ServiceCategory))
            return (false, null, "Service category is required.");

        var member = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == memberId);

        if (member == null)
            return (false, null, "Member profile not found.");

        var service = new BusinessService
        {
            MemberId = memberId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            ServiceCategory = dto.ServiceCategory.Trim(),
            IndustryId = dto.IndustryId,
            BusinessGroupId = dto.BusinessGroupId,
            SubGroupId = dto.SubGroupId,
            CategoryId = dto.CategoryId,
            ServiceType = string.IsNullOrWhiteSpace(dto.ServiceType) ? "On-Site" : dto.ServiceType.Trim(),
            PricingModel = string.IsNullOrWhiteSpace(dto.PricingModel) ? "Quote-Based" : dto.PricingModel.Trim(),
            StartingPrice = dto.StartingPrice,
            PriceUnit = dto.PriceUnit?.Trim(),
            TurnaroundTime = dto.TurnaroundTime?.Trim(),
            CoverageArea = dto.CoverageArea?.Trim(),
            Location = !string.IsNullOrWhiteSpace(dto.Location) 
                ? dto.Location.Trim() 
                : (!string.IsNullOrWhiteSpace(member.BusinessProfile?.City) ? $"{member.BusinessProfile.City}, {member.BusinessProfile.State}" : member.PhoneNumber),
            TagsJson = dto.TagsJson,
            ImagesJson = dto.ImagesJson,
            Certifications = dto.Certifications?.Trim(),
            YearsOfExperience = dto.YearsOfExperience,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.BusinessServices.Add(service);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Member {MemberId} created business service {ServiceId} ({Title})", memberId, service.Id, service.Title);

        return await GetServiceByIdAsync(service.Id, memberId);
    }

    public async Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> UpdateServiceAsync(int memberId, int serviceId, UpdateServiceDto dto)
    {
        var service = await _db.BusinessServices.FirstOrDefaultAsync(s => s.Id == serviceId);
        if (service == null)
            return (false, null, "Service not found.");

        if (service.MemberId != memberId)
            return (false, null, "You are not authorized to update this service.");

        if (string.IsNullOrWhiteSpace(dto.Title))
            return (false, null, "Service title cannot be empty.");
        if (string.IsNullOrWhiteSpace(dto.Description))
            return (false, null, "Service description cannot be empty.");
        if (string.IsNullOrWhiteSpace(dto.ServiceCategory))
            return (false, null, "Service category cannot be empty.");

        service.Title = dto.Title.Trim();
        service.Description = dto.Description.Trim();
        service.ServiceCategory = dto.ServiceCategory.Trim();
        service.IndustryId = dto.IndustryId;
        service.BusinessGroupId = dto.BusinessGroupId;
        service.SubGroupId = dto.SubGroupId;
        service.CategoryId = dto.CategoryId;
        service.ServiceType = string.IsNullOrWhiteSpace(dto.ServiceType) ? service.ServiceType : dto.ServiceType.Trim();
        service.PricingModel = string.IsNullOrWhiteSpace(dto.PricingModel) ? service.PricingModel : dto.PricingModel.Trim();
        service.StartingPrice = dto.StartingPrice;
        service.PriceUnit = dto.PriceUnit?.Trim();
        service.TurnaroundTime = dto.TurnaroundTime?.Trim();
        service.CoverageArea = dto.CoverageArea?.Trim();
        service.Location = dto.Location?.Trim();
        service.TagsJson = dto.TagsJson;
        service.ImagesJson = dto.ImagesJson;
        service.Certifications = dto.Certifications?.Trim();
        service.YearsOfExperience = dto.YearsOfExperience;
        if (dto.IsActive.HasValue)
            service.IsActive = dto.IsActive.Value;
        service.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return await GetServiceByIdAsync(service.Id, memberId);
    }

    public async Task<(bool Success, string? ErrorMessage)> DeleteServiceAsync(int memberId, int serviceId)
    {
        var service = await _db.BusinessServices
            .Include(s => s.Inquiries)
            .FirstOrDefaultAsync(s => s.Id == serviceId);

        if (service == null)
            return (false, "Service not found.");

        if (service.MemberId != memberId)
            return (false, "You are not authorized to delete this service.");

        // If there are inquiries, soft-deactivate to maintain audit history
        if (service.Inquiries.Any())
        {
            service.IsActive = false;
            service.UpdatedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return (true, null);
        }

        _db.BusinessServices.Remove(service);
        await _db.SaveChangesAsync();
        return (true, null);
    }

    public async Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> GetServiceByIdAsync(int serviceId, int? viewerMemberId = null)
    {
        var service = await _db.BusinessServices
            .Include(s => s.Member).ThenInclude(m => m.BusinessProfile)
            .Include(s => s.Industry)
            .Include(s => s.Inquiries)
            .FirstOrDefaultAsync(s => s.Id == serviceId);

        if (service == null)
            return (false, null, "Service not found.");

        // Increment view count if viewer is not the service owner
        if (viewerMemberId.HasValue && viewerMemberId.Value != service.MemberId)
        {
            service.ViewCount++;
            await _db.SaveChangesAsync();
        }

        var detail = new ServiceDetailDto(
            Id: service.Id,
            MemberId: service.MemberId,
            ProviderName: service.Member.FullName,
            ProviderCompanyName: service.Member.BusinessProfile?.CompanyName,
            ProviderEmail: service.Member.Email,
            ProviderPhone: service.Member.PhoneNumber,
            ProviderCity: service.Member.BusinessProfile?.City,
            ProviderState: service.Member.BusinessProfile?.State,
            Title: service.Title,
            Description: service.Description,
            ServiceCategory: service.ServiceCategory,
            IndustryId: service.IndustryId,
            IndustryName: service.Industry?.Name,
            BusinessGroupId: service.BusinessGroupId,
            SubGroupId: service.SubGroupId,
            CategoryId: service.CategoryId,
            ServiceType: service.ServiceType,
            PricingModel: service.PricingModel,
            StartingPrice: service.StartingPrice,
            PriceUnit: service.PriceUnit,
            TurnaroundTime: service.TurnaroundTime,
            CoverageArea: service.CoverageArea,
            Location: service.Location,
            TagsJson: service.TagsJson,
            ImagesJson: service.ImagesJson,
            Certifications: service.Certifications,
            YearsOfExperience: service.YearsOfExperience,
            IsActive: service.IsActive,
            ViewCount: service.ViewCount,
            CreatedAtUtc: service.CreatedAtUtc,
            UpdatedAtUtc: service.UpdatedAtUtc,
            InquiryCount: service.Inquiries.Count,
            IsOwner: viewerMemberId.HasValue && viewerMemberId.Value == service.MemberId
        );

        return (true, detail, null);
    }

    public async Task<(List<ServiceSummaryDto> Services, int TotalCount, int TotalPages)> SearchServicesAsync(ServiceSearchQueryDto query)
    {
        var q = _db.BusinessServices
            .AsNoTracking()
            .Include(s => s.Member).ThenInclude(m => m.BusinessProfile)
            .Include(s => s.Industry)
            .Where(s => s.IsActive);

        if (!string.IsNullOrWhiteSpace(query.Query))
        {
            var term = query.Query.Trim().ToLower();
            q = q.Where(s => s.Title.ToLower().Contains(term) ||
                             s.Description.ToLower().Contains(term) ||
                             (s.TagsJson != null && s.TagsJson.ToLower().Contains(term)) ||
                             s.ServiceCategory.ToLower().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(query.Category) && query.Category != "All")
        {
            var cat = query.Category.Trim().ToLower();
            q = q.Where(s => s.ServiceCategory.ToLower() == cat);
        }

        if (query.IndustryId.HasValue && query.IndustryId.Value > 0)
        {
            q = q.Where(s => s.IndustryId == query.IndustryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Location))
        {
            var loc = query.Location.Trim().ToLower();
            q = q.Where(s => (s.Location != null && s.Location.ToLower().Contains(loc)) ||
                             (s.CoverageArea != null && s.CoverageArea.ToLower().Contains(loc)));
        }

        if (!string.IsNullOrWhiteSpace(query.ServiceType) && query.ServiceType != "All")
        {
            var st = query.ServiceType.Trim().ToLower();
            q = q.Where(s => s.ServiceType.ToLower() == st);
        }

        var totalCount = await q.CountAsync();
        var pageSize = Math.Clamp(query.PageSize, 1, 100);
        var page = Math.Max(1, query.Page);
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var items = await q
            .OrderByDescending(s => s.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new ServiceSummaryDto(
                s.Id,
                s.MemberId,
                s.Member.FullName,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.CompanyName : null,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.City : null,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.State : null,
                s.Title,
                s.Description,
                s.ServiceCategory,
                s.IndustryId,
                s.Industry != null ? s.Industry.Name : null,
                s.ServiceType,
                s.PricingModel,
                s.StartingPrice,
                s.PriceUnit,
                s.TurnaroundTime,
                s.CoverageArea,
                s.Location,
                s.ImagesJson,
                s.IsActive,
                s.ViewCount,
                s.CreatedAtUtc
            ))
            .ToListAsync();

        return (items, totalCount, totalPages);
    }

    public async Task<List<ServiceSummaryDto>> GetMyServicesAsync(int memberId)
    {
        return await _db.BusinessServices
            .AsNoTracking()
            .Include(s => s.Member).ThenInclude(m => m.BusinessProfile)
            .Include(s => s.Industry)
            .Where(s => s.MemberId == memberId)
            .OrderByDescending(s => s.CreatedAtUtc)
            .Select(s => new ServiceSummaryDto(
                s.Id,
                s.MemberId,
                s.Member.FullName,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.CompanyName : null,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.City : null,
                s.Member.BusinessProfile != null ? s.Member.BusinessProfile.State : null,
                s.Title,
                s.Description,
                s.ServiceCategory,
                s.IndustryId,
                s.Industry != null ? s.Industry.Name : null,
                s.ServiceType,
                s.PricingModel,
                s.StartingPrice,
                s.PriceUnit,
                s.TurnaroundTime,
                s.CoverageArea,
                s.Location,
                s.ImagesJson,
                s.IsActive,
                s.ViewCount,
                s.CreatedAtUtc
            ))
            .ToListAsync();
    }

    public async Task<List<string>> GetPopularCategoriesAsync()
    {
        var dbCategories = await _db.BusinessServices
            .AsNoTracking()
            .Where(s => s.IsActive)
            .Select(s => s.ServiceCategory)
            .Distinct()
            .ToListAsync();

        var set = new HashSet<string>(StandardCategories, StringComparer.OrdinalIgnoreCase);
        foreach (var cat in dbCategories)
        {
            if (!string.IsNullOrWhiteSpace(cat))
                set.Add(cat.Trim());
        }

        return set.OrderBy(c => c).ToList();
    }

    public async Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> CreateInquiryAsync(int senderMemberId, CreateServiceInquiryDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Subject))
            return (false, null, "Inquiry subject is required.");
        if (string.IsNullOrWhiteSpace(dto.RequirementDescription))
            return (false, null, "Requirement description is required.");

        var service = await _db.BusinessServices
            .Include(s => s.Member).ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(s => s.Id == dto.ServiceId);

        if (service == null)
            return (false, null, "The specified service was not found.");

        if (!service.IsActive)
            return (false, null, "This service is currently inactive and cannot receive inquiries.");

        if (service.MemberId == senderMemberId)
            return (false, null, "You cannot send an inquiry for your own service.");

        var sender = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == senderMemberId);

        if (sender == null)
            return (false, null, "Sender identity not found.");

        var inquiryNumber = $"SINQ-{DateTime.UtcNow:yyyyMMdd}-{Random.Shared.Next(1000, 9999)}";

        var inquiry = new ServiceInquiry
        {
            InquiryNumber = inquiryNumber,
            ServiceId = service.Id,
            SenderMemberId = senderMemberId,
            RecipientMemberId = service.MemberId,
            Subject = dto.Subject.Trim(),
            RequirementDescription = dto.RequirementDescription.Trim(),
            ScopeOfWork = dto.ScopeOfWork?.Trim(),
            Location = dto.Location?.Trim(),
            PreferredStartDate = dto.PreferredStartDate,
            EstimatedBudget = dto.EstimatedBudget,
            Urgency = string.IsNullOrWhiteSpace(dto.Urgency) ? "Normal" : dto.Urgency.Trim(),
            Status = ServiceInquiryStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow
        };

        inquiry.StatusHistory.Add(new ServiceInquiryStatusHistory
        {
            PreviousStatus = null,
            NewStatus = ServiceInquiryStatus.Pending,
            ChangedByMemberId = senderMemberId,
            Remarks = "Inquiry submitted by client",
            ChangedAtUtc = DateTime.UtcNow
        });

        _db.ServiceInquiries.Add(inquiry);
        await _db.SaveChangesAsync();

        // Send Notification to Provider
        try
        {
            var senderOrgName = !string.IsNullOrWhiteSpace(sender.BusinessProfile?.CompanyName)
                ? sender.BusinessProfile.CompanyName
                : sender.FullName;

            await _notificationService.CreateNotificationAsync(
                recipientMemberId: service.MemberId,
                actorMemberId: senderMemberId,
                eventType: NotificationEventType.ServiceInquiryReceived,
                title: $"New Service Inquiry #{inquiry.InquiryNumber}",
                message: $"{senderOrgName} requested an inquiry for '{service.Title}': {inquiry.Subject}",
                referenceType: "service_inquiry",
                referenceId: inquiry.Id
            );
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send notification for service inquiry {InquiryId}", inquiry.Id);
        }

        return await GetInquiryByIdAsync(senderMemberId, inquiry.Id);
    }

    public async Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> RespondInquiryAsync(int providerMemberId, int inquiryId, RespondServiceInquiryDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.ResponseMessage))
            return (false, null, "Response message cannot be empty.");

        var inquiry = await _db.ServiceInquiries
            .Include(i => i.Service)
            .Include(i => i.SenderMember)
            .Include(i => i.RecipientMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.StatusHistory)
            .FirstOrDefaultAsync(i => i.Id == inquiryId);

        if (inquiry == null)
            return (false, null, "Service inquiry not found.");

        if (inquiry.RecipientMemberId != providerMemberId)
            return (false, null, "You are not authorized to respond to this inquiry.");

        var prevStatus = inquiry.Status;
        var newStatus = dto.AcceptInquiry ? ServiceInquiryStatus.Responded : ServiceInquiryStatus.Declined;

        inquiry.ResponseMessage = dto.ResponseMessage.Trim();
        inquiry.RespondedAtUtc = DateTime.UtcNow;
        inquiry.Status = newStatus;
        inquiry.UpdatedAtUtc = DateTime.UtcNow;

        inquiry.StatusHistory.Add(new ServiceInquiryStatusHistory
        {
            PreviousStatus = prevStatus,
            NewStatus = newStatus,
            ChangedByMemberId = providerMemberId,
            Remarks = dto.ResponseMessage.Trim(),
            ChangedAtUtc = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();

        // Notify client
        try
        {
            var providerName = !string.IsNullOrWhiteSpace(inquiry.RecipientMember.BusinessProfile?.CompanyName)
                ? inquiry.RecipientMember.BusinessProfile.CompanyName
                : inquiry.RecipientMember.FullName;

            await _notificationService.CreateNotificationAsync(
                recipientMemberId: inquiry.SenderMemberId,
                actorMemberId: providerMemberId,
                eventType: NotificationEventType.ServiceInquiryResponded,
                title: $"Response on Inquiry #{inquiry.InquiryNumber}",
                message: $"{providerName} responded to your inquiry for '{inquiry.Service.Title}'.",
                referenceType: "service_inquiry",
                referenceId: inquiry.Id
            );
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send response notification for inquiry {InquiryId}", inquiry.Id);
        }

        return await GetInquiryByIdAsync(providerMemberId, inquiry.Id);
    }

    public async Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> UpdateInquiryStatusAsync(int memberId, int inquiryId, UpdateServiceInquiryStatusDto dto)
    {
        var inquiry = await _db.ServiceInquiries
            .Include(i => i.Service)
            .Include(i => i.SenderMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.RecipientMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.StatusHistory)
            .FirstOrDefaultAsync(i => i.Id == inquiryId);

        if (inquiry == null)
            return (false, null, "Service inquiry not found.");

        if (inquiry.SenderMemberId != memberId && inquiry.RecipientMemberId != memberId)
            return (false, null, "You are not a participant in this service inquiry.");

        var prevStatus = inquiry.Status;
        inquiry.Status = dto.Status;
        inquiry.UpdatedAtUtc = DateTime.UtcNow;

        inquiry.StatusHistory.Add(new ServiceInquiryStatusHistory
        {
            PreviousStatus = prevStatus,
            NewStatus = dto.Status,
            ChangedByMemberId = memberId,
            Remarks = dto.Remarks?.Trim(),
            ChangedAtUtc = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();

        // Notify the other party
        try
        {
            var otherMemberId = (memberId == inquiry.SenderMemberId) ? inquiry.RecipientMemberId : inquiry.SenderMemberId;
            var changerName = (memberId == inquiry.SenderMemberId)
                ? inquiry.SenderMember.FullName
                : inquiry.RecipientMember.FullName;

            await _notificationService.CreateNotificationAsync(
                recipientMemberId: otherMemberId,
                actorMemberId: memberId,
                eventType: NotificationEventType.ServiceInquiryStatusChanged,
                title: $"Inquiry #{inquiry.InquiryNumber} Status Updated",
                message: $"{changerName} updated inquiry status to '{dto.Status}'.",
                referenceType: "service_inquiry",
                referenceId: inquiry.Id
            );
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send status update notification for inquiry {InquiryId}", inquiry.Id);
        }

        return await GetInquiryByIdAsync(memberId, inquiry.Id);
    }

    public async Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> GetInquiryByIdAsync(int memberId, int inquiryId)
    {
        var inquiry = await _db.ServiceInquiries
            .AsNoTracking()
            .Include(i => i.Service)
            .Include(i => i.SenderMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.RecipientMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.StatusHistory).ThenInclude(h => h.ChangedByMember)
            .FirstOrDefaultAsync(i => i.Id == inquiryId);

        if (inquiry == null)
            return (false, null, "Service inquiry not found.");

        if (inquiry.SenderMemberId != memberId && inquiry.RecipientMemberId != memberId)
            return (false, null, "You are not authorized to view this inquiry.");

        var dto = new ServiceInquiryDetailDto(
            Id: inquiry.Id,
            InquiryNumber: inquiry.InquiryNumber,
            ServiceId: inquiry.ServiceId,
            ServiceTitle: inquiry.Service.Title,
            ServiceCategory: inquiry.Service.ServiceCategory,
            SenderMemberId: inquiry.SenderMemberId,
            SenderName: inquiry.SenderMember.FullName,
            SenderCompanyName: inquiry.SenderMember.BusinessProfile?.CompanyName,
            SenderEmail: inquiry.SenderMember.Email,
            SenderPhone: inquiry.SenderMember.PhoneNumber,
            RecipientMemberId: inquiry.RecipientMemberId,
            RecipientName: inquiry.RecipientMember.FullName,
            RecipientCompanyName: inquiry.RecipientMember.BusinessProfile?.CompanyName,
            Subject: inquiry.Subject,
            RequirementDescription: inquiry.RequirementDescription,
            ScopeOfWork: inquiry.ScopeOfWork,
            Location: inquiry.Location,
            PreferredStartDate: inquiry.PreferredStartDate,
            EstimatedBudget: inquiry.EstimatedBudget,
            Urgency: inquiry.Urgency,
            Status: inquiry.Status,
            StatusName: inquiry.Status.ToString(),
            ResponseMessage: inquiry.ResponseMessage,
            RespondedAtUtc: inquiry.RespondedAtUtc,
            CreatedAtUtc: inquiry.CreatedAtUtc,
            StatusHistory: inquiry.StatusHistory
                .OrderBy(h => h.ChangedAtUtc)
                .Select(h => new ServiceInquiryStatusHistoryDto(
                    h.Id,
                    h.PreviousStatus,
                    h.NewStatus,
                    h.NewStatus.ToString(),
                    h.ChangedByMemberId,
                    h.ChangedByMember != null ? h.ChangedByMember.FullName : "System",
                    h.ChangedAtUtc,
                    h.Remarks
                ))
                .ToList()
        );

        return (true, dto, null);
    }

    public async Task<List<ServiceInquiryDetailDto>> GetMySentInquiriesAsync(int memberId)
    {
        return await _db.ServiceInquiries
            .AsNoTracking()
            .Include(i => i.Service)
            .Include(i => i.SenderMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.RecipientMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.StatusHistory).ThenInclude(h => h.ChangedByMember)
            .Where(i => i.SenderMemberId == memberId)
            .OrderByDescending(i => i.CreatedAtUtc)
            .Select(i => new ServiceInquiryDetailDto(
                i.Id,
                i.InquiryNumber,
                i.ServiceId,
                i.Service.Title,
                i.Service.ServiceCategory,
                i.SenderMemberId,
                i.SenderMember.FullName,
                i.SenderMember.BusinessProfile != null ? i.SenderMember.BusinessProfile.CompanyName : null,
                i.SenderMember.Email,
                i.SenderMember.PhoneNumber,
                i.RecipientMemberId,
                i.RecipientMember.FullName,
                i.RecipientMember.BusinessProfile != null ? i.RecipientMember.BusinessProfile.CompanyName : null,
                i.Subject,
                i.RequirementDescription,
                i.ScopeOfWork,
                i.Location,
                i.PreferredStartDate,
                i.EstimatedBudget,
                i.Urgency,
                i.Status,
                i.Status.ToString(),
                i.ResponseMessage,
                i.RespondedAtUtc,
                i.CreatedAtUtc,
                i.StatusHistory
                    .OrderBy(h => h.ChangedAtUtc)
                    .Select(h => new ServiceInquiryStatusHistoryDto(
                        h.Id,
                        h.PreviousStatus,
                        h.NewStatus,
                        h.NewStatus.ToString(),
                        h.ChangedByMemberId,
                        h.ChangedByMember.FullName,
                        h.ChangedAtUtc,
                        h.Remarks
                    ))
                    .ToList()
            ))
            .ToListAsync();
    }

    public async Task<List<ServiceInquiryDetailDto>> GetMyReceivedInquiriesAsync(int memberId)
    {
        return await _db.ServiceInquiries
            .AsNoTracking()
            .Include(i => i.Service)
            .Include(i => i.SenderMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.RecipientMember).ThenInclude(m => m.BusinessProfile)
            .Include(i => i.StatusHistory).ThenInclude(h => h.ChangedByMember)
            .Where(i => i.RecipientMemberId == memberId)
            .OrderByDescending(i => i.CreatedAtUtc)
            .Select(i => new ServiceInquiryDetailDto(
                i.Id,
                i.InquiryNumber,
                i.ServiceId,
                i.Service.Title,
                i.Service.ServiceCategory,
                i.SenderMemberId,
                i.SenderMember.FullName,
                i.SenderMember.BusinessProfile != null ? i.SenderMember.BusinessProfile.CompanyName : null,
                i.SenderMember.Email,
                i.SenderMember.PhoneNumber,
                i.RecipientMemberId,
                i.RecipientMember.FullName,
                i.RecipientMember.BusinessProfile != null ? i.RecipientMember.BusinessProfile.CompanyName : null,
                i.Subject,
                i.RequirementDescription,
                i.ScopeOfWork,
                i.Location,
                i.PreferredStartDate,
                i.EstimatedBudget,
                i.Urgency,
                i.Status,
                i.Status.ToString(),
                i.ResponseMessage,
                i.RespondedAtUtc,
                i.CreatedAtUtc,
                i.StatusHistory
                    .OrderBy(h => h.ChangedAtUtc)
                    .Select(h => new ServiceInquiryStatusHistoryDto(
                        h.Id,
                        h.PreviousStatus,
                        h.NewStatus,
                        h.NewStatus.ToString(),
                        h.ChangedByMemberId,
                        h.ChangedByMember.FullName,
                        h.ChangedAtUtc,
                        h.Remarks
                    ))
                    .ToList()
            ))
            .ToListAsync();
    }
}


namespace Connexa.Api.Services.JobWork;

using System.Security.Cryptography;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;

public class JobWorkService : IJobWorkService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<JobWorkService> _logger;

    public JobWorkService(
        ConnexaDbContext db,
        INotificationService notificationService,
        IWebHostEnvironment environment,
        ILogger<JobWorkService> logger)
    {
        _db = db;
        _notificationService = notificationService;
        _environment = environment;
        _logger = logger;
    }

    // ==========================================
    // 1. REQUIREMENTS
    // ==========================================

    public async Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CreateRequirementAsync(
        int ownerMemberId,
        CreateJobWorkRequirementDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            return (false, "Title is required.", null);

        if (string.IsNullOrWhiteSpace(dto.Description))
            return (false, "Description is required.", null);

        if (string.IsNullOrWhiteSpace(dto.JobWorkProcess))
            return (false, "Job work process is required.", null);

        if (dto.Quantity <= 0)
            return (false, "Quantity must be greater than zero.", null);

        if (string.IsNullOrWhiteSpace(dto.UnitOfMeasurement))
            return (false, "Unit of measurement is required.", null);

        if (string.IsNullOrWhiteSpace(dto.Location))
            return (false, "Location is required.", null);

        var industryExists = await _db.Industries.AnyAsync(i => i.Id == dto.IndustryId, cancellationToken);
        if (!industryExists)
            return (false, "Specified industry does not exist.", null);

        var owner = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == ownerMemberId, cancellationToken);
        if (owner == null)
            return (false, "Owner member not found.", null);

        var requirementNumber = GenerateRequirementNumber();

        var requirement = new JobWorkRequirement
        {
            RequirementNumber = requirementNumber,
            OwnerMemberId = ownerMemberId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            IndustryId = dto.IndustryId,
            BusinessGroupId = dto.BusinessGroupId,
            SubGroupId = dto.SubGroupId,
            CategoryId = dto.CategoryId,
            JobWorkProcess = dto.JobWorkProcess.Trim(),
            MachineType = dto.MachineType?.Trim(),
            MachineCategory = dto.MachineCategory?.Trim(),
            RequiredMachineCapacity = dto.RequiredMachineCapacity?.Trim(),
            TechnicalSpecifications = dto.TechnicalSpecifications?.Trim(),
            RequiredTolerance = dto.RequiredTolerance?.Trim(),
            MaterialType = dto.MaterialType?.Trim(),
            MaterialResponsibility = dto.MaterialResponsibility,
            Quantity = dto.Quantity,
            UnitOfMeasurement = dto.UnitOfMeasurement.Trim(),
            TargetBudget = dto.TargetBudget,
            Location = dto.Location.Trim(),
            DeliveryTerms = dto.DeliveryTerms?.Trim(),
            ExpectedCompletionDate = dto.TargetCompletionDateUtc,
            Status = JobWorkRequirementStatus.Open,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.JobWorkRequirements.Add(requirement);
        await _db.SaveChangesAsync(cancellationToken);

        // Associate attachments if any
        if (dto.AttachmentIds != null && dto.AttachmentIds.Count > 0)
        {
            var attachments = await _db.JobWorkAttachments
                .Where(a => dto.AttachmentIds.Contains(a.Id) && a.UploadedByMemberId == ownerMemberId && a.JobWorkRequirementId == null)
                .ToListAsync(cancellationToken);

            foreach (var att in attachments)
            {
                att.JobWorkRequirementId = requirement.Id;
            }
            await _db.SaveChangesAsync(cancellationToken);
        }

        var fullRequirement = await LoadRequirementFullAsync(requirement.Id, ownerMemberId, cancellationToken);
        return (true, "Job work requirement created successfully.", fullRequirement);
    }

    public async Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> UpdateRequirementAsync(
        int requirementId,
        int ownerMemberId,
        UpdateJobWorkRequirementDto dto,
        CancellationToken cancellationToken = default)
    {
        var requirement = await _db.JobWorkRequirements
            .FirstOrDefaultAsync(r => r.Id == requirementId, cancellationToken);

        if (requirement == null)
            return (false, "Requirement not found.", null);

        if (requirement.OwnerMemberId != ownerMemberId)
            return (false, "Only the requirement owner can update this requirement.", null);

        if (requirement.Status != JobWorkRequirementStatus.Open)
            return (false, $"Cannot update requirement with status {requirement.Status}.", null);

        requirement.Title = dto.Title.Trim();
        requirement.Description = dto.Description.Trim();
        requirement.IndustryId = dto.IndustryId;
        requirement.BusinessGroupId = dto.BusinessGroupId;
        requirement.SubGroupId = dto.SubGroupId;
        requirement.CategoryId = dto.CategoryId;
        requirement.JobWorkProcess = dto.JobWorkProcess.Trim();
        requirement.MachineType = dto.MachineType?.Trim();
        requirement.MachineCategory = dto.MachineCategory?.Trim();
        requirement.RequiredMachineCapacity = dto.RequiredMachineCapacity?.Trim();
        requirement.TechnicalSpecifications = dto.TechnicalSpecifications?.Trim();
        requirement.RequiredTolerance = dto.RequiredTolerance?.Trim();
        requirement.MaterialType = dto.MaterialType?.Trim();
        requirement.MaterialResponsibility = dto.MaterialResponsibility;
        requirement.Quantity = dto.Quantity;
        requirement.UnitOfMeasurement = dto.UnitOfMeasurement.Trim();
        requirement.TargetBudget = dto.TargetBudget;
        requirement.Location = dto.Location.Trim();
        requirement.DeliveryTerms = dto.DeliveryTerms?.Trim();
        requirement.ExpectedCompletionDate = dto.TargetCompletionDateUtc;
        requirement.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var fullRequirement = await LoadRequirementFullAsync(requirement.Id, ownerMemberId, cancellationToken);
        return (true, "Requirement updated successfully.", fullRequirement);
    }

    public async Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CancelRequirementAsync(
        int requirementId,
        int ownerMemberId,
        CancellationToken cancellationToken = default)
    {
        var requirement = await _db.JobWorkRequirements
            .FirstOrDefaultAsync(r => r.Id == requirementId, cancellationToken);

        if (requirement == null)
            return (false, "Requirement not found.", null);

        if (requirement.OwnerMemberId != ownerMemberId)
            return (false, "Only the owner can cancel this requirement.", null);

        if (requirement.Status == JobWorkRequirementStatus.Closed || requirement.Status == JobWorkRequirementStatus.Cancelled)
            return (false, $"Requirement is already {requirement.Status}.", null);

        requirement.Status = JobWorkRequirementStatus.Cancelled;
        requirement.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var full = await LoadRequirementFullAsync(requirement.Id, ownerMemberId, cancellationToken);
        return (true, "Requirement cancelled successfully.", full);
    }

    public async Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CloseRequirementAsync(
        int requirementId,
        int ownerMemberId,
        CancellationToken cancellationToken = default)
    {
        var requirement = await _db.JobWorkRequirements
            .FirstOrDefaultAsync(r => r.Id == requirementId, cancellationToken);

        if (requirement == null)
            return (false, "Requirement not found.", null);

        if (requirement.OwnerMemberId != ownerMemberId)
            return (false, "Only the owner can close this requirement.", null);

        if (requirement.Status == JobWorkRequirementStatus.Closed)
            return (false, "Requirement is already closed.", null);

        requirement.Status = JobWorkRequirementStatus.Closed;
        requirement.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var full = await LoadRequirementFullAsync(requirement.Id, ownerMemberId, cancellationToken);
        return (true, "Requirement closed successfully.", full);
    }

    public async Task<JobWorkRequirementListResponseDto> GetMarketplaceRequirementsAsync(
        int? currentMemberId,
        JobWorkRequirementFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.JobWorkRequirements
            .Include(r => r.OwnerMember).ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Industry)
            .Include(r => r.BusinessGroup)
            .Include(r => r.SubGroup)
            .Include(r => r.Category)
            .Include(r => r.Attachments)
            .Include(r => r.Quotations)
            .Include(r => r.Order)
            .AsNoTracking();

        // Status filter: defaults to Open for marketplace if not specified
        if (filter.Status.HasValue)
        {
            query = query.Where(r => r.Status == filter.Status.Value);
        }
        else
        {
            query = query.Where(r => r.Status == JobWorkRequirementStatus.Open);
        }

        if (!string.IsNullOrWhiteSpace(filter.Process))
        {
            var p = filter.Process.Trim().ToLower();
            query = query.Where(r => r.JobWorkProcess.ToLower().Contains(p));
        }

        if (!string.IsNullOrWhiteSpace(filter.MachineType))
        {
            var m = filter.MachineType.Trim().ToLower();
            query = query.Where(r => (r.MachineType != null && r.MachineType.ToLower().Contains(m)) ||
                                     (r.MachineCategory != null && r.MachineCategory.ToLower().Contains(m)));
        }

        if (filter.IndustryId.HasValue && filter.IndustryId > 0)
        {
            query = query.Where(r => r.IndustryId == filter.IndustryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(filter.Location))
        {
            var loc = filter.Location.Trim().ToLower();
            query = query.Where(r => r.Location.ToLower().Contains(loc));
        }

        if (filter.MaterialResponsibility.HasValue)
        {
            query = query.Where(r => r.MaterialResponsibility == filter.MaterialResponsibility.Value);
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var s = filter.Search.Trim().ToLower();
            query = query.Where(r =>
                r.Title.ToLower().Contains(s) ||
                r.Description.ToLower().Contains(s) ||
                r.JobWorkProcess.ToLower().Contains(s) ||
                (r.MachineType != null && r.MachineType.ToLower().Contains(s)) ||
                (r.MaterialType != null && r.MaterialType.ToLower().Contains(s)) ||
                r.Location.ToLower().Contains(s) ||
                r.RequirementNumber.ToLower().Contains(s) ||
                (r.OwnerMember.BusinessProfile != null && r.OwnerMember.BusinessProfile.CompanyName.ToLower().Contains(s)));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var page = Math.Max(1, filter.Page);
        var pageSize = Math.Clamp(filter.PageSize, 1, 50);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var items = await query
            .OrderByDescending(r => r.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(r => MapRequirementToDto(r, currentMemberId)).ToList();
        return new JobWorkRequirementListResponseDto(dtos, totalCount, page, pageSize, totalPages);
    }

    public async Task<JobWorkRequirementListResponseDto> GetMyRequirementsAsync(
        int ownerMemberId,
        JobWorkRequirementFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.JobWorkRequirements
            .Include(r => r.OwnerMember).ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Industry)
            .Include(r => r.BusinessGroup)
            .Include(r => r.SubGroup)
            .Include(r => r.Category)
            .Include(r => r.Attachments)
            .Include(r => r.Quotations)
            .Include(r => r.Order)
            .Where(r => r.OwnerMemberId == ownerMemberId)
            .AsNoTracking();

        if (filter.Status.HasValue)
        {
            query = query.Where(r => r.Status == filter.Status.Value);
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var s = filter.Search.Trim().ToLower();
            query = query.Where(r =>
                r.Title.ToLower().Contains(s) ||
                r.RequirementNumber.ToLower().Contains(s) ||
                r.JobWorkProcess.ToLower().Contains(s));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var page = Math.Max(1, filter.Page);
        var pageSize = Math.Clamp(filter.PageSize, 1, 50);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var items = await query
            .OrderByDescending(r => r.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(r => MapRequirementToDto(r, ownerMemberId)).ToList();
        return new JobWorkRequirementListResponseDto(dtos, totalCount, page, pageSize, totalPages);
    }

    public async Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> GetRequirementByIdAsync(
        int requirementId,
        int? currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var dto = await LoadRequirementFullAsync(requirementId, currentMemberId, cancellationToken);
        if (dto == null)
            return (false, "Job work requirement not found.", null);

        return (true, "Requirement retrieved successfully.", dto);
    }

    // ==========================================
    // 2. QUOTATIONS
    // ==========================================

    public async Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> SubmitQuotationAsync(
        int contractorMemberId,
        SubmitJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default)
    {
        var requirement = await _db.JobWorkRequirements
            .Include(r => r.OwnerMember).ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(r => r.Id == dto.JobWorkRequirementId, cancellationToken);

        if (requirement == null)
            return (false, "Job work requirement not found.", null);

        // Rule 1: A user cannot quote on their own requirement
        if (requirement.OwnerMemberId == contractorMemberId)
            return (false, "You cannot submit a quotation for your own job work requirement.", null);

        // Rule 2: Requirement must be Open
        if (requirement.Status != JobWorkRequirementStatus.Open)
            return (false, $"Cannot quote on requirement with status '{requirement.Status}'. Only Open requirements accept quotations.", null);

        // Rule 3: Check for duplicate active quotation
        var existingActiveQuote = await _db.JobWorkQuotations
            .FirstOrDefaultAsync(q => q.JobWorkRequirementId == dto.JobWorkRequirementId &&
                                      q.ContractorMemberId == contractorMemberId &&
                                      (q.Status == JobWorkQuotationStatus.Submitted || q.Status == JobWorkQuotationStatus.RevisionRequested), cancellationToken);

        if (existingActiveQuote != null)
        {
            return (false, "You already have an active quotation for this requirement. You can update or withdraw your existing quote.", null);
        }

        if (dto.OfferedUnitPrice <= 0)
            return (false, "Offered unit price must be greater than zero.", null);

        if (dto.Quantity <= 0)
            return (false, "Quantity must be greater than zero.", null);

        if (dto.LeadTimeDays <= 0)
            return (false, "Lead time days must be at least 1 day.", null);

        var contractor = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == contractorMemberId, cancellationToken);
        if (contractor == null)
            return (false, "Contractor member not found.", null);

        var subtotal = dto.OfferedUnitPrice * dto.Quantity;
        var taxRate = Math.Max(0, dto.TaxRatePercent);
        var taxAmount = Math.Round(subtotal * (taxRate / 100m), 2);
        var totalAmount = subtotal + taxAmount + dto.OtherCharges;

        var quotationNumber = GenerateQuotationNumber();

        var quotation = new JobWorkQuotation
        {
            QuotationNumber = quotationNumber,
            JobWorkRequirementId = dto.JobWorkRequirementId,
            ContractorMemberId = contractorMemberId,
            OfferedUnitPrice = dto.OfferedUnitPrice,
            Quantity = dto.Quantity,
            Subtotal = subtotal,
            TaxRatePercent = taxRate,
            TaxAmount = taxAmount,
            OtherCharges = dto.OtherCharges,
            TotalAmount = totalAmount,
            LeadTimeDays = dto.LeadTimeDays,
            MachineProposed = dto.MachineProposed?.Trim(),
            TechnicalRemarks = dto.TechnicalRemarks?.Trim(),
            TermsAndConditions = dto.TermsAndConditions?.Trim(),
            Status = JobWorkQuotationStatus.Submitted,
            RevisionNumber = 1,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.JobWorkQuotations.Add(quotation);
        await _db.SaveChangesAsync(cancellationToken);

        // Associate attachments
        if (dto.AttachmentIds != null && dto.AttachmentIds.Count > 0)
        {
            var attachments = await _db.JobWorkAttachments
                .Where(a => dto.AttachmentIds.Contains(a.Id) && a.UploadedByMemberId == contractorMemberId && a.JobWorkQuotationId == null)
                .ToListAsync(cancellationToken);

            foreach (var att in attachments)
            {
                att.JobWorkQuotationId = quotation.Id;
            }
            await _db.SaveChangesAsync(cancellationToken);
        }

        // Notify requirement owner
        try
        {
            var contractorCompanyName = contractor.BusinessProfile?.CompanyName ?? contractor.FullName;
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: requirement.OwnerMemberId,
                actorMemberId: contractorMemberId,
                eventType: NotificationEventType.JobWorkQuotationReceived,
                title: $"New Quotation #{quotation.QuotationNumber}",
                message: $"{contractorCompanyName} submitted a quotation of ₹{quotation.TotalAmount:N2} for requirement #{requirement.RequirementNumber} ({requirement.Title}).",
                referenceType: "job_work_requirement",
                referenceId: requirement.Id,
                cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send notification for quotation submission #{QuotationId}", quotation.Id);
        }

        var fullQuote = await LoadQuotationFullAsync(quotation.Id, contractorMemberId, cancellationToken);
        return (true, "Quotation submitted successfully.", fullQuote);
    }

    public async Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> UpdateQuotationAsync(
        int quotationId,
        int contractorMemberId,
        UpdateJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default)
    {
        var quotation = await _db.JobWorkQuotations
            .Include(q => q.Requirement)
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quotation == null)
            return (false, "Quotation not found.", null);

        if (quotation.ContractorMemberId != contractorMemberId)
            return (false, "Only the contractor who submitted this quotation can update it.", null);

        if (quotation.Status != JobWorkQuotationStatus.Submitted && quotation.Status != JobWorkQuotationStatus.RevisionRequested)
            return (false, $"Cannot update quotation in '{quotation.Status}' status.", null);

        if (dto.OfferedUnitPrice <= 0 || dto.Quantity <= 0)
            return (false, "Price and quantity must be greater than zero.", null);

        var subtotal = dto.OfferedUnitPrice * dto.Quantity;
        var taxRate = Math.Max(0, dto.TaxRatePercent);
        var taxAmount = Math.Round(subtotal * (taxRate / 100m), 2);
        var totalAmount = subtotal + taxAmount + dto.OtherCharges;

        quotation.OfferedUnitPrice = dto.OfferedUnitPrice;
        quotation.Quantity = dto.Quantity;
        quotation.Subtotal = subtotal;
        quotation.TaxRatePercent = taxRate;
        quotation.TaxAmount = taxAmount;
        quotation.OtherCharges = dto.OtherCharges;
        quotation.TotalAmount = totalAmount;
        quotation.LeadTimeDays = dto.LeadTimeDays;
        quotation.MachineProposed = dto.MachineProposed?.Trim();
        quotation.TechnicalRemarks = dto.TechnicalRemarks?.Trim();
        quotation.TermsAndConditions = dto.TermsAndConditions?.Trim();
        if (!string.IsNullOrWhiteSpace(dto.RevisionNotes)) quotation.RevisionNotes = dto.RevisionNotes.Trim();

        quotation.RevisionNumber++;
        quotation.Status = JobWorkQuotationStatus.Submitted;
        quotation.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        // Notify requirement owner about updated quote
        try
        {
            var contractor = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == contractorMemberId, cancellationToken);
            var contractorName = contractor?.BusinessProfile?.CompanyName ?? contractor?.FullName ?? "Contractor";
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: quotation.Requirement.OwnerMemberId,
                actorMemberId: contractorMemberId,
                eventType: NotificationEventType.JobWorkQuotationRevised,
                title: $"Revised Quotation #{quotation.QuotationNumber} (v{quotation.RevisionNumber})",
                message: $"{contractorName} updated quotation #{quotation.QuotationNumber} (New Total: ₹{quotation.TotalAmount:N2}).",
                referenceType: "job_work_requirement",
                referenceId: quotation.JobWorkRequirementId,
                cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send notification for quotation update #{QuotationId}", quotation.Id);
        }

        var fullQuote = await LoadQuotationFullAsync(quotation.Id, contractorMemberId, cancellationToken);
        return (true, "Quotation updated successfully.", fullQuote);
    }

    public async Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> WithdrawQuotationAsync(
        int quotationId,
        int contractorMemberId,
        CancellationToken cancellationToken = default)
    {
        var quotation = await _db.JobWorkQuotations
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quotation == null)
            return (false, "Quotation not found.", null);

        if (quotation.ContractorMemberId != contractorMemberId)
            return (false, "Only the contractor can withdraw this quotation.", null);

        if (quotation.Status != JobWorkQuotationStatus.Submitted && quotation.Status != JobWorkQuotationStatus.RevisionRequested)
            return (false, $"Cannot withdraw quotation in '{quotation.Status}' status.", null);

        quotation.Status = JobWorkQuotationStatus.Withdrawn;
        quotation.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var full = await LoadQuotationFullAsync(quotation.Id, contractorMemberId, cancellationToken);
        return (true, "Quotation withdrawn successfully.", full);
    }

    public async Task<List<JobWorkQuotationDto>> GetQuotationsForRequirementAsync(
        int requirementId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var requirement = await _db.JobWorkRequirements
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == requirementId, cancellationToken);

        if (requirement == null)
            return new List<JobWorkQuotationDto>();

        var isOwner = requirement.OwnerMemberId == currentMemberId;

        var query = _db.JobWorkQuotations
            .Include(q => q.Requirement)
            .Include(q => q.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(q => q.Attachments)
            .Where(q => q.JobWorkRequirementId == requirementId)
            .AsNoTracking();

        if (!isOwner && !isAdmin)
        {
            query = query.Where(q => q.ContractorMemberId == currentMemberId);
        }

        var quotes = await query
            .OrderBy(q => q.TotalAmount)
            .ToListAsync(cancellationToken);

        return quotes.Select(q => MapQuotationToDto(q, currentMemberId, isOwner)).ToList();
    }

    public async Task<JobWorkQuotationListResponseDto> GetMyQuotationsAsync(
        int contractorMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var query = _db.JobWorkQuotations
            .Include(q => q.Requirement)
            .Include(q => q.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(q => q.Attachments)
            .Where(q => q.ContractorMemberId == contractorMemberId)
            .AsNoTracking();

        var totalCount = await query.CountAsync(cancellationToken);
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var items = await query
            .OrderByDescending(q => q.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(q => MapQuotationToDto(q, contractorMemberId, false)).ToList();
        return new JobWorkQuotationListResponseDto(dtos, totalCount, page, pageSize, totalPages);
    }

    public async Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> GetQuotationByIdAsync(
        int quotationId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var quote = await _db.JobWorkQuotations
            .Include(q => q.Requirement)
            .Include(q => q.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(q => q.Attachments)
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quote == null)
            return (false, "Quotation not found.", null);

        var isOwner = quote.Requirement.OwnerMemberId == currentMemberId;
        var isContractor = quote.ContractorMemberId == currentMemberId;

        if (!isOwner && !isContractor && !isAdmin)
            return (false, "You are not authorized to view this quotation.", null);

        var dto = MapQuotationToDto(quote, currentMemberId, isOwner);
        return (true, "Quotation retrieved successfully.", dto);
    }

    public async Task<(bool Success, string Message, JobWorkQuotationDto? Quotation, JobWorkOrderDto? Order)> DecideQuotationAsync(
        int quotationId,
        int ownerMemberId,
        DecideJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default)
    {
        var quotation = await _db.JobWorkQuotations
            .Include(q => q.Requirement)
            .Include(q => q.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quotation == null)
            return (false, "Quotation not found.", null, null);

        if (quotation.Requirement.OwnerMemberId != ownerMemberId)
            return (false, "Only the requirement owner can decide on quotations.", null, null);

        if (quotation.Status != JobWorkQuotationStatus.Submitted && quotation.Status != JobWorkQuotationStatus.RevisionRequested)
            return (false, $"Cannot decide on quotation with status '{quotation.Status}'.", null, null);

        var decision = dto.Decision.Trim().ToLowerInvariant();

        if (decision == "accept")
        {
            var strategy = _db.Database.CreateExecutionStrategy();
            return await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
                try
                {
                    // 1. Accept quotation
                    quotation.Status = JobWorkQuotationStatus.Accepted;
                    quotation.UpdatedAtUtc = DateTime.UtcNow;

                    // 2. Close requirement
                    quotation.Requirement.Status = JobWorkRequirementStatus.Closed;
                    quotation.Requirement.UpdatedAtUtc = DateTime.UtcNow;

                    // 3. Reject competing active quotations
                    var competing = await _db.JobWorkQuotations
                        .Where(q => q.JobWorkRequirementId == quotation.JobWorkRequirementId &&
                                    q.Id != quotation.Id &&
                                    (q.Status == JobWorkQuotationStatus.Submitted || q.Status == JobWorkQuotationStatus.RevisionRequested))
                        .ToListAsync(cancellationToken);

                    foreach (var cq in competing)
                    {
                        cq.Status = JobWorkQuotationStatus.Rejected;
                        cq.RejectionReason = "Alternative quotation accepted by requirement owner.";
                        cq.UpdatedAtUtc = DateTime.UtcNow;
                    }

                    // 4. Create JobWorkOrder
                    var orderNumber = GenerateOrderNumber();
                    var order = new JobWorkOrder
                    {
                        OrderNumber = orderNumber,
                        JobWorkRequirementId = quotation.JobWorkRequirementId,
                        JobWorkQuotationId = quotation.Id,
                        BuyerMemberId = ownerMemberId,
                        ContractorMemberId = quotation.ContractorMemberId,
                        JobTitle = quotation.Requirement.Title,
                        Process = quotation.Requirement.JobWorkProcess,
                        Quantity = quotation.Quantity,
                        UnitOfMeasurement = quotation.Requirement.UnitOfMeasurement,
                        AgreedUnitPrice = quotation.OfferedUnitPrice,
                        Subtotal = quotation.Subtotal,
                        TaxAmount = quotation.TaxAmount,
                        OtherCharges = quotation.OtherCharges,
                        TotalAmount = quotation.TotalAmount,
                        LeadTimeDays = quotation.LeadTimeDays,
                        DeliveryLocation = quotation.Requirement.Location,
                        Status = JobWorkOrderStatus.Confirmed,
                        ConfirmedAtUtc = DateTime.UtcNow,
                        Notes = dto.Notes?.Trim(),
                        CreatedAtUtc = DateTime.UtcNow
                    };

                    _db.JobWorkOrders.Add(order);
                    await _db.SaveChangesAsync(cancellationToken);

                    // Add status history entry
                    var history = new JobWorkOrderStatusHistory
                    {
                        JobWorkOrderId = order.Id,
                        PreviousStatus = null,
                        NewStatus = JobWorkOrderStatus.Confirmed,
                        ChangedByMemberId = ownerMemberId,
                        Remarks = "Order created upon quotation acceptance.",
                        ChangedAtUtc = DateTime.UtcNow
                    };

                    _db.JobWorkOrderStatusHistories.Add(history);
                    await _db.SaveChangesAsync(cancellationToken);

                    await transaction.CommitAsync(cancellationToken);

                    // 5. Send notifications
                    try
                    {
                        var owner = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == ownerMemberId, cancellationToken);
                        var ownerName = owner?.BusinessProfile?.CompanyName ?? owner?.FullName ?? "Buyer";

                        // Notify winning contractor
                        await _notificationService.CreateNotificationAsync(
                            recipientMemberId: quotation.ContractorMemberId,
                            actorMemberId: ownerMemberId,
                            eventType: NotificationEventType.JobWorkQuotationAccepted,
                            title: $"Quotation Accepted #{quotation.QuotationNumber}",
                            message: $"{ownerName} accepted your quotation. Order #{order.OrderNumber} has been generated.",
                            referenceType: "job_work_order",
                            referenceId: order.Id,
                            cancellationToken: cancellationToken);

                        // Notify rejected competitors
                        foreach (var cq in competing)
                        {
                            await _notificationService.CreateNotificationAsync(
                                recipientMemberId: cq.ContractorMemberId,
                                actorMemberId: ownerMemberId,
                                eventType: NotificationEventType.JobWorkQuotationRejected,
                                title: $"Quotation Update #{cq.QuotationNumber}",
                                message: $"The requirement #{quotation.Requirement.RequirementNumber} was awarded to another contractor.",
                                referenceType: "job_work_requirement",
                                referenceId: quotation.JobWorkRequirementId,
                                cancellationToken: cancellationToken);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to send notifications for quotation acceptance #{QuotationId}", quotation.Id);
                    }

                    var quoteDto = await LoadQuotationFullAsync(quotation.Id, ownerMemberId, cancellationToken);
                    var orderDto = await LoadOrderFullAsync(order.Id, ownerMemberId, cancellationToken);

                    return (true, $"Quotation accepted and Order #{order.OrderNumber} created successfully.", quoteDto, orderDto);
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync(cancellationToken);
                    _logger.LogError(ex, "Failed to accept quotation #{QuotationId}", quotationId);
                    return (false, "Failed to accept quotation. Please try again.", null, null);
                }
            });
        }
        else if (decision == "reject")
        {
            quotation.Status = JobWorkQuotationStatus.Rejected;
            quotation.RejectionReason = dto.Notes?.Trim() ?? "Declined by requirement owner.";
            quotation.UpdatedAtUtc = DateTime.UtcNow;

            await _db.SaveChangesAsync(cancellationToken);

            try
            {
                var owner = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == ownerMemberId, cancellationToken);
                var ownerName = owner?.BusinessProfile?.CompanyName ?? owner?.FullName ?? "Buyer";

                await _notificationService.CreateNotificationAsync(
                    recipientMemberId: quotation.ContractorMemberId,
                    actorMemberId: ownerMemberId,
                    eventType: NotificationEventType.JobWorkQuotationRejected,
                    title: $"Quotation Rejected #{quotation.QuotationNumber}",
                    message: $"{ownerName} rejected your quotation: {quotation.RejectionReason}",
                    referenceType: "job_work_requirement",
                    referenceId: quotation.JobWorkRequirementId,
                    cancellationToken: cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send notification for quotation rejection #{QuotationId}", quotation.Id);
            }

            var quoteDto = await LoadQuotationFullAsync(quotation.Id, ownerMemberId, cancellationToken);
            return (true, "Quotation rejected successfully.", quoteDto, null);
        }
        else if (decision == "requestrevision" || decision == "request_revision")
        {
            if (string.IsNullOrWhiteSpace(dto.Notes))
                return (false, "Notes are required when requesting a revision.", null, null);

            quotation.Status = JobWorkQuotationStatus.RevisionRequested;
            quotation.RevisionNotes = dto.Notes.Trim();
            quotation.UpdatedAtUtc = DateTime.UtcNow;

            await _db.SaveChangesAsync(cancellationToken);

            try
            {
                var owner = await _db.Members.Include(m => m.BusinessProfile).FirstOrDefaultAsync(m => m.Id == ownerMemberId, cancellationToken);
                var ownerName = owner?.BusinessProfile?.CompanyName ?? owner?.FullName ?? "Buyer";

                await _notificationService.CreateNotificationAsync(
                    recipientMemberId: quotation.ContractorMemberId,
                    actorMemberId: ownerMemberId,
                    eventType: NotificationEventType.JobWorkQuotationRevisionRequested,
                    title: $"Revision Requested #{quotation.QuotationNumber}",
                    message: $"{ownerName} requested changes on your quotation: {quotation.RevisionNotes}",
                    referenceType: "job_work_requirement",
                    referenceId: quotation.JobWorkRequirementId,
                    cancellationToken: cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send notification for revision request #{QuotationId}", quotation.Id);
            }

            var quoteDto = await LoadQuotationFullAsync(quotation.Id, ownerMemberId, cancellationToken);
            return (true, "Revision requested successfully.", quoteDto, null);
        }
        else
        {
            return (false, "Invalid decision. Supported values: 'Accept', 'Reject', 'RequestRevision'.", null, null);
        }
    }

    // ==========================================
    // 3. ORDERS
    // ==========================================

    public async Task<JobWorkOrderListResponseDto> GetOrdersAsync(
        int currentMemberId,
        bool isBuyer,
        int page = 1,
        int pageSize = 10,
        JobWorkOrderStatus? status = null,
        CancellationToken cancellationToken = default)
    {
        var query = _db.JobWorkOrders
            .Include(o => o.Requirement)
            .Include(o => o.Quotation)
            .Include(o => o.BuyerMember).ThenInclude(m => m.BusinessProfile)
            .Include(o => o.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory).ThenInclude(h => h.ChangedByMember).ThenInclude(m => m.BusinessProfile)
            .AsNoTracking();

        if (isBuyer)
        {
            query = query.Where(o => o.BuyerMemberId == currentMemberId);
        }
        else
        {
            query = query.Where(o => o.ContractorMemberId == currentMemberId);
        }

        if (status.HasValue)
        {
            query = query.Where(o => o.Status == status.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var items = await query
            .OrderByDescending(o => o.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(o => MapOrderToDto(o, currentMemberId)).ToList();
        return new JobWorkOrderListResponseDto(dtos, totalCount, page, pageSize, totalPages);
    }

    public async Task<(bool Success, string Message, JobWorkOrderDto? Order)> GetOrderByIdAsync(
        int orderId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.JobWorkOrders
            .Include(o => o.Requirement)
            .Include(o => o.Quotation)
            .Include(o => o.BuyerMember).ThenInclude(m => m.BusinessProfile)
            .Include(o => o.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory).ThenInclude(h => h.ChangedByMember).ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
            return (false, "Job work order not found.", null);

        if (order.BuyerMemberId != currentMemberId && order.ContractorMemberId != currentMemberId && !isAdmin)
            return (false, "You are not authorized to view this order.", null);

        var dto = MapOrderToDto(order, currentMemberId);
        return (true, "Order retrieved successfully.", dto);
    }

    public async Task<(bool Success, string Message, JobWorkOrderDto? Order)> UpdateOrderStatusAsync(
        int orderId,
        int currentMemberId,
        UpdateJobWorkOrderStatusDto dto,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.JobWorkOrders
            .Include(o => o.Requirement)
            .Include(o => o.Quotation)
            .Include(o => o.BuyerMember).ThenInclude(m => m.BusinessProfile)
            .Include(o => o.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
            return (false, "Order not found.", null);

        var isBuyer = order.BuyerMemberId == currentMemberId;
        var isContractor = order.ContractorMemberId == currentMemberId;

        if (!isBuyer && !isContractor)
            return (false, "You are not authorized to update this order.", null);

        if (order.Status == JobWorkOrderStatus.Completed || order.Status == JobWorkOrderStatus.Cancelled || order.Status == JobWorkOrderStatus.Rejected)
            return (false, $"Order is already in final status '{order.Status}' and cannot be updated.", null);

        var prevStatus = order.Status;
        var newStatus = dto.NewStatus;

        // Role-based validation
        if (newStatus == JobWorkOrderStatus.Processing)
        {
            if (!isContractor)
                return (false, "Only the contractor can mark the order as Processing.", null);

            order.ProcessingStartedAtUtc = DateTime.UtcNow;
        }
        else if (newStatus == JobWorkOrderStatus.Completed)
        {
            order.CompletedAtUtc = DateTime.UtcNow;
        }
        else if (newStatus == JobWorkOrderStatus.Confirmed)
        {
            if (!isContractor)
                return (false, "Only the contractor can confirm the order.", null);

            order.ConfirmedAtUtc = DateTime.UtcNow;
        }
        else if (newStatus == JobWorkOrderStatus.Rejected)
        {
            if (!isContractor)
                return (false, "Only the contractor can reject the order.", null);

            order.RejectionReason = dto.Remarks;
        }
        else if (newStatus == JobWorkOrderStatus.Cancelled)
        {
            order.CancellationReason = dto.Remarks;
        }

        order.Status = newStatus;

        var history = new JobWorkOrderStatusHistory
        {
            JobWorkOrderId = order.Id,
            PreviousStatus = prevStatus,
            NewStatus = newStatus,
            ChangedByMemberId = currentMemberId,
            Remarks = dto.Remarks,
            ChangedAtUtc = DateTime.UtcNow
        };

        _db.JobWorkOrderStatusHistories.Add(history);
        await _db.SaveChangesAsync(cancellationToken);

        // Notify other party
        try
        {
            var recipientId = isBuyer ? order.ContractorMemberId : order.BuyerMemberId;
            var changerName = isBuyer
                ? (order.BuyerMember.BusinessProfile?.CompanyName ?? order.BuyerMember.FullName)
                : (order.ContractorMember.BusinessProfile?.CompanyName ?? order.ContractorMember.FullName);

            var eventType = newStatus switch
            {
                JobWorkOrderStatus.Processing => NotificationEventType.JobWorkOrderProcessing,
                JobWorkOrderStatus.Completed => NotificationEventType.JobWorkOrderCompleted,
                JobWorkOrderStatus.Cancelled => NotificationEventType.JobWorkOrderCancelled,
                _ => NotificationEventType.JobWorkOrderCreated
            };

            await _notificationService.CreateNotificationAsync(
                recipientMemberId: recipientId,
                actorMemberId: currentMemberId,
                eventType: eventType,
                title: $"Order #{order.OrderNumber} Updated",
                message: $"{changerName} updated order #{order.OrderNumber} to {newStatus}." + (string.IsNullOrWhiteSpace(dto.Remarks) ? "" : $" Remarks: {dto.Remarks}"),
                referenceType: "job_work_order",
                referenceId: order.Id,
                cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send notification for order status change #{OrderId}", order.Id);
        }

        var fullOrder = await LoadOrderFullAsync(order.Id, currentMemberId, cancellationToken);
        return (true, $"Order status updated to {newStatus} successfully.", fullOrder);
    }

    public async Task<(bool Success, string Message, JobWorkOrderDto? Order)> CancelOrderAsync(
        int orderId,
        int currentMemberId,
        string reason,
        CancellationToken cancellationToken = default)
    {
        return await UpdateOrderStatusAsync(orderId, currentMemberId, new UpdateJobWorkOrderStatusDto(JobWorkOrderStatus.Cancelled, reason), cancellationToken);
    }

    // ==========================================
    // 4. ATTACHMENTS
    // ==========================================

    public async Task<(bool Success, string Message, JobWorkAttachmentDto? Attachment)> UploadAttachmentAsync(
        int currentMemberId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
            return (false, "No file uploaded.", null);

        const long maxBytes = 25 * 1024 * 1024; // 25MB for CAD / engineering drawings
        if (file.Length > maxBytes)
            return (false, "File exceeds maximum permitted size of 25MB.", null);

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExts = new[]
        {
            ".pdf", ".dwg", ".dxf", ".step", ".stp", ".iges", ".igs", ".stl",
            ".zip", ".rar", ".doc", ".docx", ".xls", ".xlsx", ".jpg", ".jpeg", ".png"
        };

        if (!allowedExts.Contains(ext))
            return (false, $"File extension '{ext}' is not supported. Allowed formats: PDF, DWG, DXF, STEP/STP, IGES, STL, ZIP, Office docs, JPG, PNG.", null);

        var webRoot = _environment.WebRootPath ?? Path.Combine(AppContext.BaseDirectory, "wwwroot");
        var dir = Path.Combine(webRoot, "uploads", "job-work-attachments");
        if (!System.IO.Directory.Exists(dir))
        {
            System.IO.Directory.CreateDirectory(dir);
        }

        var storedFileName = $"jw_{currentMemberId}_{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(dir, storedFileName);

        using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        var attachment = new JobWorkAttachment
        {
            OriginalFileName = Path.GetFileName(file.FileName),
            StoredFileName = storedFileName,
            FileExtension = ext,
            ContentType = string.IsNullOrWhiteSpace(file.ContentType) ? "application/octet-stream" : file.ContentType,
            FileSizeBytes = file.Length,
            UploadedByMemberId = currentMemberId,
            UploadedAtUtc = DateTime.UtcNow
        };

        _db.JobWorkAttachments.Add(attachment);
        await _db.SaveChangesAsync(cancellationToken);

        var downloadUrl = $"/api/v1/job-works/attachments/{attachment.Id}/download";
        var dto = new JobWorkAttachmentDto(
            attachment.Id,
            attachment.JobWorkRequirementId,
            attachment.JobWorkQuotationId,
            attachment.UploadedByMemberId,
            attachment.OriginalFileName,
            attachment.StoredFileName,
            attachment.FileExtension,
            attachment.ContentType,
            attachment.FileSizeBytes,
            attachment.UploadedAtUtc,
            downloadUrl
        );

        return (true, "Attachment uploaded successfully.", dto);
    }

    public async Task<(bool Success, string Message, string? FilePath, string? ContentType, string? OriginalFileName)> GetAttachmentDownloadAsync(
        int attachmentId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var attachment = await _db.JobWorkAttachments
            .Include(a => a.JobWorkRequirement)
            .Include(a => a.JobWorkQuotation).ThenInclude(q => q!.Requirement)
            .FirstOrDefaultAsync(a => a.Id == attachmentId, cancellationToken);

        if (attachment == null)
            return (false, "Attachment not found.", null, null, null);

        // Security check: must be uploader, requirement owner, quotation contractor, or admin
        var isAuthorized = isAdmin || attachment.UploadedByMemberId == currentMemberId;
        if (!isAuthorized && attachment.JobWorkRequirement != null)
        {
            isAuthorized = attachment.JobWorkRequirement.OwnerMemberId == currentMemberId;
        }
        if (!isAuthorized && attachment.JobWorkQuotation != null)
        {
            isAuthorized = attachment.JobWorkQuotation.ContractorMemberId == currentMemberId ||
                           attachment.JobWorkQuotation.Requirement.OwnerMemberId == currentMemberId;
        }

        // Also if requirement is Open on marketplace, requirements attachments are viewable by prospective bidders
        if (!isAuthorized && attachment.JobWorkRequirement != null && attachment.JobWorkRequirement.Status == JobWorkRequirementStatus.Open)
        {
            isAuthorized = true;
        }

        if (!isAuthorized)
            return (false, "You are not authorized to download this attachment.", null, null, null);

        var webRoot = _environment.WebRootPath ?? Path.Combine(AppContext.BaseDirectory, "wwwroot");
        var filePath = Path.Combine(webRoot, "uploads", "job-work-attachments", attachment.StoredFileName);

        if (!System.IO.File.Exists(filePath))
            return (false, "File not found on storage server.", null, null, null);

        return (true, "File found.", filePath, attachment.ContentType, attachment.OriginalFileName);
    }

    // ==========================================
    // HELPERS & MAPPERS
    // ==========================================

    private async Task<JobWorkRequirementDto?> LoadRequirementFullAsync(int requirementId, int? currentMemberId, CancellationToken cancellationToken)
    {
        var req = await _db.JobWorkRequirements
            .Include(r => r.OwnerMember).ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Industry)
            .Include(r => r.BusinessGroup)
            .Include(r => r.SubGroup)
            .Include(r => r.Category)
            .Include(r => r.Attachments)
            .Include(r => r.Quotations)
            .Include(r => r.Order)
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == requirementId, cancellationToken);

        if (req == null) return null;
        return MapRequirementToDto(req, currentMemberId);
    }

    private async Task<JobWorkQuotationDto?> LoadQuotationFullAsync(int quotationId, int currentMemberId, CancellationToken cancellationToken)
    {
        var q = await _db.JobWorkQuotations
            .Include(x => x.Requirement)
            .Include(x => x.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(x => x.Attachments)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == quotationId, cancellationToken);

        if (q == null) return null;
        var isOwner = q.Requirement.OwnerMemberId == currentMemberId;
        return MapQuotationToDto(q, currentMemberId, isOwner);
    }

    private async Task<JobWorkOrderDto?> LoadOrderFullAsync(int orderId, int currentMemberId, CancellationToken cancellationToken)
    {
        var o = await _db.JobWorkOrders
            .Include(x => x.Requirement)
            .Include(x => x.Quotation)
            .Include(x => x.BuyerMember).ThenInclude(m => m.BusinessProfile)
            .Include(x => x.ContractorMember).ThenInclude(m => m.BusinessProfile)
            .Include(x => x.StatusHistory).ThenInclude(h => h.ChangedByMember).ThenInclude(m => m.BusinessProfile)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

        if (o == null) return null;
        return MapOrderToDto(o, currentMemberId);
    }

    private static JobWorkRequirementDto MapRequirementToDto(JobWorkRequirement r, int? currentMemberId)
    {
        var isOwner = currentMemberId.HasValue && r.OwnerMemberId == currentMemberId.Value;
        var myQuote = currentMemberId.HasValue
            ? r.Quotations?.FirstOrDefault(q => q.ContractorMemberId == currentMemberId.Value && q.Status != JobWorkQuotationStatus.Withdrawn)
            : null;

        var attachmentsDto = r.Attachments?.Select(a => new JobWorkAttachmentDto(
            a.Id,
            a.JobWorkRequirementId,
            a.JobWorkQuotationId,
            a.UploadedByMemberId,
            a.OriginalFileName,
            a.StoredFileName,
            a.FileExtension,
            a.ContentType,
            a.FileSizeBytes,
            a.UploadedAtUtc,
            $"/api/v1/job-works/attachments/{a.Id}/download"
        )).ToList() ?? new List<JobWorkAttachmentDto>();

        return new JobWorkRequirementDto(
            r.Id,
            r.RequirementNumber,
            r.OwnerMemberId,
            r.OwnerMember?.FullName ?? "Unknown",
            r.OwnerMember?.BusinessProfile?.CompanyName ?? r.OwnerMember?.FullName ?? "Business",
            r.OwnerMember?.BusinessProfile?.City,
            r.OwnerMember?.BusinessProfile?.State,
            r.OwnerMember?.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            r.Title,
            r.Description,
            r.IndustryId,
            r.Industry?.Name ?? "General",
            r.BusinessGroupId,
            r.BusinessGroup?.Name,
            r.SubGroupId,
            r.SubGroup?.Name,
            r.CategoryId,
            r.Category?.Name,
            r.JobWorkProcess,
            r.MachineType,
            r.MachineCategory,
            r.RequiredMachineCapacity,
            r.TechnicalSpecifications,
            r.RequiredTolerance,
            r.MaterialType,
            r.MaterialResponsibility.ToString(),
            r.Quantity,
            r.UnitOfMeasurement,
            r.TargetBudget,
            r.Location,
            r.DeliveryTerms,
            r.ExpectedCompletionDate,
            r.Status.ToString(),
            r.CreatedAtUtc,
            r.UpdatedAtUtc,
            r.Status == JobWorkRequirementStatus.Closed ? r.UpdatedAtUtc : null,
            r.Quotations?.Count(q => q.Status != JobWorkQuotationStatus.Withdrawn) ?? 0,
            r.Order?.Id,
            r.Order?.OrderNumber,
            attachmentsDto,
            isOwner,
            myQuote != null,
            myQuote?.Id
        );
    }

    private static JobWorkQuotationDto MapQuotationToDto(JobWorkQuotation q, int currentMemberId, bool isOwner)
    {
        var isContractor = q.ContractorMemberId == currentMemberId;
        var attachmentsDto = q.Attachments?.Select(a => new JobWorkAttachmentDto(
            a.Id,
            a.JobWorkRequirementId,
            a.JobWorkQuotationId,
            a.UploadedByMemberId,
            a.OriginalFileName,
            a.StoredFileName,
            a.FileExtension,
            a.ContentType,
            a.FileSizeBytes,
            a.UploadedAtUtc,
            $"/api/v1/job-works/attachments/{a.Id}/download"
        )).ToList() ?? new List<JobWorkAttachmentDto>();

        return new JobWorkQuotationDto(
            q.Id,
            q.QuotationNumber,
            q.JobWorkRequirementId,
            q.Requirement?.RequirementNumber ?? "",
            q.Requirement?.Title ?? "",
            q.ContractorMemberId,
            q.ContractorMember?.FullName ?? "Contractor",
            q.ContractorMember?.BusinessProfile?.CompanyName ?? q.ContractorMember?.FullName ?? "Contractor",
            q.ContractorMember?.BusinessProfile?.City,
            q.ContractorMember?.BusinessProfile?.State,
            q.ContractorMember?.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            q.OfferedUnitPrice,
            q.Quantity,
            q.Subtotal,
            q.TaxRatePercent,
            q.TaxAmount,
            q.OtherCharges,
            q.TotalAmount,
            q.LeadTimeDays,
            q.MachineProposed,
            q.TechnicalRemarks,
            q.TermsAndConditions,
            q.CreatedAtUtc.AddDays(30),
            q.Status.ToString(),
            q.RevisionNumber,
            q.RejectionReason,
            q.RevisionNotes,
            q.CreatedAtUtc,
            q.UpdatedAtUtc,
            attachmentsDto,
            isContractor,
            isOwner
        );
    }

    private static JobWorkOrderDto MapOrderToDto(JobWorkOrder o, int currentMemberId)
    {
        var isBuyer = o.BuyerMemberId == currentMemberId;
        var isContractor = o.ContractorMemberId == currentMemberId;

        var historiesDto = o.StatusHistory?.Select(h => new JobWorkOrderStatusHistoryDto(
            h.Id,
            h.JobWorkOrderId,
            h.PreviousStatus?.ToString(),
            h.NewStatus.ToString(),
            h.ChangedByMemberId,
            h.ChangedByMember?.FullName ?? "Member",
            h.ChangedByMember?.BusinessProfile?.CompanyName,
            h.ChangedAtUtc,
            h.Remarks
        )).OrderBy(h => h.ChangedAtUtc).ToList() ?? new List<JobWorkOrderStatusHistoryDto>();

        return new JobWorkOrderDto(
            o.Id,
            o.OrderNumber,
            o.JobWorkRequirementId,
            o.Requirement?.RequirementNumber ?? "",
            o.JobWorkQuotationId,
            o.Quotation?.QuotationNumber ?? "",
            o.BuyerMemberId,
            o.BuyerMember?.FullName ?? "Buyer",
            o.BuyerMember?.BusinessProfile?.CompanyName ?? o.BuyerMember?.FullName ?? "Buyer",
            o.BuyerMember?.Email,
            o.BuyerMember?.PhoneNumber,
            o.ContractorMemberId,
            o.ContractorMember?.FullName ?? "Contractor",
            o.ContractorMember?.BusinessProfile?.CompanyName ?? o.ContractorMember?.FullName ?? "Contractor",
            o.ContractorMember?.Email,
            o.ContractorMember?.PhoneNumber,
            o.JobTitle,
            o.Process,
            o.Quantity,
            o.UnitOfMeasurement,
            o.AgreedUnitPrice,
            o.Subtotal,
            o.TaxAmount,
            o.OtherCharges,
            o.TotalAmount,
            o.LeadTimeDays,
            o.DeliveryLocation,
            o.Status.ToString(),
            o.ConfirmedAtUtc,
            o.ProcessingStartedAtUtc,
            o.CompletedAtUtc,
            o.Status == JobWorkOrderStatus.Cancelled ? o.StatusHistory?.LastOrDefault(h => h.NewStatus == JobWorkOrderStatus.Cancelled)?.ChangedAtUtc : null,
            o.CancellationReason,
            o.RejectionReason,
            o.Notes,
            o.CreatedAtUtc,
            historiesDto,
            isBuyer,
            isContractor
        );
    }

    private static string GenerateRequirementNumber()
    {
        return $"JWR-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..5].ToUpperInvariant()}";
    }

    private static string GenerateQuotationNumber()
    {
        return $"JWQ-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..5].ToUpperInvariant()}";
    }

    private static string GenerateOrderNumber()
    {
        return $"JWO-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..5].ToUpperInvariant()}";
    }
}

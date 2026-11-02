using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Services.Rfq;

public class RfqService : IRfqService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<RfqService> _logger;

    public RfqService(
        ConnexaDbContext db,
        INotificationService notificationService,
        IWebHostEnvironment environment,
        ILogger<RfqService> logger)
    {
        _db = db;
        _notificationService = notificationService;
        _environment = environment;
        _logger = logger;
    }

    public async Task<(bool Success, string Message, RfqDto? Rfq)> CreateRfqAsync(
        int buyerMemberId,
        CreateRfqDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Quantity <= 0)
        {
            return (false, "Requested quantity must be greater than zero.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.UnitOfMeasurement))
        {
            return (false, "Unit of measurement is required.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.DeliveryLocation))
        {
            return (false, "Delivery location is required.", null);
        }

        var product = await _db.Products
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(p => p.Id == dto.ProductId && p.IsActive, cancellationToken);

        if (product == null)
        {
            return (false, "Product not found or inactive.", null);
        }

        if (product.MemberId == buyerMemberId)
        {
            return (false, "You cannot create an RFQ for your own product.", null);
        }

        var buyer = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == buyerMemberId, cancellationToken);

        if (buyer == null)
        {
            return (false, "Buyer member not found.", null);
        }

        string rfqNumber = GenerateRfqNumber();
        while (await _db.Rfqs.AnyAsync(r => r.RfqNumber == rfqNumber, cancellationToken))
        {
            rfqNumber = GenerateRfqNumber();
        }

        string title = !string.IsNullOrWhiteSpace(dto.Title)
            ? dto.Title.Trim()
            : $"RFQ for {product.Name} ({dto.Quantity:G29} {dto.UnitOfMeasurement.Trim()})";

        var rfq = new Entities.Rfq
        {
            RfqNumber = rfqNumber,
            ProductId = product.Id,
            BuyerMemberId = buyerMemberId,
            SupplierMemberId = product.MemberId,
            Title = title,
            Quantity = dto.Quantity,
            UnitOfMeasurement = dto.UnitOfMeasurement.Trim(),
            TargetPrice = dto.TargetPrice.HasValue && dto.TargetPrice.Value > 0 ? dto.TargetPrice.Value : null,
            RequiredDeliveryDateUtc = dto.RequiredDeliveryDateUtc,
            DeliveryLocation = dto.DeliveryLocation.Trim(),
            AdditionalSpecifications = dto.AdditionalSpecifications?.Trim(),
            AttachmentUrl = dto.AttachmentUrl?.Trim(),
            Status = RfqStatus.Open,
            CreatedAtUtc = DateTime.UtcNow,
            ProductInquiryId = dto.ProductInquiryId
        };

        _db.Rfqs.Add(rfq);
        await _db.SaveChangesAsync(cancellationToken);

        // Notify supplier about the new RFQ
        string buyerCompanyName = buyer.BusinessProfile?.CompanyName ?? buyer.FullName;
        await _notificationService.CreateNotificationAsync(
            recipientMemberId: product.MemberId,
            actorMemberId: buyerMemberId,
            eventType: NotificationEventType.RfqReceived,
            title: $"New RFQ #{rfq.RfqNumber}",
            message: $"{buyer.FullName} ({buyerCompanyName}) requested a quotation for {product.Name} ({dto.Quantity:G29} {dto.UnitOfMeasurement.Trim()})",
            referenceType: "rfq",
            referenceId: rfq.Id,
            cancellationToken: cancellationToken);

        var rfqDto = MapToRfqDto(rfq, buyer, product.Member, product, null, 0, buyerMemberId);
        return (true, "RFQ created successfully.", rfqDto);
    }

    public async Task<RfqListResponseDto> GetMyRfqsAsync(
        int buyerMemberId,
        RfqFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Rfqs
            .Include(r => r.Product)
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Quotations)
            .Where(r => r.BuyerMemberId == buyerMemberId);

        query = ApplyFilter(query, filter);

        int totalCount = await query.CountAsync(cancellationToken);
        int page = Math.Max(1, filter.Page);
        int pageSize = Math.Clamp(filter.PageSize, 1, 100);
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        if (totalPages < 1) totalPages = 1;

        var items = await query
            .OrderByDescending(r => r.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtoList = items.Select(r =>
        {
            var latestQuote = r.Quotations.OrderByDescending(q => q.Version).FirstOrDefault();
            return MapToRfqDto(r, r.BuyerMember, r.SupplierMember, r.Product, latestQuote, r.Quotations.Count, buyerMemberId);
        }).ToList();

        return new RfqListResponseDto(dtoList, totalCount, page, pageSize, totalPages);
    }

    public async Task<RfqListResponseDto> GetReceivedRfqsAsync(
        int supplierMemberId,
        RfqFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Rfqs
            .Include(r => r.Product)
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Quotations)
            .Where(r => r.SupplierMemberId == supplierMemberId);

        query = ApplyFilter(query, filter);

        int totalCount = await query.CountAsync(cancellationToken);
        int page = Math.Max(1, filter.Page);
        int pageSize = Math.Clamp(filter.PageSize, 1, 100);
        int totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        if (totalPages < 1) totalPages = 1;

        var items = await query
            .OrderByDescending(r => r.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtoList = items.Select(r =>
        {
            var latestQuote = r.Quotations.OrderByDescending(q => q.Version).FirstOrDefault();
            return MapToRfqDto(r, r.BuyerMember, r.SupplierMember, r.Product, latestQuote, r.Quotations.Count, supplierMemberId);
        }).ToList();

        return new RfqListResponseDto(dtoList, totalCount, page, pageSize, totalPages);
    }

    public async Task<(bool Success, string Message, RfqDto? Rfq)> GetRfqByIdAsync(
        int rfqId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var rfq = await _db.Rfqs
            .Include(r => r.Product)
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Quotations)
            .FirstOrDefaultAsync(r => r.Id == rfqId, cancellationToken);

        if (rfq == null)
        {
            return (false, "RFQ not found.", null);
        }

        if (!isAdmin && rfq.BuyerMemberId != currentMemberId && rfq.SupplierMemberId != currentMemberId)
        {
            return (false, "You are not authorized to view this RFQ.", null);
        }

        var latestQuote = rfq.Quotations.OrderByDescending(q => q.Version).FirstOrDefault();
        var dto = MapToRfqDto(rfq, rfq.BuyerMember, rfq.SupplierMember, rfq.Product, latestQuote, rfq.Quotations.Count, currentMemberId);
        return (true, "RFQ retrieved successfully.", dto);
    }

    public async Task<(bool Success, string Message, RfqDto? Rfq)> CancelRfqAsync(
        int rfqId,
        int buyerMemberId,
        CancellationToken cancellationToken = default)
    {
        var rfq = await _db.Rfqs
            .Include(r => r.Product)
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.Quotations)
            .FirstOrDefaultAsync(r => r.Id == rfqId, cancellationToken);

        if (rfq == null)
        {
            return (false, "RFQ not found.", null);
        }

        if (rfq.BuyerMemberId != buyerMemberId)
        {
            return (false, "Only the buyer who created this RFQ can cancel it.", null);
        }

        if (rfq.Status == RfqStatus.Closed)
        {
            return (false, "A closed RFQ cannot be cancelled.", null);
        }

        if (rfq.Status == RfqStatus.Cancelled)
        {
            return (false, "This RFQ is already cancelled.", null);
        }

        rfq.Status = RfqStatus.Cancelled;
        rfq.UpdatedAtUtc = DateTime.UtcNow;

        // Any active submitted quotes become expired/archived
        foreach (var q in rfq.Quotations.Where(q => q.Status == QuotationStatus.Submitted || q.Status == QuotationStatus.Draft))
        {
            q.Status = QuotationStatus.Expired;
        }

        await _db.SaveChangesAsync(cancellationToken);

        // Notify supplier
        string buyerCompanyName = rfq.BuyerMember.BusinessProfile?.CompanyName ?? rfq.BuyerMember.FullName;
        await _notificationService.CreateNotificationAsync(
            recipientMemberId: rfq.SupplierMemberId,
            actorMemberId: buyerMemberId,
            eventType: NotificationEventType.RfqStatusChanged,
            title: $"RFQ Cancelled #{rfq.RfqNumber}",
            message: $"{buyerCompanyName} cancelled RFQ #{rfq.RfqNumber}.",
            referenceType: "rfq",
            referenceId: rfq.Id,
            cancellationToken: cancellationToken);

        var latestQuote = rfq.Quotations.OrderByDescending(q => q.Version).FirstOrDefault();
        var dto = MapToRfqDto(rfq, rfq.BuyerMember, rfq.SupplierMember, rfq.Product, latestQuote, rfq.Quotations.Count, buyerMemberId);
        return (true, "RFQ cancelled successfully.", dto);
    }

    public async Task<(bool Success, string Message, QuotationDto? Quotation)> SubmitQuotationAsync(
        int rfqId,
        int supplierMemberId,
        SubmitQuotationDto dto,
        CancellationToken cancellationToken = default)
    {
        var rfq = await _db.Rfqs
            .Include(r => r.Product)
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(r => r.Id == rfqId, cancellationToken);

        if (rfq == null)
        {
            return (false, "RFQ not found.", null);
        }

        if (rfq.SupplierMemberId != supplierMemberId)
        {
            return (false, "Only the intended supplier can submit a quotation for this RFQ.", null);
        }

        if (rfq.Status == RfqStatus.Cancelled)
        {
            return (false, "Cannot submit a quotation for a cancelled RFQ.", null);
        }

        if (rfq.Status == RfqStatus.Closed)
        {
            return (false, "Cannot submit a quotation for a closed RFQ.", null);
        }

        if (dto.UnitPrice <= 0)
        {
            return (false, "Unit price must be greater than zero.", null);
        }

        if (dto.Quantity <= 0)
        {
            return (false, "Quotation quantity must be greater than zero.", null);
        }

        if (dto.TaxRatePercent < 0 || dto.TaxRatePercent > 100)
        {
            return (false, "Tax rate percent must be between 0% and 100%.", null);
        }

        if (dto.ShippingCharges < 0)
        {
            return (false, "Shipping charges cannot be negative.", null);
        }

        // Server-side financial calculations
        decimal subtotal = Math.Round(dto.UnitPrice * dto.Quantity, 2);
        decimal taxAmount = Math.Round((subtotal * dto.TaxRatePercent) / 100m, 2);
        decimal shipping = Math.Round(Math.Max(0m, dto.ShippingCharges), 2);
        decimal total = Math.Round(subtotal + taxAmount + shipping, 2);

        DateTime validUntil = dto.ValidUntilUtc.HasValue && dto.ValidUntilUtc.Value > DateTime.UtcNow
            ? dto.ValidUntilUtc.Value
            : DateTime.UtcNow.AddDays(30);

        // Check for existing quotation revision history
        var previousQuotes = await _db.Quotations
            .Where(q => q.RfqId == rfqId)
            .OrderByDescending(q => q.Version)
            .ToListAsync(cancellationToken);

        int version = 1;
        bool isRevision = false;
        if (previousQuotes.Count > 0)
        {
            version = previousQuotes.First().Version + 1;
            isRevision = true;

            // Transition previous active quotes to Revised
            foreach (var pq in previousQuotes.Where(q => q.Status == QuotationStatus.Submitted || q.Status == QuotationStatus.Draft))
            {
                pq.Status = QuotationStatus.Revised;
            }
        }

        string quoteNumber = GenerateQuotationNumber();
        while (await _db.Quotations.AnyAsync(q => q.QuotationNumber == quoteNumber, cancellationToken))
        {
            quoteNumber = GenerateQuotationNumber();
        }

        var quotation = new Quotation
        {
            RfqId = rfqId,
            QuotationNumber = quoteNumber,
            Version = version,
            SupplierMemberId = supplierMemberId,
            BuyerMemberId = rfq.BuyerMemberId,
            UnitPrice = dto.UnitPrice,
            Quantity = dto.Quantity,
            Subtotal = subtotal,
            TaxRatePercent = dto.TaxRatePercent,
            TaxAmount = taxAmount,
            ShippingCharges = shipping,
            TotalAmount = total,
            ValidUntilUtc = validUntil,
            EstimatedDeliveryTime = !string.IsNullOrWhiteSpace(dto.EstimatedDeliveryTime)
                ? dto.EstimatedDeliveryTime.Trim()
                : "7 to 10 Business Days",
            TermsAndConditions = dto.TermsAndConditions?.Trim(),
            DocumentUrl = dto.DocumentUrl?.Trim(),
            Status = QuotationStatus.Submitted,
            CreatedAtUtc = DateTime.UtcNow,
            SubmittedAtUtc = DateTime.UtcNow
        };

        _db.Quotations.Add(quotation);

        // Update RFQ status
        rfq.Status = RfqStatus.QuotationReceived;
        rfq.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        // Notify Buyer
        string supplierCompanyName = rfq.SupplierMember.BusinessProfile?.CompanyName ?? rfq.SupplierMember.FullName;
        var eventType = isRevision
            ? NotificationEventType.QuotationRevised
            : NotificationEventType.QuotationReceived;

        string title = isRevision
            ? $"Revised Quotation #{quotation.QuotationNumber} (v{quotation.Version})"
            : $"New Quotation #{quotation.QuotationNumber}";

        string message = $"{supplierCompanyName} submitted a quotation for RFQ #{rfq.RfqNumber} (Total: ₹{total:N2})";

        await _notificationService.CreateNotificationAsync(
            recipientMemberId: rfq.BuyerMemberId,
            actorMemberId: supplierMemberId,
            eventType: eventType,
            title: title,
            message: message,
            referenceType: "rfq",
            referenceId: rfq.Id,
            cancellationToken: cancellationToken);

        var quoteDto = MapToQuotationDto(quotation, rfq.RfqNumber, rfq.SupplierMember, rfq.BuyerMember);
        return (true, "Quotation submitted successfully.", quoteDto);
    }

    public async Task<List<QuotationDto>> GetQuotationsForRfqAsync(
        int rfqId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var rfq = await _db.Rfqs
            .Include(r => r.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(r => r.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(r => r.Id == rfqId, cancellationToken);

        if (rfq == null) return new List<QuotationDto>();

        if (!isAdmin && rfq.BuyerMemberId != currentMemberId && rfq.SupplierMemberId != currentMemberId)
        {
            return new List<QuotationDto>();
        }

        var quotes = await _db.Quotations
            .Include(q => q.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(q => q.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Where(q => q.RfqId == rfqId)
            .OrderByDescending(q => q.Version)
            .ToListAsync(cancellationToken);

        return quotes.Select(q => MapToQuotationDto(q, rfq.RfqNumber, q.SupplierMember, q.BuyerMember)).ToList();
    }

    public async Task<(bool Success, string Message, QuotationDto? Quotation)> GetQuotationByIdAsync(
        int quotationId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var quotation = await _db.Quotations
            .Include(q => q.Rfq)
            .Include(q => q.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(q => q.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quotation == null)
        {
            return (false, "Quotation not found.", null);
        }

        if (!isAdmin && quotation.BuyerMemberId != currentMemberId && quotation.SupplierMemberId != currentMemberId)
        {
            return (false, "You are not authorized to view this quotation.", null);
        }

        var dto = MapToQuotationDto(quotation, quotation.Rfq.RfqNumber, quotation.SupplierMember, quotation.BuyerMember);
        return (true, "Quotation retrieved successfully.", dto);
    }

    public async Task<(bool Success, string Message, QuotationDto? Quotation)> DecideQuotationAsync(
        int quotationId,
        int buyerMemberId,
        DecideQuotationDto dto,
        CancellationToken cancellationToken = default)
    {
        var quotation = await _db.Quotations
            .Include(q => q.Rfq)
            .Include(q => q.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(q => q.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(q => q.Id == quotationId, cancellationToken);

        if (quotation == null)
        {
            return (false, "Quotation not found.", null);
        }

        if (quotation.BuyerMemberId != buyerMemberId)
        {
            return (false, "Only the buyer associated with this RFQ can decide on quotations.", null);
        }

        if (quotation.Status == QuotationStatus.Accepted)
        {
            return (false, "This quotation has already been accepted.", null);
        }

        if (quotation.Status == QuotationStatus.Rejected)
        {
            return (false, "This quotation has already been rejected.", null);
        }

        if (quotation.Status == QuotationStatus.Expired)
        {
            return (false, "This quotation has expired and cannot be actioned.", null);
        }

        if (quotation.ValidUntilUtc < DateTime.UtcNow)
        {
            quotation.Status = QuotationStatus.Expired;
            await _db.SaveChangesAsync(cancellationToken);
            return (false, "This quotation has expired and can no longer be accepted.", null);
        }

        string decision = dto.Decision.Trim().ToLowerInvariant();
        string buyerCompanyName = quotation.BuyerMember.BusinessProfile?.CompanyName ?? quotation.BuyerMember.FullName;

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, QuotationDto? Quotation)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                if (decision == "accept")
                {
                    quotation.Status = QuotationStatus.Accepted;
                    quotation.DecidedAtUtc = DateTime.UtcNow;

                    // Close RFQ
                    quotation.Rfq.Status = RfqStatus.Closed;
                    quotation.Rfq.ClosedAtUtc = DateTime.UtcNow;
                    quotation.Rfq.UpdatedAtUtc = DateTime.UtcNow;

                    // Mark any other open quotations for this RFQ as rejected
                    var otherQuotes = await _db.Quotations
                        .Where(q => q.RfqId == quotation.RfqId && q.Id != quotation.Id && (q.Status == QuotationStatus.Submitted || q.Status == QuotationStatus.Draft))
                        .ToListAsync(cancellationToken);

                    foreach (var oq in otherQuotes)
                    {
                        oq.Status = QuotationStatus.Rejected;
                        oq.RejectionReason = "Alternative quotation accepted by buyer.";
                        oq.DecidedAtUtc = DateTime.UtcNow;
                    }

                    await _db.SaveChangesAsync(cancellationToken);
                    await transaction.CommitAsync(cancellationToken);

                    // Notify supplier
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: quotation.SupplierMemberId,
                        actorMemberId: buyerMemberId,
                        eventType: NotificationEventType.QuotationAccepted,
                        title: $"Quotation Accepted #{quotation.QuotationNumber}",
                        message: $"{buyerCompanyName} accepted your quotation for RFQ #{quotation.Rfq.RfqNumber} (Total: ₹{quotation.TotalAmount:N2})",
                        referenceType: "rfq",
                        referenceId: quotation.RfqId,
                        cancellationToken: cancellationToken);

                    var quoteDto = MapToQuotationDto(quotation, quotation.Rfq.RfqNumber, quotation.SupplierMember, quotation.BuyerMember);
                    return (true, "Quotation accepted successfully. RFQ closed.", quoteDto);
                }
                else if (decision == "reject")
                {
                    quotation.Status = QuotationStatus.Rejected;
                    quotation.RejectionReason = !string.IsNullOrWhiteSpace(dto.Notes)
                        ? dto.Notes.Trim()
                        : "Declined by buyer.";
                    quotation.DecidedAtUtc = DateTime.UtcNow;

                    await _db.SaveChangesAsync(cancellationToken);
                    await transaction.CommitAsync(cancellationToken);

                    // Notify supplier
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: quotation.SupplierMemberId,
                        actorMemberId: buyerMemberId,
                        eventType: NotificationEventType.QuotationRejected,
                        title: $"Quotation Declined #{quotation.QuotationNumber}",
                        message: $"{buyerCompanyName} declined quotation for RFQ #{quotation.Rfq.RfqNumber}.",
                        referenceType: "rfq",
                        referenceId: quotation.RfqId,
                        cancellationToken: cancellationToken);

                    var quoteDto = MapToQuotationDto(quotation, quotation.Rfq.RfqNumber, quotation.SupplierMember, quotation.BuyerMember);
                    return (true, "Quotation rejected.", quoteDto);
                }
                else if (decision == "requestrevision" || decision == "revision")
                {
                    if (string.IsNullOrWhiteSpace(dto.Notes))
                    {
                        return (false, "Please provide revision notes explaining the requested changes.", null);
                    }

                    quotation.Status = QuotationStatus.Revised;
                    quotation.RevisionNotes = dto.Notes.Trim();
                    quotation.DecidedAtUtc = DateTime.UtcNow;

                    await _db.SaveChangesAsync(cancellationToken);
                    await transaction.CommitAsync(cancellationToken);

                    // Notify supplier
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: quotation.SupplierMemberId,
                        actorMemberId: buyerMemberId,
                        eventType: NotificationEventType.QuotationRevisionRequested,
                        title: $"Revision Requested #{quotation.QuotationNumber}",
                        message: $"{buyerCompanyName} requested revision on RFQ #{quotation.Rfq.RfqNumber}: {dto.Notes.Trim()}",
                        referenceType: "rfq",
                        referenceId: quotation.RfqId,
                        cancellationToken: cancellationToken);

                    var quoteDto = MapToQuotationDto(quotation, quotation.Rfq.RfqNumber, quotation.SupplierMember, quotation.BuyerMember);
                    return (true, "Revision requested successfully from supplier.", quoteDto);
                }
                else
                {
                    return (false, "Invalid quotation decision. Must be 'Accept', 'Reject', or 'RequestRevision'.", null);
                }
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Error executing quotation decision {Decision} on quote #{QuoteId}", dto.Decision, quotationId);
                return (false, "Failed to process quotation decision. Please try again.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, string? AttachmentUrl)> UploadAttachmentAsync(
        int currentMemberId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return (false, "No file uploaded.", null);
        }

        const long maxBytes = 15 * 1024 * 1024; // 15MB
        if (file.Length > maxBytes)
        {
            return (false, "Attachment exceeds maximum size of 15MB.", null);
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExts = new[] { ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".jpg", ".jpeg", ".png" };
        if (!allowedExts.Contains(ext))
        {
            return (false, "Unsupported file format. Allowed: PDF, Word, Excel, JPG, PNG.", null);
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(AppContext.BaseDirectory, "wwwroot");
        var dir = Path.Combine(webRoot, "uploads", "rfq-attachments");
        if (!System.IO.Directory.Exists(dir))
        {
            System.IO.Directory.CreateDirectory(dir);
        }

        var safeFileName = $"rfq_{currentMemberId}_{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(dir, safeFileName);

        using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        var relativeUrl = $"/uploads/rfq-attachments/{safeFileName}";
        return (true, "Attachment uploaded successfully.", relativeUrl);
    }

    // --- Helper Methods ---

    private static IQueryable<Entities.Rfq> ApplyFilter(IQueryable<Entities.Rfq> query, RfqFilterDto filter)
    {
        if (!string.IsNullOrWhiteSpace(filter.Status) && filter.Status != "All")
        {
            if (Enum.TryParse<RfqStatus>(filter.Status, true, out var parsedStatus))
            {
                query = query.Where(r => r.Status == parsedStatus);
            }
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            string term = filter.Search.Trim().ToLower();
            query = query.Where(r =>
                r.RfqNumber.ToLower().Contains(term) ||
                r.Title.ToLower().Contains(term) ||
                r.Product.Name.ToLower().Contains(term) ||
                (r.BuyerMember.BusinessProfile != null && r.BuyerMember.BusinessProfile.CompanyName.ToLower().Contains(term)) ||
                (r.SupplierMember.BusinessProfile != null && r.SupplierMember.BusinessProfile.CompanyName.ToLower().Contains(term))
            );
        }

        return query;
    }

    private static string GenerateRfqNumber()
    {
        return $"RFQ-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6]}".ToUpperInvariant();
    }

    private static string GenerateQuotationNumber()
    {
        return $"QT-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6]}".ToUpperInvariant();
    }

    private static RfqDto MapToRfqDto(
        Entities.Rfq rfq,
        Member buyer,
        Member supplier,
        Product product,
        Quotation? latestQuote,
        int quotationsCount,
        int currentMemberId)
    {
        string buyerCompany = buyer.BusinessProfile?.CompanyName ?? buyer.FullName;
        string supplierCompany = supplier.BusinessProfile?.CompanyName ?? supplier.FullName;

        QuotationDto? quoteDto = null;
        if (latestQuote != null)
        {
            quoteDto = MapToQuotationDto(latestQuote, rfq.RfqNumber, supplier, buyer);
        }

        return new RfqDto(
            Id: rfq.Id,
            RfqNumber: rfq.RfqNumber,
            ProductId: rfq.ProductId,
            ProductName: product.Name,
            ProductThumbnailUrl: product.ImageUrl,
            BuyerMemberId: rfq.BuyerMemberId,
            BuyerFullName: buyer.FullName,
            BuyerCompanyName: buyerCompany,
            BuyerEmail: buyer.Email,
            BuyerPhone: buyer.PhoneNumber,
            SupplierMemberId: rfq.SupplierMemberId,
            SupplierFullName: supplier.FullName,
            SupplierCompanyName: supplierCompany,
            Title: rfq.Title,
            Quantity: rfq.Quantity,
            UnitOfMeasurement: rfq.UnitOfMeasurement,
            TargetPrice: rfq.TargetPrice,
            RequiredDeliveryDateUtc: rfq.RequiredDeliveryDateUtc,
            DeliveryLocation: rfq.DeliveryLocation,
            AdditionalSpecifications: rfq.AdditionalSpecifications,
            AttachmentUrl: rfq.AttachmentUrl,
            Status: rfq.Status.ToString(),
            CreatedAtUtc: rfq.CreatedAtUtc,
            UpdatedAtUtc: rfq.UpdatedAtUtc,
            ClosedAtUtc: rfq.ClosedAtUtc,
            QuotationsCount: quotationsCount,
            LatestQuotation: quoteDto,
            IsBuyer: rfq.BuyerMemberId == currentMemberId,
            IsSupplier: rfq.SupplierMemberId == currentMemberId
        );
    }

    private static QuotationDto MapToQuotationDto(
        Quotation q,
        string rfqNumber,
        Member supplier,
        Member buyer)
    {
        string supplierCompany = supplier.BusinessProfile?.CompanyName ?? supplier.FullName;
        string buyerCompany = buyer.BusinessProfile?.CompanyName ?? buyer.FullName;

        return new QuotationDto(
            Id: q.Id,
            RfqId: q.RfqId,
            RfqNumber: rfqNumber,
            QuotationNumber: q.QuotationNumber,
            Version: q.Version,
            SupplierMemberId: q.SupplierMemberId,
            SupplierName: supplier.FullName,
            SupplierCompanyName: supplierCompany,
            BuyerMemberId: q.BuyerMemberId,
            BuyerName: buyer.FullName,
            BuyerCompanyName: buyerCompany,
            UnitPrice: q.UnitPrice,
            Quantity: q.Quantity,
            Subtotal: q.Subtotal,
            TaxRatePercent: q.TaxRatePercent,
            TaxAmount: q.TaxAmount,
            ShippingCharges: q.ShippingCharges,
            TotalAmount: q.TotalAmount,
            ValidUntilUtc: q.ValidUntilUtc,
            EstimatedDeliveryTime: q.EstimatedDeliveryTime,
            TermsAndConditions: q.TermsAndConditions,
            DocumentUrl: q.DocumentUrl,
            Status: q.Status.ToString(),
            RejectionReason: q.RejectionReason,
            RevisionNotes: q.RevisionNotes,
            CreatedAtUtc: q.CreatedAtUtc,
            SubmittedAtUtc: q.SubmittedAtUtc,
            DecidedAtUtc: q.DecidedAtUtc,
            IsExpired: q.ValidUntilUtc < DateTime.UtcNow
        );
    }
}

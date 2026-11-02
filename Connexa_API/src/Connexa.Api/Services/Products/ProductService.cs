using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Services.Products;

public class ProductService : IProductService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ILogger<ProductService> _logger;
    private readonly INotificationService? _notificationService;

    public ProductService(
        ConnexaDbContext dbContext,
        ILogger<ProductService> logger,
        INotificationService? notificationService = null)
    {
        _dbContext = dbContext;
        _logger = logger;
        _notificationService = notificationService;
    }

    public async Task<List<ProductDto>> GetMemberProductsAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var products = await _dbContext.Products
            .AsNoTracking()
            .Where(p => p.MemberId == memberId && p.IsActive)
            .Include(p => p.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(bp => bp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.TraderProfile)
            .Include(p => p.Inquiries)
            .OrderByDescending(p => p.CreatedAtUtc)
            .ToListAsync(cancellationToken);

        return products.Select(p => MapToProductDto(p, memberId)).ToList();
    }

    public async Task<ProductCatalogResponseDto> GetCatalogProductsAsync(
        ProductFilterDto filter,
        int? viewerMemberId = null,
        CancellationToken cancellationToken = default)
    {
        var query = _dbContext.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.Member.IsActive)
            .Include(p => p.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(bp => bp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.TraderProfile)
            .Include(p => p.Inquiries)
            .AsQueryable();


        // 1. Industry Filter
        if (filter.IndustryId.HasValue && filter.IndustryId.Value > 0)
        {
            var targetId = filter.IndustryId.Value;
            query = query.Where(p =>
                p.IndustryId == targetId ||
                (!p.IndustryId.HasValue && (
                    (p.Member.BusinessProfile != null && p.Member.BusinessProfile.IndustryId == targetId) ||
                    (p.Member.ContractorProfile != null && p.Member.ContractorProfile.IndustryId == targetId)
                ))
            );
        }

        // 2. Category Filter
        if (!string.IsNullOrWhiteSpace(filter.Category) && !filter.Category.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            var cat = filter.Category.Trim();
            query = query.Where(p => p.Category == cat || (p.SubCategory != null && p.SubCategory == cat));
        }

        // 3. SubCategory Filter
        if (!string.IsNullOrWhiteSpace(filter.SubCategory) && !filter.SubCategory.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            var subCat = filter.SubCategory.Trim();
            query = query.Where(p => p.SubCategory != null && p.SubCategory == subCat);
        }

        // 4. Keyword Search
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var s = filter.Search.Trim().ToLower();
            query = query.Where(p =>
                p.Name.ToLower().Contains(s) ||
                p.Description.ToLower().Contains(s) ||
                p.Category.ToLower().Contains(s) ||
                (p.SubCategory != null && p.SubCategory.ToLower().Contains(s)) ||
                (p.TagsJson != null && p.TagsJson.ToLower().Contains(s)) ||
                (p.Member.BusinessProfile != null && p.Member.BusinessProfile.CompanyName.ToLower().Contains(s)) ||
                (p.Member.TraderProfile != null && p.Member.TraderProfile.TradingName.ToLower().Contains(s)) ||
                (p.Member.ContractorProfile != null && p.Member.ContractorProfile.WorkName.ToLower().Contains(s)) ||
                p.Member.FullName.ToLower().Contains(s));
        }

        // 5. MemberId filter
        if (filter.MemberId.HasValue && filter.MemberId.Value > 0)
        {
            query = query.Where(p => p.MemberId == filter.MemberId.Value);
        }

        // 5b. VerifiedOnly filter
        if (filter.VerifiedOnly == true)
        {
            query = query.Where(p => p.Member.BusinessProfile != null &&
                p.Member.BusinessProfile.VerificationStatus == Entities.BusinessVerificationStatus.Approved);
        }

        // 6. Sorting
        query = (filter.SortBy?.ToLowerInvariant()) switch
        {
            "name_asc" => query.OrderBy(p => p.Name),
            "name_desc" => query.OrderByDescending(p => p.Name),
            "popular" => query.OrderByDescending(p => p.ViewCount).ThenByDescending(p => p.CreatedAtUtc),
            _ => query.OrderByDescending(p => p.CreatedAtUtc)
        };

        var totalCount = await query.CountAsync(cancellationToken);
        var page = Math.Max(1, filter.Page);
        var pageSize = Math.Clamp(filter.PageSize > 0 ? filter.PageSize : (filter.Limit ?? 12), 1, 100);
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        var products = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = products.Select(p => MapToProductDto(p, viewerMemberId)).ToList();

        return new ProductCatalogResponseDto(dtos, totalCount, page, pageSize, totalPages);
    }

    public async Task<List<ProductDto>> GetAllProductsAsync(
        string? search = null,
        string? category = null,
        int? memberId = null,
        int limit = 50,
        int? viewerMemberId = null,
        CancellationToken cancellationToken = default)
    {
        var filter = new ProductFilterDto
        {
            Search = search,
            Category = category,
            MemberId = memberId,
            Page = 1,
            PageSize = limit,
            Limit = limit
        };

        var catalog = await GetCatalogProductsAsync(filter, viewerMemberId, cancellationToken);
        return catalog.Items;
    }

    public async Task<ProductDto?> GetProductByIdAsync(int id, int? viewerMemberId = null, CancellationToken cancellationToken = default)
    {
        var product = await _dbContext.Products
            .Include(p => p.Industry)
            .Include(p => p.Inquiries)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(bp => bp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.TraderProfile)
            .FirstOrDefaultAsync(p => p.Id == id && p.IsActive, cancellationToken);


        if (product == null)
        {
            return null;
        }

        // Increment view count if viewer is not the product owner
        if (viewerMemberId.HasValue && viewerMemberId.Value != product.MemberId)
        {
            product.ViewCount++;
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return MapToProductDto(product, viewerMemberId);
    }


    public async Task<(bool Success, string Message, ProductDto? Product)> CreateProductAsync(int memberId, CreateProductRequestDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return (false, "Product name is required.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.Description))
        {
            return (false, "Product description is required.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.Category))
        {
            return (false, "Product category is required.", null);
        }

        var memberExists = await _dbContext.Members.AnyAsync(m => m.Id == memberId && m.IsActive, cancellationToken);
        if (!memberExists)
        {
            return (false, "Member profile not found or inactive.", null);
        }

        var product = new Product
        {
            MemberId = memberId,
            Name = dto.Name.Trim(),
            Description = dto.Description.Trim(),
            Category = dto.Category.Trim(),
            SubCategory = string.IsNullOrWhiteSpace(dto.SubCategory) ? null : dto.SubCategory.Trim(),
            TagsJson = dto.Tags != null && dto.Tags.Count > 0 ? JsonSerializer.Serialize(dto.Tags) : null,
            ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim(),
            SpecificationsJson = dto.Specifications != null && dto.Specifications.Count > 0 ? JsonSerializer.Serialize(dto.Specifications) : null,
            IndustryId = dto.IndustryId.HasValue && dto.IndustryId.Value > 0 ? dto.IndustryId.Value : null,
            ViewCount = 0,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        _dbContext.Products.Add(product);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var resultDto = await GetProductByIdAsync(product.Id, memberId, cancellationToken);
        return (true, "Product created successfully.", resultDto);
    }

    public async Task<(bool Success, string Message, ProductDto? Product)> UpdateProductAsync(int memberId, int id, UpdateProductRequestDto dto, CancellationToken cancellationToken = default)
    {
        var product = await _dbContext.Products
            .Include(p => p.Inquiries)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (product == null || !product.IsActive)
        {
            return (false, "Product not found.", null);
        }

        if (product.MemberId != memberId)
        {
            return (false, "Unauthorized: you do not own this product.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return (false, "Product name cannot be empty.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.Description))
        {
            return (false, "Product description cannot be empty.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.Category))
        {
            return (false, "Product category cannot be empty.", null);
        }

        product.Name = dto.Name.Trim();
        product.Description = dto.Description.Trim();
        product.Category = dto.Category.Trim();
        product.SubCategory = string.IsNullOrWhiteSpace(dto.SubCategory) ? null : dto.SubCategory.Trim();
        product.TagsJson = dto.Tags != null && dto.Tags.Count > 0 ? JsonSerializer.Serialize(dto.Tags) : null;
        product.ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim();
        product.SpecificationsJson = dto.Specifications != null && dto.Specifications.Count > 0 ? JsonSerializer.Serialize(dto.Specifications) : null;
        if (dto.IndustryId.HasValue)
        {
            product.IndustryId = dto.IndustryId.Value > 0 ? dto.IndustryId.Value : null;
        }
        product.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        var resultDto = await GetProductByIdAsync(product.Id, memberId, cancellationToken);
        return (true, "Product updated successfully.", resultDto);
    }


    public async Task<(bool Success, string Message)> DeleteProductAsync(int memberId, int id, CancellationToken cancellationToken = default)
    {
        var product = await _dbContext.Products.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (product == null || !product.IsActive)
        {
            return (false, "Product not found.");
        }

        if (product.MemberId != memberId)
        {
            return (false, "Unauthorized: you do not own this product.");
        }

        product.IsActive = false;
        product.UpdatedAtUtc = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return (true, "Product deleted successfully.");
    }

    public async Task<(bool Success, string Message, ProductInquiryDto? Inquiry)> SendInquiryAsync(int senderMemberId, int productId, CreateProductInquiryDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Message))
        {
            return (false, "Inquiry message is required.", null);
        }

        var product = await _dbContext.Products
            .Include(p => p.Member)
            .FirstOrDefaultAsync(p => p.Id == productId && p.IsActive, cancellationToken);

        if (product == null)
        {
            return (false, "Product not found or is no longer available.", null);
        }

        if (product.MemberId == senderMemberId)
        {
            return (false, "You cannot send an inquiry for your own product.", null);
        }

        var sender = await _dbContext.Members
            .Include(m => m.BusinessProfile)
            .Include(m => m.TraderProfile)
            .Include(m => m.ContractorProfile)
            .FirstOrDefaultAsync(m => m.Id == senderMemberId && m.IsActive, cancellationToken);

        if (sender == null)
        {
            return (false, "Sender member profile not found.", null);
        }

        var subject = string.IsNullOrWhiteSpace(dto.Subject)
            ? $"Inquiry regarding {product.Name}"
            : dto.Subject.Trim();

        var formattedMessage = dto.Message.Trim();
        if (!string.IsNullOrWhiteSpace(dto.QuantityRequirement))
        {
            formattedMessage += $"\n\n[Requirement / Quantity: {dto.QuantityRequirement.Trim()}]";
        }
        if (!string.IsNullOrWhiteSpace(dto.ContactPhone) || !string.IsNullOrWhiteSpace(dto.ContactEmail))
        {
            var contactInfo = $"{dto.ContactPhone?.Trim()} {dto.ContactEmail?.Trim()}".Trim();
            if (!string.IsNullOrWhiteSpace(contactInfo))
            {
                formattedMessage += $"\n[Preferred Contact: {contactInfo}]";
            }
        }

        // Deduplication check: prevent duplicate submissions within 60 seconds
        var cutoff = DateTime.UtcNow.AddSeconds(-60);
        var existingInquiry = await _dbContext.ProductInquiries
            .FirstOrDefaultAsync(pi =>
                pi.ProductId == productId &&
                pi.SenderMemberId == senderMemberId &&
                pi.Subject == subject &&
                pi.CreatedAtUtc >= cutoff, cancellationToken);

        var senderCompanyName = sender.BusinessProfile?.CompanyName
            ?? sender.TraderProfile?.TradingName
            ?? sender.ContractorProfile?.WorkName
            ?? sender.FullName;

        if (existingInquiry != null)
        {
            var existingDto = new ProductInquiryDto(
                existingInquiry.Id,
                product.Id,
                product.Name,
                senderMemberId,
                sender.FullName,
                senderCompanyName,
                product.MemberId,
                existingInquiry.Subject,
                existingInquiry.Message,
                existingInquiry.Status,
                existingInquiry.CreatedAtUtc,
                QuantityRequirement: dto.QuantityRequirement,
                ContactPhone: dto.ContactPhone,
                ContactEmail: dto.ContactEmail,
                RespondedAtUtc: existingInquiry.RespondedAtUtc
            );

            return (true, "Product inquiry sent successfully.", existingDto);
        }

        var inquiry = new ProductInquiry
        {
            ProductId = productId,
            SenderMemberId = senderMemberId,
            RecipientMemberId = product.MemberId,
            Subject = subject,
            Message = formattedMessage,
            Status = "Pending",
            CreatedAtUtc = DateTime.UtcNow
        };

        _dbContext.ProductInquiries.Add(inquiry);
        await _dbContext.SaveChangesAsync(cancellationToken);

        if (_notificationService != null)
        {
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: product.MemberId,
                actorMemberId: senderMemberId,
                eventType: NotificationEventType.ProductInquiryReceived,
                title: "New Product Inquiry",
                message: $"{sender.FullName} sent an inquiry for {product.Name}.",
                referenceType: "inquiry",
                referenceId: inquiry.Id,
                cancellationToken: cancellationToken
            );
        }

        var resultDto = new ProductInquiryDto(
            inquiry.Id,
            product.Id,
            product.Name,
            senderMemberId,
            sender.FullName,
            senderCompanyName,
            product.MemberId,
            inquiry.Subject,
            inquiry.Message,
            inquiry.Status,
            inquiry.CreatedAtUtc,
            QuantityRequirement: dto.QuantityRequirement,
            ContactPhone: dto.ContactPhone,
            ContactEmail: dto.ContactEmail
        );

        return (true, "Product inquiry sent successfully.", resultDto);
    }

    public async Task<List<ProductInquiryDto>> GetReceivedInquiriesAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var inquiries = await _dbContext.ProductInquiries
            .AsNoTracking()
            .Where(pi => pi.RecipientMemberId == memberId)
            .Include(pi => pi.Product)
            .Include(pi => pi.SenderMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(pi => pi.SenderMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(pi => pi.SenderMember)
                .ThenInclude(m => m.ContractorProfile)
            .OrderByDescending(pi => pi.CreatedAtUtc)
            .ToListAsync(cancellationToken);

        return inquiries.Select(pi =>
        {
            var senderCompanyName = pi.SenderMember.BusinessProfile?.CompanyName
                ?? pi.SenderMember.TraderProfile?.TradingName
                ?? pi.SenderMember.ContractorProfile?.WorkName
                ?? pi.SenderMember.FullName;

            var parsed = ParseInquiryDetails(pi.Message);

            return new ProductInquiryDto(
                pi.Id,
                pi.ProductId,
                pi.Product.Name,
                pi.SenderMemberId,
                pi.SenderMember.FullName,
                senderCompanyName,
                pi.RecipientMemberId,
                pi.Subject,
                parsed.CleanMessage,
                pi.Status,
                pi.CreatedAtUtc,
                QuantityRequirement: parsed.QuantityRequirement,
                ContactPhone: parsed.ContactPhone ?? pi.SenderMember.PhoneNumber,
                ContactEmail: parsed.ContactEmail ?? pi.SenderMember.Email,
                RespondedAtUtc: pi.RespondedAtUtc,
                ResponseMessage: pi.ResponseMessage,
                ProductThumbnailUrl: pi.Product.ImageUrl
            );
        }).ToList();
    }

    public async Task<List<ProductInquiryDto>> GetSentInquiriesAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var inquiries = await _dbContext.ProductInquiries
            .AsNoTracking()
            .Where(pi => pi.SenderMemberId == memberId)
            .Include(pi => pi.Product)
            .Include(pi => pi.RecipientMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(pi => pi.RecipientMember)
                .ThenInclude(m => m.TraderProfile)
            .Include(pi => pi.RecipientMember)
                .ThenInclude(m => m.ContractorProfile)
            .Include(pi => pi.SenderMember)
            .OrderByDescending(pi => pi.CreatedAtUtc)
            .ToListAsync(cancellationToken);

        return inquiries.Select(pi =>
        {
            var recipientCompanyName = pi.RecipientMember.BusinessProfile?.CompanyName
                ?? pi.RecipientMember.TraderProfile?.TradingName
                ?? pi.RecipientMember.ContractorProfile?.WorkName
                ?? pi.RecipientMember.FullName;

            var parsed = ParseInquiryDetails(pi.Message);

            return new ProductInquiryDto(
                pi.Id,
                pi.ProductId,
                pi.Product.Name,
                pi.SenderMemberId,
                pi.SenderMember.FullName,
                string.Empty,
                pi.RecipientMemberId,
                pi.Subject,
                parsed.CleanMessage,
                pi.Status,
                pi.CreatedAtUtc,
                RecipientCompanyName: recipientCompanyName,
                QuantityRequirement: parsed.QuantityRequirement,
                ContactPhone: parsed.ContactPhone,
                ContactEmail: parsed.ContactEmail,
                RespondedAtUtc: pi.RespondedAtUtc,
                ResponseMessage: pi.ResponseMessage,
                ProductThumbnailUrl: pi.Product.ImageUrl
            );
        }).ToList();
    }

    public async Task<ProductInquiryDto?> GetInquiryByIdAsync(int inquiryId, int memberId, CancellationToken cancellationToken = default)
    {
        var inquiry = await _dbContext.ProductInquiries
            .Include(pi => pi.Product)
            .Include(pi => pi.SenderMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(pi => pi.RecipientMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(pi => pi.Id == inquiryId, cancellationToken);

        if (inquiry == null) return null;

        // Authorization check: Only the sender or the recipient is authorized to view this inquiry
        if (inquiry.SenderMemberId != memberId && inquiry.RecipientMemberId != memberId)
        {
            return null;
        }

        // Auto-mark as read if viewed by recipient
        if (inquiry.RecipientMemberId == memberId && inquiry.Status == "Pending")
        {
            inquiry.Status = "Read";
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        var senderCompanyName = inquiry.SenderMember.BusinessProfile?.CompanyName
            ?? inquiry.SenderMember.FullName;
        var recipientCompanyName = inquiry.RecipientMember.BusinessProfile?.CompanyName
            ?? inquiry.RecipientMember.FullName;

        var parsed = ParseInquiryDetails(inquiry.Message);

        string? contactPhone = null;
        string? contactEmail = null;
        if (inquiry.RecipientMemberId == memberId)
        {
            // Owner is authorized to view sender contact info
            contactPhone = parsed.ContactPhone ?? inquiry.SenderMember.PhoneNumber;
            contactEmail = parsed.ContactEmail ?? inquiry.SenderMember.Email;
        }
        else if (inquiry.SenderMemberId == memberId)
        {
            // Sender sees their own submitted contact info
            contactPhone = parsed.ContactPhone;
            contactEmail = parsed.ContactEmail;
        }

        return new ProductInquiryDto(
            inquiry.Id,
            inquiry.ProductId,
            inquiry.Product.Name,
            inquiry.SenderMemberId,
            inquiry.SenderMember.FullName,
            senderCompanyName,
            inquiry.RecipientMemberId,
            inquiry.Subject,
            parsed.CleanMessage,
            inquiry.Status,
            inquiry.CreatedAtUtc,
            RecipientCompanyName: recipientCompanyName,
            QuantityRequirement: parsed.QuantityRequirement,
            ContactPhone: contactPhone,
            ContactEmail: contactEmail,
            RespondedAtUtc: inquiry.RespondedAtUtc,
            ResponseMessage: inquiry.ResponseMessage,
            ProductThumbnailUrl: inquiry.Product.ImageUrl
        );
    }

    public async Task<(bool Success, string Message, ProductInquiryDto? Inquiry)> RespondToInquiryAsync(int memberId, int inquiryId, RespondToInquiryDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.ResponseMessage))
        {
            return (false, "Response message cannot be empty.", null);
        }

        var inquiry = await _dbContext.ProductInquiries
            .Include(pi => pi.Product)
            .Include(pi => pi.SenderMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(pi => pi.RecipientMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(pi => pi.Id == inquiryId, cancellationToken);

        if (inquiry == null)
        {
            return (false, "Inquiry not found.", null);
        }

        // Only the product owner (recipient) can respond to the inquiry
        if (inquiry.RecipientMemberId != memberId)
        {
            return (false, "You are not authorized to respond to this inquiry.", null);
        }

        inquiry.ResponseMessage = dto.ResponseMessage.Trim();
        inquiry.Status = "Responded";
        inquiry.RespondedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        var parsed = ParseInquiryDetails(inquiry.Message);
        var senderCompanyName = inquiry.SenderMember.BusinessProfile?.CompanyName
            ?? inquiry.SenderMember.FullName;
        var recipientCompanyName = inquiry.RecipientMember.BusinessProfile?.CompanyName
            ?? inquiry.RecipientMember.FullName;

        if (_notificationService != null)
        {
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: inquiry.SenderMemberId,
                actorMemberId: memberId,
                eventType: NotificationEventType.ProductInquiryResponded,
                title: "Inquiry Response Received",
                message: $"{recipientCompanyName} responded to your inquiry on {inquiry.Product.Name}.",
                referenceType: "inquiry",
                referenceId: inquiry.Id,
                cancellationToken: cancellationToken
            );
        }

        var resultDto = new ProductInquiryDto(
            inquiry.Id,
            inquiry.ProductId,
            inquiry.Product.Name,
            inquiry.SenderMemberId,
            inquiry.SenderMember.FullName,
            senderCompanyName,
            inquiry.RecipientMemberId,
            inquiry.Subject,
            parsed.CleanMessage,
            inquiry.Status,
            inquiry.CreatedAtUtc,
            RecipientCompanyName: recipientCompanyName,
            QuantityRequirement: parsed.QuantityRequirement,
            ContactPhone: parsed.ContactPhone ?? inquiry.SenderMember.PhoneNumber,
            ContactEmail: parsed.ContactEmail ?? inquiry.SenderMember.Email,
            RespondedAtUtc: inquiry.RespondedAtUtc,
            ResponseMessage: inquiry.ResponseMessage,
            ProductThumbnailUrl: inquiry.Product.ImageUrl
        );

        return (true, "Response sent successfully.", resultDto);
    }

    private static (string CleanMessage, string? QuantityRequirement, string? ContactPhone, string? ContactEmail) ParseInquiryDetails(string rawMessage)
    {
        if (string.IsNullOrWhiteSpace(rawMessage))
        {
            return (string.Empty, null, null, null);
        }

        var clean = rawMessage;
        string? quantity = null;
        string? phone = null;
        string? email = null;

        var reqMatch = System.Text.RegularExpressions.Regex.Match(rawMessage, @"\[Requirement\s*/\s*Quantity:\s*(.*?)\]", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (reqMatch.Success)
        {
            quantity = reqMatch.Groups[1].Value.Trim();
            clean = clean.Replace(reqMatch.Value, string.Empty);
        }

        var contactMatch = System.Text.RegularExpressions.Regex.Match(rawMessage, @"\[Preferred Contact:\s*(.*?)\]", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (contactMatch.Success)
        {
            var rawContact = contactMatch.Groups[1].Value.Trim();
            clean = clean.Replace(contactMatch.Value, string.Empty);

            var parts = rawContact.Split(new[] { ' ', ',', ';' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var part in parts)
            {
                if (part.Contains('@'))
                {
                    email = part;
                }
                else if (phone == null && part.Length >= 6)
                {
                    phone = part;
                }
            }
        }

        return (clean.Trim(), quantity, phone, email);
    }

    public async Task<DashboardStatsDto> GetDashboardStatsAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var myProductsCount = await _dbContext.Products
            .CountAsync(p => p.MemberId == memberId && p.IsActive, cancellationToken);

        var companyViewsCount = await _dbContext.ProfileViews
            .CountAsync(pv => pv.ViewedMemberId == memberId, cancellationToken);

        var productViewsSum = await _dbContext.Products
            .Where(p => p.MemberId == memberId && p.IsActive)
            .SumAsync(p => (int?)p.ViewCount, cancellationToken);
        var productViewsCount = productViewsSum ?? 0;

        var connectionRequestsCount = await _dbContext.MemberConnections
            .CountAsync(c => c.RecipientMemberId == memberId && c.Status == ConnectionStatusEnum.Pending, cancellationToken);

        var inquiriesCount = await _dbContext.ProductInquiries
            .CountAsync(pi => pi.RecipientMemberId == memberId, cancellationToken);

        var unreadNotificationsCount = _notificationService != null
            ? await _notificationService.GetUnreadCountAsync(memberId, cancellationToken)
            : (connectionRequestsCount + inquiriesCount);

        return new DashboardStatsDto(
            myProductsCount,
            companyViewsCount,
            productViewsCount,
            connectionRequestsCount,
            unreadNotificationsCount,
            inquiriesCount
        );
    }

    public async Task<List<RecommendedCompanyDto>> GetRecommendedCompaniesAsync(int memberId, int limit = 5, CancellationToken cancellationToken = default)
    {
        // 1. Get current member's industry / group / category for relevance matching
        var currentMember = await _dbContext.Members
            .AsNoTracking()
            .Include(m => m.BusinessProfile)
            .Include(m => m.ContractorProfile)
            .Include(m => m.TraderProfile)
            .FirstOrDefaultAsync(m => m.Id == memberId, cancellationToken);

        int targetIndustryId = currentMember?.BusinessProfile?.IndustryId
            ?? currentMember?.ContractorProfile?.IndustryId
            ?? 0;

        int targetGroupId = currentMember?.BusinessProfile?.BusinessGroupId
            ?? currentMember?.ContractorProfile?.BusinessGroupId
            ?? 0;

        // 2. Fetch candidates excluding current member
        var rawCandidates = await _dbContext.Members
            .AsNoTracking()
            .Where(m => m.Id != memberId && m.IsActive)
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.Industry)
            .Include(m => m.BusinessProfile)
                .ThenInclude(b => b!.Category)
            .Include(m => m.ContractorProfile)
                .ThenInclude(c => c!.Industry)
            .Include(m => m.TraderProfile)
            .Include(m => m.Products.Where(p => p.IsActive))
            .ToListAsync(cancellationToken);

        // 3. Fetch existing connections for connection status resolution
        var connections = await _dbContext.MemberConnections
            .AsNoTracking()
            .Where(c => (c.RequesterMemberId == memberId || c.RecipientMemberId == memberId))
            .ToListAsync(cancellationToken);

        var result = new List<RecommendedCompanyDto>();

        foreach (var candidate in rawCandidates)
        {
            string companyName = candidate.BusinessProfile?.CompanyName
                ?? candidate.TraderProfile?.TradingName
                ?? candidate.ContractorProfile?.WorkName
                ?? candidate.FullName;

            string businessType = candidate.BusinessProfile != null
                ? "Manufacturer / Company"
                : (candidate.ContractorProfile != null ? "Contractor / Job Worker" : (candidate.TraderProfile != null ? "Trader / Supplier" : "Business"));

            string location = candidate.ContractorProfile?.WorkCoverage
                ?? candidate.TraderProfile?.ServiceCoverage
                ?? "Gujarat, India";

            int industryId = candidate.BusinessProfile?.IndustryId
                ?? candidate.ContractorProfile?.IndustryId
                ?? 0;

            string industryName = candidate.BusinessProfile?.Industry?.Name
                ?? candidate.ContractorProfile?.Industry?.Name
                ?? (candidate.TraderProfile != null ? "Trading & Supplies" : "General Industry");

            string categoryName = candidate.BusinessProfile?.Category?.Name
                ?? (candidate.ContractorProfile != null ? "Specialized Contracting" : (candidate.TraderProfile != null ? "Distribution" : "Business Services"));

            var capabilities = new List<string>();
            var rawCaps = candidate.BusinessProfile?.BusinessCapabilities
                ?? candidate.ContractorProfile?.WorkCapabilities
                ?? candidate.TraderProfile?.Capabilities;
            if (!string.IsNullOrWhiteSpace(rawCaps))
            {
                capabilities = rawCaps.Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(s => s.Trim())
                    .Where(s => s.Length > 0)
                    .Take(4)
                    .ToList();
            }

            var productList = candidate.Products.Where(p => p.IsActive).ToList();
            int productCount = productList.Count;
            var productPreviews = productList.Select(p => p.Name).Take(3).ToList();

            // Resolve connection status: "Connect", "Request Sent", "Connected", "Respond to Request"
            var conn = connections.FirstOrDefault(c =>
                (c.RequesterMemberId == memberId && c.RecipientMemberId == candidate.Id) ||
                (c.RequesterMemberId == candidate.Id && c.RecipientMemberId == memberId));

            string connectionStatus = "Connect";
            if (conn != null)
            {
                if (conn.Status == ConnectionStatusEnum.Accepted)
                {
                    connectionStatus = "Connected";
                }
                else if (conn.Status == ConnectionStatusEnum.Pending)
                {
                    connectionStatus = conn.RequesterMemberId == memberId ? "Request Sent" : "Respond to Request";
                }
            }

            // Calculate relevance score
            int score = 0;
            if (targetIndustryId > 0 && industryId == targetIndustryId) score += 10;
            if (targetGroupId > 0 && (candidate.BusinessProfile?.BusinessGroupId == targetGroupId || candidate.ContractorProfile?.BusinessGroupId == targetGroupId)) score += 5;
            if (productCount > 0) score += 3;

            result.Add(new RecommendedCompanyDto(
                candidate.Id,
                companyName,
                candidate.FullName,
                businessType,
                location,
                industryId,
                industryName,
                categoryName,
                capabilities,
                productCount,
                productPreviews,
                connectionStatus
            ));
        }

        // Sort by relevance / products and take limit
        return result
            .OrderByDescending(r => r.ProductCount > 0)
            .ThenBy(r => r.CompanyName)
            .Take(limit)
            .ToList();
    }

    public async Task<List<ProductDto>> GetRelatedProductsAsync(int productId, int limit = 6, int? viewerMemberId = null, CancellationToken cancellationToken = default)
    {
        limit = Math.Clamp(limit, 1, 20);

        // 1. Fetch currently viewed product to obtain reference industry, category, tags, and keywords
        var targetProduct = await _dbContext.Products
            .AsNoTracking()
            .Include(p => p.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
            .FirstOrDefaultAsync(p => p.Id == productId && p.IsActive, cancellationToken);

        if (targetProduct == null)
        {
            return new List<ProductDto>();
        }

        int? targetIndustryId = targetProduct.IndustryId
            ?? targetProduct.Member?.BusinessProfile?.IndustryId
            ?? targetProduct.Member?.ContractorProfile?.IndustryId;

        var targetCategory = targetProduct.Category?.Trim().ToLowerInvariant();
        var targetSubCategory = targetProduct.SubCategory?.Trim().ToLowerInvariant();
        var targetTags = ParseTags(targetProduct.TagsJson)
            .Select(t => t.Trim().ToLowerInvariant())
            .Where(t => !string.IsNullOrEmpty(t))
            .ToHashSet();

        var targetWords = targetProduct.Name
            .Split(new[] { ' ', '-', '/', ',', '.', '&', '(', ')' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(w => w.Trim().ToLowerInvariant())
            .Where(w => w.Length >= 3)
            .ToHashSet();

        // 2. Query active candidates across active members excluding the current product
        var candidatesQuery = _dbContext.Products
            .AsNoTracking()
            .Where(p => p.Id != productId && p.IsActive && p.Member.IsActive)
            .Include(p => p.Industry)
            .Include(p => p.Inquiries)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(bp => bp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.TraderProfile);

        // Fetch candidates with sensible cap to avoid loading excessive data
        var candidates = await candidatesQuery
            .OrderByDescending(p => p.CreatedAtUtc)
            .Take(Math.Max(limit * 10, 60))
            .ToListAsync(cancellationToken);

        // 3. Compute deterministic relevance score for each candidate
        var scoredList = candidates.Select(candidate =>
        {
            int score = 0;
            int? candIndustryId = candidate.IndustryId
                ?? candidate.Member?.BusinessProfile?.IndustryId
                ?? candidate.Member?.ContractorProfile?.IndustryId;

            // Prioritize relevant products from other businesses (+10 pts)
            if (candidate.MemberId != targetProduct.MemberId)
            {
                score += 10;
            }

            // Prefer products from the same industry (+8 pts)
            if (targetIndustryId.HasValue && candIndustryId == targetIndustryId.Value)
            {
                score += 8;
            }

            // Prefer products in the same category (+6 pts)
            if (!string.IsNullOrEmpty(targetCategory) &&
                string.Equals(candidate.Category, targetProduct.Category, StringComparison.OrdinalIgnoreCase))
            {
                score += 6;
            }

            // Prefer products in the same subcategory (+4 pts)
            if (!string.IsNullOrEmpty(targetSubCategory) &&
                !string.IsNullOrEmpty(candidate.SubCategory) &&
                string.Equals(candidate.SubCategory, targetProduct.SubCategory, StringComparison.OrdinalIgnoreCase))
            {
                score += 4;
            }

            // Consider matching keywords from product tags (+3 pts per tag match)
            var candTags = ParseTags(candidate.TagsJson);
            foreach (var tag in candTags)
            {
                if (targetTags.Contains(tag.Trim().ToLowerInvariant()))
                {
                    score += 3;
                }
            }

            // Consider matching keywords from product names (+2 pts per word match)
            var candWords = candidate.Name
                .Split(new[] { ' ', '-', '/', ',', '.', '&', '(', ')' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(w => w.Trim().ToLowerInvariant());

            foreach (var w in candWords)
            {
                if (w.Length >= 3 && targetWords.Contains(w))
                {
                    score += 2;
                }
            }

            if (!string.IsNullOrWhiteSpace(candidate.Description))
            {
                var desc = candidate.Description.ToLowerInvariant();
                foreach (var tw in targetWords)
                {
                    if (desc.Contains(tw))
                    {
                        score += 1;
                        break;
                    }
                }
            }

            return new { Product = candidate, Score = score };
        });

        // 4. Stable sort: Score desc, ViewCount desc, CreatedAtUtc desc, Id asc
        var sorted = scoredList
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Product.ViewCount)
            .ThenByDescending(x => x.Product.CreatedAtUtc)
            .ThenBy(x => x.Product.Id)
            .Take(limit)
            .Select(x => MapToProductDto(x.Product, viewerMemberId))
            .ToList();

        return sorted;
    }

    public async Task<List<ProductDto>> GetRecommendedProductsAsync(
        int? memberId,
        ProductRecommendationFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, filter.Page);
        var pageSize = Math.Clamp(filter.Limit.HasValue && filter.Limit.Value > 0 ? filter.Limit.Value : filter.PageSize, 1, 50);

        // 1. Determine member's industry if available
        int? memberIndustryId = null;
        if (memberId.HasValue && memberId.Value > 0)
        {
            var member = await _dbContext.Members
                .AsNoTracking()
                .Include(m => m.BusinessProfile)
                .Include(m => m.ContractorProfile)
                .FirstOrDefaultAsync(m => m.Id == memberId.Value, cancellationToken);

            memberIndustryId = member?.BusinessProfile?.IndustryId ?? member?.ContractorProfile?.IndustryId;
        }

        // 2. Selected industry takes precedence if provided, otherwise fallback to member's industry
        int? targetIndustryId = filter.IndustryId.HasValue && filter.IndustryId.Value > 0
            ? filter.IndustryId.Value
            : memberIndustryId;

        // 3. Query active products across network
        var query = _dbContext.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.Member.IsActive)
            .Include(p => p.Industry)
            .Include(p => p.Inquiries)
            .Include(p => p.Member)
                .ThenInclude(m => m.BusinessProfile)
                    .ThenInclude(bp => bp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.ContractorProfile)
                    .ThenInclude(cp => cp!.Industry)
            .Include(p => p.Member)
                .ThenInclude(m => m.TraderProfile)
            .AsQueryable();

        // Exclude viewer's own products (keep My Products separate from recommendations)
        if (memberId.HasValue && memberId.Value > 0)
        {
            query = query.Where(p => p.MemberId != memberId.Value);
        }

        // Exclude specified product if requested
        if (filter.ExcludeProductId.HasValue && filter.ExcludeProductId.Value > 0)
        {
            query = query.Where(p => p.Id != filter.ExcludeProductId.Value);
        }

        // Category filter if specified
        if (!string.IsNullOrWhiteSpace(filter.Category) && !filter.Category.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            var cat = filter.Category.Trim();
            query = query.Where(p => p.Category == cat || (p.SubCategory != null && p.SubCategory == cat));
        }

        var candidates = await query
            .OrderByDescending(p => p.CreatedAtUtc)
            .Take(Math.Max(pageSize * 10, 100))
            .ToListAsync(cancellationToken);

        // 4. Deterministic relevance ranking
        var scoredList = candidates.Select(p =>
        {
            int score = 0;
            int? pIndustryId = p.IndustryId
                ?? p.Member?.BusinessProfile?.IndustryId
                ?? p.Member?.ContractorProfile?.IndustryId;

            // Priority: matches selected or member industry (+20 pts)
            if (targetIndustryId.HasValue && pIndustryId == targetIndustryId.Value)
            {
                score += 20;
            }

            // Products from other businesses are prioritized (+5 pts)
            if (!memberId.HasValue || p.MemberId != memberId.Value)
            {
                score += 5;
            }

            // Recency: new products within 30 days (+3 pts)
            if (p.CreatedAtUtc >= DateTime.UtcNow.AddDays(-30))
            {
                score += 3;
            }

            // Popularity / view count (+1-2 pts)
            if (p.ViewCount > 5) score += 2;
            else if (p.ViewCount > 0) score += 1;

            return new { Product = p, Score = score };
        });

        var result = scoredList
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Product.CreatedAtUtc)
            .ThenBy(x => x.Product.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => MapToProductDto(x.Product, memberId))
            .ToList();

        return result;
    }

    public async Task RecordCompanyViewAsync(int viewedMemberId, int? viewerMemberId = null, CancellationToken cancellationToken = default)
    {
        // Don't record self views
        if (viewerMemberId.HasValue && viewerMemberId.Value == viewedMemberId)
        {
            return;
        }

        var view = new ProfileView
        {
            ViewedMemberId = viewedMemberId,
            ViewerMemberId = viewerMemberId,
            ViewedAtUtc = DateTime.UtcNow
        };

        _dbContext.ProfileViews.Add(view);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private static List<string> ParseTags(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new List<string>();
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>();
        }
        catch
        {
            return new List<string>();
        }
    }

    private static Dictionary<string, string> ParseSpecifications(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new Dictionary<string, string>();
        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json) ?? new Dictionary<string, string>();
        }
        catch
        {
            return new Dictionary<string, string>();
        }
    }

    private static List<string> ParseImages(string? imageUrl, string? specificationsJson)
    {
        var list = new List<string>();
        if (!string.IsNullOrWhiteSpace(imageUrl))
        {
            var parts = imageUrl.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var part in parts)
            {
                var trimmed = part.Trim();
                if (trimmed.Length > 0 && !list.Contains(trimmed))
                {
                    list.Add(trimmed);
                }
            }
        }

        if (!string.IsNullOrWhiteSpace(specificationsJson))
        {
            try
            {
                using var doc = JsonDocument.Parse(specificationsJson);
                if (doc.RootElement.ValueKind == JsonValueKind.Object)
                {
                    if (doc.RootElement.TryGetProperty("Gallery", out var galleryProp) && galleryProp.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var item in galleryProp.EnumerateArray())
                        {
                            var s = item.GetString()?.Trim();
                            if (!string.IsNullOrEmpty(s) && !list.Contains(s))
                            {
                                list.Add(s);
                            }
                        }
                    }
                }
            }
            catch
            {
                // Ignore parsing errors for image gallery
            }
        }

        return list;
    }

    private static ProductDto MapToProductDto(Product p, int? viewerMemberId)
    {
        var companyName = p.Member?.BusinessProfile?.CompanyName
            ?? p.Member?.TraderProfile?.TradingName
            ?? p.Member?.ContractorProfile?.WorkName
            ?? p.Member?.FullName
            ?? "Connexa Supplier";

        var location = p.Member?.ContractorProfile?.WorkCoverage
            ?? p.Member?.TraderProfile?.ServiceCoverage
            ?? "Gujarat, India";

        var businessType = p.Member?.BusinessProfile != null
            ? "Manufacturer"
            : (p.Member?.ContractorProfile != null ? "Contractor" : "Supplier");

        var isOwner = viewerMemberId.HasValue && viewerMemberId.Value == p.MemberId;
        var specs = ParseSpecifications(p.SpecificationsJson);

        int? industryId = p.IndustryId
            ?? p.Member?.BusinessProfile?.IndustryId
            ?? p.Member?.ContractorProfile?.IndustryId;

        string? industryName = p.Industry?.Name
            ?? p.Member?.BusinessProfile?.Industry?.Name
            ?? p.Member?.ContractorProfile?.Industry?.Name
            ?? (p.Member?.TraderProfile != null ? "Trading & Supplies" : null);

        string? price = specs.TryGetValue("Price", out var pr) ? pr : (specs.TryGetValue("Price / Unit", out var pr2) ? pr2 : null);
        string? moq = specs.TryGetValue("MOQ", out var mq) ? mq : null;

        var isOwnerVerified = p.Member?.BusinessProfile != null &&
            p.Member.BusinessProfile.VerificationStatus == Entities.BusinessVerificationStatus.Approved;
        var ownerVerificationStatus = p.Member?.BusinessProfile?.VerificationStatus.ToString() ?? "NotSubmitted";

        return new ProductDto(
            p.Id,
            p.MemberId,
            p.Name,
            p.Description,
            p.Category,
            p.SubCategory,
            ParseTags(p.TagsJson),
            p.ImageUrl,
            specs,
            p.ViewCount,
            p.Inquiries?.Count ?? 0,
            p.CreatedAtUtc,
            p.UpdatedAtUtc,
            companyName,
            p.Member?.FullName,
            location,
            businessType,
            isOwner,
            ParseImages(p.ImageUrl, p.SpecificationsJson),
            industryId,
            industryName,
            price,
            moq,
            isOwnerVerified,
            ownerVerificationStatus
        );
    }
}


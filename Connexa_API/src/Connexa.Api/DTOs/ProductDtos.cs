namespace Connexa.Api.DTOs;

public record ProductDto(
    int Id,
    int MemberId,
    string Name,
    string Description,
    string Category,
    string? SubCategory,
    List<string> Tags,
    string? ImageUrl,
    Dictionary<string, string> Specifications,
    int ViewCount,
    int InquiryCount,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    string? CompanyName = null,
    string? OwnerName = null,
    string? Location = null,
    string? BusinessType = null,
    bool IsOwner = false,
    List<string>? AdditionalImages = null,
    int? IndustryId = null,
    string? IndustryName = null,
    string? Price = null,
    string? Moq = null,
    bool IsOwnerVerified = false,
    string OwnerVerificationStatus = "NotSubmitted"
);

public record CreateProductRequestDto(
    string Name,
    string Description,
    string Category,
    string? SubCategory = null,
    List<string>? Tags = null,
    string? ImageUrl = null,
    Dictionary<string, string>? Specifications = null,
    int? IndustryId = null
);

public record UpdateProductRequestDto(
    string Name,
    string Description,
    string Category,
    string? SubCategory = null,
    List<string>? Tags = null,
    string? ImageUrl = null,
    Dictionary<string, string>? Specifications = null,
    int? IndustryId = null
);

public class ProductFilterDto
{
    public string? Search { get; set; }
    public int? IndustryId { get; set; }
    public string? Category { get; set; }
    public string? SubCategory { get; set; }
    public string? SortBy { get; set; } // "newest", "name_asc", "name_desc", "popular"
    public int? MemberId { get; set; }
    public bool? VerifiedOnly { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 12;
    public int? Limit { get; set; }
}

public class ProductRecommendationFilterDto
{
    public int? IndustryId { get; set; }
    public string? Category { get; set; }
    public int? ExcludeProductId { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 6;
    public int? Limit { get; set; }
}

public record ProductCatalogResponseDto(
    List<ProductDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);


public record ProductInquiryDto(
    int Id,
    int ProductId,
    string ProductName,
    int SenderMemberId,
    string SenderName,
    string SenderCompanyName,
    int RecipientMemberId,
    string Subject,
    string Message,
    string Status,
    DateTime CreatedAtUtc,
    string? RecipientCompanyName = null,
    string? QuantityRequirement = null,
    string? ContactPhone = null,
    string? ContactEmail = null,
    DateTime? RespondedAtUtc = null,
    string? ResponseMessage = null,
    string? ProductThumbnailUrl = null
);

public record CreateProductInquiryDto(
    string Subject,
    string Message,
    string? QuantityRequirement = null,
    string? ContactPhone = null,
    string? ContactEmail = null
);

public record RespondToInquiryDto(
    string ResponseMessage
);

public record DashboardStatsDto(
    int MyProductsCount,
    int CompanyViewsCount,
    int ProductViewsCount,
    int ConnectionRequestsCount,
    int UnreadNotificationsCount,
    int InquiriesCount
);

public record RecommendedCompanyDto(
    int MemberId,
    string CompanyName,
    string ContactPersonName,
    string BusinessType,
    string Location,
    int IndustryId,
    string IndustryName,
    string CategoryName,
    List<string> BusinessCapabilities,
    int ProductCount,
    List<string> ProductPreviews,
    string ConnectionStatus
);

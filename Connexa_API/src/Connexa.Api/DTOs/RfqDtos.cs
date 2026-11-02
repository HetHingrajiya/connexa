namespace Connexa.Api.DTOs;

public record CreateRfqDto(
    int ProductId,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal? TargetPrice = null,
    DateTime? RequiredDeliveryDateUtc = null,
    string DeliveryLocation = "Gujarat, India",
    string? AdditionalSpecifications = null,
    string? AttachmentUrl = null,
    string? Title = null,
    int? ProductInquiryId = null
);

public record RfqDto(
    int Id,
    string RfqNumber,
    int ProductId,
    string ProductName,
    string? ProductThumbnailUrl,
    int BuyerMemberId,
    string BuyerFullName,
    string BuyerCompanyName,
    string? BuyerEmail,
    string? BuyerPhone,
    int SupplierMemberId,
    string SupplierFullName,
    string SupplierCompanyName,
    string Title,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal? TargetPrice,
    DateTime? RequiredDeliveryDateUtc,
    string DeliveryLocation,
    string? AdditionalSpecifications,
    string? AttachmentUrl,
    string Status,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    DateTime? ClosedAtUtc,
    int QuotationsCount,
    QuotationDto? LatestQuotation = null,
    bool IsBuyer = false,
    bool IsSupplier = false
);

public record RfqFilterDto(
    string? Search = null,
    string? Status = null,
    int Page = 1,
    int PageSize = 10
);

public record RfqListResponseDto(
    List<RfqDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record SubmitQuotationDto(
    decimal UnitPrice,
    decimal Quantity,
    decimal TaxRatePercent = 18.00m,
    decimal ShippingCharges = 0.00m,
    DateTime? ValidUntilUtc = null,
    string EstimatedDeliveryTime = "7 to 10 Business Days",
    string? TermsAndConditions = null,
    string? DocumentUrl = null
);

public record QuotationDto(
    int Id,
    int RfqId,
    string RfqNumber,
    string QuotationNumber,
    int Version,
    int SupplierMemberId,
    string SupplierName,
    string SupplierCompanyName,
    int BuyerMemberId,
    string BuyerName,
    string BuyerCompanyName,
    decimal UnitPrice,
    decimal Quantity,
    decimal Subtotal,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal ShippingCharges,
    decimal TotalAmount,
    DateTime ValidUntilUtc,
    string EstimatedDeliveryTime,
    string? TermsAndConditions,
    string? DocumentUrl,
    string Status,
    string? RejectionReason,
    string? RevisionNotes,
    DateTime CreatedAtUtc,
    DateTime? SubmittedAtUtc,
    DateTime? DecidedAtUtc,
    bool IsExpired = false
);

public record DecideQuotationDto(
    string Decision, // "Accept", "Reject", "RequestRevision"
    string? Notes = null
);


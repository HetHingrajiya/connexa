using Connexa.Api.Entities;

namespace Connexa.Api.DTOs;

public record CreateServiceDto(
    string Title,
    string Description,
    string ServiceCategory,
    int? IndustryId = null,
    int? BusinessGroupId = null,
    int? SubGroupId = null,
    int? CategoryId = null,
    string ServiceType = "On-Site",
    string PricingModel = "Quote-Based",
    decimal? StartingPrice = null,
    string? PriceUnit = null,
    string? TurnaroundTime = null,
    string? CoverageArea = null,
    string? Location = null,
    string? TagsJson = null,
    string? ImagesJson = null,
    string? Certifications = null,
    int? YearsOfExperience = null
);

public record UpdateServiceDto(
    string Title,
    string Description,
    string ServiceCategory,
    int? IndustryId = null,
    int? BusinessGroupId = null,
    int? SubGroupId = null,
    int? CategoryId = null,
    string ServiceType = "On-Site",
    string PricingModel = "Quote-Based",
    decimal? StartingPrice = null,
    string? PriceUnit = null,
    string? TurnaroundTime = null,
    string? CoverageArea = null,
    string? Location = null,
    string? TagsJson = null,
    string? ImagesJson = null,
    string? Certifications = null,
    int? YearsOfExperience = null,
    bool? IsActive = true
);

public record ServiceSummaryDto(
    int Id,
    int MemberId,
    string ProviderName,
    string? ProviderCompanyName,
    string? ProviderCity,
    string? ProviderState,
    string Title,
    string Description,
    string ServiceCategory,
    int? IndustryId,
    string? IndustryName,
    string ServiceType,
    string PricingModel,
    decimal? StartingPrice,
    string? PriceUnit,
    string? TurnaroundTime,
    string? CoverageArea,
    string? Location,
    string? ImagesJson,
    bool IsActive,
    int ViewCount,
    DateTime CreatedAtUtc
);

public record ServiceDetailDto(
    int Id,
    int MemberId,
    string ProviderName,
    string? ProviderCompanyName,
    string? ProviderEmail,
    string? ProviderPhone,
    string? ProviderCity,
    string? ProviderState,
    string Title,
    string Description,
    string ServiceCategory,
    int? IndustryId,
    string? IndustryName,
    int? BusinessGroupId,
    int? SubGroupId,
    int? CategoryId,
    string ServiceType,
    string PricingModel,
    decimal? StartingPrice,
    string? PriceUnit,
    string? TurnaroundTime,
    string? CoverageArea,
    string? Location,
    string? TagsJson,
    string? ImagesJson,
    string? Certifications,
    int? YearsOfExperience,
    bool IsActive,
    int ViewCount,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    int InquiryCount,
    bool IsOwner
);

public record ServiceSearchQueryDto(
    string? Query = null,
    string? Category = null,
    int? IndustryId = null,
    string? Location = null,
    string? ServiceType = null,
    int Page = 1,
    int PageSize = 20
);

public record CreateServiceInquiryDto(
    int ServiceId,
    string Subject,
    string RequirementDescription,
    string? ScopeOfWork = null,
    string? Location = null,
    DateTime? PreferredStartDate = null,
    decimal? EstimatedBudget = null,
    string Urgency = "Normal"
);

public record RespondServiceInquiryDto(
    string ResponseMessage,
    bool AcceptInquiry = true
);

public record UpdateServiceInquiryStatusDto(
    ServiceInquiryStatus Status,
    string? Remarks = null
);

public record ServiceInquiryStatusHistoryDto(
    int Id,
    ServiceInquiryStatus? PreviousStatus,
    ServiceInquiryStatus NewStatus,
    string StatusName,
    int ChangedByMemberId,
    string ChangedByName,
    DateTime ChangedAtUtc,
    string? Remarks
);

public record ServiceInquiryDetailDto(
    int Id,
    string InquiryNumber,
    int ServiceId,
    string ServiceTitle,
    string ServiceCategory,
    int SenderMemberId,
    string SenderName,
    string? SenderCompanyName,
    string? SenderEmail,
    string? SenderPhone,
    int RecipientMemberId,
    string RecipientName,
    string? RecipientCompanyName,
    string Subject,
    string RequirementDescription,
    string? ScopeOfWork,
    string? Location,
    DateTime? PreferredStartDate,
    decimal? EstimatedBudget,
    string Urgency,
    ServiceInquiryStatus Status,
    string StatusName,
    string? ResponseMessage,
    DateTime? RespondedAtUtc,
    DateTime CreatedAtUtc,
    List<ServiceInquiryStatusHistoryDto> StatusHistory
);


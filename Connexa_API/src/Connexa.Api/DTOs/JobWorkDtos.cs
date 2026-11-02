namespace Connexa.Api.DTOs;

using Connexa.Api.Entities;

public record JobWorkAttachmentDto(
    int Id,
    int? JobWorkRequirementId,
    int? JobWorkQuotationId,
    int UploadedByMemberId,
    string OriginalFileName,
    string StoredFileName,
    string FileExtension,
    string ContentType,
    long FileSizeBytes,
    DateTime UploadedAtUtc,
    string DownloadUrl
);

public record CreateJobWorkRequirementDto(
    string Title,
    string Description,
    int IndustryId,
    int? BusinessGroupId,
    int? SubGroupId,
    int? CategoryId,
    string JobWorkProcess,
    string? MachineType,
    string? MachineCategory,
    string? RequiredMachineCapacity,
    string? TechnicalSpecifications,
    string? RequiredTolerance,
    string? MaterialType,
    MaterialResponsibility MaterialResponsibility,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal? TargetBudget,
    string Location,
    string? DeliveryTerms,
    DateTime? TargetCompletionDateUtc,
    List<int>? AttachmentIds = null
);

public record UpdateJobWorkRequirementDto(
    string Title,
    string Description,
    int IndustryId,
    int? BusinessGroupId,
    int? SubGroupId,
    int? CategoryId,
    string JobWorkProcess,
    string? MachineType,
    string? MachineCategory,
    string? RequiredMachineCapacity,
    string? TechnicalSpecifications,
    string? RequiredTolerance,
    string? MaterialType,
    MaterialResponsibility MaterialResponsibility,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal? TargetBudget,
    string Location,
    string? DeliveryTerms,
    DateTime? TargetCompletionDateUtc
);

public record JobWorkRequirementFilterDto(
    string? Search = null,
    string? Process = null,
    string? MachineType = null,
    int? IndustryId = null,
    string? Location = null,
    MaterialResponsibility? MaterialResponsibility = null,
    JobWorkRequirementStatus? Status = null,
    int Page = 1,
    int PageSize = 10
);

public record JobWorkRequirementDto(
    int Id,
    string RequirementNumber,
    int OwnerMemberId,
    string OwnerFullName,
    string OwnerCompanyName,
    string? OwnerCity,
    string? OwnerState,
    bool OwnerIsVerified,
    string Title,
    string Description,
    int IndustryId,
    string IndustryName,
    int? BusinessGroupId,
    string? BusinessGroupName,
    int? SubGroupId,
    string? SubGroupName,
    int? CategoryId,
    string? CategoryName,
    string JobWorkProcess,
    string? MachineType,
    string? MachineCategory,
    string? RequiredMachineCapacity,
    string? TechnicalSpecifications,
    string? RequiredTolerance,
    string? MaterialType,
    string MaterialResponsibility,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal? TargetBudget,
    string Location,
    string? DeliveryTerms,
    DateTime? TargetCompletionDateUtc,
    string Status,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    DateTime? ClosedAtUtc,
    int QuotationsCount,
    int? ActiveOrderId,
    string? ActiveOrderNumber,
    List<JobWorkAttachmentDto> Attachments,
    bool IsOwner = false,
    bool HasQuoted = false,
    int? MyQuotationId = null
);

public record JobWorkRequirementListResponseDto(
    List<JobWorkRequirementDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record SubmitJobWorkQuotationDto(
    int JobWorkRequirementId,
    decimal OfferedUnitPrice,
    decimal Quantity,
    decimal TaxRatePercent = 18.00m,
    decimal OtherCharges = 0.00m,
    int LeadTimeDays = 7,
    string? MachineProposed = null,
    string? TechnicalRemarks = null,
    string? TermsAndConditions = null,
    DateTime? ValidUntilUtc = null,
    List<int>? AttachmentIds = null
);

public record UpdateJobWorkQuotationDto(
    decimal OfferedUnitPrice,
    decimal Quantity,
    decimal TaxRatePercent = 18.00m,
    decimal OtherCharges = 0.00m,
    int LeadTimeDays = 7,
    string? MachineProposed = null,
    string? TechnicalRemarks = null,
    string? TermsAndConditions = null,
    DateTime? ValidUntilUtc = null,
    string? RevisionNotes = null
);

public record DecideJobWorkQuotationDto(
    string Decision, // "Accept", "Reject", "RequestRevision"
    string? Notes = null
);

public record JobWorkQuotationDto(
    int Id,
    string QuotationNumber,
    int JobWorkRequirementId,
    string RequirementNumber,
    string RequirementTitle,
    int ContractorMemberId,
    string ContractorFullName,
    string ContractorCompanyName,
    string? ContractorCity,
    string? ContractorState,
    bool ContractorIsVerified,
    decimal OfferedUnitPrice,
    decimal Quantity,
    decimal Subtotal,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal OtherCharges,
    decimal TotalAmount,
    int LeadTimeDays,
    string? MachineProposed,
    string? TechnicalRemarks,
    string? TermsAndConditions,
    DateTime? ValidUntilUtc,
    string Status,
    int RevisionNumber,
    string? RejectionReason,
    string? RevisionNotes,
    DateTime CreatedAtUtc,
    DateTime? DecidedAtUtc,
    List<JobWorkAttachmentDto> Attachments,
    bool IsContractor = false,
    bool IsOwner = false
);

public record JobWorkQuotationListResponseDto(
    List<JobWorkQuotationDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record UpdateJobWorkOrderStatusDto(
    JobWorkOrderStatus NewStatus,
    string? Remarks = null,
    DateTime? EstimatedCompletionDateUtc = null
);

public record JobWorkOrderStatusHistoryDto(
    int Id,
    int JobWorkOrderId,
    string? PreviousStatus,
    string NewStatus,
    int ChangedByMemberId,
    string ChangedByMemberName,
    string? ChangedByCompanyName,
    DateTime ChangedAtUtc,
    string? Remarks
);

public record JobWorkOrderDto(
    int Id,
    string OrderNumber,
    int JobWorkRequirementId,
    string RequirementNumber,
    int JobWorkQuotationId,
    string QuotationNumber,
    int BuyerMemberId,
    string BuyerFullName,
    string BuyerCompanyName,
    string? BuyerEmail,
    string? BuyerPhone,
    int ContractorMemberId,
    string ContractorFullName,
    string ContractorCompanyName,
    string? ContractorEmail,
    string? ContractorPhone,
    string JobTitle,
    string Process,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal AgreedUnitPrice,
    decimal Subtotal,
    decimal TaxAmount,
    decimal OtherCharges,
    decimal TotalAmount,
    int LeadTimeDays,
    string DeliveryLocation,
    string Status,
    DateTime? ConfirmedAtUtc,
    DateTime? ProcessingStartedAtUtc,
    DateTime? CompletedAtUtc,
    DateTime? CancelledAtUtc,
    string? CancellationReason,
    string? RejectionReason,
    string? Notes,
    DateTime CreatedAtUtc,
    List<JobWorkOrderStatusHistoryDto> StatusHistory,
    bool IsBuyer = false,
    bool IsContractor = false
);

public record JobWorkOrderListResponseDto(
    List<JobWorkOrderDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

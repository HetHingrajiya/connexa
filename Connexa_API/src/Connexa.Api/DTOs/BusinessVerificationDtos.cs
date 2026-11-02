namespace Connexa.Api.DTOs;

public record BusinessVerificationDocumentDto(
    int Id,
    int VerificationRequestId,
    string DocumentType,
    string OriginalFileName,
    string FileExtension,
    string ContentType,
    long FileSizeBytes,
    DateTime UploadedAtUtc,
    string DownloadUrl
);

public record BusinessVerificationRequestDto(
    int Id,
    int BusinessProfileId,
    string CompanyName,
    int MemberId,
    string OwnerFullName,
    string OwnerEmail,
    string OwnerPhoneNumber,
    string Status,
    string BusinessRegistrationNumber,
    string RegisteredAddress,
    string City,
    string State,
    string Pincode,
    string? Notes,
    DateTime SubmittedAtUtc,
    DateTime? ReviewedAtUtc,
    int? ReviewedByMemberId,
    string? RejectionReason,
    List<BusinessVerificationDocumentDto> Documents
);

public record SubmitBusinessVerificationRequestDto(
    string BusinessRegistrationNumber,
    string RegisteredAddress,
    string City,
    string State,
    string Pincode,
    string? Notes = null
);

public record RejectVerificationRequestDto(
    string Reason
);

public record VerificationStatusResponseDto(
    string Status,
    bool IsVerified,
    int? LatestRequestId,
    DateTime? SubmittedAtUtc,
    DateTime? ReviewedAtUtc,
    string? RejectionReason,
    BusinessVerificationRequestDto? LatestRequest
);

public record AdminVerificationListResponseDto(
    List<BusinessVerificationRequestDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

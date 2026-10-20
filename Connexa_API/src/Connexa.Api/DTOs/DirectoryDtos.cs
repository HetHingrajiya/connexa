namespace Connexa.Api.DTOs;

public record BusinessDirectoryItemDto(
    int MemberId,
    string CompanyName,
    string ContactPersonName,
    string Email,
    string PhoneNumber,
    List<string> BusinessCapabilities,
    string? BusinessDescription,
    int IndustryId,
    string IndustryName,
    int BusinessGroupId,
    string BusinessGroupName,
    int SubGroupId,
    string SubGroupName,
    int CategoryId,
    string CategoryName,
    string VerifiedMethod,
    DateTime MemberSinceUtc,
    string BusinessType = "Manufacturer / Company",
    string? Location = null,
    string? MaskedEmail = null,
    string? MaskedPhoneNumber = null,
    string? ConnectionStatus = "Not Connected"
);

public record BusinessDirectoryResponseDto(
    List<BusinessDirectoryItemDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record BusinessDirectoryFilterDto(
    string? Search = null,
    int? IndustryId = null,
    int? BusinessGroupId = null,
    int? SubGroupId = null,
    int? CategoryId = null,
    string? Capability = null,
    string? BusinessType = null,
    string? Location = null,
    int Page = 1,
    int PageSize = 10
);


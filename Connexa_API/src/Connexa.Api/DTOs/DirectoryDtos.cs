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
    DateTime MemberSinceUtc
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
    int Page = 1,
    int PageSize = 10
);

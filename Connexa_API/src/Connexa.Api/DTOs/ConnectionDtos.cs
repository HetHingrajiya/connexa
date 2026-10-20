namespace Connexa.Api.DTOs;

public record CreateConnectionRequestDto(
    int RecipientMemberId,
    string? Note = null
);

public record ConnectionDto(
    int Id,
    int RequesterMemberId,
    int RecipientMemberId,
    string Status,
    string? Note,
    DateTime CreatedAtUtc,
    DateTime? RespondedAtUtc,
    DateTime? UpdatedAtUtc
);

public record ConnectedMemberItemDto(
    int ConnectionId,
    int MemberId,
    string FullName,
    string CompanyName,
    string BusinessType,
    int IndustryId,
    string IndustryName,
    string Location,
    DateTime ConnectedSinceUtc,
    string? MaskedEmail,
    string? MaskedPhoneNumber,
    string ConnectionStatus = "Connected"
);

public record ConnectionRequestItemDto(
    int Id,
    int MemberId,
    string FullName,
    string CompanyName,
    string BusinessType,
    int IndustryId,
    string IndustryName,
    string Location,
    string? Note,
    DateTime CreatedAtUtc,
    string Status,
    string Direction
);

public record PaginatedConnectionsDto<T>(
    List<T> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);

public record ConnectionsSummaryDto(
    int TotalConnected,
    int ReceivedPendingCount,
    int SentPendingCount
);

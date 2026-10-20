using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Connections;

public interface IConnectionService
{
    Task<(bool Success, string Message, ConnectionDto? Connection)> SendRequestAsync(
        int requesterMemberId,
        CreateConnectionRequestDto dto,
        CancellationToken cancellationToken = default);

    Task<PaginatedConnectionsDto<ConnectionRequestItemDto>> GetReceivedRequestsAsync(
        int currentMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default);

    Task<PaginatedConnectionsDto<ConnectionRequestItemDto>> GetSentRequestsAsync(
        int currentMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, ConnectionDto? Connection)> AcceptRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, ConnectionDto? Connection)> RejectRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, ConnectionDto? Connection)> CancelRequestAsync(
        int currentMemberId,
        int requestId,
        CancellationToken cancellationToken = default);

    Task<PaginatedConnectionsDto<ConnectedMemberItemDto>> GetMyConnectionsAsync(
        int currentMemberId,
        string? search = null,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message)> RemoveConnectionAsync(
        int currentMemberId,
        int targetMemberId,
        CancellationToken cancellationToken = default);

    Task<ConnectionsSummaryDto> GetSummaryAsync(
        int currentMemberId,
        CancellationToken cancellationToken = default);
}

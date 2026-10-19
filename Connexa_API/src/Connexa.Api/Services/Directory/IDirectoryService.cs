using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Directory;

public interface IDirectoryService
{
    /// <summary>
    /// Searches and paginates registered businesses with multi-attribute filtering.
    /// Excludes sensitive credentials and inactive members.
    /// </summary>
    Task<BusinessDirectoryResponseDto> SearchBusinessesAsync(BusinessDirectoryFilterDto filter, CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a single business directory profile by member ID.
    /// </summary>
    Task<BusinessDirectoryItemDto?> GetBusinessByMemberIdAsync(int memberId, CancellationToken cancellationToken = default);
}

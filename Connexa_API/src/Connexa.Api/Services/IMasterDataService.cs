using Connexa.Api.DTOs;

namespace Connexa.Api.Services;

public interface IMasterDataService
{
    Task<ApiResponse<IReadOnlyList<IndustryDto>>> GetIndustriesAsync(CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<BusinessGroupDto>>?> GetBusinessGroupsAsync(string industryId, CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<SubGroupDto>>?> GetSubGroupsAsync(string businessGroupId, CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<CategoryDto>>?> GetCategoriesAsync(string subGroupId, CancellationToken cancellationToken = default);
}
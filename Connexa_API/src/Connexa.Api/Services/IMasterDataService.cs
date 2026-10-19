using Connexa.Api.DTOs;

namespace Connexa.Api.Services;

public interface IMasterDataService
{
    Task<ApiResponse<IReadOnlyList<IndustryDto>>> GetIndustriesAsync(CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<BusinessGroupDto>>?> GetBusinessGroupsAsync(int industryId, CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<SubGroupDto>>?> GetSubGroupsAsync(int businessGroupId, CancellationToken cancellationToken = default);
    Task<ApiResponse<IReadOnlyList<CategoryDto>>?> GetCategoriesAsync(int subGroupId, CancellationToken cancellationToken = default);
}
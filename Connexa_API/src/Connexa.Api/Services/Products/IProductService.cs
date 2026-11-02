using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Products;

public interface IProductService
{
    Task<List<ProductDto>> GetMemberProductsAsync(int memberId, CancellationToken cancellationToken = default);
    Task<List<ProductDto>> GetAllProductsAsync(string? search = null, string? category = null, int? memberId = null, int limit = 50, int? viewerMemberId = null, CancellationToken cancellationToken = default);
    Task<ProductCatalogResponseDto> GetCatalogProductsAsync(ProductFilterDto filter, int? viewerMemberId = null, CancellationToken cancellationToken = default);
    Task<ProductDto?> GetProductByIdAsync(int id, int? viewerMemberId = null, CancellationToken cancellationToken = default);
    Task<(bool Success, string Message, ProductDto? Product)> CreateProductAsync(int memberId, CreateProductRequestDto dto, CancellationToken cancellationToken = default);
    Task<(bool Success, string Message, ProductDto? Product)> UpdateProductAsync(int memberId, int id, UpdateProductRequestDto dto, CancellationToken cancellationToken = default);
    Task<(bool Success, string Message)> DeleteProductAsync(int memberId, int id, CancellationToken cancellationToken = default);
    Task<(bool Success, string Message, ProductInquiryDto? Inquiry)> SendInquiryAsync(int senderMemberId, int productId, CreateProductInquiryDto dto, CancellationToken cancellationToken = default);
    Task<List<ProductInquiryDto>> GetReceivedInquiriesAsync(int memberId, CancellationToken cancellationToken = default);
    Task<List<ProductInquiryDto>> GetSentInquiriesAsync(int memberId, CancellationToken cancellationToken = default);
    Task<ProductInquiryDto?> GetInquiryByIdAsync(int inquiryId, int memberId, CancellationToken cancellationToken = default);
    Task<(bool Success, string Message, ProductInquiryDto? Inquiry)> RespondToInquiryAsync(int memberId, int inquiryId, RespondToInquiryDto dto, CancellationToken cancellationToken = default);
    Task<DashboardStatsDto> GetDashboardStatsAsync(int memberId, CancellationToken cancellationToken = default);
    Task<List<RecommendedCompanyDto>> GetRecommendedCompaniesAsync(int memberId, int limit = 5, CancellationToken cancellationToken = default);
    Task<List<ProductDto>> GetRelatedProductsAsync(int productId, int limit = 6, int? viewerMemberId = null, CancellationToken cancellationToken = default);
    Task<List<ProductDto>> GetRecommendedProductsAsync(int? memberId, ProductRecommendationFilterDto filter, CancellationToken cancellationToken = default);
    Task RecordCompanyViewAsync(int viewedMemberId, int? viewerMemberId = null, CancellationToken cancellationToken = default);
}

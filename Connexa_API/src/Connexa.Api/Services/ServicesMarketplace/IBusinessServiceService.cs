using Connexa.Api.DTOs;

namespace Connexa.Api.Services.ServicesMarketplace;

public interface IBusinessServiceService
{
    // Services Management
    Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> CreateServiceAsync(int memberId, CreateServiceDto dto);
    Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> UpdateServiceAsync(int memberId, int serviceId, UpdateServiceDto dto);
    Task<(bool Success, string? ErrorMessage)> DeleteServiceAsync(int memberId, int serviceId);
    Task<(bool Success, ServiceDetailDto? Service, string? ErrorMessage)> GetServiceByIdAsync(int serviceId, int? viewerMemberId = null);
    Task<(List<ServiceSummaryDto> Services, int TotalCount, int TotalPages)> SearchServicesAsync(ServiceSearchQueryDto query);
    Task<List<ServiceSummaryDto>> GetMyServicesAsync(int memberId);
    Task<List<string>> GetPopularCategoriesAsync();

    // Service Inquiries
    Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> CreateInquiryAsync(int senderMemberId, CreateServiceInquiryDto dto);
    Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> RespondInquiryAsync(int providerMemberId, int inquiryId, RespondServiceInquiryDto dto);
    Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> UpdateInquiryStatusAsync(int memberId, int inquiryId, UpdateServiceInquiryStatusDto dto);
    Task<(bool Success, ServiceInquiryDetailDto? Inquiry, string? ErrorMessage)> GetInquiryByIdAsync(int memberId, int inquiryId);
    Task<List<ServiceInquiryDetailDto>> GetMySentInquiriesAsync(int memberId);
    Task<List<ServiceInquiryDetailDto>> GetMyReceivedInquiriesAsync(int memberId);
}


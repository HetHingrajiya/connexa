namespace Connexa.Api.Services.JobWork;

using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Microsoft.AspNetCore.Http;

public interface IJobWorkService
{
    // --- Requirements ---
    Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CreateRequirementAsync(
        int ownerMemberId,
        CreateJobWorkRequirementDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> UpdateRequirementAsync(
        int requirementId,
        int ownerMemberId,
        UpdateJobWorkRequirementDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CancelRequirementAsync(
        int requirementId,
        int ownerMemberId,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> CloseRequirementAsync(
        int requirementId,
        int ownerMemberId,
        CancellationToken cancellationToken = default);

    Task<JobWorkRequirementListResponseDto> GetMarketplaceRequirementsAsync(
        int? currentMemberId,
        JobWorkRequirementFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<JobWorkRequirementListResponseDto> GetMyRequirementsAsync(
        int ownerMemberId,
        JobWorkRequirementFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkRequirementDto? Requirement)> GetRequirementByIdAsync(
        int requirementId,
        int? currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    // --- Quotations ---
    Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> SubmitQuotationAsync(
        int contractorMemberId,
        SubmitJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> UpdateQuotationAsync(
        int quotationId,
        int contractorMemberId,
        UpdateJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> WithdrawQuotationAsync(
        int quotationId,
        int contractorMemberId,
        CancellationToken cancellationToken = default);

    Task<List<JobWorkQuotationDto>> GetQuotationsForRequirementAsync(
        int requirementId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<JobWorkQuotationListResponseDto> GetMyQuotationsAsync(
        int contractorMemberId,
        int page = 1,
        int pageSize = 10,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkQuotationDto? Quotation)> GetQuotationByIdAsync(
        int quotationId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkQuotationDto? Quotation, JobWorkOrderDto? Order)> DecideQuotationAsync(
        int quotationId,
        int ownerMemberId,
        DecideJobWorkQuotationDto dto,
        CancellationToken cancellationToken = default);

    // --- Orders ---
    Task<JobWorkOrderListResponseDto> GetOrdersAsync(
        int currentMemberId,
        bool isBuyer,
        int page = 1,
        int pageSize = 10,
        JobWorkOrderStatus? status = null,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkOrderDto? Order)> GetOrderByIdAsync(
        int orderId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkOrderDto? Order)> UpdateOrderStatusAsync(
        int orderId,
        int currentMemberId,
        UpdateJobWorkOrderStatusDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, JobWorkOrderDto? Order)> CancelOrderAsync(
        int orderId,
        int currentMemberId,
        string reason,
        CancellationToken cancellationToken = default);

    // --- Attachments ---
    Task<(bool Success, string Message, JobWorkAttachmentDto? Attachment)> UploadAttachmentAsync(
        int currentMemberId,
        IFormFile file,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, string? FilePath, string? ContentType, string? OriginalFileName)> GetAttachmentDownloadAsync(
        int attachmentId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);
}


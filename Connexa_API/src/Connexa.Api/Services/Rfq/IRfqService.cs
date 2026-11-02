using Connexa.Api.DTOs;
using Microsoft.AspNetCore.Http;

namespace Connexa.Api.Services.Rfq;

public interface IRfqService
{
    Task<(bool Success, string Message, RfqDto? Rfq)> CreateRfqAsync(
        int buyerMemberId,
        CreateRfqDto dto,
        CancellationToken cancellationToken = default);

    Task<RfqListResponseDto> GetMyRfqsAsync(
        int buyerMemberId,
        RfqFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<RfqListResponseDto> GetReceivedRfqsAsync(
        int supplierMemberId,
        RfqFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, RfqDto? Rfq)> GetRfqByIdAsync(
        int rfqId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, RfqDto? Rfq)> CancelRfqAsync(
        int rfqId,
        int buyerMemberId,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, QuotationDto? Quotation)> SubmitQuotationAsync(
        int rfqId,
        int supplierMemberId,
        SubmitQuotationDto dto,
        CancellationToken cancellationToken = default);

    Task<List<QuotationDto>> GetQuotationsForRfqAsync(
        int rfqId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, QuotationDto? Quotation)> GetQuotationByIdAsync(
        int quotationId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, QuotationDto? Quotation)> DecideQuotationAsync(
        int quotationId,
        int buyerMemberId,
        DecideQuotationDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, string? AttachmentUrl)> UploadAttachmentAsync(
        int currentMemberId,
        IFormFile file,
        CancellationToken cancellationToken = default);
}


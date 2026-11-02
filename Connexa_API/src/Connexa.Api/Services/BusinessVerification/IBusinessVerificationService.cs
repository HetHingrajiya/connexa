using Microsoft.AspNetCore.Http;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Auth;

namespace Connexa.Api.Services.BusinessVerification;

public interface IBusinessVerificationService
{
    /// <summary>
    /// Submits a new business verification request with uploaded supporting documents.
    /// Documents are stored securely outside wwwroot.
    /// Dispatches an in-app and FCM push notification to the member.
    /// </summary>
    Task<AuthResult<BusinessVerificationRequestDto>> SubmitVerificationAsync(
        int memberId,
        SubmitBusinessVerificationRequestDto request,
        List<IFormFile> documents,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves current business verification status for the specified member.
    /// </summary>
    Task<AuthResult<VerificationStatusResponseDto>> GetVerificationStatusAsync(
        int memberId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Securely downloads a verification document.
    /// Only the document owner or an Admin is permitted to download.
    /// </summary>
    Task<(bool Success, Stream? Stream, string? ContentType, string? OriginalFileName, string? ErrorMessage, int StatusCode)> DownloadDocumentAsync(
        int documentId,
        int requestingMemberId,
        bool isAdmin,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a paginated list of verification requests for Admin review.
    /// Supports filtering by verification status.
    /// </summary>
    Task<AuthResult<AdminVerificationListResponseDto>> GetAdminVerificationsAsync(
        string? status,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a single verification request with full details and document metadata.
    /// </summary>
    Task<AuthResult<BusinessVerificationRequestDto>> GetVerificationByIdAsync(
        int requestId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Approves a pending verification request. Updates BusinessProfile status and dispatches notification.
    /// </summary>
    Task<AuthResult<BusinessVerificationRequestDto>> ApproveVerificationAsync(
        int requestId,
        int reviewerMemberId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Rejects a verification request with a mandatory reason. Updates BusinessProfile status and dispatches notification.
    /// </summary>
    Task<AuthResult<BusinessVerificationRequestDto>> RejectVerificationAsync(
        int requestId,
        int reviewerMemberId,
        string reason,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads a public business logo image for the member's business profile.
    /// </summary>
    Task<AuthResult<string>> UploadLogoAsync(
        int memberId,
        IFormFile file,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads a public gallery image for the member's business profile.
    /// </summary>
    Task<AuthResult<List<string>>> UploadBusinessImageAsync(
        int memberId,
        IFormFile file,
        CancellationToken cancellationToken = default);
}

using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Auth;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Services.BusinessVerification;

public class BusinessVerificationService : IBusinessVerificationService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<BusinessVerificationService> _logger;

    private static readonly HashSet<string> AllowedDocExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".jpg", ".jpeg", ".png"
    };

    private static readonly HashSet<string> AllowedDocContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "application/pdf", "image/jpeg", "image/png"
    };

    private static readonly HashSet<string> AllowedImageExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp"
    };

    private static readonly HashSet<string> AllowedImageContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg", "image/png", "image/webp"
    };

    private const long MaxDocSizeBytes = 10 * 1024 * 1024; // 10 MB
    private const long MaxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

    public BusinessVerificationService(
        ConnexaDbContext db,
        INotificationService notificationService,
        IWebHostEnvironment environment,
        ILogger<BusinessVerificationService> logger)
    {
        _db = db;
        _notificationService = notificationService;
        _environment = environment;
        _logger = logger;
    }

    private string GetSecureDocumentsDirectory()
    {
        var basePath = _environment.ContentRootPath;
        var dir = Path.Combine(basePath, "App_Data", "VerificationDocuments");
        if (!System.IO.Directory.Exists(dir))
        {
            System.IO.Directory.CreateDirectory(dir);
        }
        return dir;
    }

    private string GetPublicUploadsDirectory(string subFolder)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var dir = Path.Combine(webRoot, "uploads", "business-profiles", subFolder);
        if (!System.IO.Directory.Exists(dir))
        {
            System.IO.Directory.CreateDirectory(dir);
        }
        return dir;
    }

    public async Task<AuthResult<BusinessVerificationRequestDto>> SubmitVerificationAsync(
        int memberId,
        SubmitBusinessVerificationRequestDto request,
        List<IFormFile> documents,
        CancellationToken cancellationToken = default)
    {
        var member = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == memberId, cancellationToken);

        if (member == null)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Member not found.", 404);
        }

        if (member.BusinessProfile == null)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Member does not have an active Business Profile.", 400);
        }

        if (member.BusinessProfile.VerificationStatus == BusinessVerificationStatus.PendingReview)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "A verification request is already under review for this business.", 400);
        }

        // Validate required fields
        if (string.IsNullOrWhiteSpace(request.BusinessRegistrationNumber))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Business registration number (GSTIN, PAN, CIN, or Trade License) is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.RegisteredAddress))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Registered address is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.City))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "City is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.State))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "State is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.Pincode))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Pincode is required.", 400);
        }

        if (documents == null || documents.Count == 0)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "At least one supporting verification document (GST certificate, PAN, trade license, etc.) is required.", 400);
        }

        // Validate each document
        foreach (var doc in documents)
        {
            if (doc.Length == 0)
            {
                return new AuthResult<BusinessVerificationRequestDto>(false, null, $"Document '{doc.FileName}' is empty.", 400);
            }

            if (doc.Length > MaxDocSizeBytes)
            {
                return new AuthResult<BusinessVerificationRequestDto>(false, null, $"Document '{doc.FileName}' exceeds maximum size of 10 MB.", 400);
            }

            var ext = Path.GetExtension(doc.FileName);
            if (string.IsNullOrEmpty(ext) || !AllowedDocExtensions.Contains(ext))
            {
                return new AuthResult<BusinessVerificationRequestDto>(false, null, $"Document '{doc.FileName}' has unsupported file format '{ext}'. Allowed: .pdf, .jpg, .jpeg, .png", 400);
            }
        }

        var secureDir = GetSecureDocumentsDirectory();
        var verificationRequest = new BusinessVerificationRequest
        {
            BusinessProfileId = member.BusinessProfile.Id,
            MemberId = memberId,
            Status = BusinessVerificationStatus.PendingReview,
            BusinessRegistrationNumber = request.BusinessRegistrationNumber.Trim(),
            RegisteredAddress = request.RegisteredAddress.Trim(),
            City = request.City.Trim(),
            State = request.State.Trim(),
            Pincode = request.Pincode.Trim(),
            Notes = request.Notes?.Trim(),
            SubmittedAtUtc = DateTime.UtcNow
        };

        foreach (var doc in documents)
        {
            var ext = Path.GetExtension(doc.FileName).ToLowerInvariant();
            var storedName = $"{Guid.NewGuid():N}{ext}";
            var destinationPath = Path.Combine(secureDir, storedName);

            using (var stream = new FileStream(destinationPath, FileMode.Create))
            {
                await doc.CopyToAsync(stream, cancellationToken);
            }

            var docEntity = new BusinessVerificationDocument
            {
                DocumentType = DetermineDocumentType(doc.FileName),
                OriginalFileName = doc.FileName,
                StoredFileName = storedName,
                FileExtension = ext,
                ContentType = doc.ContentType ?? "application/octet-stream",
                FileSizeBytes = doc.Length,
                UploadedAtUtc = DateTime.UtcNow
            };

            verificationRequest.Documents.Add(docEntity);
        }

        // Update profile status & address
        member.BusinessProfile.VerificationStatus = BusinessVerificationStatus.PendingReview;
        if (string.IsNullOrWhiteSpace(member.BusinessProfile.Address)) member.BusinessProfile.Address = verificationRequest.RegisteredAddress;
        if (string.IsNullOrWhiteSpace(member.BusinessProfile.City)) member.BusinessProfile.City = verificationRequest.City;
        if (string.IsNullOrWhiteSpace(member.BusinessProfile.State)) member.BusinessProfile.State = verificationRequest.State;
        if (string.IsNullOrWhiteSpace(member.BusinessProfile.Pincode)) member.BusinessProfile.Pincode = verificationRequest.Pincode;

        _db.BusinessVerificationRequests.Add(verificationRequest);
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Business verification request {RequestId} submitted by Member {MemberId} for company {Company}",
            verificationRequest.Id, memberId, member.BusinessProfile.CompanyName);

        // Dispatch in-app notification & FCM push
        try
        {
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: memberId,
                actorMemberId: null,
                eventType: NotificationEventType.VerificationStatusChanged,
                title: "Business Verification Submitted",
                message: $"Your verification request for {member.BusinessProfile.CompanyName} has been submitted and is under review.",
                referenceType: "verification",
                referenceId: verificationRequest.Id,
                payloadJson: JsonSerializer.Serialize(new { requestId = verificationRequest.Id, status = "PendingReview" }),
                cancellationToken: cancellationToken
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to dispatch submission notification for verification {RequestId}", verificationRequest.Id);
        }

        var dto = MapToDto(verificationRequest, member.BusinessProfile.CompanyName, member.FullName, member.Email, member.PhoneNumber);
        return new AuthResult<BusinessVerificationRequestDto>(true, dto, null, 201);
    }

    public async Task<AuthResult<VerificationStatusResponseDto>> GetVerificationStatusAsync(
        int memberId,
        CancellationToken cancellationToken = default)
    {
        var profile = await _db.BusinessProfiles
            .Include(p => p.Member)
            .FirstOrDefaultAsync(p => p.MemberId == memberId, cancellationToken);

        if (profile == null)
        {
            return new AuthResult<VerificationStatusResponseDto>(true, new VerificationStatusResponseDto(
                Status: BusinessVerificationStatus.NotSubmitted.ToString(),
                IsVerified: false,
                LatestRequestId: null,
                SubmittedAtUtc: null,
                ReviewedAtUtc: null,
                RejectionReason: null,
                LatestRequest: null
            ), null, 200);
        }

        var latestRequest = await _db.BusinessVerificationRequests
            .Include(r => r.Documents)
            .Include(r => r.Member)
            .Where(r => r.BusinessProfileId == profile.Id)
            .OrderByDescending(r => r.SubmittedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

        BusinessVerificationRequestDto? latestDto = null;
        if (latestRequest != null)
        {
            latestDto = MapToDto(latestRequest, profile.CompanyName, profile.Member.FullName, profile.Member.Email, profile.Member.PhoneNumber);
        }

        var response = new VerificationStatusResponseDto(
            Status: profile.VerificationStatus.ToString(),
            IsVerified: profile.VerificationStatus == BusinessVerificationStatus.Approved,
            LatestRequestId: latestRequest?.Id,
            SubmittedAtUtc: latestRequest?.SubmittedAtUtc,
            ReviewedAtUtc: latestRequest?.ReviewedAtUtc,
            RejectionReason: latestRequest?.RejectionReason,
            LatestRequest: latestDto
        );

        return new AuthResult<VerificationStatusResponseDto>(true, response, null, 200);
    }

    public async Task<(bool Success, Stream? Stream, string? ContentType, string? OriginalFileName, string? ErrorMessage, int StatusCode)> DownloadDocumentAsync(
        int documentId,
        int requestingMemberId,
        bool isAdmin,
        CancellationToken cancellationToken = default)
    {
        var doc = await _db.BusinessVerificationDocuments
            .Include(d => d.VerificationRequest)
            .FirstOrDefaultAsync(d => d.Id == documentId, cancellationToken);

        if (doc == null)
        {
            return (false, null, null, null, "Document not found.", 404);
        }

        // Enforce ownership: only the owner member or an Admin can download
        if (!isAdmin && doc.VerificationRequest.MemberId != requestingMemberId)
        {
            _logger.LogWarning("[Security] Member {MemberId} unauthorized to download verification document {DocId}", requestingMemberId, documentId);
            return (false, null, null, null, "You do not have permission to access this document.", 403);
        }

        var secureDir = GetSecureDocumentsDirectory();
        var filePath = Path.Combine(secureDir, doc.StoredFileName);

        if (!File.Exists(filePath))
        {
            _logger.LogError("Verification document file missing on disk: {Path}", filePath);
            return (false, null, null, null, "Document file is missing from secure storage.", 404);
        }

        var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return (true, stream, doc.ContentType, doc.OriginalFileName, null, 200);
    }

    public async Task<AuthResult<AdminVerificationListResponseDto>> GetAdminVerificationsAsync(
        string? status,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = _db.BusinessVerificationRequests
            .Include(r => r.BusinessProfile)
            .Include(r => r.Member)
            .Include(r => r.Documents)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<BusinessVerificationStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(r => r.Status == parsedStatus);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        // Prioritize pending reviews, then latest submitted
        var items = await query
            .OrderByDescending(r => r.Status == BusinessVerificationStatus.PendingReview ? 1 : 0)
            .ThenByDescending(r => r.SubmittedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var dtos = items.Select(r => MapToDto(
            r,
            r.BusinessProfile?.CompanyName ?? string.Empty,
            r.Member?.FullName ?? string.Empty,
            r.Member?.Email ?? string.Empty,
            r.Member?.PhoneNumber ?? string.Empty
        )).ToList();

        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var response = new AdminVerificationListResponseDto(
            Items: dtos,
            TotalCount: totalCount,
            Page: page,
            PageSize: pageSize,
            TotalPages: totalPages
        );

        return new AuthResult<AdminVerificationListResponseDto>(true, response, null, 200);
    }

    public async Task<AuthResult<BusinessVerificationRequestDto>> GetVerificationByIdAsync(
        int requestId,
        CancellationToken cancellationToken = default)
    {
        var request = await _db.BusinessVerificationRequests
            .Include(r => r.BusinessProfile)
            .Include(r => r.Member)
            .Include(r => r.Documents)
            .FirstOrDefaultAsync(r => r.Id == requestId, cancellationToken);

        if (request == null)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Verification request not found.", 404);
        }

        var dto = MapToDto(
            request,
            request.BusinessProfile?.CompanyName ?? string.Empty,
            request.Member?.FullName ?? string.Empty,
            request.Member?.Email ?? string.Empty,
            request.Member?.PhoneNumber ?? string.Empty
        );

        return new AuthResult<BusinessVerificationRequestDto>(true, dto, null, 200);
    }

    public async Task<AuthResult<BusinessVerificationRequestDto>> ApproveVerificationAsync(
        int requestId,
        int reviewerMemberId,
        CancellationToken cancellationToken = default)
    {
        var request = await _db.BusinessVerificationRequests
            .Include(r => r.BusinessProfile)
            .Include(r => r.Member)
            .Include(r => r.Documents)
            .FirstOrDefaultAsync(r => r.Id == requestId, cancellationToken);

        if (request == null)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Verification request not found.", 404);
        }

        request.Status = BusinessVerificationStatus.Approved;
        request.ReviewedAtUtc = DateTime.UtcNow;
        request.ReviewedByMemberId = reviewerMemberId;
        request.RejectionReason = null;

        if (request.BusinessProfile != null)
        {
            request.BusinessProfile.VerificationStatus = BusinessVerificationStatus.Approved;
        }

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Business verification request {RequestId} APPROVED by Admin {AdminId}", requestId, reviewerMemberId);

        // Notify business owner
        try
        {
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: request.MemberId,
                actorMemberId: reviewerMemberId,
                eventType: NotificationEventType.VerificationStatusChanged,
                title: "Business Verified!",
                message: $"Congratulations! Your business '{request.BusinessProfile?.CompanyName}' has been officially verified.",
                referenceType: "verification",
                referenceId: request.Id,
                payloadJson: JsonSerializer.Serialize(new { requestId = request.Id, status = "Approved" }),
                cancellationToken: cancellationToken
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to dispatch approval notification for verification {RequestId}", requestId);
        }

        var dto = MapToDto(
            request,
            request.BusinessProfile?.CompanyName ?? string.Empty,
            request.Member?.FullName ?? string.Empty,
            request.Member?.Email ?? string.Empty,
            request.Member?.PhoneNumber ?? string.Empty
        );

        return new AuthResult<BusinessVerificationRequestDto>(true, dto, null, 200);
    }

    public async Task<AuthResult<BusinessVerificationRequestDto>> RejectVerificationAsync(
        int requestId,
        int reviewerMemberId,
        string reason,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(reason))
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Rejection reason is required.", 400);
        }

        var request = await _db.BusinessVerificationRequests
            .Include(r => r.BusinessProfile)
            .Include(r => r.Member)
            .Include(r => r.Documents)
            .FirstOrDefaultAsync(r => r.Id == requestId, cancellationToken);

        if (request == null)
        {
            return new AuthResult<BusinessVerificationRequestDto>(false, null, "Verification request not found.", 404);
        }

        request.Status = BusinessVerificationStatus.Rejected;
        request.ReviewedAtUtc = DateTime.UtcNow;
        request.ReviewedByMemberId = reviewerMemberId;
        request.RejectionReason = reason.Trim();

        if (request.BusinessProfile != null)
        {
            request.BusinessProfile.VerificationStatus = BusinessVerificationStatus.Rejected;
        }

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Business verification request {RequestId} REJECTED by Admin {AdminId}. Reason: {Reason}", requestId, reviewerMemberId, reason);

        // Notify business owner
        try
        {
            await _notificationService.CreateNotificationAsync(
                recipientMemberId: request.MemberId,
                actorMemberId: reviewerMemberId,
                eventType: NotificationEventType.VerificationStatusChanged,
                title: "Business Verification Needs Attention",
                message: $"Your verification request for '{request.BusinessProfile?.CompanyName}' was rejected: {reason.Trim()}",
                referenceType: "verification",
                referenceId: request.Id,
                payloadJson: JsonSerializer.Serialize(new { requestId = request.Id, status = "Rejected", reason = reason.Trim() }),
                cancellationToken: cancellationToken
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to dispatch rejection notification for verification {RequestId}", requestId);
        }

        var dto = MapToDto(
            request,
            request.BusinessProfile?.CompanyName ?? string.Empty,
            request.Member?.FullName ?? string.Empty,
            request.Member?.Email ?? string.Empty,
            request.Member?.PhoneNumber ?? string.Empty
        );

        return new AuthResult<BusinessVerificationRequestDto>(true, dto, null, 200);
    }

    public async Task<AuthResult<string>> UploadLogoAsync(
        int memberId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return new AuthResult<string>(false, null, "File is required.", 400);
        }

        if (file.Length > MaxImageSizeBytes)
        {
            return new AuthResult<string>(false, null, "Logo image exceeds maximum allowed size of 5 MB.", 400);
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext) || !AllowedImageExtensions.Contains(ext))
        {
            return new AuthResult<string>(false, null, "Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp", 400);
        }

        var profile = await _db.BusinessProfiles.FirstOrDefaultAsync(p => p.MemberId == memberId, cancellationToken);
        if (profile == null)
        {
            return new AuthResult<string>(false, null, "Business Profile not found.", 404);
        }

        var logosDir = GetPublicUploadsDirectory("logos");
        var fileName = $"{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(logosDir, fileName);

        using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        var relativeUrl = $"/uploads/business-profiles/logos/{fileName}";
        profile.LogoUrl = relativeUrl;
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated logo for Member {MemberId} to {Url}", memberId, relativeUrl);
        return new AuthResult<string>(true, relativeUrl, null, 200);
    }

    public async Task<AuthResult<List<string>>> UploadBusinessImageAsync(
        int memberId,
        IFormFile file,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return new AuthResult<List<string>>(false, null, "File is required.", 400);
        }

        if (file.Length > MaxImageSizeBytes)
        {
            return new AuthResult<List<string>>(false, null, "Image exceeds maximum allowed size of 5 MB.", 400);
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext) || !AllowedImageExtensions.Contains(ext))
        {
            return new AuthResult<List<string>>(false, null, "Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp", 400);
        }

        var profile = await _db.BusinessProfiles.FirstOrDefaultAsync(p => p.MemberId == memberId, cancellationToken);
        if (profile == null)
        {
            return new AuthResult<List<string>>(false, null, "Business Profile not found.", 404);
        }

        var galleryDir = GetPublicUploadsDirectory("gallery");
        var fileName = $"{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(galleryDir, fileName);

        using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        var relativeUrl = $"/uploads/business-profiles/gallery/{fileName}";
        var currentImages = string.IsNullOrWhiteSpace(profile.BusinessImagesJson)
            ? new List<string>()
            : JsonSerializer.Deserialize<List<string>>(profile.BusinessImagesJson) ?? new List<string>();

        currentImages.Add(relativeUrl);
        profile.BusinessImagesJson = JsonSerializer.Serialize(currentImages);
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Added gallery image for Member {MemberId}: {Url}", memberId, relativeUrl);
        return new AuthResult<List<string>>(true, currentImages, null, 200);
    }

    private static string DetermineDocumentType(string fileName)
    {
        var lower = fileName.ToLowerInvariant();
        if (lower.Contains("gst")) return "GstCertificate";
        if (lower.Contains("pan")) return "PanCard";
        if (lower.Contains("trade") || lower.Contains("license")) return "TradeLicense";
        if (lower.Contains("cin") || lower.Contains("incorp")) return "IncorporationCertificate";
        if (lower.Contains("msme") || lower.Contains("udyam")) return "MsmeCertificate";
        return "BusinessProof";
    }

    private static BusinessVerificationRequestDto MapToDto(
        BusinessVerificationRequest req,
        string companyName,
        string ownerName,
        string ownerEmail,
        string ownerPhone)
    {
        var docs = req.Documents.Select(d => new BusinessVerificationDocumentDto(
            Id: d.Id,
            VerificationRequestId: d.VerificationRequestId,
            DocumentType: d.DocumentType,
            OriginalFileName: d.OriginalFileName,
            FileExtension: d.FileExtension,
            ContentType: d.ContentType,
            FileSizeBytes: d.FileSizeBytes,
            UploadedAtUtc: d.UploadedAtUtc,
            DownloadUrl: $"/api/v1/business-verification/documents/{d.Id}/download"
        )).ToList();

        return new BusinessVerificationRequestDto(
            Id: req.Id,
            BusinessProfileId: req.BusinessProfileId,
            CompanyName: companyName,
            MemberId: req.MemberId,
            OwnerFullName: ownerName,
            OwnerEmail: ownerEmail,
            OwnerPhoneNumber: ownerPhone,
            Status: req.Status.ToString(),
            BusinessRegistrationNumber: req.BusinessRegistrationNumber,
            RegisteredAddress: req.RegisteredAddress,
            City: req.City,
            State: req.State,
            Pincode: req.Pincode,
            Notes: req.Notes,
            SubmittedAtUtc: req.SubmittedAtUtc,
            ReviewedAtUtc: req.ReviewedAtUtc,
            ReviewedByMemberId: req.ReviewedByMemberId,
            RejectionReason: req.RejectionReason,
            Documents: docs
        );
    }
}

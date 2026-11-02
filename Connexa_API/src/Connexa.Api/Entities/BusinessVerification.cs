namespace Connexa.Api.Entities;

public enum BusinessVerificationStatus
{
    NotSubmitted = 0,
    PendingReview = 1,
    Approved = 2,
    Rejected = 3
}

public class BusinessVerificationRequest
{
    public int Id { get; set; }
    public int BusinessProfileId { get; set; }
    public int MemberId { get; set; }
    public BusinessVerificationStatus Status { get; set; } = BusinessVerificationStatus.PendingReview;

    // Official Registration Details
    public string BusinessRegistrationNumber { get; set; } = string.Empty; // GSTIN, PAN, CIN, Trade License
    public string RegisteredAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public string? Notes { get; set; }

    // Timestamps and Decision Tracking
    public DateTime SubmittedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReviewedAtUtc { get; set; }
    public int? ReviewedByMemberId { get; set; }
    public string? RejectionReason { get; set; }

    // Navigation properties
    public BusinessProfile BusinessProfile { get; set; } = null!;
    public Member Member { get; set; } = null!;
    public Member? ReviewedByMember { get; set; }
    public ICollection<BusinessVerificationDocument> Documents { get; set; } = new List<BusinessVerificationDocument>();
}

public class BusinessVerificationDocument
{
    public int Id { get; set; }
    public int VerificationRequestId { get; set; }
    public string DocumentType { get; set; } = string.Empty; // e.g. "GstCertificate", "PanCard", "TradeLicense", "BusinessProof", "IdentityProof"
    public string OriginalFileName { get; set; } = string.Empty;
    public string StoredFileName { get; set; } = string.Empty; // GUID-based filename on secure storage
    public string FileExtension { get; set; } = string.Empty; // ".pdf", ".jpg", ".png"
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public DateTime UploadedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation property
    public BusinessVerificationRequest VerificationRequest { get; set; } = null!;
}

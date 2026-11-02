namespace Connexa.Api.Entities;

public class JobWorkAttachment
{
    public int Id { get; set; }
    public int? JobWorkRequirementId { get; set; }
    public int? JobWorkQuotationId { get; set; }
    public int UploadedByMemberId { get; set; }

    public string OriginalFileName { get; set; } = string.Empty;
    public string StoredFileName { get; set; } = string.Empty; // GUID-based filename on disk
    public string FileExtension { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public DateTime UploadedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public JobWorkRequirement? JobWorkRequirement { get; set; }
    public JobWorkQuotation? JobWorkQuotation { get; set; }
    public Member UploadedByMember { get; set; } = null!;
}


namespace Connexa.Api.Entities;

public class BusinessProfile
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string BusinessCapabilities { get; set; } = string.Empty;
    public string BusinessDescription { get; set; } = string.Empty;

    // 4-Tier Master Data Foreign Keys
    public int IndustryId { get; set; }
    public int BusinessGroupId { get; set; }
    public int SubGroupId { get; set; }
    public int CategoryId { get; set; }

    // Address & Location
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Pincode { get; set; }

    // Media & Online Presence
    public string? WebsiteUrl { get; set; }
    public string? LogoUrl { get; set; }
    public string? BusinessImagesJson { get; set; }

    // Verification Lifecycle Status
    public BusinessVerificationStatus VerificationStatus { get; set; } = BusinessVerificationStatus.NotSubmitted;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Member Member { get; set; } = null!;
    public Industry Industry { get; set; } = null!;
    public BusinessGroup BusinessGroup { get; set; } = null!;
    public SubGroup SubGroup { get; set; } = null!;
    public Category Category { get; set; } = null!;
    public ICollection<BusinessVerificationRequest> VerificationRequests { get; set; } = new List<BusinessVerificationRequest>();
}

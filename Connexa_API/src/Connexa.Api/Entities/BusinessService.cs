namespace Connexa.Api.Entities;

public class BusinessService
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ServiceCategory { get; set; } = string.Empty;

    // Optional 4-tier classification
    public int? IndustryId { get; set; }
    public int? BusinessGroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? CategoryId { get; set; }

    // Service specifics
    public string ServiceType { get; set; } = "On-Site"; // "On-Site", "Remote", "Workshop", "Hybrid"
    public string PricingModel { get; set; } = "Quote-Based"; // "Fixed Quote", "Hourly Rate", "Daily Rate", "Project Based"
    public decimal? StartingPrice { get; set; }
    public string? PriceUnit { get; set; } // "/hour", "/day", "/project", "/visit"
    public string? TurnaroundTime { get; set; } // "2-3 Days", "1-2 Weeks", "24-48 Hours"
    public string? CoverageArea { get; set; } // "Pan India", "Regional", "Local"
    public string? Location { get; set; } // City, State
    public string? TagsJson { get; set; }
    public string? ImagesJson { get; set; }
    public string? Certifications { get; set; }
    public int? YearsOfExperience { get; set; }

    public bool IsActive { get; set; } = true;
    public int ViewCount { get; set; } = 0;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public Member Member { get; set; } = null!;
    public Industry? Industry { get; set; }
    public ICollection<ServiceInquiry> Inquiries { get; set; } = new List<ServiceInquiry>();
}


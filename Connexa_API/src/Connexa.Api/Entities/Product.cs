namespace Connexa.Api.Entities;

public class Product
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? SubCategory { get; set; }
    public string? TagsJson { get; set; }
    public string? ImageUrl { get; set; }
    public string? SpecificationsJson { get; set; }
    public int ViewCount { get; set; } = 0;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public int? IndustryId { get; set; }

    // Navigation properties
    public Member Member { get; set; } = null!;
    public Industry? Industry { get; set; }
    public ICollection<ProductInquiry> Inquiries { get; set; } = new List<ProductInquiry>();
    public ICollection<Rfq> Rfqs { get; set; } = new List<Rfq>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}


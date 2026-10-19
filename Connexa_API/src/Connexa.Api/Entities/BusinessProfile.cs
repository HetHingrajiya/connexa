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

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Member Member { get; set; } = null!;
    public Industry Industry { get; set; } = null!;
    public BusinessGroup BusinessGroup { get; set; } = null!;
    public SubGroup SubGroup { get; set; } = null!;
    public Category Category { get; set; } = null!;
}

namespace Connexa.Api.Entities;

public class ContractorProfile
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string WorkName { get; set; } = string.Empty;
    public string WorkCapabilities { get; set; } = string.Empty;
    public string ProcessesSupported { get; set; } = string.Empty;
    public string WorkCoverage { get; set; } = string.Empty;

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

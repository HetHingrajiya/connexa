namespace Connexa.Api.Entities;

public class BusinessGroup
{
    public int Id { get; set; }
    public int IndustryId { get; set; }
    public Industry Industry { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<SubGroup> SubGroups { get; set; } = new List<SubGroup>();
}
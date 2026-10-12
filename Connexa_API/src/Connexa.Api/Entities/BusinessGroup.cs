namespace Connexa.Api.Entities;

public class BusinessGroup
{
    public string Id { get; set; } = string.Empty;
    public string IndustryId { get; set; } = string.Empty;
    public Industry Industry { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<SubGroup> SubGroups { get; set; } = new List<SubGroup>();
}
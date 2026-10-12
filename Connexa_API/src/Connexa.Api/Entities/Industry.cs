namespace Connexa.Api.Entities;

public class Industry
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<BusinessGroup> BusinessGroups { get; set; } = new List<BusinessGroup>();
}
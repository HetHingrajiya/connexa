namespace Connexa.Api.Entities;

public class SubGroup
{
    public string Id { get; set; } = string.Empty;
    public string BusinessGroupId { get; set; } = string.Empty;
    public BusinessGroup BusinessGroup { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Category> Categories { get; set; } = new List<Category>();
}
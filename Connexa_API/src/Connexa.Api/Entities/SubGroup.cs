namespace Connexa.Api.Entities;

public class SubGroup
{
    public int Id { get; set; }
    public int BusinessGroupId { get; set; }
    public BusinessGroup BusinessGroup { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Category> Categories { get; set; } = new List<Category>();
}
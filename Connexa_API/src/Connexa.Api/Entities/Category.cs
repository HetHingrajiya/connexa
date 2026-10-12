namespace Connexa.Api.Entities;

public class Category
{
    public string Id { get; set; } = string.Empty;
    public string SubGroupId { get; set; } = string.Empty;
    public SubGroup SubGroup { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
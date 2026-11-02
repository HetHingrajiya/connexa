namespace Connexa.Api.Entities;

public class BusinessPostAttachment
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public BusinessPost Post { get; set; } = null!;

    public string MediaUrl { get; set; } = string.Empty;
    public string? MediaType { get; set; } // "image", "document", etc.
    public int DisplayOrder { get; set; } = 0;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}


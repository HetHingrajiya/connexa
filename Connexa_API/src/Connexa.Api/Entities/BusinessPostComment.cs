namespace Connexa.Api.Entities;

public class BusinessPostComment
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public BusinessPost Post { get; set; } = null!;

    public int MemberId { get; set; }
    public Member Member { get; set; } = null!;

    public string Content { get; set; } = string.Empty;

    public bool IsEdited { get; set; } = false;
    public bool IsDeleted { get; set; } = false;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public ICollection<BusinessPostReport> Reports { get; set; } = new List<BusinessPostReport>();
}


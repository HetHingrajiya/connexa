namespace Connexa.Api.Entities;

public class BusinessPost
{
    public int Id { get; set; }

    public int MemberId { get; set; }
    public Member Member { get; set; } = null!;

    public string Content { get; set; } = string.Empty;

    public int? IndustryId { get; set; }
    public Industry? Industry { get; set; }

    public int LikeCount { get; set; } = 0;
    public int CommentCount { get; set; } = 0;

    public bool IsEdited { get; set; } = false;
    public bool IsDeleted { get; set; } = false;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public ICollection<BusinessPostAttachment> Attachments { get; set; } = new List<BusinessPostAttachment>();
    public ICollection<BusinessPostLike> Likes { get; set; } = new List<BusinessPostLike>();
    public ICollection<BusinessPostComment> Comments { get; set; } = new List<BusinessPostComment>();
    public ICollection<BusinessPostReport> Reports { get; set; } = new List<BusinessPostReport>();
}


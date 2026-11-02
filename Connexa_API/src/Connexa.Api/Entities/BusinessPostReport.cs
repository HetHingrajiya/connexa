namespace Connexa.Api.Entities;

public enum PostReportStatus
{
    Pending = 1,
    Reviewed = 2,
    Dismissed = 3,
    ActionTaken = 4
}

public class BusinessPostReport
{
    public int Id { get; set; }

    public int ReporterMemberId { get; set; }
    public Member ReporterMember { get; set; } = null!;

    public int? PostId { get; set; }
    public BusinessPost? Post { get; set; }

    public int? CommentId { get; set; }
    public BusinessPostComment? Comment { get; set; }

    public string Reason { get; set; } = string.Empty; // "Spam", "Inappropriate", "Harassment", "Fake Business", "Other"
    public string? Details { get; set; }

    public PostReportStatus Status { get; set; } = PostReportStatus.Pending;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReviewedAtUtc { get; set; }
}


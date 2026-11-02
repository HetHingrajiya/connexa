namespace Connexa.Api.Entities;

public class AccountDeletionRequest
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public DateTime RequestedAtUtc { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "PendingReview"; // PendingReview, Completed, Cancelled
    public DateTime? ProcessedAtUtc { get; set; }
    public string? AdminNotes { get; set; }

    public Member Member { get; set; } = null!;
}


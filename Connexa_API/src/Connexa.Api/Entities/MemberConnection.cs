namespace Connexa.Api.Entities;

public enum ConnectionStatusEnum
{
    Pending = 1,
    Accepted = 2,
    Rejected = 3,
    Cancelled = 4
}

public class MemberConnection
{
    public int Id { get; set; }
    public int RequesterMemberId { get; set; }
    public int RecipientMemberId { get; set; }
    public ConnectionStatusEnum Status { get; set; } = ConnectionStatusEnum.Pending;
    public string? Note { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public Member RequesterMember { get; set; } = null!;
    public Member RecipientMember { get; set; } = null!;
}

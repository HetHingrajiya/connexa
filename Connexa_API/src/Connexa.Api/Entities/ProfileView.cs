namespace Connexa.Api.Entities;

public class ProfileView
{
    public int Id { get; set; }
    public int ViewedMemberId { get; set; }
    public int? ViewerMemberId { get; set; }
    public DateTime ViewedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Member ViewedMember { get; set; } = null!;
}

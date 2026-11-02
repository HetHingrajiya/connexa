namespace Connexa.Api.Entities;

public class BusinessPostLike
{
    public int PostId { get; set; }
    public BusinessPost Post { get; set; } = null!;

    public int MemberId { get; set; }
    public Member Member { get; set; } = null!;

    public DateTime LikedAtUtc { get; set; } = DateTime.UtcNow;
}


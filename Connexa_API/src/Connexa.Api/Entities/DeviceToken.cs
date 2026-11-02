namespace Connexa.Api.Entities;

public class DeviceToken
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = "android"; // "android", "ios", "web", "windows"
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Member Member { get; set; } = null!;
}

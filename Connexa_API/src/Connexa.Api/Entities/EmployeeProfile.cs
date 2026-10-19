namespace Connexa.Api.Entities;

public class EmployeeProfile
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string JobTitle { get; set; } = string.Empty;
    public string Skills { get; set; } = string.Empty;
    public string Experience { get; set; } = string.Empty;
    public string PreferredJobType { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public Member Member { get; set; } = null!;
}

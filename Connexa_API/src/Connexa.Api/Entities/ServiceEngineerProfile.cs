namespace Connexa.Api.Entities;

public class ServiceEngineerProfile
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string Specialization { get; set; } = string.Empty;
    public string SupportedEquipment { get; set; } = string.Empty;
    public string YearsOfExperience { get; set; } = string.Empty;
    public string ServiceCoverage { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public Member Member { get; set; } = null!;
}

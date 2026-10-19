namespace Connexa.Api.Entities;

public enum ProfileTypeEnum
{
    BusinessCompany = 1,
    EmployeeJobSeeker = 2,
    ServiceEngineer = 3,
    TraderSupplier = 4,
    ContractorJobWorker = 5
}

public class Member
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string CountryCode { get; set; } = "+91";
    public string PhoneNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public ProfileTypeEnum PrimaryProfileType { get; set; }
    public string VerifiedMethod { get; set; } = string.Empty; // "Email" or "WhatsApp"
    public string VerifiedDestination { get; set; } = string.Empty;
    public string Role { get; set; } = "Member"; // Strictly "Member" for public registration
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // 1-to-1 Profile navigations
    public BusinessProfile? BusinessProfile { get; set; }
    public EmployeeProfile? EmployeeProfile { get; set; }
    public ServiceEngineerProfile? ServiceEngineerProfile { get; set; }
    public TraderProfile? TraderProfile { get; set; }
    public ContractorProfile? ContractorProfile { get; set; }
}

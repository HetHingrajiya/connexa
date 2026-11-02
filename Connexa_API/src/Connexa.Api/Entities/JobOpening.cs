namespace Connexa.Api.Entities;

public enum JobOpeningStatus
{
    Open = 1,
    Closed = 2,
    Cancelled = 3
}

public class JobOpening
{
    public int Id { get; set; }

    public int MemberId { get; set; }
    public Member Member { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? Department { get; set; }

    public int? IndustryId { get; set; }
    public Industry? Industry { get; set; }

    public int? BusinessGroupId { get; set; }
    public BusinessGroup? BusinessGroup { get; set; }

    public int? SubGroupId { get; set; }
    public SubGroup? SubGroup { get; set; }

    public int? CategoryId { get; set; }
    public Category? Category { get; set; }

    /// <summary>
    /// Full-time, Part-time, Contract, Shift-based, Internship
    /// </summary>
    public string JobType { get; set; } = "Full-time";

    /// <summary>
    /// On-site, Remote, Hybrid
    /// </summary>
    public string WorkplaceType { get; set; } = "On-site";

    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string? Address { get; set; }

    public int MinExperienceYears { get; set; } = 0;
    public int? MaxExperienceYears { get; set; }

    public decimal? MinSalary { get; set; }
    public decimal? MaxSalary { get; set; }

    /// <summary>
    /// Per Month, Per Annum, Per Hour
    /// </summary>
    public string SalaryPeriod { get; set; } = "Per Month";

    public string? RequiredSkillsJson { get; set; }
    public string? EducationRequirements { get; set; }
    public int OpeningsCount { get; set; } = 1;

    public JobOpeningStatus Status { get; set; } = JobOpeningStatus.Open;
    public DateTime? ApplicationDeadlineUtc { get; set; }

    public int ViewCount { get; set; } = 0;
    public int ApplicationsCount { get; set; } = 0;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public ICollection<JobApplication> Applications { get; set; } = new List<JobApplication>();
}


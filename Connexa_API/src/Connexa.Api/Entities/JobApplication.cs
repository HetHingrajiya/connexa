namespace Connexa.Api.Entities;

public enum JobApplicationStatus
{
    Submitted = 1,
    UnderReview = 2,
    Shortlisted = 3,
    Rejected = 4,
    Accepted = 5,
    Withdrawn = 6
}

public class JobApplication
{
    public int Id { get; set; }
    public string ApplicationNumber { get; set; } = string.Empty;

    public int JobOpeningId { get; set; }
    public JobOpening JobOpening { get; set; } = null!;

    public int ApplicantMemberId { get; set; }
    public Member ApplicantMember { get; set; } = null!;

    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;

    public string? CurrentCompany { get; set; }
    public string? CurrentDesignation { get; set; }
    public int YearsOfExperience { get; set; } = 0;
    public decimal? ExpectedSalary { get; set; }
    public int? NoticePeriodDays { get; set; }

    public string? CoverLetter { get; set; }
    public string? ResumeUrl { get; set; }
    public string? ResumeFileName { get; set; }

    public JobApplicationStatus Status { get; set; } = JobApplicationStatus.Submitted;
    public string? EmployerNotes { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    public ICollection<JobApplicationAttachment> Attachments { get; set; } = new List<JobApplicationAttachment>();
    public ICollection<JobApplicationStatusHistory> StatusHistory { get; set; } = new List<JobApplicationStatusHistory>();
}


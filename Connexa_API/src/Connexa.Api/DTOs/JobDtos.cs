using System.ComponentModel.DataAnnotations;
using Connexa.Api.Entities;

namespace Connexa.Api.DTOs;

public class CreateJobOpeningDto
{
    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(4000)]
    public string Description { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? Department { get; set; }

    public int? IndustryId { get; set; }
    public int? BusinessGroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? CategoryId { get; set; }

    [MaxLength(50)]
    public string JobType { get; set; } = "Full-time";

    [MaxLength(50)]
    public string WorkplaceType { get; set; } = "On-site";

    [Required, MaxLength(100)]
    public string City { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string State { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Address { get; set; }

    [Range(0, 50)]
    public int MinExperienceYears { get; set; } = 0;

    [Range(0, 50)]
    public int? MaxExperienceYears { get; set; }

    [Range(0, 100000000)]
    public decimal? MinSalary { get; set; }

    [Range(0, 100000000)]
    public decimal? MaxSalary { get; set; }

    [MaxLength(50)]
    public string SalaryPeriod { get; set; } = "Per Month";

    [MaxLength(2000)]
    public string? RequiredSkillsJson { get; set; }

    [MaxLength(200)]
    public string? EducationRequirements { get; set; }

    [Range(1, 1000)]
    public int OpeningsCount { get; set; } = 1;

    public DateTime? ApplicationDeadlineUtc { get; set; }
}

public class UpdateJobOpeningDto : CreateJobOpeningDto
{
    public JobOpeningStatus Status { get; set; } = JobOpeningStatus.Open;
}

public class JobOpeningSummaryDto
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public string EmployerName { get; set; } = string.Empty;
    public string? EmployerCompanyName { get; set; }
    public string? EmployerCity { get; set; }
    public string? EmployerState { get; set; }
    public bool IsEmployerVerified { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Department { get; set; }
    public int? IndustryId { get; set; }
    public string? IndustryName { get; set; }

    public string JobType { get; set; } = "Full-time";
    public string WorkplaceType { get; set; } = "On-site";
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;

    public int MinExperienceYears { get; set; }
    public int? MaxExperienceYears { get; set; }
    public decimal? MinSalary { get; set; }
    public decimal? MaxSalary { get; set; }
    public string SalaryPeriod { get; set; } = "Per Month";

    public int OpeningsCount { get; set; }
    public JobOpeningStatus Status { get; set; }
    public string StatusName => Status.ToString();

    public int ApplicationsCount { get; set; }
    public int ViewCount { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ApplicationDeadlineUtc { get; set; }
}

public class JobOpeningDetailDto : JobOpeningSummaryDto
{
    public string Description { get; set; } = string.Empty;
    public string? Address { get; set; }
    public int? BusinessGroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? CategoryId { get; set; }
    public string? RequiredSkillsJson { get; set; }
    public string? EducationRequirements { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }

    public bool IsOwner { get; set; }
    public bool HasApplied { get; set; }
    public int? MyApplicationId { get; set; }
}

public class JobSearchQueryDto
{
    public string? Query { get; set; }
    public int? IndustryId { get; set; }
    public string? JobType { get; set; }
    public string? WorkplaceType { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public int? MinExperience { get; set; }
    public int? MaxExperience { get; set; }
    public decimal? MinSalary { get; set; }
    public JobOpeningStatus? Status { get; set; } = JobOpeningStatus.Open;

    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class SubmitJobApplicationDto
{
    [Required]
    public int JobOpeningId { get; set; }

    [Required, MaxLength(150)]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress, MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Phone { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? CurrentCompany { get; set; }

    [MaxLength(150)]
    public string? CurrentDesignation { get; set; }

    [Range(0, 50)]
    public int YearsOfExperience { get; set; } = 0;

    [Range(0, 100000000)]
    public decimal? ExpectedSalary { get; set; }

    [Range(0, 365)]
    public int? NoticePeriodDays { get; set; }

    [MaxLength(4000)]
    public string? CoverLetter { get; set; }

    [MaxLength(1000)]
    public string? ResumeUrl { get; set; }

    [MaxLength(255)]
    public string? ResumeFileName { get; set; }
}

public class UpdateJobApplicationStatusDto
{
    [Required]
    public JobApplicationStatus Status { get; set; }

    [MaxLength(1000)]
    public string? Remarks { get; set; }

    [MaxLength(2000)]
    public string? EmployerNotes { get; set; }
}

public class JobApplicationSummaryDto
{
    public int Id { get; set; }
    public string ApplicationNumber { get; set; } = string.Empty;
    public int JobOpeningId { get; set; }
    public string JobTitle { get; set; } = string.Empty;
    public string? EmployerCompanyName { get; set; }

    public int ApplicantMemberId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;

    public string? CurrentCompany { get; set; }
    public string? CurrentDesignation { get; set; }
    public int YearsOfExperience { get; set; }
    public decimal? ExpectedSalary { get; set; }
    public string? ResumeUrl { get; set; }
    public string? ResumeFileName { get; set; }

    public JobApplicationStatus Status { get; set; }
    public string StatusName => Status.ToString();
    public DateTime CreatedAtUtc { get; set; }
}

public class JobApplicationDetailDto : JobApplicationSummaryDto
{
    public int? NoticePeriodDays { get; set; }
    public string? CoverLetter { get; set; }
    public string? EmployerNotes { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }

    public JobOpeningSummaryDto? JobOpening { get; set; }
    public List<JobApplicationStatusHistoryDto> StatusHistory { get; set; } = new();
}

public class JobApplicationStatusHistoryDto
{
    public int Id { get; set; }
    public JobApplicationStatus? PreviousStatus { get; set; }
    public JobApplicationStatus NewStatus { get; set; }
    public string StatusName => NewStatus.ToString();
    public int ChangedByMemberId { get; set; }
    public string ChangedByName { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public DateTime ChangedAtUtc { get; set; }
}


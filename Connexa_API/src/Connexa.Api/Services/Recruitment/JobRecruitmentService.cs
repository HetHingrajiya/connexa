using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace Connexa.Api.Services.Recruitment;

public class JobRecruitmentService : IJobRecruitmentService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notifications;

    public JobRecruitmentService(ConnexaDbContext db, INotificationService notifications)
    {
        _db = db;
        _notifications = notifications;
    }

    public async Task<(List<JobOpeningSummaryDto> Items, int TotalCount)> SearchJobOpeningsAsync(JobSearchQueryDto query)
    {
        var q = _db.JobOpenings
            .Include(j => j.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(j => j.Industry)
            .AsNoTracking()
            .AsQueryable();

        if (query.Status.HasValue)
        {
            q = q.Where(j => j.Status == query.Status.Value);
        }
        else
        {
            q = q.Where(j => j.Status == JobOpeningStatus.Open);
        }

        if (!string.IsNullOrWhiteSpace(query.Query))
        {
            var term = query.Query.Trim().ToLower();
            q = q.Where(j => j.Title.ToLower().Contains(term) ||
                             j.Description.ToLower().Contains(term) ||
                             (j.Department != null && j.Department.ToLower().Contains(term)));
        }

        if (query.IndustryId.HasValue && query.IndustryId.Value > 0)
        {
            q = q.Where(j => j.IndustryId == query.IndustryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.JobType) && !query.JobType.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            q = q.Where(j => j.JobType == query.JobType);
        }

        if (!string.IsNullOrWhiteSpace(query.WorkplaceType) && !query.WorkplaceType.Equals("All", StringComparison.OrdinalIgnoreCase))
        {
            q = q.Where(j => j.WorkplaceType == query.WorkplaceType);
        }

        if (!string.IsNullOrWhiteSpace(query.City))
        {
            var city = query.City.Trim().ToLower();
            q = q.Where(j => j.City.ToLower().Contains(city));
        }

        if (!string.IsNullOrWhiteSpace(query.State))
        {
            var state = query.State.Trim().ToLower();
            q = q.Where(j => j.State.ToLower().Contains(state));
        }

        if (query.MinExperience.HasValue)
        {
            q = q.Where(j => j.MinExperienceYears <= query.MinExperience.Value);
        }

        if (query.MaxExperience.HasValue)
        {
            q = q.Where(j => j.MaxExperienceYears == null || j.MaxExperienceYears <= query.MaxExperience.Value);
        }

        if (query.MinSalary.HasValue)
        {
            q = q.Where(j => j.MaxSalary == null || j.MaxSalary >= query.MinSalary.Value);
        }

        var total = await q.CountAsync();

        var page = query.PageNumber > 0 ? query.PageNumber : 1;
        var size = query.PageSize > 0 ? query.PageSize : 20;

        var items = await q
            .OrderByDescending(j => j.CreatedAtUtc)
            .Skip((page - 1) * size)
            .Take(size)
            .Select(j => MapToSummaryDto(j))
            .ToListAsync();

        return (items, total);
    }

    public async Task<JobOpeningDetailDto?> GetJobOpeningByIdAsync(int id, int? currentMemberId = null)
    {
        var job = await _db.JobOpenings
            .Include(j => j.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(j => j.Industry)
            .FirstOrDefaultAsync(j => j.Id == id);

        if (job == null) return null;

        job.ViewCount++;
        await _db.SaveChangesAsync();

        var dto = MapToDetailDto(job);

        if (currentMemberId.HasValue)
        {
            dto.IsOwner = job.MemberId == currentMemberId.Value;

            var existingApp = await _db.JobApplications
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.JobOpeningId == id &&
                                          a.ApplicantMemberId == currentMemberId.Value &&
                                          a.Status != JobApplicationStatus.Withdrawn);

            if (existingApp != null)
            {
                dto.HasApplied = true;
                dto.MyApplicationId = existingApp.Id;
            }
        }

        return dto;
    }

    public async Task<JobOpeningDetailDto> CreateJobOpeningAsync(int employerMemberId, CreateJobOpeningDto dto)
    {
        var member = await _db.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == employerMemberId)
            ?? throw new KeyNotFoundException("Employer member account not found.");

        var job = new JobOpening
        {
            MemberId = employerMemberId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            Department = dto.Department?.Trim(),
            IndustryId = dto.IndustryId,
            BusinessGroupId = dto.BusinessGroupId,
            SubGroupId = dto.SubGroupId,
            CategoryId = dto.CategoryId,
            JobType = string.IsNullOrWhiteSpace(dto.JobType) ? "Full-time" : dto.JobType.Trim(),
            WorkplaceType = string.IsNullOrWhiteSpace(dto.WorkplaceType) ? "On-site" : dto.WorkplaceType.Trim(),
            City = dto.City.Trim(),
            State = dto.State.Trim(),
            Address = dto.Address?.Trim(),
            MinExperienceYears = dto.MinExperienceYears,
            MaxExperienceYears = dto.MaxExperienceYears,
            MinSalary = dto.MinSalary,
            MaxSalary = dto.MaxSalary,
            SalaryPeriod = string.IsNullOrWhiteSpace(dto.SalaryPeriod) ? "Per Month" : dto.SalaryPeriod.Trim(),
            RequiredSkillsJson = dto.RequiredSkillsJson?.Trim(),
            EducationRequirements = dto.EducationRequirements?.Trim(),
            OpeningsCount = dto.OpeningsCount > 0 ? dto.OpeningsCount : 1,
            Status = JobOpeningStatus.Open,
            ApplicationDeadlineUtc = dto.ApplicationDeadlineUtc,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.JobOpenings.Add(job);
        await _db.SaveChangesAsync();

        return await GetJobOpeningByIdAsync(job.Id, employerMemberId)
            ?? throw new InvalidOperationException("Failed to load created job opening.");
    }

    public async Task<JobOpeningDetailDto> UpdateJobOpeningAsync(int employerMemberId, int id, UpdateJobOpeningDto dto)
    {
        var job = await _db.JobOpenings
            .FirstOrDefaultAsync(j => j.Id == id)
            ?? throw new KeyNotFoundException("Job opening not found.");

        if (job.MemberId != employerMemberId)
        {
            throw new UnauthorizedAccessException("You are not authorized to update this job opening.");
        }

        job.Title = dto.Title.Trim();
        job.Description = dto.Description.Trim();
        job.Department = dto.Department?.Trim();
        job.IndustryId = dto.IndustryId;
        job.BusinessGroupId = dto.BusinessGroupId;
        job.SubGroupId = dto.SubGroupId;
        job.CategoryId = dto.CategoryId;
        job.JobType = string.IsNullOrWhiteSpace(dto.JobType) ? "Full-time" : dto.JobType.Trim();
        job.WorkplaceType = string.IsNullOrWhiteSpace(dto.WorkplaceType) ? "On-site" : dto.WorkplaceType.Trim();
        job.City = dto.City.Trim();
        job.State = dto.State.Trim();
        job.Address = dto.Address?.Trim();
        job.MinExperienceYears = dto.MinExperienceYears;
        job.MaxExperienceYears = dto.MaxExperienceYears;
        job.MinSalary = dto.MinSalary;
        job.MaxSalary = dto.MaxSalary;
        job.SalaryPeriod = string.IsNullOrWhiteSpace(dto.SalaryPeriod) ? "Per Month" : dto.SalaryPeriod.Trim();
        job.RequiredSkillsJson = dto.RequiredSkillsJson?.Trim();
        job.EducationRequirements = dto.EducationRequirements?.Trim();
        job.OpeningsCount = dto.OpeningsCount > 0 ? dto.OpeningsCount : 1;
        job.Status = dto.Status;
        job.ApplicationDeadlineUtc = dto.ApplicationDeadlineUtc;
        job.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return await GetJobOpeningByIdAsync(job.Id, employerMemberId)
            ?? throw new InvalidOperationException("Failed to load updated job opening.");
    }

    public async Task<bool> CloseJobOpeningAsync(int employerMemberId, int id)
    {
        var job = await _db.JobOpenings
            .FirstOrDefaultAsync(j => j.Id == id)
            ?? throw new KeyNotFoundException("Job opening not found.");

        if (job.MemberId != employerMemberId)
        {
            throw new UnauthorizedAccessException("You are not authorized to close this job opening.");
        }

        job.Status = JobOpeningStatus.Closed;
        job.UpdatedAtUtc = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<List<JobOpeningSummaryDto>> GetMyPostedJobsAsync(int employerMemberId)
    {
        return await _db.JobOpenings
            .Include(j => j.Member)
                .ThenInclude(m => m.BusinessProfile)
            .Include(j => j.Industry)
            .AsNoTracking()
            .Where(j => j.MemberId == employerMemberId)
            .OrderByDescending(j => j.CreatedAtUtc)
            .Select(j => MapToSummaryDto(j))
            .ToListAsync();
    }

    public async Task<JobApplicationDetailDto> ApplyForJobAsync(int applicantMemberId, SubmitJobApplicationDto dto)
    {
        var job = await _db.JobOpenings
            .Include(j => j.Member)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(j => j.Id == dto.JobOpeningId)
            ?? throw new KeyNotFoundException("Job opening not found.");

        if (job.Status != JobOpeningStatus.Open)
        {
            throw new InvalidOperationException("This job opening is no longer accepting applications.");
        }

        if (job.MemberId == applicantMemberId)
        {
            throw new InvalidOperationException("You cannot apply to your own job opening.");
        }

        var hasExisting = await _db.JobApplications.AnyAsync(a =>
            a.JobOpeningId == dto.JobOpeningId &&
            a.ApplicantMemberId == applicantMemberId &&
            a.Status != JobApplicationStatus.Withdrawn);

        if (hasExisting)
        {
            throw new InvalidOperationException("You have already submitted an active application for this job opening.");
        }

        var appNumber = GenerateApplicationNumber();

        var application = new JobApplication
        {
            ApplicationNumber = appNumber,
            JobOpeningId = dto.JobOpeningId,
            ApplicantMemberId = applicantMemberId,
            FullName = dto.FullName.Trim(),
            Email = dto.Email.Trim().ToLower(),
            Phone = dto.Phone.Trim(),
            CurrentCompany = dto.CurrentCompany?.Trim(),
            CurrentDesignation = dto.CurrentDesignation?.Trim(),
            YearsOfExperience = dto.YearsOfExperience,
            ExpectedSalary = dto.ExpectedSalary,
            NoticePeriodDays = dto.NoticePeriodDays,
            CoverLetter = dto.CoverLetter?.Trim(),
            ResumeUrl = dto.ResumeUrl?.Trim(),
            ResumeFileName = dto.ResumeFileName?.Trim(),
            Status = JobApplicationStatus.Submitted,
            CreatedAtUtc = DateTime.UtcNow
        };

        application.StatusHistory.Add(new JobApplicationStatusHistory
        {
            PreviousStatus = null,
            NewStatus = JobApplicationStatus.Submitted,
            ChangedByMemberId = applicantMemberId,
            Remarks = "Application submitted by candidate",
            ChangedAtUtc = DateTime.UtcNow
        });

        job.ApplicationsCount++;

        _db.JobApplications.Add(application);
        await _db.SaveChangesAsync();

        // Dispatch notification to employer
        try
        {
            await _notifications.CreateNotificationAsync(
                recipientMemberId: job.MemberId,
                eventType: NotificationEventType.JobApplicationReceived,
                title: "New Job Application Received",
                message: $"{dto.FullName} applied for '{job.Title}'.",
                referenceType: "job_application",
                referenceId: application.Id,
                actorMemberId: applicantMemberId
            );
        }
        catch
        {
            // Do not fail application creation on notification failure
        }

        return await GetApplicationDetailAsync(applicantMemberId, application.Id)
            ?? throw new InvalidOperationException("Failed to load submitted job application.");
    }

    public async Task<List<JobApplicationSummaryDto>> GetMyApplicationsAsync(int applicantMemberId)
    {
        return await _db.JobApplications
            .Include(a => a.JobOpening)
                .ThenInclude(j => j.Member)
                    .ThenInclude(m => m.BusinessProfile)
            .AsNoTracking()
            .Where(a => a.ApplicantMemberId == applicantMemberId)
            .OrderByDescending(a => a.CreatedAtUtc)
            .Select(a => MapToApplicationSummaryDto(a))
            .ToListAsync();
    }

    public async Task<List<JobApplicationSummaryDto>> GetApplicationsForJobAsync(int employerMemberId, int jobOpeningId)
    {
        var job = await _db.JobOpenings.AsNoTracking().FirstOrDefaultAsync(j => j.Id == jobOpeningId)
            ?? throw new KeyNotFoundException("Job opening not found.");

        if (job.MemberId != employerMemberId)
        {
            throw new UnauthorizedAccessException("You are not authorized to view applications for this job opening.");
        }

        return await _db.JobApplications
            .Include(a => a.JobOpening)
                .ThenInclude(j => j.Member)
                    .ThenInclude(m => m.BusinessProfile)
            .AsNoTracking()
            .Where(a => a.JobOpeningId == jobOpeningId)
            .OrderByDescending(a => a.CreatedAtUtc)
            .Select(a => MapToApplicationSummaryDto(a))
            .ToListAsync();
    }

    public async Task<JobApplicationDetailDto?> GetApplicationDetailAsync(int currentMemberId, int applicationId)
    {
        var app = await _db.JobApplications
            .Include(a => a.JobOpening)
                .ThenInclude(j => j.Member)
                    .ThenInclude(m => m.BusinessProfile)
            .Include(a => a.JobOpening)
                .ThenInclude(j => j.Industry)
            .Include(a => a.StatusHistory)
                .ThenInclude(h => h.ChangedByMember)
            .FirstOrDefaultAsync(a => a.Id == applicationId);

        if (app == null) return null;

        var isApplicant = app.ApplicantMemberId == currentMemberId;
        var isEmployer = app.JobOpening.MemberId == currentMemberId;

        if (!isApplicant && !isEmployer)
        {
            throw new UnauthorizedAccessException("You are not authorized to view this application.");
        }

        var dto = new JobApplicationDetailDto
        {
            Id = app.Id,
            ApplicationNumber = app.ApplicationNumber,
            JobOpeningId = app.JobOpeningId,
            JobTitle = app.JobOpening.Title,
            EmployerCompanyName = app.JobOpening.Member.BusinessProfile?.CompanyName,
            ApplicantMemberId = app.ApplicantMemberId,
            FullName = app.FullName,
            Email = app.Email,
            Phone = app.Phone,
            CurrentCompany = app.CurrentCompany,
            CurrentDesignation = app.CurrentDesignation,
            YearsOfExperience = app.YearsOfExperience,
            ExpectedSalary = app.ExpectedSalary,
            NoticePeriodDays = app.NoticePeriodDays,
            CoverLetter = app.CoverLetter,
            ResumeUrl = app.ResumeUrl,
            ResumeFileName = app.ResumeFileName,
            Status = app.Status,
            EmployerNotes = isEmployer ? app.EmployerNotes : null, // keep employer notes internal to employer
            ReviewedAtUtc = app.ReviewedAtUtc,
            CreatedAtUtc = app.CreatedAtUtc,
            UpdatedAtUtc = app.UpdatedAtUtc,
            JobOpening = MapToSummaryDto(app.JobOpening),
            StatusHistory = app.StatusHistory
                .OrderBy(h => h.ChangedAtUtc)
                .Select(h => new JobApplicationStatusHistoryDto
                {
                    Id = h.Id,
                    PreviousStatus = h.PreviousStatus,
                    NewStatus = h.NewStatus,
                    ChangedByMemberId = h.ChangedByMemberId,
                    ChangedByName = h.ChangedByMember.FullName,
                    Remarks = h.Remarks,
                    ChangedAtUtc = h.ChangedAtUtc
                })
                .ToList()
        };

        return dto;
    }

    public async Task<JobApplicationDetailDto> UpdateApplicationStatusAsync(int employerMemberId, int applicationId, UpdateJobApplicationStatusDto dto)
    {
        var app = await _db.JobApplications
            .Include(a => a.JobOpening)
            .FirstOrDefaultAsync(a => a.Id == applicationId)
            ?? throw new KeyNotFoundException("Job application not found.");

        if (app.JobOpening.MemberId != employerMemberId)
        {
            throw new UnauthorizedAccessException("Only the job employer can update the application status.");
        }

        if (app.Status == JobApplicationStatus.Withdrawn)
        {
            throw new InvalidOperationException("Cannot change status of a withdrawn application.");
        }

        var prev = app.Status;
        app.Status = dto.Status;
        app.EmployerNotes = dto.EmployerNotes ?? app.EmployerNotes;
        app.ReviewedAtUtc = DateTime.UtcNow;
        app.UpdatedAtUtc = DateTime.UtcNow;

        _db.JobApplicationStatusHistories.Add(new JobApplicationStatusHistory
        {
            JobApplicationId = app.Id,
            PreviousStatus = prev,
            NewStatus = dto.Status,
            ChangedByMemberId = employerMemberId,
            Remarks = dto.Remarks,
            ChangedAtUtc = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();

        // Notify applicant
        try
        {
            await _notifications.CreateNotificationAsync(
                recipientMemberId: app.ApplicantMemberId,
                eventType: NotificationEventType.JobApplicationStatusChanged,
                title: "Job Application Status Updated",
                message: $"Your application for '{app.JobOpening.Title}' is now {dto.Status}.",
                referenceType: "job_application",
                referenceId: app.Id,
                actorMemberId: employerMemberId
            );
        }
        catch
        {
        }

        return await GetApplicationDetailAsync(employerMemberId, applicationId)
            ?? throw new InvalidOperationException("Failed to load updated application.");
    }

    public async Task<bool> WithdrawApplicationAsync(int applicantMemberId, int applicationId)
    {
        var app = await _db.JobApplications
            .Include(a => a.JobOpening)
            .FirstOrDefaultAsync(a => a.Id == applicationId)
            ?? throw new KeyNotFoundException("Job application not found.");

        if (app.ApplicantMemberId != applicantMemberId)
        {
            throw new UnauthorizedAccessException("You are not authorized to withdraw this application.");
        }

        if (app.Status == JobApplicationStatus.Withdrawn)
        {
            return true;
        }

        var prev = app.Status;
        app.Status = JobApplicationStatus.Withdrawn;
        app.UpdatedAtUtc = DateTime.UtcNow;

        _db.JobApplicationStatusHistories.Add(new JobApplicationStatusHistory
        {
            JobApplicationId = app.Id,
            PreviousStatus = prev,
            NewStatus = JobApplicationStatus.Withdrawn,
            ChangedByMemberId = applicantMemberId,
            Remarks = "Application withdrawn by candidate",
            ChangedAtUtc = DateTime.UtcNow
        });

        if (app.JobOpening.ApplicationsCount > 0)
        {
            app.JobOpening.ApplicationsCount--;
        }

        await _db.SaveChangesAsync();
        return true;
    }

    private static string GenerateApplicationNumber()
    {
        var yyyymm = DateTime.UtcNow.ToString("yyyyMM");
        var rand = Random.Shared.Next(1000, 9999);
        return $"APP-JOB-{yyyymm}-{rand}";
    }

    private static JobOpeningSummaryDto MapToSummaryDto(JobOpening j)
    {
        return new JobOpeningSummaryDto
        {
            Id = j.Id,
            MemberId = j.MemberId,
            EmployerName = j.Member?.FullName ?? "Employer",
            EmployerCompanyName = j.Member?.BusinessProfile?.CompanyName,
            EmployerCity = j.Member?.BusinessProfile?.City,
            EmployerState = j.Member?.BusinessProfile?.State,
            IsEmployerVerified = j.Member?.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Title = j.Title,
            Department = j.Department,
            IndustryId = j.IndustryId,
            IndustryName = j.Industry?.Name,
            JobType = j.JobType,
            WorkplaceType = j.WorkplaceType,
            City = j.City,
            State = j.State,
            MinExperienceYears = j.MinExperienceYears,
            MaxExperienceYears = j.MaxExperienceYears,
            MinSalary = j.MinSalary,
            MaxSalary = j.MaxSalary,
            SalaryPeriod = j.SalaryPeriod,
            OpeningsCount = j.OpeningsCount,
            Status = j.Status,
            ApplicationsCount = j.ApplicationsCount,
            ViewCount = j.ViewCount,
            CreatedAtUtc = j.CreatedAtUtc,
            ApplicationDeadlineUtc = j.ApplicationDeadlineUtc
        };
    }

    private static JobOpeningDetailDto MapToDetailDto(JobOpening j)
    {
        return new JobOpeningDetailDto
        {
            Id = j.Id,
            MemberId = j.MemberId,
            EmployerName = j.Member?.FullName ?? "Employer",
            EmployerCompanyName = j.Member?.BusinessProfile?.CompanyName,
            EmployerCity = j.Member?.BusinessProfile?.City,
            EmployerState = j.Member?.BusinessProfile?.State,
            IsEmployerVerified = j.Member?.BusinessProfile?.VerificationStatus == BusinessVerificationStatus.Approved,
            Title = j.Title,
            Department = j.Department,
            IndustryId = j.IndustryId,
            IndustryName = j.Industry?.Name,
            BusinessGroupId = j.BusinessGroupId,
            SubGroupId = j.SubGroupId,
            CategoryId = j.CategoryId,
            JobType = j.JobType,
            WorkplaceType = j.WorkplaceType,
            City = j.City,
            State = j.State,
            Address = j.Address,
            MinExperienceYears = j.MinExperienceYears,
            MaxExperienceYears = j.MaxExperienceYears,
            MinSalary = j.MinSalary,
            MaxSalary = j.MaxSalary,
            SalaryPeriod = j.SalaryPeriod,
            OpeningsCount = j.OpeningsCount,
            Status = j.Status,
            ApplicationsCount = j.ApplicationsCount,
            ViewCount = j.ViewCount,
            CreatedAtUtc = j.CreatedAtUtc,
            UpdatedAtUtc = j.UpdatedAtUtc,
            ApplicationDeadlineUtc = j.ApplicationDeadlineUtc,
            Description = j.Description,
            RequiredSkillsJson = j.RequiredSkillsJson,
            EducationRequirements = j.EducationRequirements
        };
    }

    private static JobApplicationSummaryDto MapToApplicationSummaryDto(JobApplication a)
    {
        return new JobApplicationSummaryDto
        {
            Id = a.Id,
            ApplicationNumber = a.ApplicationNumber,
            JobOpeningId = a.JobOpeningId,
            JobTitle = a.JobOpening?.Title ?? "Job Opening",
            EmployerCompanyName = a.JobOpening?.Member?.BusinessProfile?.CompanyName,
            ApplicantMemberId = a.ApplicantMemberId,
            FullName = a.FullName,
            Email = a.Email,
            Phone = a.Phone,
            CurrentCompany = a.CurrentCompany,
            CurrentDesignation = a.CurrentDesignation,
            YearsOfExperience = a.YearsOfExperience,
            ExpectedSalary = a.ExpectedSalary,
            ResumeUrl = a.ResumeUrl,
            ResumeFileName = a.ResumeFileName,
            Status = a.Status,
            CreatedAtUtc = a.CreatedAtUtc
        };
    }
}

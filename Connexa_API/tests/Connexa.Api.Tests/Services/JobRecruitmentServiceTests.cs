namespace Connexa.Api.Tests.Services;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Connexa.Api.Services.Recruitment;

public class JobRecruitmentServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly JobRecruitmentService _service;
    private readonly NotificationService _notificationService;

    public JobRecruitmentServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaRecruitmentTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);
        _service = new JobRecruitmentService(_dbContext, _notificationService);

        SeedData();
    }

    private void SeedData()
    {
        var industry = new Industry
        {
            Id = 1,
            Name = "Industrial Machinery & Manufacturing",
            Description = "Heavy engineering and machinery"
        };
        _dbContext.Industries.Add(industry);

        var employer = new Member
        {
            Id = 301,
            FullName = "Precision Machine Tools Corp",
            Email = "hr@precisiontools.test",
            CountryCode = "+91",
            PhoneNumber = "9876500001",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 301,
                MemberId = 301,
                CompanyName = "Precision Machine Tools Corp",
                City = "Rajkot",
                State = "Gujarat",
                IndustryId = 1,
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        var candidate = new Member
        {
            Id = 302,
            FullName = "Bhavin Patel",
            Email = "bhavin.cnc@test.com",
            CountryCode = "+91",
            PhoneNumber = "9876500002",
            Role = "Member",
            IsActive = true
        };

        var job = new JobOpening
        {
            Id = 1,
            MemberId = 301,
            Title = "Senior CNC Machine Operator",
            Description = "Looking for skilled 5-axis CNC operator with VMC experience.",
            Department = "Manufacturing",
            IndustryId = 1,
            JobType = "Full-time",
            WorkplaceType = "On-site",
            City = "Rajkot",
            State = "Gujarat",
            MinExperienceYears = 3,
            MaxExperienceYears = 8,
            MinSalary = 35000,
            MaxSalary = 50000,
            SalaryPeriod = "Per Month",
            OpeningsCount = 2,
            Status = JobOpeningStatus.Open,
            ViewCount = 10,
            ApplicationsCount = 0,
            CreatedAtUtc = DateTime.UtcNow.AddDays(-2)
        };

        _dbContext.Members.AddRange(employer, candidate);
        _dbContext.JobOpenings.Add(job);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task SearchJobOpeningsAsync_FiltersByQueryAndIndustry()
    {
        var query = new JobSearchQueryDto
        {
            Query = "CNC",
            IndustryId = 1,
            Status = JobOpeningStatus.Open
        };

        var (items, total) = await _service.SearchJobOpeningsAsync(query);

        Assert.Equal(1, total);
        Assert.Single(items);
        Assert.Equal("Senior CNC Machine Operator", items[0].Title);
        Assert.Equal("Rajkot", items[0].City);
    }

    [Fact]
    public async Task GetJobOpeningByIdAsync_IncrementsViewCountAndSetsHasApplied()
    {
        var initial = await _dbContext.JobOpenings.AsNoTracking().FirstAsync(j => j.Id == 1);
        Assert.Equal(10, initial.ViewCount);

        var result = await _service.GetJobOpeningByIdAsync(1, 302);

        Assert.NotNull(result);
        Assert.Equal(11, result.ViewCount);
        Assert.False(result.IsOwner);
        Assert.False(result.HasApplied);

        var ownerResult = await _service.GetJobOpeningByIdAsync(1, 301);
        Assert.NotNull(ownerResult);
        Assert.True(ownerResult.IsOwner);
    }

    [Fact]
    public async Task CreateJobOpeningAsync_ValidData_CreatesOpenJob()
    {
        var dto = new CreateJobOpeningDto
        {
            Title = "Quality Assurance Engineer",
            Description = "ISO 9001 standard inspection for fabricated parts.",
            Department = "Quality",
            IndustryId = 1,
            JobType = "Full-time",
            WorkplaceType = "On-site",
            City = "Ahmedabad",
            State = "Gujarat",
            MinExperienceYears = 2,
            MinSalary = 40000,
            OpeningsCount = 1
        };

        var created = await _service.CreateJobOpeningAsync(301, dto);

        Assert.True(created.Id > 1);
        Assert.Equal("Quality Assurance Engineer", created.Title);
        Assert.Equal(JobOpeningStatus.Open, created.Status);
        Assert.Equal(0, created.ApplicationsCount);
    }

    [Fact]
    public async Task UpdateJobOpeningAsync_NonOwner_ThrowsUnauthorized()
    {
        var dto = new UpdateJobOpeningDto
        {
            Title = "Malicious update",
            Description = "Should not work",
            City = "Rajkot",
            State = "Gujarat"
        };

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            _service.UpdateJobOpeningAsync(302, 1, dto));
    }

    [Fact]
    public async Task UpdateJobOpeningAsync_Owner_UpdatesFields()
    {
        var dto = new UpdateJobOpeningDto
        {
            Title = "Lead CNC Machine Operator & Programmer",
            Description = "Updated with programming responsibilities.",
            City = "Rajkot",
            State = "Gujarat",
            MinExperienceYears = 4,
            MinSalary = 45000,
            Status = JobOpeningStatus.Open
        };

        var updated = await _service.UpdateJobOpeningAsync(301, 1, dto);

        Assert.Equal("Lead CNC Machine Operator & Programmer", updated.Title);
        Assert.Equal(4, updated.MinExperienceYears);
        Assert.Equal(45000, updated.MinSalary);
    }

    [Fact]
    public async Task CloseJobOpeningAsync_Owner_ClosesJob()
    {
        var closed = await _service.CloseJobOpeningAsync(301, 1);
        Assert.True(closed);

        var job = await _dbContext.JobOpenings.FirstAsync(j => j.Id == 1);
        Assert.Equal(JobOpeningStatus.Closed, job.Status);
    }

    [Fact]
    public async Task CloseJobOpeningAsync_NonOwner_ThrowsUnauthorized()
    {
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            _service.CloseJobOpeningAsync(302, 1));
    }

    [Fact]
    public async Task ApplyForJobAsync_ValidApplication_CreatesApplicationAndNotifiesEmployer()
    {
        var dto = new SubmitJobApplicationDto
        {
            JobOpeningId = 1,
            FullName = "Bhavin Patel",
            Email = "bhavin@test.com",
            Phone = "+919876500002",
            CurrentCompany = "Shreeji Engineering",
            CurrentDesignation = "CNC Turner",
            YearsOfExperience = 5,
            ExpectedSalary = 45000,
            NoticePeriodDays = 15,
            CoverLetter = "Experienced in Fanuc & Siemens controllers.",
            ResumeUrl = "https://storage.connexa.test/resumes/bhavin.pdf",
            ResumeFileName = "bhavin_resume.pdf"
        };

        var app = await _service.ApplyForJobAsync(302, dto);

        Assert.NotNull(app);
        Assert.StartsWith("APP-JOB-", app.ApplicationNumber);
        Assert.Equal(JobApplicationStatus.Submitted, app.Status);
        Assert.Equal(1, app.JobOpeningId);
        Assert.Equal(302, app.ApplicantMemberId);

        var job = await _dbContext.JobOpenings.FirstAsync(j => j.Id == 1);
        Assert.Equal(1, job.ApplicationsCount);

        var notifications = await _dbContext.Notifications
            .Where(n => n.RecipientMemberId == 301)
            .ToListAsync();
        Assert.Contains(notifications, n => n.EventType == NotificationEventType.JobApplicationReceived);
    }

    [Fact]
    public async Task ApplyForJobAsync_OwnerApplyingToOwnJob_ThrowsInvalidOperation()
    {
        var dto = new SubmitJobApplicationDto
        {
            JobOpeningId = 1,
            FullName = "Self Apply",
            Email = "hr@precisiontools.test",
            Phone = "+919876500001"
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.ApplyForJobAsync(301, dto));
        Assert.Contains("cannot apply to your own job", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ApplyForJobAsync_DuplicateActiveApplication_ThrowsInvalidOperation()
    {
        var dto = new SubmitJobApplicationDto
        {
            JobOpeningId = 1,
            FullName = "Bhavin Patel",
            Email = "bhavin@test.com",
            Phone = "+919876500002"
        };

        await _service.ApplyForJobAsync(302, dto);

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.ApplyForJobAsync(302, dto));
        Assert.Contains("already submitted an active application", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task UpdateApplicationStatusAsync_Employer_UpdatesStatusAndNotifiesApplicant()
    {
        var app = await _service.ApplyForJobAsync(302, new SubmitJobApplicationDto
        {
            JobOpeningId = 1,
            FullName = "Bhavin Patel",
            Email = "bhavin@test.com",
            Phone = "+919876500002"
        });

        var updateDto = new UpdateJobApplicationStatusDto
        {
            Status = JobApplicationStatus.Shortlisted,
            Remarks = "Candidate selected for in-person machining test",
            EmployerNotes = "Good Siemens controller background"
        };

        var updated = await _service.UpdateApplicationStatusAsync(301, app.Id, updateDto);

        Assert.Equal(JobApplicationStatus.Shortlisted, updated.Status);
        Assert.Equal("Good Siemens controller background", updated.EmployerNotes);

        var candidateNotification = await _dbContext.Notifications
            .FirstOrDefaultAsync(n => n.RecipientMemberId == 302 && n.EventType == NotificationEventType.JobApplicationStatusChanged);
        Assert.NotNull(candidateNotification);
    }

    [Fact]
    public async Task WithdrawApplicationAsync_Applicant_WithdrawsApplicationAndDecrementsCount()
    {
        var app = await _service.ApplyForJobAsync(302, new SubmitJobApplicationDto
        {
            JobOpeningId = 1,
            FullName = "Bhavin Patel",
            Email = "bhavin@test.com",
            Phone = "+919876500002"
        });

        var jobBefore = await _dbContext.JobOpenings.FirstAsync(j => j.Id == 1);
        Assert.Equal(1, jobBefore.ApplicationsCount);

        var success = await _service.WithdrawApplicationAsync(302, app.Id);
        Assert.True(success);

        var appAfter = await _dbContext.JobApplications.FirstAsync(a => a.Id == app.Id);
        Assert.Equal(JobApplicationStatus.Withdrawn, appAfter.Status);

        var jobAfter = await _dbContext.JobOpenings.FirstAsync(j => j.Id == 1);
        Assert.Equal(0, jobAfter.ApplicationsCount);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

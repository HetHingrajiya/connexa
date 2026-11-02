using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Recruitment;

public interface IJobRecruitmentService
{
    Task<(List<JobOpeningSummaryDto> Items, int TotalCount)> SearchJobOpeningsAsync(JobSearchQueryDto query);
    Task<JobOpeningDetailDto?> GetJobOpeningByIdAsync(int id, int? currentMemberId = null);
    Task<JobOpeningDetailDto> CreateJobOpeningAsync(int employerMemberId, CreateJobOpeningDto dto);
    Task<JobOpeningDetailDto> UpdateJobOpeningAsync(int employerMemberId, int id, UpdateJobOpeningDto dto);
    Task<bool> CloseJobOpeningAsync(int employerMemberId, int id);
    Task<List<JobOpeningSummaryDto>> GetMyPostedJobsAsync(int employerMemberId);

    Task<JobApplicationDetailDto> ApplyForJobAsync(int applicantMemberId, SubmitJobApplicationDto dto);
    Task<List<JobApplicationSummaryDto>> GetMyApplicationsAsync(int applicantMemberId);
    Task<List<JobApplicationSummaryDto>> GetApplicationsForJobAsync(int employerMemberId, int jobOpeningId);
    Task<JobApplicationDetailDto?> GetApplicationDetailAsync(int currentMemberId, int applicationId);
    Task<JobApplicationDetailDto> UpdateApplicationStatusAsync(int employerMemberId, int applicationId, UpdateJobApplicationStatusDto dto);
    Task<bool> WithdrawApplicationAsync(int applicantMemberId, int applicationId);
}


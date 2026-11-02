using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Recruitment;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/job-applications")]
[Authorize]
public class JobApplicationsController : ControllerBase
{
    private readonly IJobRecruitmentService _recruitmentService;
    private readonly ILogger<JobApplicationsController> _logger;

    public JobApplicationsController(IJobRecruitmentService recruitmentService, ILogger<JobApplicationsController> logger)
    {
        _recruitmentService = recruitmentService;
        _logger = logger;
    }

    /// <summary>
    /// Submits a job application for a job opening.
    /// POST /api/v1/job-applications
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<JobApplicationDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ApplyForJob([FromBody] SubmitJobApplicationDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new ErrorResponseDto
            {
                Success = false,
                Message = "Validation failed",
                Error = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage))
            });
        }

        var memberId = GetCurrentMemberId();
        try
        {
            var application = await _recruitmentService.ApplyForJobAsync(memberId, dto);
            return CreatedAtAction(nameof(GetApplicationById), new { id = application.Id },
                ApiResponse<JobApplicationDetailDto>.WithMessage(application, "Job application submitted successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
    }

    /// <summary>
    /// Retrieves applications submitted by the current authenticated member.
    /// GET /api/v1/job-applications/my
    /// </summary>
    [HttpGet("my")]
    [ProducesResponseType(typeof(ApiResponse<List<JobApplicationSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyApplications()
    {
        var memberId = GetCurrentMemberId();
        var applications = await _recruitmentService.GetMyApplicationsAsync(memberId);
        return Ok(ApiResponse<List<JobApplicationSummaryDto>>.Ok(applications, applications.Count));
    }

    /// <summary>
    /// Retrieves all applications received for a specific job opening (employer only).
    /// GET /api/v1/job-applications/job/{jobOpeningId}
    /// </summary>
    [HttpGet("job/{jobOpeningId:int}")]
    [ProducesResponseType(typeof(ApiResponse<List<JobApplicationSummaryDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetApplicationsForJob(int jobOpeningId)
    {
        var memberId = GetCurrentMemberId();
        try
        {
            var applications = await _recruitmentService.GetApplicationsForJobAsync(memberId, jobOpeningId);
            return Ok(ApiResponse<List<JobApplicationSummaryDto>>.Ok(applications, applications.Count));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new ErrorResponseDto { Success = false, Message = ex.Message });
        }
    }

    /// <summary>
    /// Retrieves application detail with timeline. Authorized only for candidate and employer.
    /// GET /api/v1/job-applications/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<JobApplicationDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetApplicationById(int id)
    {
        var memberId = GetCurrentMemberId();
        try
        {
            var app = await _recruitmentService.GetApplicationDetailAsync(memberId, id);
            if (app == null)
            {
                return NotFound(new ErrorResponseDto { Success = false, Message = $"Job application with ID {id} not found." });
            }

            return Ok(ApiResponse<JobApplicationDetailDto>.Ok(app));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new ErrorResponseDto { Success = false, Message = ex.Message });
        }
    }

    /// <summary>
    /// Updates the status of an application (employer only).
    /// PUT /api/v1/job-applications/{id}/status
    /// </summary>
    [HttpPut("{id:int}/status")]
    [ProducesResponseType(typeof(ApiResponse<JobApplicationDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateApplicationStatus(int id, [FromBody] UpdateJobApplicationStatusDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new ErrorResponseDto { Success = false, Message = "Validation failed", Error = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)) });
        }

        var memberId = GetCurrentMemberId();
        try
        {
            var updated = await _recruitmentService.UpdateApplicationStatusAsync(memberId, id, dto);
            return Ok(ApiResponse<JobApplicationDetailDto>.WithMessage(updated, "Application status updated successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new ErrorResponseDto { Success = false, Message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
    }

    /// <summary>
    /// Candidate withdraws their application.
    /// PUT /api/v1/job-applications/{id}/withdraw
    /// </summary>
    [HttpPut("{id:int}/withdraw")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> WithdrawApplication(int id)
    {
        var memberId = GetCurrentMemberId();
        try
        {
            var result = await _recruitmentService.WithdrawApplicationAsync(memberId, id);
            return Ok(ApiResponse<bool>.WithMessage(result, "Job application withdrawn successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new ErrorResponseDto { Success = false, Message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new ErrorResponseDto { Success = false, Message = ex.Message });
        }
    }

    private int GetCurrentMemberId()
    {
        var subClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value
            ?? User.FindFirst("id")?.Value;

        if (int.TryParse(subClaim, out var memberId))
        {
            return memberId;
        }

        throw new UnauthorizedAccessException("Invalid or missing user ID claim in authentication token.");
    }
}


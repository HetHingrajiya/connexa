using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Recruitment;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/jobs")]
public class JobsController : ControllerBase
{
    private readonly IJobRecruitmentService _recruitmentService;
    private readonly ILogger<JobsController> _logger;

    public JobsController(IJobRecruitmentService recruitmentService, ILogger<JobsController> logger)
    {
        _recruitmentService = recruitmentService;
        _logger = logger;
    }

    /// <summary>
    /// Searches active job openings with full-text search, filters and pagination.
    /// GET /api/v1/jobs
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<JobOpeningSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SearchJobs(
        [FromQuery] string? query,
        [FromQuery] int? industryId,
        [FromQuery] string? jobType,
        [FromQuery] string? workplaceType,
        [FromQuery] string? city,
        [FromQuery] string? state,
        [FromQuery] int? minExperience,
        [FromQuery] int? maxExperience,
        [FromQuery] decimal? minSalary,
        [FromQuery] JobOpeningStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var searchQuery = new JobSearchQueryDto
        {
            Query = query,
            IndustryId = industryId,
            JobType = jobType,
            WorkplaceType = workplaceType,
            City = city,
            State = state,
            MinExperience = minExperience,
            MaxExperience = maxExperience,
            MinSalary = minSalary,
            Status = status ?? JobOpeningStatus.Open,
            PageNumber = page,
            PageSize = pageSize
        };

        var (items, totalCount) = await _recruitmentService.SearchJobOpeningsAsync(searchQuery);
        return Ok(ApiResponse<List<JobOpeningSummaryDto>>.Ok(items, totalCount));
    }

    /// <summary>
    /// Retrieves full details of a job opening.
    /// GET /api/v1/jobs/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<JobOpeningDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetJobById(int id)
    {
        int? currentMemberId = null;
        if (User.Identity?.IsAuthenticated == true)
        {
            currentMemberId = GetCurrentMemberId();
        }

        var job = await _recruitmentService.GetJobOpeningByIdAsync(id, currentMemberId);
        if (job == null)
        {
            return NotFound(new ErrorResponseDto { Success = false, Message = $"Job opening with ID {id} not found." });
        }

        return Ok(ApiResponse<JobOpeningDetailDto>.Ok(job));
    }

    /// <summary>
    /// Retrieves job openings published by the authenticated employer.
    /// GET /api/v1/jobs/my
    /// </summary>
    [HttpGet("my")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<List<JobOpeningSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyPostedJobs()
    {
        var memberId = GetCurrentMemberId();
        var jobs = await _recruitmentService.GetMyPostedJobsAsync(memberId);
        return Ok(ApiResponse<List<JobOpeningSummaryDto>>.Ok(jobs, jobs.Count));
    }

    /// <summary>
    /// Posts a new job opening for the authenticated employer.
    /// POST /api/v1/jobs
    /// </summary>
    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<JobOpeningDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateJobOpening([FromBody] CreateJobOpeningDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new ErrorResponseDto { Success = false, Message = "Validation failed", Error = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)) });
        }

        var memberId = GetCurrentMemberId();
        var created = await _recruitmentService.CreateJobOpeningAsync(memberId, dto);
        return CreatedAtAction(nameof(GetJobById), new { id = created.Id }, ApiResponse<JobOpeningDetailDto>.WithMessage(created, "Job opening published successfully."));
    }

    /// <summary>
    /// Updates an existing job opening.
    /// PUT /api/v1/jobs/{id}
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<JobOpeningDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateJobOpening(int id, [FromBody] UpdateJobOpeningDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new ErrorResponseDto { Success = false, Message = "Validation failed", Error = string.Join("; ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)) });
        }

        var memberId = GetCurrentMemberId();
        try
        {
            var updated = await _recruitmentService.UpdateJobOpeningAsync(memberId, id, dto);
            return Ok(ApiResponse<JobOpeningDetailDto>.WithMessage(updated, "Job opening updated successfully."));
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
    /// Closes an active job opening.
    /// PUT /api/v1/jobs/{id}/close
    /// </summary>
    [HttpPut("{id:int}/close")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ErrorResponseDto), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CloseJobOpening(int id)
    {
        var memberId = GetCurrentMemberId();
        try
        {
            var success = await _recruitmentService.CloseJobOpeningAsync(memberId, id);
            return Ok(ApiResponse<bool>.WithMessage(success, "Job opening closed successfully."));
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


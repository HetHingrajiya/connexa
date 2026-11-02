using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Feed;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/feed")]
[Authorize]
public class FeedController : ControllerBase
{
    private readonly IBusinessFeedService _feedService;
    private readonly ILogger<FeedController> _logger;

    public FeedController(IBusinessFeedService feedService, ILogger<FeedController> logger)
    {
        _feedService = feedService;
        _logger = logger;
    }

    /// <summary>
    /// Gets paginated community feed posts with optional industry or member filter.
    /// GET /api/v1/feed
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedFeedResponse<PostSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetFeed(
        [FromQuery] int? industryId,
        [FromQuery] int? memberId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PagedFeedResponse<PostSummaryDto>>.Fail("Invalid authentication token."));

        var query = new FeedQueryDto(industryId, memberId, page, pageSize);
        var result = await _feedService.GetFeedAsync(currentMemberId.Value, query, ct);

        return Ok(ApiResponse<PagedFeedResponse<PostSummaryDto>>.Ok(result, result.TotalCount));
    }

    /// <summary>
    /// Gets a single post by id.
    /// GET /api/v1/feed/{id}
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPostById(int id, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PostSummaryDto>.Fail("Invalid authentication token."));

        var post = await _feedService.GetPostByIdAsync(id, currentMemberId.Value, ct);
        if (post == null)
            return NotFound(ApiResponse<PostSummaryDto>.Fail("Post not found."));

        return Ok(ApiResponse<PostSummaryDto>.Ok(post, 1));
    }

    /// <summary>
    /// Publishes a new business post.
    /// POST /api/v1/feed
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreatePost([FromBody] CreatePostDto dto, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PostSummaryDto>.Fail("Invalid authentication token."));

        try
        {
            var created = await _feedService.CreatePostAsync(currentMemberId.Value, dto, ct);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<PostSummaryDto>.Ok(created, 1));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<PostSummaryDto>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Updates an existing business post.
    /// PUT /api/v1/feed/{id}
    /// </summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<PostSummaryDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePost(int id, [FromBody] UpdatePostDto dto, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PostSummaryDto>.Fail("Invalid authentication token."));

        try
        {
            var updated = await _feedService.UpdatePostAsync(id, currentMemberId.Value, dto, ct);
            return Ok(ApiResponse<PostSummaryDto>.Ok(updated, 1));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<PostSummaryDto>.Fail(ex.Message));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<PostSummaryDto>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<PostSummaryDto>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Soft deletes an existing business post.
    /// DELETE /api/v1/feed/{id}
    /// </summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePost(int id, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication token."));

        try
        {
            var success = await _feedService.DeletePostAsync(id, currentMemberId.Value, ct);
            if (!success)
                return NotFound(ApiResponse<bool>.Fail("Post not found."));

            return Ok(ApiResponse<bool>.WithMessage(true, "Post deleted successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<bool>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Toggles like / unlike on a post.
    /// POST /api/v1/feed/{id}/like
    /// </summary>
    [HttpPost("{id:int}/like")]
    [ProducesResponseType(typeof(ApiResponse<ToggleLikeResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ToggleLikeResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleLike(int id, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<ToggleLikeResponseDto>.Fail("Invalid authentication token."));

        try
        {
            var res = await _feedService.ToggleLikeAsync(id, currentMemberId.Value, ct);
            return Ok(ApiResponse<ToggleLikeResponseDto>.Ok(res, 1));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<ToggleLikeResponseDto>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Gets comments for a post.
    /// GET /api/v1/feed/{id}/comments
    /// </summary>
    [HttpGet("{id:int}/comments")]
    [ProducesResponseType(typeof(ApiResponse<List<PostCommentDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetComments(int id, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<List<PostCommentDto>>.Fail("Invalid authentication token."));

        var comments = await _feedService.GetPostCommentsAsync(id, currentMemberId.Value, ct);
        return Ok(ApiResponse<List<PostCommentDto>>.Ok(comments, comments.Count));
    }

    /// <summary>
    /// Adds a comment to a post.
    /// POST /api/v1/feed/{id}/comments
    /// </summary>
    [HttpPost("{id:int}/comments")]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> AddComment(int id, [FromBody] CreateCommentDto dto, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PostCommentDto>.Fail("Invalid authentication token."));

        try
        {
            var comment = await _feedService.AddCommentAsync(id, currentMemberId.Value, dto, ct);
            return StatusCode(StatusCodes.Status201Created, ApiResponse<PostCommentDto>.Ok(comment, 1));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<PostCommentDto>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<PostCommentDto>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Updates a comment.
    /// PUT /api/v1/feed/comments/{commentId}
    /// </summary>
    [HttpPut("comments/{commentId:int}")]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<PostCommentDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateComment(int commentId, [FromBody] UpdateCommentDto dto, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<PostCommentDto>.Fail("Invalid authentication token."));

        try
        {
            var comment = await _feedService.UpdateCommentAsync(commentId, currentMemberId.Value, dto, ct);
            return Ok(ApiResponse<PostCommentDto>.Ok(comment, 1));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<PostCommentDto>.Fail(ex.Message));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<PostCommentDto>.Fail(ex.Message));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<PostCommentDto>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Deletes a comment.
    /// DELETE /api/v1/feed/comments/{commentId}
    /// </summary>
    [HttpDelete("comments/{commentId:int}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteComment(int commentId, CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication token."));

        try
        {
            var success = await _feedService.DeleteCommentAsync(commentId, currentMemberId.Value, ct);
            if (!success)
                return NotFound(ApiResponse<bool>.Fail("Comment not found."));

            return Ok(ApiResponse<bool>.WithMessage(true, "Comment deleted successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<bool>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Reports a post or comment for moderation.
    /// POST /api/v1/feed/report
    /// </summary>
    [HttpPost("report")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ReportContent(
        [FromQuery] int? postId,
        [FromQuery] int? commentId,
        [FromBody] ReportContentDto dto,
        CancellationToken ct = default)
    {
        var currentMemberId = GetCurrentMemberId();
        if (!currentMemberId.HasValue)
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication token."));

        try
        {
            var success = await _feedService.ReportContentAsync(currentMemberId.Value, postId, commentId, dto, ct);
            return Ok(ApiResponse<bool>.WithMessage(success, "Report submitted successfully."));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<bool>.Fail(ex.Message));
        }
    }

    private int? GetCurrentMemberId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (int.TryParse(claim, out var memberId))
        {
            return memberId;
        }
        return null;
    }
}


using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Auth;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/members")]
[Authorize]
public class MembersController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<MembersController> _logger;

    public MembersController(IAuthService authService, ILogger<MembersController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Retrieves current authenticated member profile and domain details.
    /// Derived from validated JWT claims.
    /// GET /api/v1/members/me
    /// </summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentMember(CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<MemberProfileResponseDto>.Fail("Invalid authentication claims."));
        }

        var result = await _authService.GetMemberProfileAsync(memberId, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<MemberProfileResponseDto>.Fail(result.ErrorMessage ?? "Unable to retrieve member profile."));
        }

        return Ok(ApiResponse<MemberProfileResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Updates current authenticated member profile.
    /// Derived strictly from validated JWT claims. Enforces server-side validation and ownership.
    /// PUT /api/v1/members/me/profile
    /// </summary>
    [HttpPut("me/profile")]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<MemberProfileResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCurrentMemberProfile([FromBody] UpdateMemberProfileRequestDto request, CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<MemberProfileResponseDto>.Fail("Invalid authentication claims."));
        }

        var result = await _authService.UpdateMemberProfileAsync(memberId, request, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<MemberProfileResponseDto>.Fail(result.ErrorMessage ?? "Unable to update member profile."));
        }

        return Ok(ApiResponse<MemberProfileResponseDto>.Ok(result.Data!, 1, null));
    }
}

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

    /// <summary>
    /// Changes password for current authenticated member. Requires current password verification.
    /// POST /api/v1/members/me/change-password
    /// </summary>
    [HttpPost("me/change-password")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword(
        [FromBody] ChangePasswordRequestDto request,
        CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.ChangePasswordAsync(memberId, request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<bool>.Fail(result.ErrorMessage ?? "Password change failed."));
        }

        return Ok(ApiResponse<bool>.WithMessage(true, "Password changed successfully."));
    }

    /// <summary>
    /// Lists active sessions for current authenticated member.
    /// GET /api/v1/members/me/sessions
    /// </summary>
    [HttpGet("me/sessions")]
    [ProducesResponseType(typeof(ApiResponse<List<ActiveSessionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ActiveSessionDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetActiveSessions(CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<List<ActiveSessionDto>>.Fail("Invalid authentication claims."));
        }

        var result = await _authService.GetActiveSessionsAsync(memberId, null, cancellationToken);
        return Ok(ApiResponse<List<ActiveSessionDto>>.Ok(result.Data ?? new List<ActiveSessionDto>(), result.Data?.Count ?? 0));
    }

    /// <summary>
    /// Revokes a specific active session.
    /// DELETE /api/v1/members/me/sessions/{id}
    /// </summary>
    [HttpDelete("me/sessions/{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RevokeSession(int id, CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.RevokeSessionAsync(memberId, id, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<bool>.Fail(result.ErrorMessage ?? "Session revocation failed."));
        }

        return Ok(ApiResponse<bool>.WithMessage(true, "Session revoked successfully."));
    }

    /// <summary>
    /// Revokes all other active sessions except current.
    /// POST /api/v1/members/me/sessions/revoke-others
    /// </summary>
    [HttpPost("me/sessions/revoke-others")]
    [ProducesResponseType(typeof(ApiResponse<int>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<int>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RevokeAllOtherSessions(CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<int>.Fail("Invalid authentication claims."));
        }

        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.RevokeAllOtherSessionsAsync(memberId, null, clientIp, cancellationToken);

        return Ok(ApiResponse<int>.WithMessage(result.Data, $"{result.Data} other session(s) revoked successfully."));
    }

    /// <summary>
    /// Deactivates current authenticated member account. Requires password verification.
    /// POST /api/v1/members/me/deactivate
    /// </summary>
    [HttpPost("me/deactivate")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeactivateAccount(
        [FromBody] DeactivateAccountRequestDto request,
        CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.DeactivateAccountAsync(memberId, request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<bool>.Fail(result.ErrorMessage ?? "Deactivation failed."));
        }

        return Ok(ApiResponse<bool>.WithMessage(true, "Account deactivated successfully. All active sessions have been terminated."));
    }

    /// <summary>
    /// Submits a formal account deletion request. Requires password verification and deactivates account immediately.
    /// POST /api/v1/members/me/delete-request
    /// </summary>
    [HttpPost("me/delete-request")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RequestAccountDeletion(
        [FromBody] DeleteAccountRequestDto request,
        CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Invalid authentication claims."));
        }

        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.RequestAccountDeletionAsync(memberId, request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<bool>.Fail(result.ErrorMessage ?? "Deletion request failed."));
        }

        return Ok(ApiResponse<bool>.WithMessage(true, "Account deletion request submitted successfully. Account has been deactivated."));
    }

    /// <summary>
    /// Returns account status and security summary.
    /// GET /api/v1/members/me/account-status
    /// </summary>
    [HttpGet("me/account-status")]
    [ProducesResponseType(typeof(ApiResponse<AccountStatusResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AccountStatusResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAccountStatus(CancellationToken cancellationToken)
    {
        var memberIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(memberIdClaim) || !int.TryParse(memberIdClaim, out var memberId))
        {
            return Unauthorized(ApiResponse<AccountStatusResponseDto>.Fail("Invalid authentication claims."));
        }

        var result = await _authService.GetAccountStatusAsync(memberId, cancellationToken);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<AccountStatusResponseDto>.Fail(result.ErrorMessage ?? "Unable to retrieve account status."));
        }

        return Ok(ApiResponse<AccountStatusResponseDto>.Ok(result.Data!, 1));
    }
}

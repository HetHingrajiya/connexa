using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Auth;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Sets password for a verified member using server-validated registration CredentialSetupToken or OTP grant.
    /// POST /api/v1/auth/setup-password
    /// </summary>
    [HttpPost("setup-password")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetupPassword(
        [FromBody] SetupPasswordRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.SetupPasswordAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<AuthResponseDto>.Fail(result.ErrorMessage ?? "Credential setup failed."));
        }

        return Ok(ApiResponse<AuthResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Dispatches an OTP to a registered member's verified email or WhatsApp to recover/authorize credential setup.
    /// POST /api/v1/auth/request-setup-otp
    /// </summary>
    [HttpPost("request-setup-otp")]
    [ProducesResponseType(typeof(ApiResponse<RequestSetupOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<RequestSetupOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RequestSetupOtpResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RequestSetupOtp(
        [FromBody] RequestSetupOtpRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.RequestSetupOtpAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<RequestSetupOtpResponseDto>.Fail(result.ErrorMessage ?? "OTP request failed."));
        }

        return Ok(ApiResponse<RequestSetupOtpResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Verifies the OTP dispatched for credential setup recovery and returns a fresh, single-use CredentialSetupToken.
    /// POST /api/v1/auth/verify-setup-otp
    /// </summary>
    [HttpPost("verify-setup-otp")]
    [ProducesResponseType(typeof(ApiResponse<VerifySetupOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerifySetupOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<VerifySetupOtpResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> VerifySetupOtp(
        [FromBody] VerifySetupOtpRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.VerifySetupOtpAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<VerifySetupOtpResponseDto>.Fail(result.ErrorMessage ?? "OTP verification failed."));
        }

        return Ok(ApiResponse<VerifySetupOtpResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Authenticates a member by email or phone and password, returning short-lived JWT access token and refresh token.
    /// POST /api/v1/auth/login
    /// </summary>
    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status429TooManyRequests)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();
        var result = await _authService.LoginAsync(request, clientIp, userAgent, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<AuthResponseDto>.Fail(result.ErrorMessage ?? "Login failed."));
        }

        return Ok(ApiResponse<AuthResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Rotates refresh token and issues a new access token. Replay attempts trigger cascade revocation.
    /// POST /api/v1/auth/refresh
    /// </summary>
    [HttpPost("refresh")]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<AuthResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();
        var result = await _authService.RefreshTokenAsync(request, clientIp, userAgent, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<AuthResponseDto>.Fail(result.ErrorMessage ?? "Token refresh failed."));
        }

        return Ok(ApiResponse<AuthResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Revokes active refresh token and terminates session.
    /// POST /api/v1/auth/logout
    /// </summary>
    [HttpPost("logout")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Logout(
        [FromBody] LogoutRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.LogoutAsync(request, clientIp, cancellationToken);
        return Ok(ApiResponse<bool>.Ok(true, 1));
    }

    /// <summary>
    /// Initiates password recovery by dispatching an OTP to the member's verified email or WhatsApp.
    /// POST /api/v1/auth/forgot-password
    /// </summary>
    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ForgotPassword(
        [FromBody] ForgotPasswordRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.ForgotPasswordAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<ForgotPasswordResponseDto>.Fail(result.ErrorMessage ?? "Password recovery request failed."));
        }

        return Ok(ApiResponse<ForgotPasswordResponseDto>.Ok(result.Data!, 1));
    }

    /// <summary>
    /// Verifies OTP code and sets a new password complying with security complexity policies.
    /// POST /api/v1/auth/reset-password
    /// </summary>
    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ResetPassword(
        [FromBody] ResetPasswordRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.ResetPasswordAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            return StatusCode(result.StatusCode, ApiResponse<bool>.Fail(result.ErrorMessage ?? "Password reset failed."));
        }

        return Ok(ApiResponse<bool>.WithMessage(true, "Password reset successful. All prior sessions have been terminated."));
    }
}

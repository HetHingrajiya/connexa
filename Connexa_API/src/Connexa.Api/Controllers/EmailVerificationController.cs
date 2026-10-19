using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/verification/email")]
public class EmailVerificationController : ControllerBase
{
    private readonly IEmailVerificationService _verificationService;
    private readonly ILogger<EmailVerificationController> _logger;

    public EmailVerificationController(
        IEmailVerificationService verificationService,
        ILogger<EmailVerificationController> logger)
    {
        _verificationService = verificationService;
        _logger = logger;
    }

    /// <summary>
    /// Initiates a Gmail SMTP email OTP verification challenge for a destination email address.
    /// POST /api/v1/verification/email/send
    /// </summary>
    [HttpPost("send")]
    [ProducesResponseType(typeof(ApiResponse<SendEmailOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SendEmailOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<SendEmailOtpResponseDto>), StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ApiResponse<SendEmailOtpResponseDto>), StatusCodes.Status502BadGateway)]
    public async Task<IActionResult> SendOtp([FromBody] SendEmailOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.SendOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<SendEmailOtpResponseDto>.Fail(errorMessage ?? "Failed to initiate email verification."));
        }

        return Ok(ApiResponse<SendEmailOtpResponseDto>.Ok(response!, 1));
    }

    /// <summary>
    /// Requests a new OTP code for an active email verification challenge subject to cooldown and limits.
    /// POST /api/v1/verification/email/resend
    /// </summary>
    [HttpPost("resend")]
    [ProducesResponseType(typeof(ApiResponse<ResendEmailOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ResendEmailOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ResendEmailOtpResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<ResendEmailOtpResponseDto>), StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ApiResponse<ResendEmailOtpResponseDto>), StatusCodes.Status502BadGateway)]
    public async Task<IActionResult> ResendOtp([FromBody] ResendEmailOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.ResendOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<ResendEmailOtpResponseDto>.Fail(errorMessage ?? "Failed to resend verification code."));
        }

        return Ok(ApiResponse<ResendEmailOtpResponseDto>.Ok(response!, 1));
    }

    /// <summary>
    /// Verifies the 6-digit OTP code, transitions challenge state atomically, and returns an opaque verification grant bound to the email.
    /// POST /api/v1/verification/email/verify
    /// </summary>
    [HttpPost("verify")]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<VerifyEmailOtpResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyEmailOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.VerifyOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<VerifyEmailOtpResponseDto>.Fail(errorMessage ?? "Email verification failed."));
        }

        return Ok(ApiResponse<VerifyEmailOtpResponseDto>.Ok(response!, 1));
    }
}

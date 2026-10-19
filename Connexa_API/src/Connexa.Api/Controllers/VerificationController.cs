using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/verification/whatsapp")]
public class VerificationController : ControllerBase
{
    private readonly IPhoneVerificationService _verificationService;
    private readonly ILogger<VerificationController> _logger;

    public VerificationController(
        IPhoneVerificationService verificationService,
        ILogger<VerificationController> logger)
    {
        _verificationService = verificationService;
        _logger = logger;
    }

    /// <summary>
    /// Initiates a WhatsApp OTP verification challenge for a destination phone number.
    /// POST /api/v1/verification/whatsapp/send
    /// </summary>
    [HttpPost("send")]
    [ProducesResponseType(typeof(ApiResponse<SendOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SendOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<SendOtpResponseDto>), StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ApiResponse<SendOtpResponseDto>), StatusCodes.Status502BadGateway)]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.SendOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<SendOtpResponseDto>.Fail(errorMessage ?? "Failed to initiate verification."));
        }

        return Ok(ApiResponse<SendOtpResponseDto>.Ok(response!, 1));
    }

    /// <summary>
    /// Requests a new OTP code for an active verification challenge subject to cooldown and limits.
    /// POST /api/v1/verification/whatsapp/resend
    /// </summary>
    [HttpPost("resend")]
    [ProducesResponseType(typeof(ApiResponse<ResendOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ResendOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ResendOtpResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<ResendOtpResponseDto>), StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ApiResponse<ResendOtpResponseDto>), StatusCodes.Status502BadGateway)]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.ResendOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<ResendOtpResponseDto>.Fail(errorMessage ?? "Failed to resend verification code."));
        }

        return Ok(ApiResponse<ResendOtpResponseDto>.Ok(response!, 1));
    }

    /// <summary>
    /// Verifies the 6-digit OTP code, transitions challenge state atomically, and returns an opaque verification grant.
    /// POST /api/v1/verification/whatsapp/verify
    /// </summary>
    [HttpPost("verify")]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto request, CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var (success, response, errorMessage, statusCode) = await _verificationService.VerifyOtpAsync(request, clientIp, cancellationToken);

        if (!success)
        {
            return StatusCode(statusCode, ApiResponse<VerifyOtpResponseDto>.Fail(errorMessage ?? "Verification failed."));
        }

        return Ok(ApiResponse<VerifyOtpResponseDto>.Ok(response!, 1));
    }
}

using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/verification")]
public class VerificationPolicyController : ControllerBase
{
    private readonly IRegistrationVerificationPolicyService _policyService;
    private readonly ILogger<VerificationPolicyController> _logger;

    public VerificationPolicyController(
        IRegistrationVerificationPolicyService policyService,
        ILogger<VerificationPolicyController> logger)
    {
        _policyService = policyService;
        _logger = logger;
    }

    /// <summary>
    /// Enforces the unified registration verification policy: EmailVerified OR PhoneVerified.
    /// Validates the server-issued verification grant against database state.
    /// Rejects client boolean spoofing.
    /// POST /api/v1/verification/validate-grant
    /// </summary>
    [HttpPost("validate-grant")]
    [ProducesResponseType(typeof(ApiResponse<ValidateVerificationGrantResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ValidateVerificationGrantResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ValidateGrant(
        [FromBody] ValidateVerificationGrantRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request == null)
        {
            return BadRequest(ApiResponse<ValidateVerificationGrantResponseDto>.Fail("Request body cannot be null."));
        }

        var (isValid, method, destination, expiresAt, errorMessage) = await _policyService.ValidateGrantAsync(
            request.VerificationGrant,
            request.RegistrationFlowId,
            cancellationToken);

        if (!isValid)
        {
            return BadRequest(ApiResponse<ValidateVerificationGrantResponseDto>.Fail(errorMessage ?? "Verification grant validation failed."));
        }

        var responseDto = new ValidateVerificationGrantResponseDto(
            IsValid: true,
            VerifiedMethod: method!,
            MaskedDestination: destination!,
            ExpiresAtUtc: expiresAt,
            Message: $"Verification policy satisfied via {method} ({destination})."
        );

        return Ok(ApiResponse<ValidateVerificationGrantResponseDto>.Ok(responseDto, 1));
    }

    /// <summary>
    /// Atomically consumes the verification grant during registration finalization.
    /// Rejects consumed, reused, expired, or mismatched grants.
    /// POST /api/v1/verification/consume-grant
    /// </summary>
    [HttpPost("consume-grant")]
    [ProducesResponseType(typeof(ApiResponse<ValidateVerificationGrantResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ValidateVerificationGrantResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ConsumeGrant(
        [FromBody] ValidateVerificationGrantRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request == null)
        {
            return BadRequest(ApiResponse<ValidateVerificationGrantResponseDto>.Fail("Request body cannot be null."));
        }

        var (consumed, method, destination, errorMessage) = await _policyService.ConsumeGrantAsync(
            request.VerificationGrant,
            request.RegistrationFlowId,
            cancellationToken);

        if (!consumed)
        {
            return BadRequest(ApiResponse<ValidateVerificationGrantResponseDto>.Fail(errorMessage ?? "Grant consumption failed."));
        }

        var responseDto = new ValidateVerificationGrantResponseDto(
            IsValid: true,
            VerifiedMethod: method!,
            MaskedDestination: destination!,
            ExpiresAtUtc: null,
            Message: $"Verification grant consumed successfully for {method} ({destination})."
        );

        return Ok(ApiResponse<ValidateVerificationGrantResponseDto>.Ok(responseDto, 1));
    }
}

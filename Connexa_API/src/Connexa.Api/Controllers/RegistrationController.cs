using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;
using Connexa.Api.Services.Registration;

namespace Connexa.Api.Controllers;

[ApiController]
[Route("api/v1/registration")]
public class RegistrationController : ControllerBase
{
    private readonly IRegistrationService _registrationService;
    private readonly ILogger<RegistrationController> _logger;

    public RegistrationController(
        IRegistrationService registrationService,
        ILogger<RegistrationController> logger)
    {
        _registrationService = registrationService;
        _logger = logger;
    }

    /// <summary>
    /// Submits the completed registration draft with a server-validated verification grant.
    /// Transactionally persists the Member record and selected profile details to SQL Server.
    /// POST /api/v1/registration/submit
    /// </summary>
    [HttpPost("submit")]
    [ProducesResponseType(typeof(ApiResponse<RegistrationResponseDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RegistrationResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RegistrationResponseDto>), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(ApiResponse<RegistrationResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> SubmitRegistration(
        [FromBody] SubmitRegistrationRequestDto request,
        CancellationToken cancellationToken)
    {
        var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _registrationService.SubmitRegistrationAsync(request, clientIp, cancellationToken);

        if (!result.Success)
        {
            var apiResponse = ApiResponse<RegistrationResponseDto>.Fail(result.ErrorMessage ?? "Registration failed.");
            return StatusCode(result.StatusCode, apiResponse);
        }

        return StatusCode(StatusCodes.Status201Created, ApiResponse<RegistrationResponseDto>.Ok(result.Data!, 1));
    }
}

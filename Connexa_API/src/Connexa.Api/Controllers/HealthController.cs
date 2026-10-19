using Microsoft.AspNetCore.Mvc;
using Connexa.Api.DTOs;

namespace Connexa.Api.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    [HttpGet("/health")]
    public IActionResult GetRootHealth()
    {
        return Ok(new HealthResponseDto(
            Status: "ok",
            Service: "Connexa B2B API",
            Version: null,
            Timestamp: DateTime.UtcNow.ToString("o")
        ));
    }

    [HttpGet("/api/v1/health")]
    public IActionResult GetApiHealth()
    {
        return Ok(new HealthResponseDto(
            Status: "ok",
            Service: "Connexa B2B API",
            Version: "1.0.0",
            Timestamp: DateTime.UtcNow.ToString("o")
        ));
    }
}
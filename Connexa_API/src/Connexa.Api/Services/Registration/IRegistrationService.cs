using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Registration;

public record RegistrationResult(
    bool Success,
    RegistrationResponseDto? Data,
    string? ErrorMessage,
    int StatusCode
);

public interface IRegistrationService
{
    Task<RegistrationResult> SubmitRegistrationAsync(
        SubmitRegistrationRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);
}

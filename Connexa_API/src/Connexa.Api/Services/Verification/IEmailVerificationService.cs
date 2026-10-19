using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Verification;

public interface IEmailVerificationService
{
    Task<(bool Success, SendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);

    Task<(bool Success, ResendEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);

    Task<(bool Success, VerifyEmailOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyEmailOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);
}

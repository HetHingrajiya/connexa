using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Verification;

public interface IPhoneVerificationService
{
    Task<(bool Success, SendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> SendOtpAsync(
        SendOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);

    Task<(bool Success, ResendOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> ResendOtpAsync(
        ResendOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);

    Task<(bool Success, VerifyOtpResponseDto? Response, string? ErrorMessage, int StatusCode)> VerifyOtpAsync(
        VerifyOtpRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default);
}

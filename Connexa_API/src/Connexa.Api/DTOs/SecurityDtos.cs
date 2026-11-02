namespace Connexa.Api.DTOs;

public record ForgotPasswordRequestDto(
    string Identifier, // Registered email or phone number
    string? PreferredChannel = null // "Email" or "WhatsApp", optional
);

public record ForgotPasswordResponseDto(
    bool Success,
    string Message,
    string MaskedDestination,
    string Channel,
    string FlowId,
    int ChallengeId,
    int ExpirySeconds
);

public record ResetPasswordRequestDto(
    string Identifier,
    string OtpCode,
    string FlowId,
    int ChallengeId,
    string NewPassword,
    string ConfirmPassword
);

public record ChangePasswordRequestDto(
    string CurrentPassword,
    string NewPassword,
    string ConfirmPassword,
    bool RevokeOtherSessions = true
);

public record ActiveSessionDto(
    int Id,
    string DeviceName,
    string? IpAddress,
    DateTime CreatedAtUtc,
    DateTime LastActiveAtUtc,
    bool IsCurrent
);

public record DeactivateAccountRequestDto(
    string Password,
    string? Reason
);

public record DeleteAccountRequestDto(
    string Password,
    string Reason
);

public record AccountStatusResponseDto(
    bool IsActive,
    DateTime? DeactivatedAtUtc,
    string? DeactivationReason,
    bool HasPendingDeletionRequest,
    DateTime? DeletionRequestedAtUtc
);


namespace Connexa.Api.DTOs;

// --- WhatsApp Verification DTOs ---

public record SendOtpRequestDto(
    string PhoneNumber,
    string RegistrationFlowId
);

public record SendOtpResponseDto(
    int ChallengeId,
    string MaskedPhoneNumber,
    DateTime ExpiresAtUtc,
    int CooldownSeconds,
    bool Accepted,
    string Status,
    string? Message,
    bool IsLiveDelivery = true
);

public record ResendOtpRequestDto(
    int ChallengeId,
    string RegistrationFlowId
);

public record ResendOtpResponseDto(
    int ChallengeId,
    string MaskedPhoneNumber,
    DateTime ExpiresAtUtc,
    int CooldownSeconds,
    bool Accepted,
    string Status,
    string? Message,
    bool IsLiveDelivery = true
);

public record VerifyOtpRequestDto(
    int ChallengeId,
    string RegistrationFlowId,
    string OtpCode
);

public record VerifyOtpResponseDto(
    bool Verified,
    string MaskedPhoneNumber,
    string VerificationGrant,
    DateTime VerificationGrantExpiresAtUtc,
    string Message
);

// --- Email Verification DTOs ---

public record SendEmailOtpRequestDto(
    string Email,
    string RegistrationFlowId
);

public record SendEmailOtpResponseDto(
    int ChallengeId,
    string MaskedEmail,
    DateTime ExpiresAtUtc,
    int CooldownSeconds,
    bool Accepted,
    string Status,
    string? Message,
    bool IsLiveDelivery = true
);

public record ResendEmailOtpRequestDto(
    int ChallengeId,
    string RegistrationFlowId
);

public record ResendEmailOtpResponseDto(
    int ChallengeId,
    string MaskedEmail,
    DateTime ExpiresAtUtc,
    int CooldownSeconds,
    bool Accepted,
    string Status,
    string? Message,
    bool IsLiveDelivery = true
);

public record VerifyEmailOtpRequestDto(
    int ChallengeId,
    string RegistrationFlowId,
    string OtpCode
);

public record VerifyEmailOtpResponseDto(
    bool Verified,
    string MaskedEmail,
    string VerificationGrant,
    DateTime VerificationGrantExpiresAtUtc,
    string Message
);

// --- Unified Verification Policy DTOs ---

public record ValidateVerificationGrantRequestDto(
    string VerificationGrant,
    string RegistrationFlowId
);

public record ValidateVerificationGrantResponseDto(
    bool IsValid,
    string VerifiedMethod,
    string MaskedDestination,
    DateTime? ExpiresAtUtc,
    string Message
);

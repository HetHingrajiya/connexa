namespace Connexa.Api.DTOs;

public record SetupPasswordRequestDto(
    string? CredentialSetupToken,
    string? VerificationGrant,
    string? Destination,
    string Password,
    string ConfirmPassword
);

public record LoginRequestDto(
    string Identifier, // Email or mobile phone number
    string Password
);

public record RefreshTokenRequestDto(
    string RefreshToken
);

public record LogoutRequestDto(
    string? RefreshToken
);

public record AuthenticatedMemberDto(
    int MemberId,
    string FullName,
    string Email,
    string PhoneNumber,
    string Role,
    string PrimaryProfileType
);

public record AuthResponseDto(
    string AccessToken,
    string RefreshToken,
    string TokenType,
    int ExpiresIn,
    AuthenticatedMemberDto Member
);

public record MemberProfileResponseDto(
    int MemberId,
    string FullName,
    string CountryCode,
    string PhoneNumber,
    string Email,
    string PrimaryProfileType,
    string VerifiedMethod,
    string VerifiedDestination,
    string Role,
    bool IsActive,
    DateTime CreatedAtUtc,
    object? ProfileDetails
);

public record RequestSetupOtpRequestDto(
    string Identifier, // Registered email or phone number
    string Channel // "Email" or "WhatsApp"
);

public record RequestSetupOtpResponseDto(
    bool Success,
    int ChallengeId,
    string Destination,
    string MaskedDestination,
    string Channel,
    string FlowId,
    string Message
);

public record VerifySetupOtpRequestDto(
    int ChallengeId,
    string FlowId,
    string OtpCode,
    string Channel
);

public record VerifySetupOtpResponseDto(
    bool Success,
    string CredentialSetupToken,
    DateTime ExpiresAtUtc,
    string Destination,
    string Message
);

// --- Profile Update DTOs ---

public record UpdateBusinessProfileDto(
    string CompanyName,
    List<string>? BusinessCapabilities,
    string? BusinessDescription,
    int IndustryId,
    int BusinessGroupId,
    int SubGroupId,
    int CategoryId
);

public record UpdateEmployeeProfileDto(
    string JobTitle,
    string Skills,
    string? Experience,
    string? PreferredJobType
);

public record UpdateServiceEngineerProfileDto(
    string Specialization,
    string? SupportedEquipment,
    string? YearsOfExperience,
    string? ServiceCoverage
);

public record UpdateTraderProfileDto(
    string TradingName,
    List<string>? Capabilities,
    string? ProductsSupplied,
    string? ServiceCoverage
);

public record UpdateContractorProfileDto(
    string WorkName,
    List<string>? WorkCapabilities,
    string? ProcessesSupported,
    string? WorkCoverage,
    int IndustryId,
    int BusinessGroupId,
    int SubGroupId,
    int CategoryId
);

public record UpdateMemberProfileRequestDto(
    string FullName,
    UpdateBusinessProfileDto? BusinessDetails = null,
    UpdateEmployeeProfileDto? EmployeeDetails = null,
    UpdateServiceEngineerProfileDto? ServiceEngineerDetails = null,
    UpdateTraderProfileDto? TraderDetails = null,
    UpdateContractorProfileDto? ContractorDetails = null
);

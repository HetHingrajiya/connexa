namespace Connexa.Api.DTOs;

public record BusinessProfileDetailsDto(
    string CompanyName,
    List<string>? BusinessCapabilities,
    string? BusinessDescription,
    int IndustryId,
    int BusinessGroupId,
    int SubGroupId,
    int CategoryId
);

public record EmployeeProfileDetailsDto(
    string JobTitle,
    string Skills,
    string? Experience,
    string? PreferredJobType
);

public record ServiceEngineerProfileDetailsDto(
    string Specialization,
    string? SupportedEquipment,
    string? YearsOfExperience,
    string? ServiceCoverage
);

public record TraderProfileDetailsDto(
    string TradingName,
    List<string>? Capabilities,
    string? ProductsSupplied,
    string? ServiceCoverage
);

public record ContractorProfileDetailsDto(
    string WorkName,
    List<string>? WorkCapabilities,
    string? ProcessesSupported,
    string? WorkCoverage,
    int IndustryId,
    int BusinessGroupId,
    int SubGroupId,
    int CategoryId
);

public record SubmitRegistrationRequestDto(
    string VerificationGrant,
    string RegistrationFlowId,
    string FullName,
    string CountryCode,
    string MobileNumber,
    string Email,
    int ProfileType,
    BusinessProfileDetailsDto? BusinessDetails = null,
    EmployeeProfileDetailsDto? EmployeeDetails = null,
    ServiceEngineerProfileDetailsDto? ServiceEngineerDetails = null,
    TraderProfileDetailsDto? TraderDetails = null,
    ContractorProfileDetailsDto? ContractorDetails = null
);

public record RegistrationResponseDto(
    int MemberId,
    string FullName,
    string Email,
    string PhoneNumber,
    string PrimaryProfileType,
    string VerifiedMethod,
    string VerifiedDestination,
    DateTime CreatedAtUtc,
    string Message,
    string? CredentialSetupToken = null,
    DateTime? CredentialSetupTokenExpiresAtUtc = null
);

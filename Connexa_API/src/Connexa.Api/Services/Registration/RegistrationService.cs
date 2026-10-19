using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Services.Registration;

public class RegistrationService : IRegistrationService
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly ILogger<RegistrationService> _logger;

    public RegistrationService(
        ConnexaDbContext dbContext,
        IOtpCryptographyService crypto,
        ILogger<RegistrationService> logger)
    {
        _dbContext = dbContext;
        _crypto = crypto;
        _logger = logger;
    }

    public async Task<RegistrationResult> SubmitRegistrationAsync(
        SubmitRegistrationRequestDto request,
        string? clientIp,
        CancellationToken cancellationToken = default)
    {
        if (request == null)
        {
            return new RegistrationResult(false, null, "Request body cannot be null.", 400);
        }

        // 1. Basic Field Validations
        if (string.IsNullOrWhiteSpace(request.VerificationGrant))
        {
            return new RegistrationResult(false, null, "Verification grant token is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.RegistrationFlowId))
        {
            return new RegistrationResult(false, null, "RegistrationFlowId is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return new RegistrationResult(false, null, "Full Name is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.MobileNumber))
        {
            return new RegistrationResult(false, null, "Mobile number is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return new RegistrationResult(false, null, "Email address is required.", 400);
        }

        if (!Enum.IsDefined(typeof(ProfileTypeEnum), request.ProfileType))
        {
            return new RegistrationResult(false, null, "Invalid primary profile type selected.", 400);
        }

        var profileType = (ProfileTypeEnum)request.ProfileType;

        // 2. Profile-Specific Validations
        switch (profileType)
        {
            case ProfileTypeEnum.BusinessCompany:
                if (request.BusinessDetails == null)
                {
                    return new RegistrationResult(false, null, "Business details are required for Business / Company profile.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.BusinessDetails.CompanyName))
                {
                    return new RegistrationResult(false, null, "Company Name is required.", 400);
                }
                if (request.BusinessDetails.IndustryId <= 0 ||
                    request.BusinessDetails.BusinessGroupId <= 0 ||
                    request.BusinessDetails.SubGroupId <= 0 ||
                    request.BusinessDetails.CategoryId <= 0)
                {
                    return new RegistrationResult(false, null, "Complete 4-tier industry hierarchy selection is required for Business profile.", 400);
                }
                break;

            case ProfileTypeEnum.EmployeeJobSeeker:
                if (request.EmployeeDetails == null)
                {
                    return new RegistrationResult(false, null, "Employee details are required for Employee / Job Seeker profile.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.EmployeeDetails.JobTitle))
                {
                    return new RegistrationResult(false, null, "Job Title is required.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.EmployeeDetails.Skills))
                {
                    return new RegistrationResult(false, null, "Skills are required.", 400);
                }
                break;

            case ProfileTypeEnum.ServiceEngineer:
                if (request.ServiceEngineerDetails == null)
                {
                    return new RegistrationResult(false, null, "Service engineer details are required for Service Engineer profile.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.ServiceEngineerDetails.Specialization))
                {
                    return new RegistrationResult(false, null, "Specialization is required.", 400);
                }
                break;

            case ProfileTypeEnum.TraderSupplier:
                if (request.TraderDetails == null)
                {
                    return new RegistrationResult(false, null, "Trader details are required for Trader / Supplier profile.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.TraderDetails.TradingName))
                {
                    return new RegistrationResult(false, null, "Trading Name is required.", 400);
                }
                break;

            case ProfileTypeEnum.ContractorJobWorker:
                if (request.ContractorDetails == null)
                {
                    return new RegistrationResult(false, null, "Contractor details are required for Contractor / Job Worker profile.", 400);
                }
                if (string.IsNullOrWhiteSpace(request.ContractorDetails.WorkName))
                {
                    return new RegistrationResult(false, null, "Contractor or Work Name is required.", 400);
                }
                if (request.ContractorDetails.IndustryId <= 0 ||
                    request.ContractorDetails.BusinessGroupId <= 0 ||
                    request.ContractorDetails.SubGroupId <= 0 ||
                    request.ContractorDetails.CategoryId <= 0)
                {
                    return new RegistrationResult(false, null, "Complete 4-tier industry hierarchy selection is required for Contractor profile.", 400);
                }
                break;
        }

        var rawPhone = string.IsNullOrWhiteSpace(request.CountryCode)
            ? request.MobileNumber
            : $"{request.CountryCode}{request.MobileNumber}";
        var normalizedPhone = _crypto.NormalizePhoneNumber(rawPhone);
        var normalizedEmail = _crypto.NormalizeEmail(request.Email);
        var cleanGrant = request.VerificationGrant.Trim();
        var cleanFlowId = request.RegistrationFlowId.Trim();

        // 3. Execute Transactional Persistence with Execution Strategy for Connection Resiliency
        var strategy = _dbContext.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                // Validate verification grant against server state
                var challenge = await _dbContext.OtpChallenges
                    .FirstOrDefaultAsync(c => c.VerificationGrantToken == cleanGrant, cancellationToken);

            if (challenge == null)
            {
                _logger.LogWarning("[Registration] Rejected: Verification grant not found.");
                return new RegistrationResult(false, null, "Invalid or unknown verification grant.", 400);
            }

            if (!challenge.RegistrationFlowId.Equals(cleanFlowId, StringComparison.Ordinal))
            {
                _logger.LogWarning("[Registration] Rejected: Grant flow mismatch. Expected: {Expected}, Actual: {Actual}",
                    challenge.RegistrationFlowId, cleanFlowId);
                return new RegistrationResult(false, null, "Verification grant does not belong to this registration session.", 400);
            }

            if (challenge.Status != OtpChallengeStatus.Verified)
            {
                _logger.LogWarning("[Registration] Rejected: Grant challenge is not verified ({Status}).", challenge.Status);
                return new RegistrationResult(false, null, $"Verification grant is not in verified state ({challenge.Status}).", 400);
            }

            var now = DateTime.UtcNow;
            if (challenge.VerificationGrantExpiresAtUtc == null || now > challenge.VerificationGrantExpiresAtUtc.Value)
            {
                _logger.LogWarning("[Registration] Rejected: Verification grant expired at {ExpiresAt}.", challenge.VerificationGrantExpiresAtUtc);
                return new RegistrationResult(false, null, "Verification grant token has expired. Please verify your contact information again.", 400);
            }

            // Destination binding: Verified channel destination must match submitted request data
            string verifiedMethod;
            string verifiedDestination;

            if (!string.IsNullOrWhiteSpace(challenge.Email))
            {
                var challengeEmail = _crypto.NormalizeEmail(challenge.Email);
                if (!challengeEmail.Equals(normalizedEmail, StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("[Registration] Rejected: Grant email ({GrantEmail}) does not match submitted email ({SubmitEmail}).",
                        _crypto.MaskEmail(challengeEmail), _crypto.MaskEmail(normalizedEmail));
                    return new RegistrationResult(false, null, "The verified email address does not match the email submitted in the registration draft.", 400);
                }

                verifiedMethod = "Email";
                verifiedDestination = _crypto.MaskEmail(challenge.Email);
            }
            else if (!string.IsNullOrWhiteSpace(challenge.PhoneNumber))
            {
                var challengePhone = challenge.PhoneNumber;
                if (!challengePhone.Equals(normalizedPhone, StringComparison.Ordinal))
                {
                    _logger.LogWarning("[Registration] Rejected: Grant phone ({GrantPhone}) does not match submitted phone ({SubmitPhone}).",
                        _crypto.MaskPhoneNumber(challengePhone), _crypto.MaskPhoneNumber(normalizedPhone));
                    return new RegistrationResult(false, null, "The verified phone number does not match the phone number submitted in the registration draft.", 400);
                }

                verifiedMethod = "WhatsApp";
                verifiedDestination = _crypto.MaskPhoneNumber(challenge.PhoneNumber);
            }
            else
            {
                return new RegistrationResult(false, null, "Corrupt verification grant state.", 400);
            }

            // 4. Duplicate Account Prevention
            var phoneExists = await _dbContext.Members
                .AnyAsync(m => m.PhoneNumber == normalizedPhone, cancellationToken);
            if (phoneExists)
            {
                _logger.LogWarning("[Registration] Rejected: Phone number already registered.");
                return new RegistrationResult(false, null, "An account with this phone number already exists. Please sign in instead.", 409);
            }

            var emailExists = await _dbContext.Members
                .AnyAsync(m => m.Email == normalizedEmail, cancellationToken);
            if (emailExists)
            {
                _logger.LogWarning("[Registration] Rejected: Email address already registered.");
                return new RegistrationResult(false, null, "An account with this email address already exists. Please sign in instead.", 409);
            }

            // 5. Foreign Key Hierarchy Validation
            int? industryId = null;
            int? businessGroupId = null;
            int? subGroupId = null;
            int? categoryId = null;

            if (profileType == ProfileTypeEnum.BusinessCompany)
            {
                industryId = request.BusinessDetails!.IndustryId;
                businessGroupId = request.BusinessDetails.BusinessGroupId;
                subGroupId = request.BusinessDetails.SubGroupId;
                categoryId = request.BusinessDetails.CategoryId;
            }
            else if (profileType == ProfileTypeEnum.ContractorJobWorker)
            {
                industryId = request.ContractorDetails!.IndustryId;
                businessGroupId = request.ContractorDetails.BusinessGroupId;
                subGroupId = request.ContractorDetails.SubGroupId;
                categoryId = request.ContractorDetails.CategoryId;
            }

            if (categoryId.HasValue)
            {
                var category = await _dbContext.Categories
                    .Include(c => c.SubGroup)
                    .ThenInclude(sg => sg.BusinessGroup)
                    .ThenInclude(bg => bg.Industry)
                    .FirstOrDefaultAsync(c => c.Id == categoryId.Value, cancellationToken);

                if (category == null ||
                    category.SubGroupId != subGroupId!.Value ||
                    category.SubGroup.BusinessGroupId != businessGroupId!.Value ||
                    category.SubGroup.BusinessGroup.IndustryId != industryId!.Value)
                {
                    _logger.LogWarning("[Registration] Rejected: Invalid master data hierarchy (Ind: {Ind}, Group: {Group}, Sub: {Sub}, Cat: {Cat}).",
                        industryId, businessGroupId, subGroupId, categoryId);
                    return new RegistrationResult(false, null, "The selected industry hierarchy (Industry/Group/SubGroup/Category) is invalid or does not exist.", 400);
                }
            }

            // 6. Atomically Consume the Verification Grant
            challenge.VerificationGrantToken = null;
            challenge.VerificationGrantExpiresAtUtc = null;
            challenge.Status = OtpChallengeStatus.Superseded;

            // 7. Create Member Account (Strictly "Member" role; Admin assignment forbidden)
            var credentialSetupToken = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));
            var credentialSetupExpiresAt = DateTime.UtcNow.AddMinutes(30);

            var member = new Member
            {
                FullName = request.FullName.Trim(),
                CountryCode = string.IsNullOrWhiteSpace(request.CountryCode) ? "+91" : request.CountryCode.Trim(),
                PhoneNumber = normalizedPhone,
                Email = normalizedEmail,
                PrimaryProfileType = profileType,
                VerifiedMethod = verifiedMethod,
                VerifiedDestination = verifiedDestination,
                Role = "Member",
                IsActive = true,
                CreatedAtUtc = DateTime.UtcNow,
                CredentialSetupToken = credentialSetupToken,
                CredentialSetupTokenExpiresAtUtc = credentialSetupExpiresAt
            };

            _dbContext.Members.Add(member);
            await _dbContext.SaveChangesAsync(cancellationToken);

            // 8. Create Profile-Specific Record
            switch (profileType)
            {
                case ProfileTypeEnum.BusinessCompany:
                    var b = request.BusinessDetails!;
                    var bus = new BusinessProfile
                    {
                        MemberId = member.Id,
                        CompanyName = b.CompanyName.Trim(),
                        BusinessCapabilities = b.BusinessCapabilities != null && b.BusinessCapabilities.Count > 0
                            ? string.Join(", ", b.BusinessCapabilities)
                            : string.Empty,
                        BusinessDescription = b.BusinessDescription?.Trim() ?? string.Empty,
                        IndustryId = b.IndustryId,
                        BusinessGroupId = b.BusinessGroupId,
                        SubGroupId = b.SubGroupId,
                        CategoryId = b.CategoryId,
                        CreatedAtUtc = DateTime.UtcNow
                    };
                    _dbContext.BusinessProfiles.Add(bus);
                    break;

                case ProfileTypeEnum.EmployeeJobSeeker:
                    var e = request.EmployeeDetails!;
                    var emp = new EmployeeProfile
                    {
                        MemberId = member.Id,
                        JobTitle = e.JobTitle.Trim(),
                        Skills = e.Skills.Trim(),
                        Experience = e.Experience?.Trim() ?? string.Empty,
                        PreferredJobType = e.PreferredJobType?.Trim() ?? string.Empty,
                        CreatedAtUtc = DateTime.UtcNow
                    };
                    _dbContext.EmployeeProfiles.Add(emp);
                    break;

                case ProfileTypeEnum.ServiceEngineer:
                    var s = request.ServiceEngineerDetails!;
                    var se = new ServiceEngineerProfile
                    {
                        MemberId = member.Id,
                        Specialization = s.Specialization.Trim(),
                        SupportedEquipment = s.SupportedEquipment?.Trim() ?? string.Empty,
                        YearsOfExperience = s.YearsOfExperience?.Trim() ?? string.Empty,
                        ServiceCoverage = s.ServiceCoverage?.Trim() ?? string.Empty,
                        CreatedAtUtc = DateTime.UtcNow
                    };
                    _dbContext.ServiceEngineerProfiles.Add(se);
                    break;

                case ProfileTypeEnum.TraderSupplier:
                    var t = request.TraderDetails!;
                    var tr = new TraderProfile
                    {
                        MemberId = member.Id,
                        TradingName = t.TradingName.Trim(),
                        Capabilities = t.Capabilities != null && t.Capabilities.Count > 0
                            ? string.Join(", ", t.Capabilities)
                            : string.Empty,
                        ProductsSupplied = t.ProductsSupplied?.Trim() ?? string.Empty,
                        ServiceCoverage = t.ServiceCoverage?.Trim() ?? string.Empty,
                        CreatedAtUtc = DateTime.UtcNow
                    };
                    _dbContext.TraderProfiles.Add(tr);
                    break;

                case ProfileTypeEnum.ContractorJobWorker:
                    var c = request.ContractorDetails!;
                    var ct = new ContractorProfile
                    {
                        MemberId = member.Id,
                        WorkName = c.WorkName.Trim(),
                        WorkCapabilities = c.WorkCapabilities != null && c.WorkCapabilities.Count > 0
                            ? string.Join(", ", c.WorkCapabilities)
                            : string.Empty,
                        ProcessesSupported = c.ProcessesSupported?.Trim() ?? string.Empty,
                        WorkCoverage = c.WorkCoverage?.Trim() ?? string.Empty,
                        IndustryId = c.IndustryId,
                        BusinessGroupId = c.BusinessGroupId,
                        SubGroupId = c.SubGroupId,
                        CategoryId = c.CategoryId,
                        CreatedAtUtc = DateTime.UtcNow
                    };
                    _dbContext.ContractorProfiles.Add(ct);
                    break;
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "[Registration] Registration successful for Member ID: {MemberId}, Name: {FullName}, Profile: {ProfileType}, Method: {Method}.",
                member.Id, member.FullName, profileType, verifiedMethod);

            var responseDto = new RegistrationResponseDto(
                MemberId: member.Id,
                FullName: member.FullName,
                Email: member.Email,
                PhoneNumber: member.PhoneNumber,
                PrimaryProfileType: profileType.ToString(),
                VerifiedMethod: verifiedMethod,
                VerifiedDestination: verifiedDestination,
                CreatedAtUtc: member.CreatedAtUtc,
                Message: "Registration completed successfully. Profile records persisted to database.",
                CredentialSetupToken: credentialSetupToken,
                CredentialSetupTokenExpiresAtUtc: credentialSetupExpiresAt
            );

            return new RegistrationResult(true, responseDto, null, 201);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync(cancellationToken);
            _logger.LogError(ex, "[Registration] Fatal database error during registration transaction. Rolled back.");
            return new RegistrationResult(false, null, "An error occurred while persisting your registration. Please try again.", 500);
        }
        });
    }
}


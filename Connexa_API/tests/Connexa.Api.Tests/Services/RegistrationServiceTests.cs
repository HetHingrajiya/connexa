using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Connexa.Api.Configuration;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Registration;
using Connexa.Api.Services.Verification;

namespace Connexa.Api.Tests.Services;

public class RegistrationServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly IOtpCryptographyService _crypto;
    private readonly RegistrationService _registrationService;

    public RegistrationServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaRegTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);

        var secOptions = Options.Create(new OtpSecurityOptions
        {
            HmacSecretKey = "Connexa_Test_Reg_Key_For_Testing_Purposes_32_Bytes"
        });
        _crypto = new OtpCryptographyService(secOptions);

        _registrationService = new RegistrationService(
            _dbContext,
            _crypto,
            NullLogger<RegistrationService>.Instance);

        // Seed 4-tier master data
        SeedMasterData();
    }

    private void SeedMasterData()
    {
        var industry = new Industry { Id = 1, Name = "Manufacturing", Code = "MFG" };
        var group = new BusinessGroup { Id = 2, IndustryId = 1, Name = "Machinery", Code = "MACH" };
        var subGroup = new SubGroup { Id = 3, BusinessGroupId = 2, Name = "Industrial Tools", Code = "IT" };
        var category = new Category { Id = 4, SubGroupId = 3, Name = "Power Tools", Code = "PT" };

        _dbContext.Industries.Add(industry);
        _dbContext.BusinessGroups.Add(group);
        _dbContext.SubGroups.Add(subGroup);
        _dbContext.Categories.Add(category);
        _dbContext.SaveChanges();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }

    [Fact]
    public async Task SubmitRegistration_WithoutValidGrant_ReturnsBadRequest()
    {
        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "non_existent_grant_token",
            RegistrationFlowId: "flow_123",
            FullName: "Test User",
            CountryCode: "+91",
            MobileNumber: "9876543210",
            Email: "test@example.com",
            ProfileType: (int)ProfileTypeEnum.BusinessCompany,
            BusinessDetails: new BusinessProfileDetailsDto("Acme Corp", new List<string> { "Manufacturer" }, "Desc", 1, 2, 3, 4)
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("Invalid or unknown verification grant", result.ErrorMessage);
    }

    [Fact]
    public async Task SubmitRegistration_WithExpiredGrant_ReturnsBadRequest()
    {
        var challenge = new OtpChallenge
        {
            Email = "expired@example.com",
            RegistrationFlowId = "flow_expired",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_expired_123",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(-5),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_expired_123",
            RegistrationFlowId: "flow_expired",
            FullName: "Expired User",
            CountryCode: "+91",
            MobileNumber: "9876543210",
            Email: "expired@example.com",
            ProfileType: (int)ProfileTypeEnum.EmployeeJobSeeker,
            EmployeeDetails: new EmployeeProfileDetailsDto("Engineer", "C#", "5 years", "Full-time")
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("expired", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitRegistration_WithMismatchedFlow_ReturnsBadRequest()
    {
        var challenge = new OtpChallenge
        {
            Email = "flow@example.com",
            RegistrationFlowId = "flow_original",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_valid_123",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_valid_123",
            RegistrationFlowId: "flow_attacker_mismatch",
            FullName: "User",
            CountryCode: "+91",
            MobileNumber: "9876543210",
            Email: "flow@example.com",
            ProfileType: (int)ProfileTypeEnum.EmployeeJobSeeker,
            EmployeeDetails: new EmployeeProfileDetailsDto("Engineer", "C#", "5 years", "Full-time")
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("session", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitRegistration_WithMismatchedEmail_ReturnsBadRequest()
    {
        var challenge = new OtpChallenge
        {
            Email = "verified_original@example.com",
            RegistrationFlowId = "flow_email_bind",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_email_bind",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_email_bind",
            RegistrationFlowId: "flow_email_bind",
            FullName: "User",
            CountryCode: "+91",
            MobileNumber: "9876543210",
            Email: "different_unverified@example.com",
            ProfileType: (int)ProfileTypeEnum.EmployeeJobSeeker,
            EmployeeDetails: new EmployeeProfileDetailsDto("Engineer", "C#", "5 years", "Full-time")
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("email", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitRegistration_WithValidEmailGrant_CreatesMemberAndBusinessProfile_AndConsumesGrant()
    {
        var challenge = new OtpChallenge
        {
            Email = "business_owner@connexa.com",
            RegistrationFlowId = "flow_biz_1",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_biz_token_valid",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_biz_token_valid",
            RegistrationFlowId: "flow_biz_1",
            FullName: "Rajesh Kumar",
            CountryCode: "+91",
            MobileNumber: "9811223344",
            Email: "business_owner@connexa.com",
            ProfileType: (int)ProfileTypeEnum.BusinessCompany,
            BusinessDetails: new BusinessProfileDetailsDto(
                CompanyName: "Apex Precision Tools Ltd",
                BusinessCapabilities: new List<string> { "Manufacturer", "Supplier" },
                BusinessDescription: "Precision CNC machinery",
                IndustryId: 1,
                BusinessGroupId: 2,
                SubGroupId: 3,
                CategoryId: 4
            )
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.True(result.Success);
        Assert.Equal(201, result.StatusCode);
        Assert.NotNull(result.Data);
        Assert.True(result.Data.MemberId > 0);
        Assert.Equal("Rajesh Kumar", result.Data.FullName);
        Assert.Equal("Email", result.Data.VerifiedMethod);

        // Verify Member in DB
        var member = await _dbContext.Members
            .Include(m => m.BusinessProfile)
            .FirstOrDefaultAsync(m => m.Id == result.Data.MemberId);

        Assert.NotNull(member);
        Assert.Equal("Member", member.Role); // Explicitly Member, never Admin
        Assert.Equal("+919811223344", member.PhoneNumber);
        Assert.Equal("business_owner@connexa.com", member.Email);
        Assert.NotNull(member.BusinessProfile);
        Assert.Equal("Apex Precision Tools Ltd", member.BusinessProfile.CompanyName);
        Assert.Equal(4, member.BusinessProfile.CategoryId);

        // Verify Grant Consumed Atomically
        var consumedChallenge = await _dbContext.OtpChallenges.FindAsync(challenge.Id);
        Assert.NotNull(consumedChallenge);
        Assert.Null(consumedChallenge.VerificationGrantToken);
        Assert.Null(consumedChallenge.VerificationGrantExpiresAtUtc);
        Assert.Equal(OtpChallengeStatus.Superseded, consumedChallenge.Status);
    }

    [Fact]
    public async Task SubmitRegistration_WithValidPhoneGrant_CreatesMemberAndEmployeeProfile()
    {
        var challenge = new OtpChallenge
        {
            PhoneNumber = "+919822334455",
            RegistrationFlowId = "flow_emp_1",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_phone_token_valid",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_phone_token_valid",
            RegistrationFlowId: "flow_emp_1",
            FullName: "Ananya Desai",
            CountryCode: "+91",
            MobileNumber: "9822334455",
            Email: "ananya.desai@example.com",
            ProfileType: (int)ProfileTypeEnum.EmployeeJobSeeker,
            EmployeeDetails: new EmployeeProfileDetailsDto(
                JobTitle: "Lead Mechanical Engineer",
                Skills: "CAD, CAM, FEA",
                Experience: "8 Years",
                PreferredJobType: "Full-Time"
            )
        );

        var result = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");

        Assert.True(result.Success);
        Assert.Equal(201, result.StatusCode);
        Assert.Equal("WhatsApp", result.Data!.VerifiedMethod);

        // Verify in DB
        var member = await _dbContext.Members
            .Include(m => m.EmployeeProfile)
            .FirstOrDefaultAsync(m => m.Id == result.Data.MemberId);

        Assert.NotNull(member);
        Assert.NotNull(member.EmployeeProfile);
        Assert.Equal("Lead Mechanical Engineer", member.EmployeeProfile.JobTitle);
    }

    [Fact]
    public async Task SubmitRegistration_DuplicatePhoneOrEmail_ReturnsConflict()
    {
        // Pre-existing member
        var existing = new Member
        {
            FullName = "Existing Member",
            CountryCode = "+91",
            PhoneNumber = "+919877777777",
            Email = "existing@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.TraderSupplier,
            VerifiedMethod = "Email",
            VerifiedDestination = "e•••g@connexa.com"
        };
        _dbContext.Members.Add(existing);
        await _dbContext.SaveChangesAsync();

        // Try registering with same phone
        var challenge = new OtpChallenge
        {
            Email = "unique@connexa.com",
            RegistrationFlowId = "flow_dup",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_dup_phone",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var dupPhoneRequest = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_dup_phone",
            RegistrationFlowId: "flow_dup",
            FullName: "New User",
            CountryCode: "+91",
            MobileNumber: "9877777777", // Duplicate
            Email: "unique@connexa.com",
            ProfileType: (int)ProfileTypeEnum.TraderSupplier,
            TraderDetails: new TraderProfileDetailsDto("Trader Co", null, null, null)
        );

        var result = await _registrationService.SubmitRegistrationAsync(dupPhoneRequest, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(409, result.StatusCode);
        Assert.Contains("phone number already exists", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitRegistration_InvalidForeignKeys_ReturnsBadRequest()
    {
        var challenge = new OtpChallenge
        {
            Email = "contractor@connexa.com",
            RegistrationFlowId = "flow_fk",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_fk_test",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var badHierarchyRequest = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_fk_test",
            RegistrationFlowId: "flow_fk",
            FullName: "Contractor User",
            CountryCode: "+91",
            MobileNumber: "9812345678",
            Email: "contractor@connexa.com",
            ProfileType: (int)ProfileTypeEnum.ContractorJobWorker,
            ContractorDetails: new ContractorProfileDetailsDto(
                WorkName: "Fabricators Hub",
                WorkCapabilities: new List<string> { "Welding" },
                ProcessesSupported: "TIG, MIG",
                WorkCoverage: "Pan India",
                IndustryId: 1,
                BusinessGroupId: 2,
                SubGroupId: 99999, // INVALID FK
                CategoryId: 4
            )
        );

        var result = await _registrationService.SubmitRegistrationAsync(badHierarchyRequest, "127.0.0.1");

        Assert.False(result.Success);
        Assert.Equal(400, result.StatusCode);
        Assert.Contains("hierarchy", result.ErrorMessage, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitRegistration_ReusedConsumedGrant_Fails()
    {
        var challenge = new OtpChallenge
        {
            Email = "reused@connexa.com",
            RegistrationFlowId = "flow_reused",
            Status = OtpChallengeStatus.Verified,
            VerificationGrantToken = "grant_reused",
            VerificationGrantExpiresAtUtc = DateTime.UtcNow.AddMinutes(30),
            OtpHashingSalt = "salt",
            OtpHash = "hash"
        };
        _dbContext.OtpChallenges.Add(challenge);
        await _dbContext.SaveChangesAsync();

        var request = new SubmitRegistrationRequestDto(
            VerificationGrant: "grant_reused",
            RegistrationFlowId: "flow_reused",
            FullName: "User One",
            CountryCode: "+91",
            MobileNumber: "9100000001",
            Email: "reused@connexa.com",
            ProfileType: (int)ProfileTypeEnum.EmployeeJobSeeker,
            EmployeeDetails: new EmployeeProfileDetailsDto("Tech", "C#", "1", "Full")
        );

        // First attempt succeeds
        var firstResult = await _registrationService.SubmitRegistrationAsync(request, "127.0.0.1");
        Assert.True(firstResult.Success);

        // Second attempt with same grant fails (consumed)
        var secondRequest = request with { MobileNumber = "9100000002", Email = "different@connexa.com" };
        var secondResult = await _registrationService.SubmitRegistrationAsync(secondRequest, "127.0.0.1");

        Assert.False(secondResult.Success);
        Assert.Equal(400, secondResult.StatusCode);
    }
}

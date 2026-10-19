using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Auth;

namespace Connexa.Api.Tests.Integration;

public class AuthEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };

    public AuthEndpointsTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task SetupPassword_WithValidCredentialSetupToken_SucceedsAndReturnsTokens()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

        var testEmail = $"auth_test_setup_{Guid.NewGuid():N}@connexa.com";
        var setupToken = Guid.NewGuid().ToString("N");

        var member = new Member
        {
            FullName = "Setup Test Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.EmployeeJobSeeker,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true,
            CredentialSetupToken = setupToken,
            CredentialSetupTokenExpiresAtUtc = DateTime.UtcNow.AddMinutes(15)
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: setupToken,
            VerificationGrant: null,
            Destination: null,
            Password: "SecurePassword123!",
            ConfirmPassword: "SecurePassword123!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.True(body.Success);
        Assert.NotNull(body.Data);
        Assert.False(string.IsNullOrWhiteSpace(body.Data.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(body.Data.RefreshToken));
        Assert.Equal("Bearer", body.Data.TokenType);
        Assert.Equal(member.Id, body.Data.Member.MemberId);
        Assert.Equal("Member", body.Data.Member.Role);

        // Verify database: password hash is set and setup token cleared
        using var verifyScope = _factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var updated = await verifyDb.Members.FindAsync(member.Id);
        Assert.NotNull(updated);
        Assert.NotNull(updated.PasswordHash);
        Assert.NotNull(updated.PasswordSalt);
        Assert.Null(updated.CredentialSetupToken);
    }

    [Fact]
    public async Task SetupPassword_WithInvalidToken_Returns400BadRequest()
    {
        var client = _factory.CreateClient();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: "non_existent_token_12345",
            VerificationGrant: null,
            Destination: null,
            Password: "SecurePassword123!",
            ConfirmPassword: "SecurePassword123!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.False(body.Success);
    }

    [Fact]
    public async Task SetupPassword_WithWeakPassword_FailsPolicyWith400()
    {
        var client = _factory.CreateClient();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: "some_token",
            VerificationGrant: null,
            Destination: null,
            Password: "weak",
            ConfirmPassword: "weak"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SetupPassword_WithMissingToken_Returns400BadRequest()
    {
        var client = _factory.CreateClient();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: null,
            VerificationGrant: null,
            Destination: null,
            Password: "SecurePassword123!",
            ConfirmPassword: "SecurePassword123!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.False(body.Success);
        Assert.Contains("required", body.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SetupPassword_WithExpiredToken_Returns400BadRequest()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

        var testEmail = $"auth_expired_test_{Guid.NewGuid():N}@connexa.com";
        var expiredToken = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));

        var member = new Member
        {
            FullName = "Expired Token Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.EmployeeJobSeeker,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true,
            CredentialSetupToken = expiredToken,
            CredentialSetupTokenExpiresAtUtc = DateTime.UtcNow.AddMinutes(-10) // Expired 10 mins ago
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: expiredToken,
            VerificationGrant: null,
            Destination: null,
            Password: "SecurePassword123!",
            ConfirmPassword: "SecurePassword123!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.False(body.Success);
        Assert.Contains("expired", body.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SetupPassword_WithReusedToken_FailsOnSecondAttempt()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

        var testEmail = $"auth_reuse_test_{Guid.NewGuid():N}@connexa.com";
        var singleUseToken = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));

        var member = new Member
        {
            FullName = "Reused Token Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.ContractorJobWorker,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true,
            CredentialSetupToken = singleUseToken,
            CredentialSetupTokenExpiresAtUtc = DateTime.UtcNow.AddMinutes(30)
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new SetupPasswordRequestDto(
            CredentialSetupToken: singleUseToken,
            VerificationGrant: null,
            Destination: null,
            Password: "SecurePassword123!",
            ConfirmPassword: "SecurePassword123!"
        );

        // First attempt: Must succeed (200 OK)
        var firstResponse = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);
        Assert.Equal(HttpStatusCode.OK, firstResponse.StatusCode);

        // Second attempt: Must fail (400 Bad Request) because token was atomically wiped
        var secondResponse = await client.PostAsJsonAsync("/api/v1/auth/setup-password", request);
        Assert.Equal(HttpStatusCode.BadRequest, secondResponse.StatusCode);
        var body = await secondResponse.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.False(body.Success);
        Assert.Contains("expired", body.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task RequestSetupOtp_ForRegisteredMember_DispatchesOtpSuccessfully()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

        var testEmail = $"setup_otp_registered_{Guid.NewGuid():N}@connexa.com";
        var member = new Member
        {
            FullName = "Existing Registered Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new RequestSetupOtpRequestDto(
            Identifier: testEmail,
            Channel: "Email"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/request-setup-otp", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<RequestSetupOtpResponseDto>>(_jsonOptions);
        Assert.NotNull(body?.Data);
        Assert.True(body.Success);
        Assert.True(body.Data.ChallengeId > 0);
        Assert.Equal(testEmail, body.Data.Destination);
    }

    [Fact]
    public async Task RequestSetupOtp_ForNonExistentMember_Returns404NotFound()
    {
        var client = _factory.CreateClient();

        var request = new RequestSetupOtpRequestDto(
            Identifier: $"unregistered_{Guid.NewGuid():N}@connexa.com",
            Channel: "Email"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/request-setup-otp", request);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task VerifySetupOtp_WithValidOtp_IssuesFreshCredentialSetupToken_AndAllowsPasswordSetup()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();

        var testEmail = $"verify_setup_{Guid.NewGuid():N}@connexa.com";
        var member = new Member
        {
            FullName = "Recovery OTP Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.ServiceEngineer,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        // 1. Request OTP
        var reqOtpResponse = await client.PostAsJsonAsync("/api/v1/auth/request-setup-otp", new RequestSetupOtpRequestDto(testEmail, "Email"));
        Assert.Equal(HttpStatusCode.OK, reqOtpResponse.StatusCode);
        var reqBody = await reqOtpResponse.Content.ReadFromJsonAsync<ApiResponse<RequestSetupOtpResponseDto>>(_jsonOptions);
        Assert.NotNull(reqBody?.Data);

        var challengeId = reqBody.Data.ChallengeId;
        var flowId = reqBody.Data.FlowId;

        // Retrieve OTP code from challenge
        using var checkScope = _factory.Services.CreateScope();
        var checkDb = checkScope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var challenge = await checkDb.OtpChallenges.FindAsync(challengeId);
        Assert.NotNull(challenge);
        var otpCode = challenge.OtpCode!;

        // 2. Verify OTP
        var verifyResponse = await client.PostAsJsonAsync("/api/v1/auth/verify-setup-otp", new VerifySetupOtpRequestDto(challengeId, flowId, otpCode, "Email"));
        Assert.Equal(HttpStatusCode.OK, verifyResponse.StatusCode);
        var verifyBody = await verifyResponse.Content.ReadFromJsonAsync<ApiResponse<VerifySetupOtpResponseDto>>(_jsonOptions);
        Assert.NotNull(verifyBody?.Data);
        Assert.True(verifyBody.Success);
        Assert.Equal(64, verifyBody.Data.CredentialSetupToken.Length);

        // 3. Complete password setup with the fresh token
        var setupResponse = await client.PostAsJsonAsync("/api/v1/auth/setup-password", new SetupPasswordRequestDto(
            CredentialSetupToken: verifyBody.Data.CredentialSetupToken,
            VerificationGrant: null,
            Destination: null,
            Password: "StrongPassword2026!",
            ConfirmPassword: "StrongPassword2026!"
        ));

        Assert.Equal(HttpStatusCode.OK, setupResponse.StatusCode);
        var setupBody = await setupResponse.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(setupBody?.Data);
        Assert.Equal(member.Id, setupBody.Data.Member.MemberId);
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsTokensAndMemberInfo()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        var testEmail = $"auth_login_valid_{Guid.NewGuid():N}@connexa.com";
        var password = "ValidPassword123#";
        var (hash, salt) = hasher.HashPassword(password);

        var member = new Member
        {
            FullName = "Login Valid Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.TraderSupplier,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true,
            PasswordHash = hash,
            PasswordSalt = salt
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new LoginRequestDto(
            Identifier: testEmail,
            Password: password
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/login", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.True(body.Success);
        Assert.NotNull(body.Data);
        Assert.Equal(member.Id, body.Data.Member.MemberId);
        Assert.Equal("TraderSupplier", body.Data.Member.PrimaryProfileType);
    }

    [Fact]
    public async Task Login_WithInvalidPassword_Returns401Unauthorized()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        var testEmail = $"auth_login_wrong_{Guid.NewGuid():N}@connexa.com";
        var (hash, salt) = hasher.HashPassword("CorrectPassword123!");

        var member = new Member
        {
            FullName = "Wrong Pass Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = testEmail,
            PrimaryProfileType = ProfileTypeEnum.EmployeeJobSeeker,
            VerifiedMethod = "Email",
            VerifiedDestination = testEmail,
            Role = "Member",
            IsActive = true,
            PasswordHash = hash,
            PasswordSalt = salt
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var request = new LoginRequestDto(
            Identifier: testEmail,
            Password: "WrongPassword999!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/login", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body);
        Assert.False(body.Success);
    }

    [Fact]
    public async Task Login_WithNonExistentAccount_Returns401WithoutLeakingAccountStatus()
    {
        var client = _factory.CreateClient();

        var request = new LoginRequestDto(
            Identifier: "non_existent_user_9999@connexa.com",
            Password: "SomePassword123!"
        );

        var response = await client.PostAsJsonAsync("/api/v1/auth/login", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task RefreshToken_Rotation_IssuesNewTokensAndRevokesOld()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var member = new Member
        {
            FullName = "Refresh Test Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = $"refresh_test_{Guid.NewGuid():N}@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = "dest@connexa.com",
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var (plainRefresh, entity) = tokenService.GenerateRefreshToken(member.Id, "127.0.0.1");
        db.RefreshTokens.Add(entity);
        await db.SaveChangesAsync();

        // 1. Refresh with valid token
        var refreshRequest = new RefreshTokenRequestDto(RefreshToken: plainRefresh);
        var response = await client.PostAsJsonAsync("/api/v1/auth/refresh", refreshRequest);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>(_jsonOptions);
        Assert.NotNull(body?.Data);
        Assert.NotEqual(plainRefresh, body.Data.RefreshToken);

        // 2. Replay attack test: attempt to refresh AGAIN with the old plain token
        var replayResponse = await client.PostAsJsonAsync("/api/v1/auth/refresh", refreshRequest);

        Assert.Equal(HttpStatusCode.Unauthorized, replayResponse.StatusCode);
    }

    [Fact]
    public async Task GetCurrentMember_WithValidToken_Returns200AndMemberData()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var member = new Member
        {
            FullName = "Claims Test Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = $"claims_test_{Guid.NewGuid():N}@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.EmployeeJobSeeker,
            VerifiedMethod = "Email",
            VerifiedDestination = "claims@connexa.com",
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var accessToken = tokenService.GenerateAccessToken(member);

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var response = await client.GetAsync("/api/v1/members/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<MemberProfileResponseDto>>(_jsonOptions);
        Assert.NotNull(body?.Data);
        Assert.Equal(member.Id, body.Data.MemberId);
        Assert.Equal("Claims Test Member", body.Data.FullName);
    }

    [Fact]
    public async Task GetCurrentMember_WithoutToken_Returns401Unauthorized()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/members/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

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

public class MemberProfileAndDirectoryTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };

    public MemberProfileAndDirectoryTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task UpdateProfile_WithoutToken_Returns401Unauthorized()
    {
        var client = _factory.CreateClient();

        var request = new UpdateMemberProfileRequestDto("Updated Name");
        var response = await client.PutAsJsonAsync("/api/v1/members/me/profile", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProfile_WithValidBusinessHierarchy_UpdatesAndReturns200()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        // Fetch existing valid 4-tier hierarchy
        var category = await db.Categories
            .Include(c => c.SubGroup)
                .ThenInclude(sg => sg.BusinessGroup)
                    .ThenInclude(bg => bg.Industry)
            .FirstOrDefaultAsync();

        Assert.NotNull(category);
        var subGroup = category.SubGroup;
        var group = subGroup.BusinessGroup;
        var industry = group.Industry;

        var member = new Member
        {
            FullName = "Original Business Owner",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = $"biz_update_{Guid.NewGuid():N}@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = "biz@connexa.com",
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var token = tokenService.GenerateAccessToken(member);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var updateRequest = new UpdateMemberProfileRequestDto(
            FullName: "Renamed Business Owner",
            BusinessDetails: new UpdateBusinessProfileDto(
                CompanyName: "Apex Pumps & Motors Pvt Ltd",
                BusinessCapabilities: new List<string> { "Manufacturer", "Exporter" },
                BusinessDescription: "High-grade centrifugal pumps manufacturing unit.",
                IndustryId: industry.Id,
                BusinessGroupId: group.Id,
                SubGroupId: subGroup.Id,
                CategoryId: category.Id
            )
        );

        var response = await client.PutAsJsonAsync("/api/v1/members/me/profile", updateRequest);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse<MemberProfileResponseDto>>(_jsonOptions);
        Assert.NotNull(body?.Data);
        Assert.Equal("Renamed Business Owner", body.Data.FullName);
        Assert.Equal(member.Id, body.Data.MemberId);

        // Verify in database
        using var verifyScope = _factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var updatedProfile = await verifyDb.BusinessProfiles
            .Include(b => b.Industry)
            .Include(b => b.Category)
            .FirstOrDefaultAsync(b => b.MemberId == member.Id);

        Assert.NotNull(updatedProfile);
        Assert.Equal("Apex Pumps & Motors Pvt Ltd", updatedProfile.CompanyName);
        Assert.Equal("Manufacturer, Exporter", updatedProfile.BusinessCapabilities);
        Assert.Equal(industry.Id, updatedProfile.IndustryId);
        Assert.Equal(category.Id, updatedProfile.CategoryId);
    }

    [Fact]
    public async Task UpdateProfile_WithMismatchedHierarchy_Returns400BadRequest()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var member = new Member
        {
            FullName = "Mismatched Test Member",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = $"mismatch_{Guid.NewGuid():N}@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = "mismatch@connexa.com",
            Role = "Member",
            IsActive = true
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var token = tokenService.GenerateAccessToken(member);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Category 9999 does not exist
        var updateRequest = new UpdateMemberProfileRequestDto(
            FullName: "Should Fail Owner",
            BusinessDetails: new UpdateBusinessProfileDto(
                CompanyName: "Faulty Hierarchy Ltd",
                BusinessCapabilities: new List<string> { "Manufacturer" },
                BusinessDescription: "Testing hierarchy rejection",
                IndustryId: 1,
                BusinessGroupId: 1,
                SubGroupId: 1,
                CategoryId: 99999
            )
        );

        var response = await client.PutAsJsonAsync("/api/v1/members/me/profile", updateRequest);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Directory_WithoutToken_Returns401Unauthorized()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/v1/directory/businesses");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Directory_WithValidToken_ReturnsPaginatedBusinessesAndExcludesSensitiveData()
    {
        var client = _factory.CreateClient();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        // Ensure category and business exist
        var cat = await db.Categories
            .Include(c => c.SubGroup)
                .ThenInclude(s => s.BusinessGroup)
            .FirstOrDefaultAsync();

        if (cat == null)
        {
            var ind = new Industry { Name = "Tech & Software" };
            db.Industries.Add(ind);
            await db.SaveChangesAsync();

            var grp = new BusinessGroup { IndustryId = ind.Id, Name = "Enterprise Software" };
            db.BusinessGroups.Add(grp);
            await db.SaveChangesAsync();

            var sub = new SubGroup { BusinessGroupId = grp.Id, Name = "Cloud Infrastructure" };
            db.SubGroups.Add(sub);
            await db.SaveChangesAsync();

            cat = new Category { SubGroupId = sub.Id, Name = "DevOps Platforms" };
            db.Categories.Add(cat);
            await db.SaveChangesAsync();
        }

        var member = new Member
        {
            FullName = "Directory Contact Person",
            CountryCode = "+91",
            PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
            Email = $"dir_test_{Guid.NewGuid():N}@connexa.com",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            VerifiedMethod = "Email",
            VerifiedDestination = "dir@connexa.com",
            Role = "Member",
            IsActive = true,
            PasswordHash = "SecretHashNeverLeak",
            PasswordSalt = "SecretSaltNeverLeak"
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        var biz = new BusinessProfile
        {
            MemberId = member.Id,
            CompanyName = $"DirectTestCorp_{Guid.NewGuid():N}",
            BusinessCapabilities = "Cloud Provider, DevOps Consulting",
            BusinessDescription = "Reliable cloud solutions",
            IndustryId = cat.SubGroup.BusinessGroup.IndustryId,
            BusinessGroupId = cat.SubGroup.BusinessGroupId,
            SubGroupId = cat.SubGroupId,
            CategoryId = cat.Id
        };
        db.BusinessProfiles.Add(biz);
        await db.SaveChangesAsync();

        var token = tokenService.GenerateAccessToken(member);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await client.GetAsync($"/api/v1/directory/businesses?search={biz.CompanyName}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse<BusinessDirectoryResponseDto>>(_jsonOptions);
        Assert.NotNull(body?.Data);
        Assert.True(body.Data.TotalCount >= 1);
        Assert.Contains(body.Data.Items, item => item.CompanyName == biz.CompanyName);

        var foundItem = body.Data.Items.First(item => item.CompanyName == biz.CompanyName);
        Assert.Equal("Directory Contact Person", foundItem.ContactPersonName);
        Assert.Equal(cat.Name, foundItem.CategoryName);
        Assert.Equal(2, foundItem.BusinessCapabilities.Count);

        // Verify sensitive fields are not in the raw JSON payload
        var rawJson = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("SecretHashNeverLeak", rawJson);
        Assert.DoesNotContain("SecretSaltNeverLeak", rawJson);
        Assert.DoesNotContain("passwordHash", rawJson, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("passwordSalt", rawJson, StringComparison.OrdinalIgnoreCase);

        // Test single business lookup
        var singleResponse = await client.GetAsync($"/api/v1/directory/businesses/{member.Id}");
        Assert.Equal(HttpStatusCode.OK, singleResponse.StatusCode);
        var singleBody = await singleResponse.Content.ReadFromJsonAsync<ApiResponse<BusinessDirectoryItemDto>>(_jsonOptions);
        Assert.NotNull(singleBody?.Data);
        Assert.Equal(biz.CompanyName, singleBody.Data.CompanyName);
    }
}

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
using Xunit;

namespace Connexa.Api.Tests.Integration;

public class ApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public ApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetHealth_Returns200Ok()
    {
        var response = await _client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<JsonElement>(JsonOptions);
        Assert.Equal("ok", content.GetProperty("status").GetString());
        Assert.Equal("Connexa B2B API", content.GetProperty("service").GetString());
    }

    [Fact]
    public async Task GetApiHealth_Returns200Ok_WithVersion()
    {
        var response = await _client.GetAsync("/api/v1/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<JsonElement>(JsonOptions);
        Assert.Equal("ok", content.GetProperty("status").GetString());
        Assert.Equal("1.0.0", content.GetProperty("version").GetString());
    }

    [Fact]
    public async Task GetIndustries_ReturnsRealDatabaseRecords_MatchingNodeContract()
    {
        var response = await _client.GetAsync("/api/v1/master/industries");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<IndustryDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 4);
        Assert.NotNull(result.Data);

        var mfg = result.Data.FirstOrDefault(i => i.Id == 4 || i.Code == "MFG");
        Assert.NotNull(mfg);
        Assert.Equal("Manufacturing & Heavy Engineering", mfg.Name);
        Assert.Equal("MFG", mfg.Code);
    }

    [Fact]
    public async Task GetBusinessGroups_ByPath_ReturnsChildGroups_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/industries/4/business-groups");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<BusinessGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 2);
        Assert.NotNull(result.Parent);
        Assert.Equal(4, result.Parent.Id);
        Assert.All(result.Data, bg => Assert.Equal(4, bg.IndustryId));

        var mach = result.Data.FirstOrDefault(bg => bg.Id == 3 || bg.Code == "MACH");
        Assert.NotNull(mach);
        Assert.Equal("Machinery & Equipment", mach.Name);
    }

    [Fact]
    public async Task GetBusinessGroups_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/business-groups?industryId=4");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<BusinessGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, bg => bg.Id == 3 || bg.Code == "MACH");
    }

    [Fact]
    public async Task GetSubGroups_ByPath_ReturnsChildSubGroups_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/business-groups/3/sub-groups");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<SubGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 2);
        Assert.NotNull(result.Parent);
        Assert.Equal(3, result.Parent.Id);
        Assert.All(result.Data, sg => Assert.Equal(3, sg.BusinessGroupId));

        var cnc = result.Data.FirstOrDefault(sg => sg.Id == 3 || sg.Code == "CNC");
        Assert.NotNull(cnc);
        Assert.Equal("CNC & Machine Tools", cnc.Name);
    }

    [Fact]
    public async Task GetSubGroups_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/sub-groups?businessGroupId=3");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<SubGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, sg => sg.Id == 3 || sg.Code == "CNC");
    }

    [Fact]
    public async Task GetCategories_ByPath_ReturnsChildCategories_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/sub-groups/3/categories");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<CategoryDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 4);
        Assert.NotNull(result.Parent);
        Assert.Equal(3, result.Parent.Id);
        Assert.All(result.Data, c => Assert.Equal(3, c.SubGroupId));

        var lathe = result.Data.FirstOrDefault(c => c.Id == 13 || c.Code == "LATH");
        Assert.NotNull(lathe);
        Assert.Equal("CNC Lathes & Turning Centers", lathe.Name);
    }

    [Fact]
    public async Task GetCategories_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/categories?subGroupId=3");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<CategoryDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, c => c.Id == 13 || c.Code == "LATH");
    }

    [Fact]
    public async Task NonExistentParent_Returns404_WithHelpfulMessage()
    {
        var response = await _client.GetAsync("/api/v1/master/industries/99999/business-groups");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var error = await response.Content.ReadFromJsonAsync<ErrorResponseDto>(JsonOptions);
        Assert.NotNull(error);
        Assert.False(error.Success);
        Assert.Contains("not found", error.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task MissingQueryParam_Returns400BadRequest()
    {
        var response = await _client.GetAsync("/api/v1/master/business-groups");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var error = await response.Content.ReadFromJsonAsync<ErrorResponseDto>(JsonOptions);
        Assert.NotNull(error);
        Assert.False(error.Success);
        Assert.Contains("required", error.Message, StringComparison.OrdinalIgnoreCase);
    }

    private async Task<string> GetOrCreateTestMemberAccessTokenAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ConnexaDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var member = await db.Members.FirstOrDefaultAsync(m => m.IsActive);
        if (member == null)
        {
            member = new Member
            {
                FullName = "Integration Discovery Member",
                CountryCode = "+91",
                PhoneNumber = "+91" + Random.Shared.NextInt64(7000000000, 7999999999),
                Email = $"disc_{Guid.NewGuid():N}@connexa.com",
                PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
                VerifiedMethod = "Email",
                VerifiedDestination = "disc@connexa.com",
                Role = "Member",
                IsActive = true
            };
            db.Members.Add(member);
            await db.SaveChangesAsync();
        }

        return tokenService.GenerateAccessToken(member);
    }

    [Fact]
    public async Task GetProducts_Unauthenticated_Returns401Unauthorized()
    {
        var response = await _client.GetAsync("/api/v1/products");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetProducts_Authenticated_ReturnsGlobalCatalog_FromMultipleMembers()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/products?page=1&pageSize=10");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductCatalogResponseDto>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.True(result.Data.TotalCount >= 1);
        Assert.NotEmpty(result.Data.Items);

        var first = result.Data.Items.First();
        Assert.NotNull(first.Name);
        Assert.NotNull(first.Category);
    }

    [Fact]
    public async Task GetProducts_FilterByIndustry_ReturnsMatchingResults()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/products?industryId=1");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductCatalogResponseDto>>(JsonOptions);
        Assert.NotNull(result?.Data);
        if (result.Data.Items.Any())
        {
            Assert.All(result.Data.Items, p => Assert.Equal(1, p.IndustryId));
        }
    }

    [Fact]
    public async Task GetProducts_Pagination_ReturnsCorrectMetadata()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/products?page=1&pageSize=1");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<ProductCatalogResponseDto>>(JsonOptions);
        Assert.NotNull(result?.Data);
        Assert.Equal(1, result.Data.Page);
        Assert.Equal(1, result.Data.PageSize);
        Assert.True(result.Data.Items.Count <= 1);
    }

    [Fact]
    public async Task GetRecommendedProducts_Unauthenticated_Returns401Unauthorized()
    {
        var response = await _client.GetAsync("/api/v1/products/recommended");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetRecommendedProducts_Authenticated_ReturnsRecommendations()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/products/recommended?pageSize=6");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<ProductDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
    }

    [Fact]
    public async Task GetRelatedProducts_ReturnsRelatedItems_ExcludingCurrentProduct()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        // First get catalog to pick a valid product ID
        using var catReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/products?page=1&pageSize=1");
        catReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var catResp = await _client.SendAsync(catReq);
        var catResult = await catResp.Content.ReadFromJsonAsync<ApiResponse<ProductCatalogResponseDto>>(JsonOptions);
        var targetProduct = catResult?.Data?.Items.FirstOrDefault();

        if (targetProduct != null)
        {
            using var relReq = new HttpRequestMessage(HttpMethod.Get, $"/api/v1/products/{targetProduct.Id}/related?limit=5");
            relReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var relResp = await _client.SendAsync(relReq);
            Assert.Equal(HttpStatusCode.OK, relResp.StatusCode);

            var relResult = await relResp.Content.ReadFromJsonAsync<ApiResponse<List<ProductDto>>>(JsonOptions);
            Assert.NotNull(relResult);
            Assert.True(relResult.Success);
            Assert.NotNull(relResult.Data);
            Assert.DoesNotContain(relResult.Data, p => p.Id == targetProduct.Id);
        }
    }

    [Fact]
    public async Task GetNotifications_Unauthenticated_Returns401Unauthorized()
    {
        var response = await _client.GetAsync("/api/v1/notifications");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetNotifications_Authenticated_ReturnsPaginatedResult()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/notifications?page=1&pageSize=10");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<PaginatedNotificationsDto>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal(1, result.Data.Page);
    }

    [Fact]
    public async Task GetUnreadNotificationCount_Authenticated_ReturnsCount()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/notifications/unread-count");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<UnreadNotificationCountDto>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.True(result.Data.UnreadCount >= 0);
    }

    [Fact]
    public async Task RegisterDeviceToken_Authenticated_ReturnsSuccess()
    {
        var token = await GetOrCreateTestMemberAccessTokenAsync();
        var body = new RegisterDeviceTokenDto("test_fcm_token_device_999", "android");
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/notifications/device-tokens")
        {
            Content = JsonContent.Create(body)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<bool>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Data);
    }
}
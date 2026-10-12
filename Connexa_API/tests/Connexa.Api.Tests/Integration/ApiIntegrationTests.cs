using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Connexa.Api.DTOs;
using Xunit;

namespace Connexa.Api.Tests.Integration;

public class ApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public ApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
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

        var mfg = result.Data.FirstOrDefault(i => i.Id == "ind_mfg");
        Assert.NotNull(mfg);
        Assert.Equal("Manufacturing & Heavy Engineering", mfg.Name);
        Assert.Equal("MFG", mfg.Code);
    }

    [Fact]
    public async Task GetBusinessGroups_ByPath_ReturnsChildGroups_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/industries/ind_mfg/business-groups");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<BusinessGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 2);
        Assert.NotNull(result.Parent);
        Assert.Equal("ind_mfg", result.Parent.Id);
        Assert.All(result.Data, bg => Assert.Equal("ind_mfg", bg.IndustryId));

        var mach = result.Data.FirstOrDefault(bg => bg.Id == "bg_mach");
        Assert.NotNull(mach);
        Assert.Equal("Machinery & Equipment", mach.Name);
    }

    [Fact]
    public async Task GetBusinessGroups_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/business-groups?industryId=ind_mfg");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<BusinessGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, bg => bg.Id == "bg_mach");
    }

    [Fact]
    public async Task GetSubGroups_ByPath_ReturnsChildSubGroups_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/business-groups/bg_mach/sub-groups");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<SubGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 2);
        Assert.NotNull(result.Parent);
        Assert.Equal("bg_mach", result.Parent.Id);
        Assert.All(result.Data, sg => Assert.Equal("bg_mach", sg.BusinessGroupId));

        var cnc = result.Data.FirstOrDefault(sg => sg.Id == "sg_cnc");
        Assert.NotNull(cnc);
        Assert.Equal("CNC & Machine Tools", cnc.Name);
    }

    [Fact]
    public async Task GetSubGroups_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/sub-groups?businessGroupId=bg_mach");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<SubGroupDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, sg => sg.Id == "sg_cnc");
    }

    [Fact]
    public async Task GetCategories_ByPath_ReturnsChildCategories_WithParentRef()
    {
        var response = await _client.GetAsync("/api/v1/master/sub-groups/sg_cnc/categories");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<CategoryDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.True(result.Count >= 4);
        Assert.NotNull(result.Parent);
        Assert.Equal("sg_cnc", result.Parent.Id);
        Assert.All(result.Data, c => Assert.Equal("sg_cnc", c.SubGroupId));

        var lathe = result.Data.FirstOrDefault(c => c.Id == "cat_lathe");
        Assert.NotNull(lathe);
        Assert.Equal("CNC Lathes & Turning Centers", lathe.Name);
    }

    [Fact]
    public async Task GetCategories_ByQueryFallback_ReturnsSameRecords()
    {
        var response = await _client.GetAsync("/api/v1/master/categories?subGroupId=sg_cnc");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<ApiResponse<List<CategoryDto>>>(JsonOptions);
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Contains(result.Data, c => c.Id == "cat_lathe");
    }

    [Fact]
    public async Task NonExistentParent_Returns404_WithHelpfulMessage()
    {
        var response = await _client.GetAsync("/api/v1/master/industries/non_existent_id/business-groups");
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
}
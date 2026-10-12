using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Connexa.Api.Data;
using Connexa.Api.Entities;
using Connexa.Api.Services;
using Xunit;

namespace Connexa.Api.Tests.Services;

public class MasterDataServiceTests
{
    private ConnexaDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        var context = new ConnexaDbContext(options);

        // Seed sample hierarchy
        var ind1 = new Industry { Id = "ind_1", Name = "Alpha Industry", Code = "ALP" };
        var ind2 = new Industry { Id = "ind_2", Name = "Beta Industry", Code = "BET" };

        var bg1 = new BusinessGroup { Id = "bg_1", IndustryId = "ind_1", Name = "Alpha Group 1" };
        var bg2 = new BusinessGroup { Id = "bg_2", IndustryId = "ind_1", Name = "Alpha Group 2" };
        var bgOther = new BusinessGroup { Id = "bg_other", IndustryId = "ind_2", Name = "Beta Group 1" };

        var sg1 = new SubGroup { Id = "sg_1", BusinessGroupId = "bg_1", Name = "SubGroup 1" };
        var sg2 = new SubGroup { Id = "sg_2", BusinessGroupId = "bg_1", Name = "SubGroup 2" };

        var cat1 = new Category { Id = "cat_1", SubGroupId = "sg_1", Name = "Category 1" };
        var cat2 = new Category { Id = "cat_2", SubGroupId = "sg_1", Name = "Category 2" };

        context.Industries.AddRange(ind1, ind2);
        context.BusinessGroups.AddRange(bg1, bg2, bgOther);
        context.SubGroups.AddRange(sg1, sg2);
        context.Categories.AddRange(cat1, cat2);
        context.SaveChanges();

        return context;
    }

    [Fact]
    public async Task GetIndustriesAsync_ReturnsAllIndustries_OrderedByName()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetIndustriesAsync();

        Assert.True(result.Success);
        Assert.Equal(2, result.Count);
        Assert.Equal("Alpha Industry", result.Data[0].Name);
        Assert.Equal("Beta Industry", result.Data[1].Name);
    }

    [Fact]
    public async Task GetBusinessGroupsAsync_ReturnsOnlyChildrenOfTargetParent()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetBusinessGroupsAsync("ind_1");

        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Equal(2, result.Count);
        Assert.All(result.Data, bg => Assert.Equal("ind_1", bg.IndustryId));
        Assert.NotNull(result.Parent);
        Assert.Equal("ind_1", result.Parent.Id);
        Assert.Equal("Alpha Industry", result.Parent.Name);
    }

    [Fact]
    public async Task GetBusinessGroupsAsync_NonExistentParent_ReturnsNull()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetBusinessGroupsAsync("non_existent");

        Assert.Null(result);
    }

    [Fact]
    public async Task GetSubGroupsAsync_ReturnsOnlyChildrenOfTargetGroup()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetSubGroupsAsync("bg_1");

        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Equal(2, result.Count);
        Assert.All(result.Data, sg => Assert.Equal("bg_1", sg.BusinessGroupId));
        Assert.NotNull(result.Parent);
        Assert.Equal("bg_1", result.Parent.Id);
        Assert.Equal("ind_1", result.Parent.IndustryId);
    }

    [Fact]
    public async Task GetSubGroupsAsync_NonExistentParent_ReturnsNull()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetSubGroupsAsync("non_existent");

        Assert.Null(result);
    }

    [Fact]
    public async Task GetCategoriesAsync_ReturnsOnlyChildrenOfTargetSubGroup()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetCategoriesAsync("sg_1");

        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.Equal(2, result.Count);
        Assert.All(result.Data, c => Assert.Equal("sg_1", c.SubGroupId));
        Assert.NotNull(result.Parent);
        Assert.Equal("sg_1", result.Parent.Id);
        Assert.Equal("bg_1", result.Parent.BusinessGroupId);
    }

    [Fact]
    public async Task GetCategoriesAsync_NonExistentParent_ReturnsNull()
    {
        using var context = CreateInMemoryDbContext();
        var service = new MasterDataService(context, NullLogger<MasterDataService>.Instance);

        var result = await service.GetCategoriesAsync("non_existent");

        Assert.Null(result);
    }
}
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Directory;

namespace Connexa.Api.Tests.Services;

public class DirectoryServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly DirectoryService _directoryService;

    public DirectoryServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaDirTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _directoryService = new DirectoryService(_dbContext, NullLogger<DirectoryService>.Instance);

        SeedSampleData();
    }

    private void SeedSampleData()
    {
        var indTextiles = new Industry { Id = 1, Name = "Textiles & Fabrics", Code = "TXT" };
        var indChemicals = new Industry { Id = 2, Name = "Chemical Processing", Code = "CHM" };

        var bgTextiles = new BusinessGroup { Id = 1, IndustryId = 1, Name = "Spinning & Weaving", Code = "SPW" };
        var bgChemicals = new BusinessGroup { Id = 2, IndustryId = 2, Name = "Industrial Chemicals", Code = "ICH" };

        var sgCotton = new SubGroup { Id = 1, BusinessGroupId = 1, Name = "Cotton Mills", Code = "CTM" };
        var sgSolvents = new SubGroup { Id = 2, BusinessGroupId = 2, Name = "Organic Solvents", Code = "ORS" };

        var catDenim = new Category { Id = 1, SubGroupId = 1, Name = "Denim Fabric", Code = "DNM" };
        var catAcetone = new Category { Id = 2, SubGroupId = 2, Name = "Industrial Acetone", Code = "ACT" };

        _dbContext.Industries.AddRange(indTextiles, indChemicals);
        _dbContext.BusinessGroups.AddRange(bgTextiles, bgChemicals);
        _dbContext.SubGroups.AddRange(sgCotton, sgSolvents);
        _dbContext.Categories.AddRange(catDenim, catAcetone);

        // 1. Approved Verified Business
        var m1 = new Member
        {
            Id = 1,
            FullName = "Rajesh Shah",
            Email = "rajesh@apexsolvents.com",
            CountryCode = "+91",
            PhoneNumber = "9876543210",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 1,
                MemberId = 1,
                CompanyName = "Apex Industrial Solvents Ltd",
                BusinessCapabilities = "Chemical synthesis, Pure acetone, Batch distillation",
                BusinessDescription = "Leading ISO certified industrial solvents manufacturer in Ankleshwar.",
                IndustryId = 2,
                BusinessGroupId = 2,
                SubGroupId = 2,
                CategoryId = 2,
                City = "Ankleshwar",
                State = "Gujarat",
                Pincode = "393002",
                VerificationStatus = BusinessVerificationStatus.Approved,
                LogoUrl = "https://cdn.connexa.test/logos/apex.png"
            }
        };

        // 2. Pending Review Business
        var m2 = new Member
        {
            Id = 2,
            FullName = "Aarav Patel",
            Email = "aarav@pateltextiles.com",
            CountryCode = "+91",
            PhoneNumber = "9876543211",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 2,
                MemberId = 2,
                CompanyName = "Patel Textiles Ltd",
                BusinessCapabilities = "Weaving, Cotton spinning, Denim manufacturing",
                BusinessDescription = "Premium cotton denim fabric mill.",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1,
                City = "Surat",
                State = "Gujarat",
                Pincode = "395001",
                VerificationStatus = BusinessVerificationStatus.PendingReview
            }
        };

        // 3. Rejected Business
        var m3 = new Member
        {
            Id = 3,
            FullName = "Kiran Mehta",
            Email = "kiran@mehtadyes.com",
            CountryCode = "+91",
            PhoneNumber = "9876543212",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 3,
                MemberId = 3,
                CompanyName = "Mehta Reactive Dyes",
                BusinessCapabilities = "Reactive dye processing, Synthetic colorants",
                BusinessDescription = "Manufacturer of reactive dyes.",
                IndustryId = 2,
                BusinessGroupId = 2,
                SubGroupId = 2,
                CategoryId = 2,
                City = "Ahmedabad",
                State = "Gujarat",
                Pincode = "382445",
                VerificationStatus = BusinessVerificationStatus.Rejected
            }
        };

        // 4. Not Submitted Business
        var m4 = new Member
        {
            Id = 4,
            FullName = "Vikram Joshi",
            Email = "vikram@joshifabrics.com",
            CountryCode = "+91",
            PhoneNumber = "9876543213",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 4,
                MemberId = 4,
                CompanyName = "Joshi Fabrics & Weaving",
                BusinessCapabilities = "Custom weaving, Grey fabric",
                BusinessDescription = "Textile weaving contractor.",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1,
                City = "Vapi",
                State = "Gujarat",
                Pincode = "396191",
                VerificationStatus = BusinessVerificationStatus.NotSubmitted
            }
        };

        _dbContext.Members.AddRange(m1, m2, m3, m4);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task SearchBusinessesAsync_ReturnsAllActiveBusinesses_WithCorrectVerificationFlags()
    {
        var filter = new BusinessDirectoryFilterDto();

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.NotNull(result);
        Assert.Equal(4, result.TotalCount);
        Assert.Equal(4, result.Items.Count);

        var approved = result.Items.FirstOrDefault(i => i.CompanyName == "Apex Industrial Solvents Ltd");
        Assert.NotNull(approved);
        Assert.True(approved.IsVerified);
        Assert.Equal("Approved", approved.VerificationStatus);
        Assert.Equal("Ankleshwar, Gujarat", approved.Location);
        Assert.Equal("https://cdn.connexa.test/logos/apex.png", approved.LogoUrl);

        var pending = result.Items.FirstOrDefault(i => i.CompanyName == "Patel Textiles Ltd");
        Assert.NotNull(pending);
        Assert.False(pending.IsVerified);
        Assert.Equal("PendingReview", pending.VerificationStatus);

        var rejected = result.Items.FirstOrDefault(i => i.CompanyName == "Mehta Reactive Dyes");
        Assert.NotNull(rejected);
        Assert.False(rejected.IsVerified);
        Assert.Equal("Rejected", rejected.VerificationStatus);

        var notSubmitted = result.Items.FirstOrDefault(i => i.CompanyName == "Joshi Fabrics & Weaving");
        Assert.NotNull(notSubmitted);
        Assert.False(notSubmitted.IsVerified);
        Assert.Equal("NotSubmitted", notSubmitted.VerificationStatus);
    }

    [Fact]
    public async Task SearchBusinessesAsync_WithVerifiedOnlyTrue_ReturnsOnlyApprovedBusinesses()
    {
        var filter = new BusinessDirectoryFilterDto(VerifiedOnly: true);

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.NotNull(result);
        Assert.Equal(1, result.TotalCount);
        Assert.Single(result.Items);
        Assert.Equal("Apex Industrial Solvents Ltd", result.Items.First().CompanyName);
        Assert.True(result.Items.First().IsVerified);
        Assert.Equal("Approved", result.Items.First().VerificationStatus);
    }

    [Fact]
    public async Task SearchBusinessesAsync_WithVerifiedOnlyTrue_ExcludesPendingRejectedAndNotSubmitted()
    {
        var filter = new BusinessDirectoryFilterDto(VerifiedOnly: true);

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.DoesNotContain(result.Items, i => i.CompanyName == "Patel Textiles Ltd");
        Assert.DoesNotContain(result.Items, i => i.CompanyName == "Mehta Reactive Dyes");
        Assert.DoesNotContain(result.Items, i => i.CompanyName == "Joshi Fabrics & Weaving");
    }

    [Fact]
    public async Task SearchBusinessesAsync_CombinesSearchAndVerifiedOnlyFilters()
    {
        // Search matches two companies (Apex Industrial Solvents & Mehta Reactive Dyes for "Industrial")
        // But with VerifiedOnly=true, only Apex should be returned
        var filter = new BusinessDirectoryFilterDto(Search: "Industrial", VerifiedOnly: true);

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.NotNull(result);
        Assert.Equal(1, result.TotalCount);
        Assert.Equal("Apex Industrial Solvents Ltd", result.Items.First().CompanyName);
    }

    [Fact]
    public async Task SearchBusinessesAsync_CombinesIndustryAndVerifiedOnlyFilters()
    {
        // Industry 1 (Textiles) has Patel Textiles (Pending) and Joshi Fabrics (NotSubmitted)
        // With VerifiedOnly=true, result for Industry 1 should be 0
        var filter = new BusinessDirectoryFilterDto(IndustryId: 1, VerifiedOnly: true);

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.NotNull(result);
        Assert.Equal(0, result.TotalCount);
        Assert.Empty(result.Items);

        // Industry 2 (Chemicals) has Apex (Approved) and Mehta (Rejected)
        // With VerifiedOnly=true, result for Industry 2 should be 1
        var filterChem = new BusinessDirectoryFilterDto(IndustryId: 2, VerifiedOnly: true);
        var resultChem = await _directoryService.SearchBusinessesAsync(filterChem);

        Assert.Equal(1, resultChem.TotalCount);
        Assert.Equal("Apex Industrial Solvents Ltd", resultChem.Items.First().CompanyName);
    }

    [Fact]
    public async Task SearchBusinessesAsync_RespectsPagination_WithTotalCountAndTotalPages()
    {
        var filter = new BusinessDirectoryFilterDto(Page: 1, PageSize: 2);

        var page1 = await _directoryService.SearchBusinessesAsync(filter);

        Assert.Equal(4, page1.TotalCount);
        Assert.Equal(2, page1.Items.Count);
        Assert.Equal(1, page1.Page);
        Assert.Equal(2, page1.PageSize);
        Assert.Equal(2, page1.TotalPages);

        var page2Filter = new BusinessDirectoryFilterDto(Page: 2, PageSize: 2);
        var page2 = await _directoryService.SearchBusinessesAsync(page2Filter);

        Assert.Equal(4, page2.TotalCount);
        Assert.Equal(2, page2.Items.Count);
        Assert.Equal(2, page2.Page);

        // Verify distinct items across pages
        var page1Ids = page1.Items.Select(i => i.MemberId).ToList();
        var page2Ids = page2.Items.Select(i => i.MemberId).ToList();
        Assert.Empty(page1Ids.Intersect(page2Ids));
    }

    [Fact]
    public async Task SearchBusinessesAsync_WithNoMatches_ReturnsEmptyListGracefully()
    {
        var filter = new BusinessDirectoryFilterDto(Search: "NonExistentCompanyXYZ999");

        var result = await _directoryService.SearchBusinessesAsync(filter);

        Assert.NotNull(result);
        Assert.Equal(0, result.TotalCount);
        Assert.Empty(result.Items);
        Assert.Equal(0, result.TotalPages);
    }

    [Fact]
    public async Task GetBusinessByMemberIdAsync_ReturnsRealVerificationStatusAndLocation()
    {
        var item = await _directoryService.GetBusinessByMemberIdAsync(1);

        Assert.NotNull(item);
        Assert.Equal("Apex Industrial Solvents Ltd", item.CompanyName);
        Assert.True(item.IsVerified);
        Assert.Equal("Approved", item.VerificationStatus);
        Assert.Equal("Ankleshwar, Gujarat", item.Location);
    }

    [Fact]
    public async Task GetBusinessByMemberIdAsync_WhenNotFound_ReturnsNull()
    {
        var item = await _directoryService.GetBusinessByMemberIdAsync(99999);

        Assert.Null(item);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}


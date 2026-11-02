using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Products;

namespace Connexa.Api.Tests.Services;

public class ProductServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly ProductService _productService;

    public ProductServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaProdTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _productService = new ProductService(_dbContext, NullLogger<ProductService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var industry = new Industry { Id = 1, Name = "Manufacturing", Code = "MFG" };
        var group = new BusinessGroup { Id = 1, IndustryId = 1, Name = "Textiles", Code = "TXT" };
        var subGroup = new SubGroup { Id = 1, BusinessGroupId = 1, Name = "Weaving", Code = "WEA" };
        var category = new Category { Id = 1, SubGroupId = 1, Name = "Cotton Weaving", Code = "CW" };

        _dbContext.Industries.Add(industry);
        _dbContext.BusinessGroups.Add(group);
        _dbContext.SubGroups.Add(subGroup);
        _dbContext.Categories.Add(category);

        // Member 1
        var member1 = new Member
        {
            Id = 1,
            FullName = "Aarav Patel",
            Email = "aarav@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543210",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 1,
                MemberId = 1,
                CompanyName = "Patel Textiles Ltd",
                BusinessCapabilities = "Yarn, Fabrics",
                BusinessDescription = "Premium textile manufacture",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1
            }
        };

        // Member 2
        var member2 = new Member
        {
            Id = 2,
            FullName = "Priya Sharma",
            Email = "priya@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876543211",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 2,
                MemberId = 2,
                CompanyName = "Sharma Garments Ltd",
                BusinessCapabilities = "Cotton apparel, Stitching",
                BusinessDescription = "Exporter of apparel",
                IndustryId = 1,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1
            }
        };

        _dbContext.Members.AddRange(member1, member2);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateProduct_ValidData_CreatesSuccessfully()
    {
        var request = new CreateProductRequestDto(
            Name: "Cotton Yarn 40s",
            Description: "High-grade combed cotton yarn for fine weaving.",
            Category: "Textile Raw Materials",
            SubCategory: "Cotton Yarn",
            Tags: new List<string> { "Cotton", "Combed", "Textiles" },
            ImageUrl: "https://images.unsplash.com/photo-1584917865442-de89df76afd3",
            Specifications: new Dictionary<string, string> { { "Count", "40s Ne" }, { "Material", "100% Cotton" } }
        );

        var (success, message, product) = await _productService.CreateProductAsync(1, request);

        Assert.True(success);
        Assert.NotNull(product);
        Assert.Equal("Cotton Yarn 40s", product.Name);
        Assert.Equal("Textile Raw Materials", product.Category);
        Assert.Equal(3, product.Tags.Count);
        Assert.Equal("40s Ne", product.Specifications["Count"]);
    }

    [Fact]
    public async Task UpdateProduct_OwnerCanUpdate_NonOwnerCannot()
    {
        var (createSuccess, _, created) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Original Name",
            Description: "Original Description",
            Category: "Fabrics"
        ));
        Assert.True(createSuccess);

        // Member 2 attempts to update member 1's product -> should fail
        var (updateFail, failMessage, _) = await _productService.UpdateProductAsync(2, created!.Id, new UpdateProductRequestDto(
            Name: "Hacked Name",
            Description: "Hacked Description",
            Category: "Fabrics"
        ));
        Assert.False(updateFail);
        Assert.Contains("Unauthorized", failMessage);

        // Member 1 updates product -> should succeed
        var (updateSuccess, _, updated) = await _productService.UpdateProductAsync(1, created.Id, new UpdateProductRequestDto(
            Name: "Updated Name",
            Description: "Updated Description",
            Category: "Premium Fabrics",
            Tags: new List<string> { "Updated" }
        ));
        Assert.True(updateSuccess);
        Assert.NotNull(updated);
        Assert.Equal("Updated Name", updated.Name);
    }

    [Fact]
    public async Task DeleteProduct_OwnerCanDelete_NonOwnerCannot()
    {
        var (_, _, created) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Product to Delete",
            Description: "Description",
            Category: "Hardware"
        ));

        // Member 2 fails
        var (delFail, _) = await _productService.DeleteProductAsync(2, created!.Id);
        Assert.False(delFail);

        // Member 1 succeeds
        var (delSuccess, _) = await _productService.DeleteProductAsync(1, created.Id);
        Assert.True(delSuccess);

        var myProducts = await _productService.GetMemberProductsAsync(1);
        Assert.DoesNotContain(myProducts, p => p.Id == created.Id);
    }

    [Fact]
    public async Task ProductViews_IncrementsWhenViewedByOtherMember()
    {
        var (_, _, created) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Product with Views",
            Description: "Description",
            Category: "Electronics"
        ));

        // Owner views: view count should NOT increment
        var p1 = await _productService.GetProductByIdAsync(created!.Id, viewerMemberId: 1);
        Assert.Equal(0, p1!.ViewCount);

        // Other member views: view count should increment
        var p2 = await _productService.GetProductByIdAsync(created.Id, viewerMemberId: 2);
        Assert.Equal(1, p2!.ViewCount);
    }

    [Fact]
    public async Task ProductInquiries_SendAndReceiveInquiries()
    {
        var (_, _, created) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Special Machinery",
            Description: "Description",
            Category: "Machinery"
        ));

        // Member 2 sends inquiry to Member 1's product
        var (inqSuccess, _, inquiry) = await _productService.SendInquiryAsync(2, created!.Id, new CreateProductInquiryDto(
            Subject: "Quote Request",
            Message: "We would like to request pricing for 10 units."
        ));

        Assert.True(inqSuccess);
        Assert.NotNull(inquiry);
        Assert.Equal("Quote Request", inquiry.Subject);
        Assert.Equal("Priya Sharma", inquiry.SenderName);

        // Member 1 checks received inquiries
        var received = await _productService.GetReceivedInquiriesAsync(1);
        Assert.Single(received);
        Assert.Equal("Special Machinery", received[0].ProductName);
        Assert.Equal("Sharma Garments Ltd", received[0].SenderCompanyName);
    }

    [Fact]
    public async Task DashboardStats_AccuratelyReflectsDatabaseData()
    {
        // Add 2 products for Member 1
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("P1", "Desc", "Cat"));
        var (_, _, p2) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("P2", "Desc", "Cat"));

        // Add 1 profile view for Member 1
        await _productService.RecordCompanyViewAsync(viewedMemberId: 1, viewerMemberId: 2);

        // Add 1 product view for Member 1's product
        await _productService.GetProductByIdAsync(p2!.Id, viewerMemberId: 2);

        // Add 1 connection request where Member 1 is recipient
        _dbContext.MemberConnections.Add(new MemberConnection
        {
            RequesterMemberId = 2,
            RecipientMemberId = 1,
            Status = ConnectionStatusEnum.Pending,
            CreatedAtUtc = DateTime.UtcNow
        });
        await _dbContext.SaveChangesAsync();

        var stats = await _productService.GetDashboardStatsAsync(1);

        Assert.Equal(2, stats.MyProductsCount);
        Assert.Equal(1, stats.CompanyViewsCount);
        Assert.Equal(1, stats.ProductViewsCount);
        Assert.Equal(1, stats.ConnectionRequestsCount);
    }

    [Fact]
    public async Task RecommendedCompanies_RecommendsOtherMembersExcludingSelf()
    {
        var recs = await _productService.GetRecommendedCompaniesAsync(1, limit: 5);

        Assert.NotEmpty(recs);
        Assert.DoesNotContain(recs, r => r.MemberId == 1);
        Assert.Contains(recs, r => r.MemberId == 2);
        Assert.Equal("Sharma Garments Ltd", recs[0].CompanyName);
        Assert.Equal("Connect", recs[0].ConnectionStatus);
    }

    [Fact]
    public async Task SendInquiry_ValidData_CreatesInquirySuccessfully()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Test Product", "Description", "Textiles"));

        var (success, message, inquiry) = await _productService.SendInquiryAsync(
            senderMemberId: 2,
            productId: prod!.Id,
            dto: new CreateProductInquiryDto(
                Subject: "Bulk Quote",
                Message: "Looking to order 1,000 units.",
                QuantityRequirement: "1,000 units",
                ContactPhone: "+91 9876543211",
                ContactEmail: "priya@connexa.test"
            )
        );

        Assert.True(success);
        Assert.NotNull(inquiry);
        Assert.Equal(prod.Id, inquiry.ProductId);
        Assert.Equal(2, inquiry.SenderMemberId);
        Assert.Equal(1, inquiry.RecipientMemberId);
        Assert.Equal("Bulk Quote", inquiry.Subject);
        Assert.Contains("1,000 units", inquiry.Message);
        Assert.Equal("Pending", inquiry.Status);
    }

    [Fact]
    public async Task SendInquiry_DuplicateWithin60Seconds_ReturnsExistingInquiryWithoutDuplicating()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Test Product 2", "Description", "Textiles"));

        var dto = new CreateProductInquiryDto(
            Subject: "Urgent Inquiry",
            Message: "Please provide a price quote.",
            QuantityRequirement: "500 units"
        );

        var (success1, _, inq1) = await _productService.SendInquiryAsync(2, prod!.Id, dto);
        var (success2, _, inq2) = await _productService.SendInquiryAsync(2, prod.Id, dto);

        Assert.True(success1);
        Assert.True(success2);
        Assert.Equal(inq1!.Id, inq2!.Id);

        // Verify only 1 inquiry is in the database
        var totalInquiries = await _dbContext.ProductInquiries.CountAsync(pi => pi.ProductId == prod.Id);
        Assert.Equal(1, totalInquiries);
    }

    [Fact]
    public async Task SendInquiry_SelfInquiry_FailsValidation()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("My Own Product", "Description", "Textiles"));

        var (success, message, inquiry) = await _productService.SendInquiryAsync(
            senderMemberId: 1, // Same as product owner
            productId: prod!.Id,
            dto: new CreateProductInquiryDto("Subject", "Message")
        );

        Assert.False(success);
        Assert.Contains("own product", message);
        Assert.Null(inquiry);
    }

    [Fact]
    public async Task SendInquiry_InactiveOrNonExistentProduct_FailsValidation()
    {
        var (success, message, _) = await _productService.SendInquiryAsync(
            senderMemberId: 2,
            productId: 99999, // Does not exist
            dto: new CreateProductInquiryDto("Subject", "Message")
        );

        Assert.False(success);
        Assert.Contains("not found", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task GetInquiryById_SenderOrRecipientAuthorized_ReturnsInquiry()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Auth Product", "Desc", "Textiles"));
        var (_, _, inq) = await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto("Inquiry", "Message"));

        // Recipient (member 1) can access
        var recipientView = await _productService.GetInquiryByIdAsync(inq!.Id, memberId: 1);
        Assert.NotNull(recipientView);
        Assert.Equal("Read", recipientView.Status); // Automatically marked as read

        // Sender (member 2) can access
        var senderView = await _productService.GetInquiryByIdAsync(inq.Id, memberId: 2);
        Assert.NotNull(senderView);

        // Unrelated third-party member (member 99) cannot access
        var strangerView = await _productService.GetInquiryByIdAsync(inq.Id, memberId: 99);
        Assert.Null(strangerView);
    }

    [Fact]
    public async Task GetSentInquiries_ReturnsInquiriesSentByMember()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Sent Test Product", "Desc", "Textiles"));
        await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto("Sent Inquiry 1", "Msg 1"));

        var sent = await _productService.GetSentInquiriesAsync(memberId: 2);
        Assert.NotEmpty(sent);
        Assert.Contains(sent, i => i.ProductId == prod.Id && i.Subject == "Sent Inquiry 1");
    }

    [Fact]
    public async Task GetProductById_PopulatesOwnerCompanyDetailsAndIsOwnerFlag()
    {
        var (_, _, created) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Organic Fabric",
            Description: "100% pure organic cotton fabric.",
            Category: "Textiles",
            SubCategory: "Organic",
            Tags: new List<string> { "Cotton", "Eco" },
            ImageUrl: "https://images.connexa.test/fabric1.jpg,https://images.connexa.test/fabric2.jpg",
            Specifications: new Dictionary<string, string> { { "MOQ", "100 meters" }, { "GSM", "180" } }
        ));

        // Owner views their product
        var ownerView = await _productService.GetProductByIdAsync(created!.Id, viewerMemberId: 1);
        Assert.NotNull(ownerView);
        Assert.True(ownerView.IsOwner);
        Assert.Equal("Patel Textiles Ltd", ownerView.CompanyName);
        Assert.Equal("Aarav Patel", ownerView.OwnerName);
        Assert.Equal(2, ownerView.AdditionalImages?.Count);
        Assert.Equal(0, ownerView.ViewCount); // Owner views do not increment view count

        // Buyer views the product
        var buyerView = await _productService.GetProductByIdAsync(created.Id, viewerMemberId: 2);
        Assert.NotNull(buyerView);
        Assert.False(buyerView.IsOwner);
        Assert.Equal(1, buyerView.ViewCount); // Viewer incremented view count
    }

    [Fact]
    public async Task GetAllProducts_FiltersByCategoryAndSearchTerm()
    {
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("Denim Jeans", "Heavyweight blue denim", "Apparel"));
        await _productService.CreateProductAsync(2, new CreateProductRequestDto("Cotton Twill", "Lightweight cotton twill weave", "Textiles"));

        var apparelOnly = await _productService.GetAllProductsAsync(category: "Apparel");
        Assert.Single(apparelOnly);
        Assert.Equal("Denim Jeans", apparelOnly[0].Name);

        var searchResult = await _productService.GetAllProductsAsync(search: "Twill");
        Assert.Single(searchResult);
        Assert.Equal("Cotton Twill", searchResult[0].Name);
    }

    [Fact]
    public async Task RespondToInquiry_OwnerCanRespondSuccessfully()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Test Machine", "Desc", "Industrial", ImageUrl: "https://connexa.test/img.png"));
        var (_, _, inquiry) = await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto(
            Subject: "Pricing inquiry",
            Message: "What is the lead time?",
            QuantityRequirement: "500 units",
            ContactPhone: "9876543211",
            ContactEmail: "priya@connexa.test"
        ));

        // Owner (Member 1) responds
        var (success, message, responseDto) = await _productService.RespondToInquiryAsync(
            memberId: 1,
            inquiryId: inquiry!.Id,
            new RespondToInquiryDto("We have stock ready and can deliver within 3 days.")
        );

        Assert.True(success);
        Assert.Equal("Response sent successfully.", message);
        Assert.NotNull(responseDto);
        Assert.Equal("Responded", responseDto.Status);
        Assert.NotNull(responseDto.RespondedAtUtc);
        Assert.Equal("We have stock ready and can deliver within 3 days.", responseDto.ResponseMessage);
        Assert.Equal("500 units", responseDto.QuantityRequirement);
        Assert.Equal("https://connexa.test/img.png", responseDto.ProductThumbnailUrl);

        // Verify database persistence
        var dbInquiry = await _dbContext.ProductInquiries.FindAsync(inquiry.Id);
        Assert.NotNull(dbInquiry);
        Assert.Equal("Responded", dbInquiry.Status);
        Assert.Equal("We have stock ready and can deliver within 3 days.", dbInquiry.ResponseMessage);
    }

    [Fact]
    public async Task RespondToInquiry_NonOwnerForbidden()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Test Machine", "Desc", "Industrial"));
        var (_, _, inquiry) = await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto("Test", "Msg"));

        // Buyer (Member 2) tries to respond to inquiry
        var (successBuyer, messageBuyer, _) = await _productService.RespondToInquiryAsync(
            memberId: 2,
            inquiryId: inquiry!.Id,
            new RespondToInquiryDto("Buyer trying to respond")
        );
        Assert.False(successBuyer);
        Assert.Contains("not authorized", messageBuyer);

        // Stranger (Member 99) tries to respond
        var (successStranger, messageStranger, _) = await _productService.RespondToInquiryAsync(
            memberId: 99,
            inquiryId: inquiry.Id,
            new RespondToInquiryDto("Stranger trying to respond")
        );
        Assert.False(successStranger);
        Assert.Contains("not authorized", messageStranger);
    }

    [Fact]
    public async Task RespondToInquiry_ValidationAndNotFound()
    {
        // Empty response
        var (successEmpty, msgEmpty, _) = await _productService.RespondToInquiryAsync(
            memberId: 1,
            inquiryId: 9999,
            new RespondToInquiryDto("   ")
        );
        Assert.False(successEmpty);
        Assert.Contains("cannot be empty", msgEmpty);

        // Not found
        var (successNotFound, msgNotFound, _) = await _productService.RespondToInquiryAsync(
            memberId: 1,
            inquiryId: 9999,
            new RespondToInquiryDto("Valid response message")
        );
        Assert.False(successNotFound);
        Assert.Contains("not found", msgNotFound);
    }

    [Fact]
    public async Task GetReceivedInquiries_ParsesQuantityAndContactAndThumbnail()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Loom", "Loom desc", "Machinery", ImageUrl: "https://connexa.test/loom.png"));
        await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto(
            Subject: "Loom quote",
            Message: "Need 5 units of high speed loom",
            QuantityRequirement: "5 units",
            ContactPhone: "9876543211",
            ContactEmail: "priya@connexa.test"
        ));

        var received = await _productService.GetReceivedInquiriesAsync(memberId: 1);
        Assert.Single(received);
        var inq = received[0];
        Assert.Equal("5 units", inq.QuantityRequirement);
        Assert.Equal("https://connexa.test/loom.png", inq.ProductThumbnailUrl);
        Assert.Equal("Priya Sharma", inq.SenderName);
        Assert.Equal("Sharma Garments Ltd", inq.SenderCompanyName);
        Assert.Equal("Pending", inq.Status);
        Assert.Contains("Need 5 units", inq.Message);
        Assert.DoesNotContain("[Requirement / Quantity:", inq.Message);
    }

    [Fact]
    public async Task GetInquiryById_AutoMarksAsReadWhenViewedByOwner()
    {
        var (_, _, prod) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Loom 2", "Desc", "Machinery"));
        var (_, _, createdInq) = await _productService.SendInquiryAsync(2, prod!.Id, new CreateProductInquiryDto(
            Subject: "Loom quote 2",
            Message: "Inquiry message 2"
        ));

        Assert.Equal("Pending", createdInq!.Status);

        // Owner views inquiry for the first time
        var viewed = await _productService.GetInquiryByIdAsync(createdInq.Id, memberId: 1);
        Assert.NotNull(viewed);
        Assert.Equal("Read", viewed.Status);

        // Verify in DB
        var inDb = await _dbContext.ProductInquiries.FindAsync(createdInq.Id);
        Assert.Equal("Read", inDb!.Status);
    }

    [Fact]
    public async Task GetCatalogProducts_ReturnsEligibleProductsFromMultipleMembers()
    {
        // Member 1 creates Product A
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("Product A", "Patel Description", "Textiles"));
        // Member 2 creates Product B
        await _productService.CreateProductAsync(2, new CreateProductRequestDto("Product B", "Sharma Description", "Apparel"));

        var catalog = await _productService.GetCatalogProductsAsync(new ProductFilterDto(), viewerMemberId: 1);

        Assert.NotNull(catalog);
        Assert.Equal(2, catalog.TotalCount);
        Assert.Contains(catalog.Items, p => p.Name == "Product A" && p.IsOwner);
        Assert.Contains(catalog.Items, p => p.Name == "Product B" && !p.IsOwner);
        Assert.Equal("Patel Textiles Ltd", catalog.Items.First(p => p.Name == "Product A").CompanyName);
        Assert.Equal("Sharma Garments Ltd", catalog.Items.First(p => p.Name == "Product B").CompanyName);
    }

    [Fact]
    public async Task GetCatalogProducts_FiltersByIndustryCorrectly()
    {
        // Industry 1: Manufacturing (seeded in setup)
        // Add Industry 2: Chemicals
        var ind2 = new Industry { Id = 2, Name = "Chemicals & Petrochemicals", Code = "CHEM" };
        _dbContext.Industries.Add(ind2);

        // Add Member 3 under Industry 2
        var member3 = new Member
        {
            Id = 3,
            FullName = "Rahul Chemical",
            Email = "rahul@chem.test",
            PhoneNumber = "9876543212",
            PrimaryProfileType = ProfileTypeEnum.BusinessCompany,
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 3,
                MemberId = 3,
                CompanyName = "Gujarat Chemicals Ltd",
                BusinessCapabilities = "Industrial solvents",
                IndustryId = 2,
                BusinessGroupId = 1,
                SubGroupId = 1,
                CategoryId = 1
            }
        };
        _dbContext.Members.Add(member3);
        await _dbContext.SaveChangesAsync();

        // Product in Industry 1 (via Member 1's profile)
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("Textile Yarn", "Yarn desc", "Textiles"));

        // Product in Industry 2 (via Member 3's profile)
        await _productService.CreateProductAsync(3, new CreateProductRequestDto("Organic Solvent X", "Solvent desc", "Chemicals"));

        // Explicit Product with Industry 2 created by Member 1 (Cross-industry)
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("Specialty Dye", "Dye desc", "Chemicals", IndustryId: 2));

        // Filter by Industry 2 -> Should return Organic Solvent X and Specialty Dye
        var chemCatalog = await _productService.GetCatalogProductsAsync(new ProductFilterDto { IndustryId = 2 });
        Assert.Equal(2, chemCatalog.TotalCount);
        Assert.Contains(chemCatalog.Items, p => p.Name == "Organic Solvent X");
        Assert.Contains(chemCatalog.Items, p => p.Name == "Specialty Dye");

        // Filter by Industry 1 -> Should return Textile Yarn
        var mfgCatalog = await _productService.GetCatalogProductsAsync(new ProductFilterDto { IndustryId = 1 });
        Assert.Single(mfgCatalog.Items);
        Assert.Equal("Textile Yarn", mfgCatalog.Items[0].Name);
    }

    [Fact]
    public async Task GetCatalogProducts_FiltersByCategoryAndSearch()
    {
        await _productService.CreateProductAsync(1, new CreateProductRequestDto("Heavy CNC Lathe", "High precision lathe machine", "Machinery", Tags: new List<string> { "CNC", "Heavy" }));
        await _productService.CreateProductAsync(2, new CreateProductRequestDto("Cotton Twill Weave", "Fabrics for shirts", "Textiles"));

        // Category filter
        var catResult = await _productService.GetCatalogProductsAsync(new ProductFilterDto { Category = "Machinery" });
        Assert.Single(catResult.Items);
        Assert.Equal("Heavy CNC Lathe", catResult.Items[0].Name);

        // Search query matching tag
        var searchResult = await _productService.GetCatalogProductsAsync(new ProductFilterDto { Search = "CNC" });
        Assert.Single(searchResult.Items);
        Assert.Equal("Heavy CNC Lathe", searchResult.Items[0].Name);

        // Search query matching company name
        var companySearch = await _productService.GetCatalogProductsAsync(new ProductFilterDto { Search = "Sharma" });
        Assert.Single(companySearch.Items);
        Assert.Equal("Cotton Twill Weave", companySearch.Items[0].Name);
    }

    [Fact]
    public async Task GetCatalogProducts_PaginationAndSorting()
    {
        for (int i = 1; i <= 5; i++)
        {
            await _productService.CreateProductAsync(1, new CreateProductRequestDto($"Item {i:D2}", $"Description {i}", "General"));
        }

        // Page 1, PageSize 2
        var page1 = await _productService.GetCatalogProductsAsync(new ProductFilterDto { Page = 1, PageSize = 2, SortBy = "name_asc" });
        Assert.Equal(5, page1.TotalCount);
        Assert.Equal(3, page1.TotalPages);
        Assert.Equal(2, page1.Items.Count);
        Assert.Equal("Item 01", page1.Items[0].Name);
        Assert.Equal("Item 02", page1.Items[1].Name);

        // Page 2, PageSize 2
        var page2 = await _productService.GetCatalogProductsAsync(new ProductFilterDto { Page = 2, PageSize = 2, SortBy = "name_asc" });
        Assert.Equal(2, page2.Items.Count);
        Assert.Equal("Item 03", page2.Items[0].Name);
        Assert.Equal("Item 04", page2.Items[1].Name);
    }

    [Fact]
    public async Task GetCatalogProducts_HidesInactiveProductsAndMembers()
    {
        var (_, _, active) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Active Item", "Desc", "General"));
        var (_, _, inactive) = await _productService.CreateProductAsync(1, new CreateProductRequestDto("Inactive Item", "Desc", "General"));

        // Soft delete the second product
        await _productService.DeleteProductAsync(1, inactive!.Id);

        var catalog = await _productService.GetCatalogProductsAsync(new ProductFilterDto());
        Assert.Single(catalog.Items);
        Assert.Equal("Active Item", catalog.Items[0].Name);
    }

    [Fact]
    public async Task GetRelatedProducts_ExcludesCurrentProduct_AndPrioritizesSameIndustryAndCategory()
    {
        // Target product by Member 1 (Industry 1 Textiles, Category Cotton)
        var (_, _, p1) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Cotton Yarn 30s",
            Description: "Fine combed cotton yarn",
            Category: "Yarn",
            SubCategory: "Combed",
            Tags: new List<string> { "Textile", "Cotton", "Spinning" },
            IndustryId: 1
        ));

        // Candidate 1 by Member 2: Same Industry 1, Same Category Yarn, Matching Tags (Score will be highest)
        var (_, _, c1) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Cotton Combed Yarn 40s",
            Description: "High quality spinning yarn",
            Category: "Yarn",
            SubCategory: "Combed",
            Tags: new List<string> { "Cotton", "Textile" },
            IndustryId: 1
        ));

        // Candidate 2 by Member 2: Same Industry 1, Different Category Fabrics
        var (_, _, c2) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Cotton Denim Fabric",
            Description: "Heavy denim fabric",
            Category: "Fabrics",
            IndustryId: 1
        ));

        // Candidate 3: Inactive product (should be excluded)
        var (_, _, c3) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Deleted Yarn",
            Description: "Removed",
            Category: "Yarn",
            IndustryId: 1
        ));
        await _productService.DeleteProductAsync(2, c3!.Id);

        var related = await _productService.GetRelatedProductsAsync(p1!.Id, limit: 5, viewerMemberId: 1);

        // Current product p1 and inactive c3 must not be in related
        Assert.DoesNotContain(related, r => r.Id == p1.Id);
        Assert.DoesNotContain(related, r => r.Id == c3.Id);

        // Highest score c1 should appear before c2
        Assert.True(related.Count >= 2);
        Assert.Equal(c1!.Id, related[0].Id);
        Assert.Equal("Cotton Combed Yarn 40s", related[0].Name);
    }

    [Fact]
    public async Task GetRelatedProducts_PrioritizesOtherBusinesses()
    {
        // Product 1 by Member 1
        var (_, _, p1) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Industrial Sewing Machine",
            Description: "Heavy duty stitcher",
            Category: "Machinery",
            IndustryId: 1
        ));

        // Candidate A: same member 1 (own product)
        var (_, _, candOwn) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Machine Needles Pack",
            Description: "Needles for machine",
            Category: "Machinery",
            IndustryId: 1
        ));

        // Candidate B: other member 2 (different business)
        var (_, _, candOther) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Machine Thread Spool",
            Description: "Thread for machine",
            Category: "Machinery",
            IndustryId: 1
        ));

        var related = await _productService.GetRelatedProductsAsync(p1!.Id, limit: 5, viewerMemberId: 1);

        Assert.Equal(2, related.Count);
        // Candidate from other business gets +10 points so should be ranked first
        Assert.Equal(candOther!.Id, related[0].Id);
        Assert.Equal(candOwn!.Id, related[1].Id);
    }

    [Fact]
    public async Task GetRelatedProducts_ReturnsEmpty_WhenNoCandidatesExist()
    {
        var (_, _, solo) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "Solo Unique Product",
            Description: "Only item in DB",
            Category: "Rare"
        ));

        var related = await _productService.GetRelatedProductsAsync(solo!.Id, limit: 5);
        Assert.Empty(related);
    }

    [Fact]
    public async Task GetRecommendedProducts_PrioritizesMemberIndustry_AndExcludesOwnProducts()
    {
        // Member 1 has Industry 1 (Textiles)
        // Create product by Member 1 (own product)
        var (_, _, own) = await _productService.CreateProductAsync(1, new CreateProductRequestDto(
            Name: "My Own Product",
            Description: "Owned by viewer",
            Category: "Textiles",
            IndustryId: 1
        ));

        // Create product by Member 2 in Industry 1 (Textiles)
        var (_, _, recIndustry1) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Silk Weave Sample",
            Description: "Textile offering",
            Category: "Textiles",
            IndustryId: 1
        ));

        // Create product by Member 2 in Industry 99 (Other)
        var (_, _, recIndustry99) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Chemical Solvent Drum",
            Description: "Chemical offering",
            Category: "Chemicals",
            IndustryId: 99
        ));

        var filter = new ProductRecommendationFilterDto { Page = 1, PageSize = 10 };
        var recommended = await _productService.GetRecommendedProductsAsync(memberId: 1, filter);

        // Own product must be excluded
        Assert.DoesNotContain(recommended, r => r.Id == own!.Id);

        // Industry 1 item should be ranked higher than Industry 99
        Assert.NotEmpty(recommended);
        Assert.Equal(recIndustry1!.Id, recommended[0].Id);
    }

    [Fact]
    public async Task GetRecommendedProducts_RespectsExplicitIndustryOverride()
    {
        // Member 1 has default Industry 1
        var (_, _, itemInd1) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Cotton Bale",
            Description: "Textile industry item",
            Category: "Raw Material",
            IndustryId: 1
        ));

        var (_, _, itemInd2) = await _productService.CreateProductAsync(2, new CreateProductRequestDto(
            Name: "Steel Pipe 2-inch",
            Description: "Construction industry item",
            Category: "Metals",
            IndustryId: 2
        ));

        // Explicit filter for Industry 2 should prioritize Steel Pipe over Member 1's profile industry
        var filter = new ProductRecommendationFilterDto { IndustryId = 2, Page = 1, PageSize = 10 };
        var recommended = await _productService.GetRecommendedProductsAsync(memberId: 1, filter);

        Assert.NotEmpty(recommended);
        Assert.Equal(itemInd2!.Id, recommended[0].Id);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
    }
}



namespace Connexa.Api.Tests.Services;

using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.JobWork;
using Connexa.Api.Services.Notifications;

public class JobWorkServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly JobWorkService _jobWorkService;
    private readonly NotificationService _notificationService;

    public JobWorkServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaJobWorkTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);
        var testEnv = new TestWebHostEnvironment();
        _jobWorkService = new JobWorkService(_dbContext, _notificationService, testEnv, NullLogger<JobWorkService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var industry = new Industry
        {
            Id = 1,
            Name = "Precision Engineering & Manufacturing",
            Description = "CNC machining, casting, tooling"
        };
        _dbContext.Industries.Add(industry);

        var buyer = new Member
        {
            Id = 101,
            FullName = "Ramesh Patel",
            Email = "ramesh@pateleng.test",
            CountryCode = "+91",
            PhoneNumber = "9825000001",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 101,
                MemberId = 101,
                CompanyName = "Patel Precision Engineering Ltd",
                City = "Rajkot",
                State = "Gujarat",
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        var contractorA = new Member
        {
            Id = 201,
            FullName = "Kishore Shah",
            Email = "kishore@shahmat.test",
            CountryCode = "+91",
            PhoneNumber = "9825000002",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 201,
                MemberId = 201,
                CompanyName = "Shah CNC Machining Works",
                City = "Ahmedabad",
                State = "Gujarat",
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        var contractorB = new Member
        {
            Id = 202,
            FullName = "Anil Mehta",
            Email = "anil@mehtatool.test",
            CountryCode = "+91",
            PhoneNumber = "9825000003",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 202,
                MemberId = 202,
                CompanyName = "Mehta Advanced Tooling",
                City = "Vadodara",
                State = "Gujarat",
                VerificationStatus = BusinessVerificationStatus.Approved
            }
        };

        _dbContext.Members.AddRange(buyer, contractorA, contractorB);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateRequirement_ValidDto_CreatesOpenRequirementWithUniqueNumber()
    {
        var dto = new CreateJobWorkRequirementDto(
            Title: "VMC 4-Axis Machining of Aluminium Manifolds",
            Description: "Need 500 pcs Aluminium 6061-T6 manifold blocks with +/- 0.01mm tolerance",
            IndustryId: 1,
            BusinessGroupId: null,
            SubGroupId: null,
            CategoryId: null,
            JobWorkProcess: "CNC Milling",
            MachineType: "VMC 4-Axis",
            MachineCategory: "Milling",
            RequiredMachineCapacity: "800x500x500 mm",
            TechnicalSpecifications: "Hard anodized, Ra 0.8 surface finish",
            RequiredTolerance: "+/- 0.01 mm",
            MaterialType: "Aluminium 6061-T6",
            MaterialResponsibility: MaterialResponsibility.BuyerSupplied,
            Quantity: 500,
            UnitOfMeasurement: "Pieces",
            TargetBudget: 250000m,
            Location: "Rajkot, Gujarat",
            DeliveryTerms: "Ex-factory delivery within 20 days",
            TargetCompletionDateUtc: DateTime.UtcNow.AddDays(25)
        );

        var (success, message, requirement) = await _jobWorkService.CreateRequirementAsync(101, dto);

        Assert.True(success);
        Assert.NotNull(requirement);
        Assert.StartsWith("JWR-", requirement.RequirementNumber);
        Assert.Equal("Open", requirement.Status);
        Assert.Equal(500, requirement.Quantity);
        Assert.Equal("Patel Precision Engineering Ltd", requirement.OwnerCompanyName);
        Assert.True(requirement.OwnerIsVerified);
    }

    [Fact]
    public async Task SubmitQuotation_SelfQuotation_ReturnsFalseWithForbiddenMessage()
    {
        var req = await CreateTestRequirementAsync(101);

        var quoteDto = new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 450m,
            Quantity: 500,
            TaxRatePercent: 18m,
            OtherCharges: 5000m,
            LeadTimeDays: 14,
            MachineProposed: "Mazak 4-Axis VMC"
        );

        // Buyer attempting to quote on their own requirement
        var (success, message, quotation) = await _jobWorkService.SubmitQuotationAsync(101, quoteDto);

        Assert.False(success);
        Assert.Null(quotation);
        Assert.Contains("cannot submit a quotation for your own", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task SubmitQuotation_ValidContractor_CalculatesTotalsAndSetsStatusSubmitted()
    {
        var req = await CreateTestRequirementAsync(101);

        var quoteDto = new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 400m,
            Quantity: 500,
            TaxRatePercent: 18m,
            OtherCharges: 2000m,
            LeadTimeDays: 12,
            MachineProposed: "BFW 4-Axis VMC"
        );

        var (success, message, quotation) = await _jobWorkService.SubmitQuotationAsync(201, quoteDto);

        Assert.True(success);
        Assert.NotNull(quotation);
        Assert.Equal("Submitted", quotation.Status);
        Assert.Equal(200000m, quotation.Subtotal); // 400 * 500
        Assert.Equal(36000m, quotation.TaxAmount);  // 18% of 200,000
        Assert.Equal(238000m, quotation.TotalAmount); // 200,000 + 36,000 + 2,000
        Assert.Equal("Shah CNC Machining Works", quotation.ContractorCompanyName);
    }

    [Fact]
    public async Task SubmitQuotation_DuplicateActiveQuote_ReturnsFalse()
    {
        var req = await CreateTestRequirementAsync(101);

        var quoteDto = new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 400m,
            Quantity: 500,
            LeadTimeDays: 12
        );

        var first = await _jobWorkService.SubmitQuotationAsync(201, quoteDto);
        Assert.True(first.Success);

        // Second submission from same contractor while first is active
        var second = await _jobWorkService.SubmitQuotationAsync(201, quoteDto);
        Assert.False(second.Success);
        Assert.Contains("already have an active quotation", second.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task DecideQuotation_Accept_AtomicallyClosesRequirementRejectsOthersAndCreatesOrder()
    {
        var req = await CreateTestRequirementAsync(101);

        // Contractor A submits quote
        var quoteA = await _jobWorkService.SubmitQuotationAsync(201, new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 420m,
            Quantity: 500,
            TaxRatePercent: 18m,
            OtherCharges: 1000m,
            LeadTimeDays: 14
        ));
        Assert.True(quoteA.Success);

        // Contractor B submits quote
        var quoteB = await _jobWorkService.SubmitQuotationAsync(202, new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 390m,
            Quantity: 500,
            TaxRatePercent: 18m,
            OtherCharges: 1500m,
            LeadTimeDays: 10
        ));
        Assert.True(quoteB.Success);

        // Buyer decides to accept Contractor B's quote
        var decideDto = new DecideJobWorkQuotationDto(
            Decision: "accept",
            Notes: "Accepted best price and lead time."
        );

        var (success, message, decidedQuote, order) = await _jobWorkService.DecideQuotationAsync(quoteB.Quotation!.Id, 101, decideDto);

        Assert.True(success);
        Assert.NotNull(decidedQuote);
        Assert.NotNull(order);
        Assert.Equal("Accepted", decidedQuote.Status);

        // Verify order created
        Assert.StartsWith("JWO-", order.OrderNumber);
        Assert.Equal(101, order.BuyerMemberId);
        Assert.Equal(202, order.ContractorMemberId);
        Assert.Equal(req.Id, order.JobWorkRequirementId);
        Assert.Equal(quoteB.Quotation.Id, order.JobWorkQuotationId);
        Assert.Equal("Confirmed", order.Status);
        Assert.Equal(195000m, order.Subtotal); // 390 * 500

        // Verify requirement closed
        var reqDb = await _dbContext.JobWorkRequirements.FindAsync(req.Id);
        Assert.Equal(JobWorkRequirementStatus.Closed, reqDb!.Status);

        // Verify Contractor A's quote was rejected
        var quoteADb = await _dbContext.JobWorkQuotations.FindAsync(quoteA.Quotation!.Id);
        Assert.Equal(JobWorkQuotationStatus.Rejected, quoteADb!.Status);
        Assert.Contains("Alternative quotation accepted", quoteADb.RejectionReason);
    }

    [Fact]
    public async Task UpdateOrderStatus_ContractorStartsProcessingAndCompletes_LifecycleTracksCorrectly()
    {
        var req = await CreateTestRequirementAsync(101);
        var quote = await _jobWorkService.SubmitQuotationAsync(201, new SubmitJobWorkQuotationDto(
            JobWorkRequirementId: req.Id,
            OfferedUnitPrice: 400m,
            Quantity: 500
        ));

        var (_, _, _, order) = await _jobWorkService.DecideQuotationAsync(quote.Quotation!.Id, 101, new DecideJobWorkQuotationDto("accept"));
        Assert.NotNull(order);

        // Contractor starts processing
        var processResult = await _jobWorkService.UpdateOrderStatusAsync(
            order.Id,
            201, // contractor
            new UpdateJobWorkOrderStatusDto(JobWorkOrderStatus.Processing, "Material received, started VMC cycle.")
        );

        Assert.True(processResult.Success);
        Assert.Equal("Processing", processResult.Order!.Status);
        Assert.NotNull(processResult.Order.ProcessingStartedAtUtc);

        // Contractor marks completed
        var completeResult = await _jobWorkService.UpdateOrderStatusAsync(
            order.Id,
            201,
            new UpdateJobWorkOrderStatusDto(JobWorkOrderStatus.Completed, "All 500 parts machined and QC approved.")
        );

        Assert.True(completeResult.Success);
        Assert.Equal("Completed", completeResult.Order!.Status);
        Assert.NotNull(completeResult.Order.CompletedAtUtc);
        Assert.True(completeResult.Order.StatusHistory.Count >= 2);
    }

    [Fact]
    public async Task MarketplaceFiltering_FiltersByProcessAndLocation()
    {
        await CreateTestRequirementAsync(101, process: "CNC Milling", location: "Rajkot, Gujarat");
        await CreateTestRequirementAsync(101, process: "Fiber Laser Cutting", location: "Ahmedabad, Gujarat");

        var millingFilter = new JobWorkRequirementFilterDto(Process: "CNC Milling");
        var millingList = await _jobWorkService.GetMarketplaceRequirementsAsync(null, millingFilter);
        Assert.All(millingList.Items, r => Assert.Equal("CNC Milling", r.JobWorkProcess));

        var rajkotFilter = new JobWorkRequirementFilterDto(Location: "Rajkot");
        var rajkotList = await _jobWorkService.GetMarketplaceRequirementsAsync(null, rajkotFilter);
        Assert.All(rajkotList.Items, r => Assert.Contains("Rajkot", r.Location));
    }

    private async Task<JobWorkRequirementDto> CreateTestRequirementAsync(
        int ownerId,
        string process = "CNC Milling",
        string location = "Rajkot, Gujarat")
    {
        var dto = new CreateJobWorkRequirementDto(
            Title: $"Requirement for {process}",
            Description: "Detailed engineering spec for precision machining",
            IndustryId: 1,
            BusinessGroupId: null,
            SubGroupId: null,
            CategoryId: null,
            JobWorkProcess: process,
            MachineType: "VMC 4-Axis",
            MachineCategory: "Milling",
            RequiredMachineCapacity: "800x500x500 mm",
            TechnicalSpecifications: "Ra 0.8 finish",
            RequiredTolerance: "+/- 0.01 mm",
            MaterialType: "Aluminium 6061",
            MaterialResponsibility: MaterialResponsibility.BuyerSupplied,
            Quantity: 500,
            UnitOfMeasurement: "Pieces",
            TargetBudget: 200000m,
            Location: location,
            DeliveryTerms: "Ex-works",
            TargetCompletionDateUtc: DateTime.UtcNow.AddDays(30)
        );

        var (success, _, requirement) = await _jobWorkService.CreateRequirementAsync(ownerId, dto);
        Assert.True(success);
        return requirement!;
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

// Lightweight mock environment for file upload directory in tests
public class TestWebHostEnvironment : IWebHostEnvironment
{
    public string WebRootPath { get; set; } = Path.Combine(Path.GetTempPath(), "ConnexaTestWebRoot");
    public IFileProvider WebRootFileProvider { get; set; } = null!;
    public string ApplicationName { get; set; } = "Connexa.Api.Tests";
    public IFileProvider ContentRootFileProvider { get; set; } = null!;
    public string ContentRootPath { get; set; } = Path.GetTempPath();
    public string EnvironmentName { get; set; } = "Testing";
}

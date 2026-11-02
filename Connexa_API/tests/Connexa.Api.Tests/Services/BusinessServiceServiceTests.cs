namespace Connexa.Api.Tests.Services;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Connexa.Api.Services.ServicesMarketplace;

public class BusinessServiceServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly BusinessServiceService _service;
    private readonly NotificationService _notificationService;

    public BusinessServiceServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaServiceTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);
        _service = new BusinessServiceService(_dbContext, _notificationService, NullLogger<BusinessServiceService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var industry = new Industry
        {
            Id = 1,
            Name = "Industrial Automation & Engineering",
            Description = "Machinery, automation and technical services"
        };
        _dbContext.Industries.Add(industry);

        var provider = new Member
        {
            Id = 201,
            FullName = "Rajesh Automation",
            Email = "rajesh@automation.test",
            CountryCode = "+91",
            PhoneNumber = "9825100001",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 201,
                MemberId = 201,
                CompanyName = "Rajesh Automation & Robotics",
                City = "Ahmedabad",
                State = "Gujarat",
                IndustryId = 1
            }
        };

        var client = new Member
        {
            Id = 202,
            FullName = "Suresh Mills",
            Email = "suresh@mills.test",
            CountryCode = "+91",
            PhoneNumber = "9825100002",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 202,
                MemberId = 202,
                CompanyName = "Suresh Textile Mills",
                City = "Surat",
                State = "Gujarat",
                IndustryId = 1
            }
        };

        _dbContext.Members.AddRange(provider, client);
        _dbContext.SaveChanges();
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }

    [Fact]
    public async Task CreateServiceAsync_ValidPayload_CreatesSuccessfully()
    {
        var dto = new CreateServiceDto(
            Title: "PLC Programming & SCADA Integration",
            Description: "Complete automation solution for Siemens and Allen Bradley PLCs with turnkey commissioning.",
            ServiceCategory: "Automation Services",
            IndustryId: 1,
            ServiceType: "On-Site",
            PricingModel: "Project Based",
            StartingPrice: 50000m,
            PriceUnit: "/project",
            TurnaroundTime: "1-2 Weeks",
            CoverageArea: "Pan India",
            Location: "Ahmedabad, Gujarat"
        );

        var (success, service, error) = await _service.CreateServiceAsync(201, dto);

        Assert.True(success);
        Assert.Null(error);
        Assert.NotNull(service);
        Assert.Equal("PLC Programming & SCADA Integration", service.Title);
        Assert.Equal("Automation Services", service.ServiceCategory);
        Assert.Equal(201, service.MemberId);
        Assert.Equal("Rajesh Automation", service.ProviderName);
        Assert.True(service.IsActive);
        Assert.Equal(0, service.ViewCount);
    }

    [Fact]
    public async Task CreateServiceAsync_MissingTitleOrCategory_ReturnsError()
    {
        var dto = new CreateServiceDto(
            Title: "",
            Description: "Valid description",
            ServiceCategory: ""
        );

        var (success, service, error) = await _service.CreateServiceAsync(201, dto);

        Assert.False(success);
        Assert.Null(service);
        Assert.NotNull(error);
    }

    [Fact]
    public async Task UpdateServiceAsync_ByOwner_UpdatesFieldsSuccessfully()
    {
        var createDto = new CreateServiceDto(
            Title: "Industrial Machine Repair",
            Description: "On-site mechanical and hydraulic breakdown repair.",
            ServiceCategory: "Machine Repair",
            StartingPrice: 5000m,
            PriceUnit: "/visit"
        );

        var (_, created, _) = await _service.CreateServiceAsync(201, createDto);
        Assert.NotNull(created);

        var updateDto = new UpdateServiceDto(
            Title: "24/7 Industrial Machine & Hydraulic Repair",
            Description: "Round-the-clock emergency breakdown response.",
            ServiceCategory: "Machine Repair",
            StartingPrice: 7500m,
            PriceUnit: "/visit",
            TurnaroundTime: "Same Day Emergency"
        );

        var (updateSuccess, updated, updateError) = await _service.UpdateServiceAsync(201, created.Id, updateDto);

        Assert.True(updateSuccess);
        Assert.Null(updateError);
        Assert.NotNull(updated);
        Assert.Equal("24/7 Industrial Machine & Hydraulic Repair", updated.Title);
        Assert.Equal(7500m, updated.StartingPrice);
        Assert.Equal("Same Day Emergency", updated.TurnaroundTime);
        Assert.NotNull(updated.UpdatedAtUtc);
    }

    [Fact]
    public async Task UpdateServiceAsync_ByNonOwner_ReturnsError()
    {
        var createDto = new CreateServiceDto(
            Title: "CNC Calibration",
            Description: "Laser interferometer calibration.",
            ServiceCategory: "Technical Support"
        );

        var (_, created, _) = await _service.CreateServiceAsync(201, createDto);

        var updateDto = new UpdateServiceDto(
            Title: "Hacked Calibration Title",
            Description: "Malicious update attempt",
            ServiceCategory: "Technical Support"
        );

        var (success, _, error) = await _service.UpdateServiceAsync(202, created!.Id, updateDto);

        Assert.False(success);
        Assert.Equal("You are not authorized to update this service.", error);
    }

    [Fact]
    public async Task DeleteServiceAsync_ByOwner_RemovesSuccessfully()
    {
        var createDto = new CreateServiceDto(
            Title: "Fabrication Consultation",
            Description: "Structural engineering design check.",
            ServiceCategory: "Consultancy"
        );

        var (_, created, _) = await _service.CreateServiceAsync(201, createDto);

        var (delSuccess, delError) = await _service.DeleteServiceAsync(201, created!.Id);

        Assert.True(delSuccess);
        Assert.Null(delError);

        var (getSuccess, getService, _) = await _service.GetServiceByIdAsync(created.Id);
        Assert.False(getSuccess);
        Assert.Null(getService);
    }

    [Fact]
    public async Task SearchServicesAsync_FiltersByCategoryAndQuery()
    {
        await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "CNC 5-Axis VMC Milling Job Services",
            Description: "High tolerance aerospace grade components.",
            ServiceCategory: "CNC Machining",
            Location: "Ahmedabad"
        ));

        await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "Heavy Steel Fabrication Services",
            Description: "Welding, beam cutting, pressure vessels.",
            ServiceCategory: "Fabrication",
            Location: "Vadodara"
        ));

        var query = new ServiceSearchQueryDto(
            Query: "VMC Milling",
            Category: "CNC Machining"
        );

        var (results, count, pages) = await _service.SearchServicesAsync(query);

        Assert.Single(results);
        Assert.Equal(1, count);
        Assert.Equal(1, pages);
        Assert.Equal("CNC 5-Axis VMC Milling Job Services", results[0].Title);
    }

    [Fact]
    public async Task GetServiceByIdAsync_IncrementsViewCountForNonOwner()
    {
        var (_, created, _) = await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "Transformer Oil Testing",
            Description: "Dielectric breakdown and moisture test.",
            ServiceCategory: "Electrical Services"
        ));

        // Owner view: does not increment view count
        await _service.GetServiceByIdAsync(created!.Id, viewerMemberId: 201);
        var (_, s1, _) = await _service.GetServiceByIdAsync(created.Id);
        Assert.Equal(0, s1!.ViewCount);

        // Non-owner view: increments view count
        await _service.GetServiceByIdAsync(created.Id, viewerMemberId: 202);
        var (_, s2, _) = await _service.GetServiceByIdAsync(created.Id);
        Assert.Equal(1, s2!.ViewCount);
    }

    [Fact]
    public async Task CreateInquiryAsync_ValidPayload_CreatesInquiryAndDispatchesNotification()
    {
        var (_, service, _) = await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "Boiler Maintenance & Inspection",
            Description: "IBR certified boiler cleaning and hydro testing.",
            ServiceCategory: "Industrial Maintenance"
        ));

        var inquiryDto = new CreateServiceInquiryDto(
            ServiceId: service!.Id,
            Subject: "Annual Boiler Overhaul for Textile Plant",
            RequirementDescription: "Need comprehensive inspection and certificate renewal for 5 TPH boiler.",
            Location: "Surat",
            PreferredStartDate: DateTime.UtcNow.AddDays(7),
            EstimatedBudget: 85000m,
            Urgency: "Normal"
        );

        var (success, inquiry, error) = await _service.CreateInquiryAsync(202, inquiryDto);

        Assert.True(success);
        Assert.Null(error);
        Assert.NotNull(inquiry);
        Assert.StartsWith("SINQ-", inquiry.InquiryNumber);
        Assert.Equal(ServiceInquiryStatus.Pending, inquiry.Status);
        Assert.Equal("Annual Boiler Overhaul for Textile Plant", inquiry.Subject);
        Assert.Equal(202, inquiry.SenderMemberId);
        Assert.Equal(201, inquiry.RecipientMemberId);
        Assert.Single(inquiry.StatusHistory);

        // Notification should exist in database for provider
        var notifications = await _dbContext.Notifications
            .Where(n => n.RecipientMemberId == 201)
            .ToListAsync();
        Assert.NotEmpty(notifications);
        Assert.Contains(notifications, n => n.EventType == NotificationEventType.ServiceInquiryReceived);
    }

    [Fact]
    public async Task CreateInquiryAsync_OwnService_ReturnsError()
    {
        var (_, service, _) = await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "VFD Drive Repair",
            Description: "AC drive testing and IGBT replacement.",
            ServiceCategory: "Electrical Services"
        ));

        var inquiryDto = new CreateServiceInquiryDto(
            ServiceId: service!.Id,
            Subject: "Self inquiry",
            RequirementDescription: "Testing self inquiry"
        );

        var (success, inquiry, error) = await _service.CreateInquiryAsync(201, inquiryDto);

        Assert.False(success);
        Assert.Null(inquiry);
        Assert.Equal("You cannot send an inquiry for your own service.", error);
    }

    [Fact]
    public async Task RespondInquiryAsync_ByProvider_UpdatesStatusAndDispatchesNotification()
    {
        var (_, service, _) = await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "Gearbox Refurbishment",
            Description: "Planetary and bevel gearbox overhaul.",
            ServiceCategory: "Machine Repair"
        ));

        var (_, inquiry, _) = await _service.CreateInquiryAsync(202, new CreateServiceInquiryDto(
            ServiceId: service!.Id,
            Subject: "Need repair for 100 HP Extruder Gearbox",
            RequirementDescription: "Loud gear mesh noise and oil leakage."
        ));

        var respondDto = new RespondServiceInquiryDto(
            ResponseMessage: "We can deploy a technician this Thursday for an on-site vibration analysis. Estimated quote: ₹25,000.",
            AcceptInquiry: true
        );

        var (respSuccess, responded, respError) = await _service.RespondInquiryAsync(201, inquiry!.Id, respondDto);

        Assert.True(respSuccess);
        Assert.Null(respError);
        Assert.NotNull(responded);
        Assert.Equal(ServiceInquiryStatus.Responded, responded.Status);
        Assert.NotNull(responded.ResponseMessage);
        Assert.NotNull(responded.RespondedAtUtc);
        Assert.Equal(2, responded.StatusHistory.Count);

        // Client (202) should receive response notification
        var notifications = await _dbContext.Notifications
            .Where(n => n.RecipientMemberId == 202)
            .ToListAsync();
        Assert.Contains(notifications, n => n.EventType == NotificationEventType.ServiceInquiryResponded);
    }

    [Fact]
    public async Task UpdateInquiryStatusAsync_ParticipantUpdatesStatus_PersistsHistory()
    {
        var (_, service, _) = await _service.CreateServiceAsync(201, new CreateServiceDto(
            Title: "Cleanroom HVAC Validation",
            Description: "HEPA filter integrity and particle count test.",
            ServiceCategory: "Technical Support"
        ));

        var (_, inquiry, _) = await _service.CreateInquiryAsync(202, new CreateServiceInquiryDto(
            ServiceId: service!.Id,
            Subject: "HVAC DQ/IQ/OQ Validation",
            RequirementDescription: "ISO Class 7 cleanroom testing."
        ));

        var statusDto = new UpdateServiceInquiryStatusDto(
            Status: ServiceInquiryStatus.Accepted,
            Remarks: "Client confirmed site entry gate pass and work permit."
        );

        var (statusSuccess, updated, statusError) = await _service.UpdateInquiryStatusAsync(202, inquiry!.Id, statusDto);

        Assert.True(statusSuccess);
        Assert.Null(statusError);
        Assert.NotNull(updated);
        Assert.Equal(ServiceInquiryStatus.Accepted, updated.Status);
        Assert.Equal(2, updated.StatusHistory.Count);
        Assert.Equal("Client confirmed site entry gate pass and work permit.", updated.StatusHistory.Last().Remarks);
    }
}


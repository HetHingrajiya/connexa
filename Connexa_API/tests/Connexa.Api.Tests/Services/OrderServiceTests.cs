using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;
using Connexa.Api.Services.Orders;

namespace Connexa.Api.Tests.Services;

public class OrderServiceTests : IDisposable
{
    private readonly ConnexaDbContext _dbContext;
    private readonly OrderService _orderService;
    private readonly NotificationService _notificationService;

    public OrderServiceTests()
    {
        var dbOptions = new DbContextOptionsBuilder<ConnexaDbContext>()
            .UseInMemoryDatabase(databaseName: $"ConnexaOrderTestDb_{Guid.NewGuid()}")
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _dbContext = new ConnexaDbContext(dbOptions);
        _notificationService = new NotificationService(_dbContext, NullLogger<NotificationService>.Instance);
        _orderService = new OrderService(_dbContext, _notificationService, NullLogger<OrderService>.Instance);

        SeedData();
    }

    private void SeedData()
    {
        var buyer = new Member
        {
            Id = 10,
            FullName = "Buyer John",
            Email = "buyer@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876500001",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 10,
                MemberId = 10,
                CompanyName = "Buyer Corp"
            }
        };

        var supplier = new Member
        {
            Id = 20,
            FullName = "Supplier Sarah",
            Email = "supplier@connexa.test",
            CountryCode = "+91",
            PhoneNumber = "9876500002",
            Role = "Member",
            IsActive = true,
            BusinessProfile = new BusinessProfile
            {
                Id = 20,
                MemberId = 20,
                CompanyName = "Supplier Ltd"
            }
        };

        var product = new Product
        {
            Id = 100,
            MemberId = 20,
            Name = "Industrial Grade Steel Bolts",
            Description = "High tensile bolts",
            Category = "Fasteners",
            IsActive = true
        };

        var rfq = new Rfq
        {
            Id = 200,
            RfqNumber = "RFQ-20261101-0001",
            BuyerMemberId = 10,
            SupplierMemberId = 20,
            ProductId = 100,
            Title = "Need 100 Steel Bolts",
            Quantity = 100,
            UnitOfMeasurement = "Piece",
            DeliveryLocation = "Mumbai Port Hub",
            Status = RfqStatus.Open,
            CreatedAtUtc = DateTime.UtcNow
        };

        var acceptedQuotation = new Quotation
        {
            Id = 300,
            QuotationNumber = "QTN-20261101-0001",
            RfqId = 200,
            SupplierMemberId = 20,
            BuyerMemberId = 10,
            UnitPrice = 45.0m,
            Quantity = 100,
            Subtotal = 4500.0m,
            TaxRatePercent = 18.0m,
            TaxAmount = 810.0m,
            ShippingCharges = 200.0m,
            TotalAmount = 5510.0m,
            Status = QuotationStatus.Accepted,
            TermsAndConditions = "Net 30 Days",
            EstimatedDeliveryTime = "7 days",
            CreatedAtUtc = DateTime.UtcNow,
            ValidUntilUtc = DateTime.UtcNow.AddDays(14)
        };

        var pendingQuotation = new Quotation
        {
            Id = 301,
            QuotationNumber = "QTN-20261101-0002",
            RfqId = 200,
            SupplierMemberId = 20,
            BuyerMemberId = 10,
            UnitPrice = 45.0m,
            Quantity = 100,
            Subtotal = 4500.0m,
            TaxRatePercent = 18.0m,
            TaxAmount = 810.0m,
            ShippingCharges = 200.0m,
            TotalAmount = 5510.0m,
            Status = QuotationStatus.Submitted, // Not accepted!
            TermsAndConditions = "Net 30 Days",
            EstimatedDeliveryTime = "7 days",
            CreatedAtUtc = DateTime.UtcNow,
            ValidUntilUtc = DateTime.UtcNow.AddDays(14)
        };

        _dbContext.Members.AddRange(buyer, supplier);
        _dbContext.Products.Add(product);
        _dbContext.Rfqs.Add(rfq);
        _dbContext.Quotations.AddRange(acceptedQuotation, pendingQuotation);
        _dbContext.SaveChanges();
    }

    [Fact]
    public async Task CreateOrderAsync_ValidAcceptedQuotation_CreatesOrderAndStatusHistory()
    {
        var dto = new CreateOrderDto(
            QuotationId: 300,
            DeliveryAddress: "45 Industrial Park, Mumbai 400001",
            ExpectedDeliveryDateUtc: DateTime.UtcNow.AddDays(10),
            Notes: "Please pack in waterproof crates."
        );

        var (success, message, order) = await _orderService.CreateOrderAsync(10, dto);

        Assert.True(success, message);
        Assert.NotNull(order);
        Assert.StartsWith("ORD-", order.OrderNumber);
        Assert.Equal(10, order.BuyerMemberId);
        Assert.Equal(20, order.SupplierMemberId);
        Assert.Equal(300, order.QuotationId);
        Assert.Equal(45.0m, order.UnitPrice);
        Assert.Equal(100m, order.Quantity);
        Assert.Equal(4500.0m, order.Subtotal);
        Assert.Equal(810.0m, order.TaxAmount);
        Assert.Equal(200.0m, order.ShippingCharges);
        Assert.Equal(5510.0m, order.TotalAmount);
        Assert.Equal("PendingConfirmation", order.Status);
        Assert.Single(order.StatusHistory);
        Assert.Equal("PendingConfirmation", order.StatusHistory[0].NewStatus);

        // Verify notification was recorded in DB
        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 20 && n.EventType == NotificationEventType.OrderCreated);
        Assert.NotNull(notif);
        Assert.Equal(order.Id, notif.ReferenceId);
    }

    [Fact]
    public async Task CreateOrderAsync_NonBuyer_ReturnsForbiddenMessage()
    {
        var dto = new CreateOrderDto(
            QuotationId: 300,
            DeliveryAddress: "Somewhere"
        );

        var (success, message, order) = await _orderService.CreateOrderAsync(999, dto);

        Assert.False(success);
        Assert.Contains("only the buyer", message, StringComparison.OrdinalIgnoreCase);
        Assert.Null(order);
    }

    [Fact]
    public async Task CreateOrderAsync_UnacceptedQuotation_Fails()
    {
        var dto = new CreateOrderDto(
            QuotationId: 301, // Submitted, not Accepted
            DeliveryAddress: "Somewhere"
        );

        var (success, message, order) = await _orderService.CreateOrderAsync(10, dto);

        Assert.False(success);
        Assert.Contains("accepted", message, StringComparison.OrdinalIgnoreCase);
        Assert.Null(order);
    }

    [Fact]
    public async Task CreateOrderAsync_DuplicateQuotation_Fails()
    {
        var dto = new CreateOrderDto(
            QuotationId: 300,
            DeliveryAddress: "First Address"
        );

        var (success1, _, _) = await _orderService.CreateOrderAsync(10, dto);
        Assert.True(success1);

        // Attempting to create order again for same quotation
        var (success2, message2, _) = await _orderService.CreateOrderAsync(10, dto);
        Assert.False(success2);
        Assert.Contains("already been created", message2, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ConfirmOrderAsync_Supplier_TransitionsToConfirmed()
    {
        var createDto = new CreateOrderDto(
            QuotationId: 300,
            DeliveryAddress: "Warehouse 2"
        );
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);

        var confirmDto = new ConfirmOrderDto(Remarks: "Order confirmed. Raw materials allocated.");
        var (success, message, updatedOrder) = await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, confirmDto);

        Assert.True(success, message);
        Assert.Equal("Confirmed", updatedOrder!.Status);
        Assert.NotNull(updatedOrder.ConfirmedAtUtc);
        Assert.Equal(2, updatedOrder.StatusHistory.Count);

        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 10 && n.EventType == NotificationEventType.OrderConfirmed);
        Assert.NotNull(notif);
    }

    [Fact]
    public async Task ConfirmOrderAsync_NonSupplier_Fails()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);

        var confirmDto = new ConfirmOrderDto(Remarks: "Invalid confirmation");
        var (success, message, _) = await _orderService.ConfirmOrderAsync(createdOrder!.Id, 10, confirmDto); // Buyer trying to confirm

        Assert.False(success);
        Assert.Contains("Only the designated supplier", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task RejectOrderAsync_Supplier_TransitionsToRejected()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);

        var rejectDto = new RejectOrderDto(Reason: "Capacity exceeded for this month.");
        var (success, message, updatedOrder) = await _orderService.RejectOrderAsync(createdOrder!.Id, 20, rejectDto);

        Assert.True(success, message);
        Assert.Equal("Rejected", updatedOrder!.Status);
        Assert.Equal("Capacity exceeded for this month.", updatedOrder.RejectionReason);

        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 10 && n.EventType == NotificationEventType.OrderRejected);
        Assert.NotNull(notif);
    }

    [Fact]
    public async Task ProcessOrderAsync_Supplier_TransitionsToProcessing()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());

        var processDto = new ProcessOrderDto(Remarks: "Manufacturing in progress.");
        var (success, message, updatedOrder) = await _orderService.ProcessOrderAsync(createdOrder.Id, 20, processDto);

        Assert.True(success, message);
        Assert.Equal("Processing", updatedOrder!.Status);
    }

    [Fact]
    public async Task ShipOrderAsync_SupplierWithTracking_TransitionsToShipped()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());
        await _orderService.ProcessOrderAsync(createdOrder.Id, 20, new ProcessOrderDto());

        var shipDto = new ShipOrderDto(
            CarrierName: "BlueDart Express",
            TrackingNumber: "BD-9823471029",
            TrackingUrl: "https://track.bluedart.com/BD-9823471029"
        );
        var (success, message, updatedOrder) = await _orderService.ShipOrderAsync(createdOrder.Id, 20, shipDto);

        Assert.True(success, message);
        Assert.Equal("Shipped", updatedOrder!.Status);
        Assert.Equal("BlueDart Express", updatedOrder.CarrierName);
        Assert.Equal("BD-9823471029", updatedOrder.TrackingNumber);
        Assert.NotNull(updatedOrder.ShippedAtUtc);

        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 10 && n.EventType == NotificationEventType.OrderShipped);
        Assert.NotNull(notif);
    }

    [Fact]
    public async Task ShipOrderAsync_MissingCarrierOrTracking_Fails()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());

        var shipDto = new ShipOrderDto(
            CarrierName: "", // Missing
            TrackingNumber: ""
        );
        var (success, message, _) = await _orderService.ShipOrderAsync(createdOrder.Id, 20, shipDto);

        Assert.False(success);
        Assert.Contains("Carrier name is required", message);
    }

    [Fact]
    public async Task DeliverOrderAsync_TransitionsToDelivered()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());
        await _orderService.ShipOrderAsync(createdOrder.Id, 20, new ShipOrderDto(
            CarrierName: "FedEx",
            TrackingNumber: "FX-12345"
        ));

        var deliverDto = new DeliverOrderDto(Remarks: "Received and verified in warehouse.");
        var (success, message, updatedOrder) = await _orderService.DeliverOrderAsync(createdOrder.Id, 10, deliverDto);

        Assert.True(success, message);
        Assert.Equal("Delivered", updatedOrder!.Status);
        Assert.NotNull(updatedOrder.DeliveredAtUtc);

        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 20 && n.EventType == NotificationEventType.OrderDelivered);
        Assert.NotNull(notif);
    }

    [Fact]
    public async Task DeliverOrderAsync_FromConfirmed_DirectDelivery_TransitionsToDelivered()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Direct Handover Site");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());

        // Client receives order directly from Confirmed status
        var deliverDto = new DeliverOrderDto(Remarks: "Client received items directly at warehouse.");
        var (success, message, updatedOrder) = await _orderService.DeliverOrderAsync(createdOrder.Id, 10, deliverDto);

        Assert.True(success, message);
        Assert.Equal("Delivered", updatedOrder!.Status);
        Assert.NotNull(updatedOrder.DeliveredAtUtc);
    }

    [Fact]
    public async Task DeliverOrderAsync_UnauthorizedMember_Fails()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Direct Handover Site");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());

        // Stranger (member 999) tries to complete
        var deliverDto = new DeliverOrderDto(Remarks: "Attempting unauthorized delivery completion");
        var (success, message, _) = await _orderService.DeliverOrderAsync(createdOrder.Id, 999, deliverDto);

        Assert.False(success);
        Assert.Contains("not authorized", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CancelOrderAsync_BeforeShipped_TransitionsToCancelled()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);

        var cancelDto = new CancelOrderDto(Reason: "Project scope changed.");
        var (success, message, updatedOrder) = await _orderService.CancelOrderAsync(createdOrder!.Id, 10, cancelDto);

        Assert.True(success, message);
        Assert.Equal("Cancelled", updatedOrder!.Status);
        Assert.Equal("Project scope changed.", updatedOrder.CancellationReason);
        Assert.NotNull(updatedOrder.CancelledAtUtc);

        var notif = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.RecipientMemberId == 20 && n.EventType == NotificationEventType.OrderCancelled);
        Assert.NotNull(notif);
    }

    [Fact]
    public async Task CancelOrderAsync_AfterShipped_Fails()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        var (_, _, createdOrder) = await _orderService.CreateOrderAsync(10, createDto);
        await _orderService.ConfirmOrderAsync(createdOrder!.Id, 20, new ConfirmOrderDto());
        await _orderService.ShipOrderAsync(createdOrder.Id, 20, new ShipOrderDto(CarrierName: "FedEx", TrackingNumber: "FX-123"));

        var cancelDto = new CancelOrderDto(Reason: "Cannot cancel once in transit.");
        var (success, message, _) = await _orderService.CancelOrderAsync(createdOrder.Id, 10, cancelDto);

        Assert.False(success);
        Assert.Contains("Cannot cancel", message);
    }

    [Fact]
    public async Task GetMyOrdersAsync_And_GetReceivedOrdersAsync_ReturnsCorrectLists()
    {
        var createDto = new CreateOrderDto(QuotationId: 300, DeliveryAddress: "Warehouse 2");
        await _orderService.CreateOrderAsync(10, createDto);

        var myOrders = await _orderService.GetMyOrdersAsync(10, new OrderFilterDto());
        Assert.Equal(1, myOrders.TotalCount);
        Assert.Single(myOrders.Items);
        Assert.Equal("Buyer Corp", myOrders.Items[0].BuyerCompanyName);

        var receivedOrders = await _orderService.GetReceivedOrdersAsync(20, new OrderFilterDto());
        Assert.Equal(1, receivedOrders.TotalCount);
        Assert.Single(receivedOrders.Items);
        Assert.Equal("Supplier Ltd", receivedOrders.Items[0].SupplierCompanyName);
    }

    public void Dispose()
    {
        _dbContext.Database.EnsureDeleted();
        _dbContext.Dispose();
    }
}

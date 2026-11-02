using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Connexa.Api.Data;
using Connexa.Api.DTOs;
using Connexa.Api.Entities;
using Connexa.Api.Services.Notifications;

namespace Connexa.Api.Services.Orders;

public class OrderService : IOrderService
{
    private readonly ConnexaDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        ConnexaDbContext db,
        INotificationService notificationService,
        ILogger<OrderService> logger)
    {
        _db = db;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> CreateOrderAsync(
        int buyerMemberId,
        CreateOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.QuotationId <= 0)
        {
            return (false, "Valid Quotation ID is required.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.DeliveryAddress))
        {
            return (false, "Delivery address is required to place an order.", null);
        }

        var quotation = await _db.Quotations
            .Include(q => q.Rfq)
            .Include(q => q.Rfq.Product)
            .Include(q => q.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(q => q.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(q => q.Id == dto.QuotationId, cancellationToken);

        if (quotation == null)
        {
            return (false, "Quotation not found.", null);
        }

        if (quotation.BuyerMemberId != buyerMemberId)
        {
            return (false, "Only the buyer associated with this quotation can create an order.", null);
        }

        if (quotation.Status != QuotationStatus.Accepted)
        {
            return (false, "Only an accepted quotation can be converted into an order.", null);
        }

        // Prevent duplicate order creation
        bool orderExists = await _db.Orders.AnyAsync(o => o.QuotationId == dto.QuotationId, cancellationToken);
        if (orderExists)
        {
            return (false, "An order has already been created for this accepted quotation.", null);
        }

        // Server-side financial calculations from authoritative quotation data
        decimal unitPrice = quotation.UnitPrice;
        decimal quantity = quotation.Quantity;
        decimal subtotal = Math.Round(unitPrice * quantity, 2);
        decimal taxAmount = Math.Round((subtotal * quotation.TaxRatePercent) / 100m, 2);
        decimal shipping = Math.Round(Math.Max(0m, quotation.ShippingCharges), 2);
        decimal total = Math.Round(subtotal + taxAmount + shipping, 2);

        string orderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6]}".ToUpperInvariant();

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var order = new Order
                {
                    OrderNumber = orderNumber,
                    QuotationId = quotation.Id,
                    RfqId = quotation.RfqId,
                    ProductId = quotation.Rfq.ProductId,
                    BuyerMemberId = quotation.BuyerMemberId,
                    SupplierMemberId = quotation.SupplierMemberId,
                    ProductName = quotation.Rfq.Product.Name,
                    Quantity = quantity,
                    UnitOfMeasurement = quotation.Rfq.UnitOfMeasurement,
                    UnitPrice = unitPrice,
                    Subtotal = subtotal,
                    TaxRatePercent = quotation.TaxRatePercent,
                    TaxAmount = taxAmount,
                    ShippingCharges = shipping,
                    TotalAmount = total,
                    TermsAndConditionsSnapshot = quotation.TermsAndConditions,
                    DeliveryAddress = dto.DeliveryAddress.Trim(),
                    ExpectedDeliveryDateUtc = dto.ExpectedDeliveryDateUtc ?? quotation.Rfq.RequiredDeliveryDateUtc,
                    Status = OrderStatus.PendingConfirmation,
                    Notes = dto.Notes?.Trim(),
                    CreatedAtUtc = DateTime.UtcNow
                };

                _db.Orders.Add(order);
                await _db.SaveChangesAsync(cancellationToken);

                var initialHistory = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = null,
                    NewStatus = OrderStatus.PendingConfirmation,
                    ChangedByMemberId = buyerMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = "Order created from Accepted Quotation."
                };

                _db.OrderStatusHistories.Add(initialHistory);
                await _db.SaveChangesAsync(cancellationToken);

                await transaction.CommitAsync(cancellationToken);

                // Notify Supplier
                string buyerCompanyName = quotation.BuyerMember.BusinessProfile?.CompanyName ?? quotation.BuyerMember.FullName;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: order.SupplierMemberId,
                        actorMemberId: buyerMemberId,
                        eventType: NotificationEventType.OrderCreated,
                        title: $"New Order #{order.OrderNumber}",
                        message: $"{buyerCompanyName} placed order #{order.OrderNumber} for {order.ProductName} (Total: ₹{order.TotalAmount:N2})",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderCreated notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, quotation.QuotationNumber, quotation.Rfq.RfqNumber, quotation.Rfq.Product.ImageUrl,
                    quotation.BuyerMember, quotation.SupplierMember, new List<OrderStatusHistory> { initialHistory }, isBuyer: true, isSupplier: false);

                return (true, "Order created successfully. Awaiting supplier confirmation.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to create order for Quotation ID {QuotationId}", dto.QuotationId);
                return (false, "An error occurred while creating the order. Please try again.", null);
            }
        });
    }

    public async Task<OrderListResponseDto> GetMyOrdersAsync(
        int buyerMemberId,
        OrderFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Orders
            .AsNoTracking()
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
                .ThenInclude(h => h.ChangedByMember)
                    .ThenInclude(m => m.BusinessProfile)
            .Where(o => o.BuyerMemberId == buyerMemberId);

        return await ApplyFiltersAndPaginateAsync(query, filter, buyerMemberId, isBuyerList: true, cancellationToken);
    }

    public async Task<OrderListResponseDto> GetReceivedOrdersAsync(
        int supplierMemberId,
        OrderFilterDto filter,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Orders
            .AsNoTracking()
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
                .ThenInclude(h => h.ChangedByMember)
                    .ThenInclude(m => m.BusinessProfile)
            .Where(o => o.SupplierMemberId == supplierMemberId);

        return await ApplyFiltersAndPaginateAsync(query, filter, supplierMemberId, isBuyerList: false, cancellationToken);
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> GetOrderByIdAsync(
        int orderId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
                .ThenInclude(h => h.ChangedByMember)
                    .ThenInclude(m => m.BusinessProfile)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        bool isBuyer = order.BuyerMemberId == currentMemberId;
        bool isSupplier = order.SupplierMemberId == currentMemberId;

        if (!isBuyer && !isSupplier && !isAdmin)
        {
            return (false, "You are not authorized to view this order.", null);
        }

        var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
            order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer, isSupplier);

        return (true, "Order retrieved successfully.", orderDto);
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> ConfirmOrderAsync(
        int orderId,
        int supplierMemberId,
        ConfirmOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        if (order.SupplierMemberId != supplierMemberId)
        {
            return (false, "Only the designated supplier can confirm this order.", null);
        }

        if (order.Status != OrderStatus.PendingConfirmation)
        {
            return (false, $"Cannot confirm order from status '{order.Status}'. Order must be 'PendingConfirmation'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Confirmed;
                order.ConfirmedAtUtc = DateTime.UtcNow;
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Confirmed,
                    ChangedByMemberId = supplierMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? "Order confirmed by supplier."
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                string supplierCompanyName = order.SupplierMember.BusinessProfile?.CompanyName ?? order.SupplierMember.FullName;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: order.BuyerMemberId,
                        actorMemberId: supplierMemberId,
                        eventType: NotificationEventType.OrderConfirmed,
                        title: $"Order Confirmed #{order.OrderNumber}",
                        message: $"{supplierCompanyName} confirmed your order #{order.OrderNumber}.",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderConfirmed notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer: false, isSupplier: true);

                return (true, "Order confirmed successfully.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to confirm Order ID {OrderId}", orderId);
                return (false, "Failed to confirm order.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> RejectOrderAsync(
        int orderId,
        int supplierMemberId,
        RejectOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reason))
        {
            return (false, "Rejection reason is required.", null);
        }

        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        if (order.SupplierMemberId != supplierMemberId)
        {
            return (false, "Only the designated supplier can reject this order.", null);
        }

        if (order.Status != OrderStatus.PendingConfirmation)
        {
            return (false, $"Cannot reject order with status '{order.Status}'. Order must be 'PendingConfirmation'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Rejected;
                order.RejectionReason = dto.Reason.Trim();
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Rejected,
                    ChangedByMemberId = supplierMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? dto.Reason.Trim()
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                string supplierCompanyName = order.SupplierMember.BusinessProfile?.CompanyName ?? order.SupplierMember.FullName;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: order.BuyerMemberId,
                        actorMemberId: supplierMemberId,
                        eventType: NotificationEventType.OrderRejected,
                        title: $"Order Rejected #{order.OrderNumber}",
                        message: $"{supplierCompanyName} declined order #{order.OrderNumber}. Reason: {dto.Reason}",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderRejected notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer: false, isSupplier: true);

                return (true, "Order rejected.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to reject Order ID {OrderId}", orderId);
                return (false, "Failed to reject order.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> ProcessOrderAsync(
        int orderId,
        int supplierMemberId,
        ProcessOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        if (order.SupplierMemberId != supplierMemberId)
        {
            return (false, "Only the designated supplier can update this order to processing.", null);
        }

        if (order.Status != OrderStatus.Confirmed)
        {
            return (false, $"Cannot move order to processing from status '{order.Status}'. Order must be 'Confirmed'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Processing;
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Processing,
                    ChangedByMemberId = supplierMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? "Order production/processing started."
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                string supplierCompanyName = order.SupplierMember.BusinessProfile?.CompanyName ?? order.SupplierMember.FullName;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: order.BuyerMemberId,
                        actorMemberId: supplierMemberId,
                        eventType: NotificationEventType.OrderProcessing,
                        title: $"Order In Processing #{order.OrderNumber}",
                        message: $"Order #{order.OrderNumber} is now being processed by {supplierCompanyName}.",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderProcessing notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer: false, isSupplier: true);

                return (true, "Order moved to processing.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to process Order ID {OrderId}", orderId);
                return (false, "Failed to update order to processing.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> ShipOrderAsync(
        int orderId,
        int supplierMemberId,
        ShipOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.CarrierName))
        {
            return (false, "Logistics/Carrier name is required.", null);
        }

        if (string.IsNullOrWhiteSpace(dto.TrackingNumber))
        {
            return (false, "Tracking reference / LR number is required.", null);
        }

        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        if (order.SupplierMemberId != supplierMemberId)
        {
            return (false, "Only the designated supplier can mark this order as shipped.", null);
        }

        if (order.Status != OrderStatus.Processing && order.Status != OrderStatus.Confirmed)
        {
            return (false, $"Cannot mark order shipped from status '{order.Status}'. Order must be 'Processing' or 'Confirmed'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Shipped;
                order.CarrierName = dto.CarrierName.Trim();
                order.TrackingNumber = dto.TrackingNumber.Trim();
                order.TrackingUrl = dto.TrackingUrl?.Trim();
                order.ShippedAtUtc = DateTime.UtcNow;
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Shipped,
                    ChangedByMemberId = supplierMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? $"Dispatched via {dto.CarrierName.Trim()} (Ref: {dto.TrackingNumber.Trim()})"
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                string supplierCompanyName = order.SupplierMember.BusinessProfile?.CompanyName ?? order.SupplierMember.FullName;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: order.BuyerMemberId,
                        actorMemberId: supplierMemberId,
                        eventType: NotificationEventType.OrderShipped,
                        title: $"Order Shipped #{order.OrderNumber}",
                        message: $"Order #{order.OrderNumber} has shipped via {dto.CarrierName}. Tracking: {dto.TrackingNumber}",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderShipped notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer: false, isSupplier: true);

                return (true, "Order marked as shipped.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to ship Order ID {OrderId}", orderId);
                return (false, "Failed to mark order as shipped.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> DeliverOrderAsync(
        int orderId,
        int currentMemberId,
        DeliverOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        bool isBuyer = order.BuyerMemberId == currentMemberId;
        bool isSupplier = order.SupplierMemberId == currentMemberId;

        if (!isBuyer && !isSupplier)
        {
            return (false, "You are not authorized to mark this order as completed.", null);
        }

        if (order.Status == OrderStatus.Delivered)
        {
            return (false, "Order is already marked as Delivered/Completed.", null);
        }

        if (order.Status == OrderStatus.Cancelled || order.Status == OrderStatus.Rejected)
        {
            return (false, $"Cannot complete order with status '{order.Status}'.", null);
        }

        if (order.Status != OrderStatus.Confirmed &&
            order.Status != OrderStatus.Processing &&
            order.Status != OrderStatus.Shipped)
        {
            return (false, $"Cannot mark order delivered/completed from status '{order.Status}'. Order must be 'Confirmed', 'Processing', or 'Shipped'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Delivered;
                order.DeliveredAtUtc = DateTime.UtcNow;
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Delivered,
                    ChangedByMemberId = currentMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? (isBuyer ? "Order received and confirmed completed by client." : "Marked completed/delivered by seller.")
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                int targetRecipientId = isBuyer ? order.SupplierMemberId : order.BuyerMemberId;
                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: targetRecipientId,
                        actorMemberId: currentMemberId,
                        eventType: NotificationEventType.OrderDelivered,
                        title: $"Order Completed #{order.OrderNumber}",
                        message: $"Order #{order.OrderNumber} for {order.ProductName} has been completed.",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderDelivered notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer, isSupplier);

                return (true, "Order completed successfully.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to deliver Order ID {OrderId}", orderId);
                return (false, "Failed to mark order delivered.", null);
            }
        });
    }

    public async Task<(bool Success, string Message, OrderDto? Order)> CancelOrderAsync(
        int orderId,
        int currentMemberId,
        CancelOrderDto dto,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Reason))
        {
            return (false, "Cancellation reason is required.", null);
        }

        var order = await _db.Orders
            .Include(o => o.Quotation)
            .Include(o => o.Rfq)
            .Include(o => o.Product)
            .Include(o => o.BuyerMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.SupplierMember)
                .ThenInclude(m => m.BusinessProfile)
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return (false, "Order not found.", null);
        }

        bool isBuyer = order.BuyerMemberId == currentMemberId;
        bool isSupplier = order.SupplierMemberId == currentMemberId;

        if (!isBuyer && !isSupplier)
        {
            return (false, "You are not authorized to cancel this order.", null);
        }

        if (order.Status == OrderStatus.Shipped || order.Status == OrderStatus.Delivered)
        {
            return (false, "Cannot cancel an order that has already shipped or been delivered.", null);
        }

        if (order.Status == OrderStatus.Cancelled || order.Status == OrderStatus.Rejected)
        {
            return (false, $"Order is already in a terminal status '{order.Status}'.", null);
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync<(bool Success, string Message, OrderDto? Order)>(async () =>
        {
            using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var previous = order.Status;
                order.Status = OrderStatus.Cancelled;
                order.CancellationReason = dto.Reason.Trim();
                order.CancelledAtUtc = DateTime.UtcNow;
                order.UpdatedAtUtc = DateTime.UtcNow;

                var history = new OrderStatusHistory
                {
                    OrderId = order.Id,
                    PreviousStatus = previous,
                    NewStatus = OrderStatus.Cancelled,
                    ChangedByMemberId = currentMemberId,
                    ChangedAtUtc = DateTime.UtcNow,
                    Remarks = dto.Remarks?.Trim() ?? dto.Reason.Trim()
                };

                _db.OrderStatusHistories.Add(history);
                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                int targetRecipientId = isBuyer ? order.SupplierMemberId : order.BuyerMemberId;
                string actorName = isBuyer
                    ? (order.BuyerMember.BusinessProfile?.CompanyName ?? order.BuyerMember.FullName)
                    : (order.SupplierMember.BusinessProfile?.CompanyName ?? order.SupplierMember.FullName);

                try
                {
                    await _notificationService.CreateNotificationAsync(
                        recipientMemberId: targetRecipientId,
                        actorMemberId: currentMemberId,
                        eventType: NotificationEventType.OrderCancelled,
                        title: $"Order Cancelled #{order.OrderNumber}",
                        message: $"{actorName} cancelled order #{order.OrderNumber}. Reason: {dto.Reason}",
                        referenceType: "order",
                        referenceId: order.Id,
                        cancellationToken: cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to dispatch OrderCancelled notification for Order {OrderNumber}", order.OrderNumber);
                }

                var orderDto = MapToOrderDto(order, order.Quotation.QuotationNumber, order.Rfq.RfqNumber, order.Product.ImageUrl,
                    order.BuyerMember, order.SupplierMember, order.StatusHistory.ToList(), isBuyer, isSupplier);

                return (true, "Order cancelled successfully.", orderDto);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(cancellationToken);
                _logger.LogError(ex, "Failed to cancel Order ID {OrderId}", orderId);
                return (false, "Failed to cancel order.", null);
            }
        });
    }

    private async Task<OrderListResponseDto> ApplyFiltersAndPaginateAsync(
        IQueryable<Order> query,
        OrderFilterDto filter,
        int currentMemberId,
        bool isBuyerList,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(filter.Status) && filter.Status.Trim().ToLowerInvariant() != "all")
        {
            if (Enum.TryParse<OrderStatus>(filter.Status.Trim(), true, out var parsedStatus))
            {
                query = query.Where(o => o.Status == parsedStatus);
            }
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            string s = filter.Search.Trim().ToLower();
            query = query.Where(o =>
                o.OrderNumber.ToLower().Contains(s) ||
                o.ProductName.ToLower().Contains(s) ||
                o.Quotation.QuotationNumber.ToLower().Contains(s) ||
                o.Rfq.RfqNumber.ToLower().Contains(s) ||
                (o.CarrierName != null && o.CarrierName.ToLower().Contains(s)) ||
                (o.TrackingNumber != null && o.TrackingNumber.ToLower().Contains(s)) ||
                (o.BuyerMember.BusinessProfile != null && o.BuyerMember.BusinessProfile.CompanyName.ToLower().Contains(s)) ||
                (o.SupplierMember.BusinessProfile != null && o.SupplierMember.BusinessProfile.CompanyName.ToLower().Contains(s)));
        }

        int totalCount = await query.CountAsync(cancellationToken);
        int page = filter.Page < 1 ? 1 : filter.Page;
        int pageSize = filter.PageSize < 1 ? 10 : (filter.PageSize > 50 ? 50 : filter.PageSize);
        int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        var orders = await query
            .OrderByDescending(o => o.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var items = orders.Select(o => MapToOrderDto(
            o,
            o.Quotation.QuotationNumber,
            o.Rfq.RfqNumber,
            o.Product.ImageUrl,
            o.BuyerMember,
            o.SupplierMember,
            o.StatusHistory.OrderBy(h => h.ChangedAtUtc).ToList(),
            isBuyer: isBuyerList,
            isSupplier: !isBuyerList
        )).ToList();

        return new OrderListResponseDto(items, totalCount, page, pageSize, totalPages);
    }

    private static OrderDto MapToOrderDto(
        Order order,
        string quotationNumber,
        string rfqNumber,
        string? productThumbnailUrl,
        Member buyer,
        Member supplier,
        List<OrderStatusHistory> history,
        bool isBuyer,
        bool isSupplier)
    {
        var historyDtos = history.Select(h => new OrderStatusHistoryDto(
            h.Id,
            h.OrderId,
            h.PreviousStatus?.ToString(),
            h.NewStatus.ToString(),
            h.ChangedByMemberId,
            h.ChangedByMember?.FullName ?? "Member",
            h.ChangedByMember?.BusinessProfile?.CompanyName,
            h.ChangedAtUtc,
            h.Remarks
        )).OrderBy(h => h.ChangedAtUtc).ToList();

        return new OrderDto(
            Id: order.Id,
            OrderNumber: order.OrderNumber,
            QuotationId: order.QuotationId,
            QuotationNumber: quotationNumber,
            RfqId: order.RfqId,
            RfqNumber: rfqNumber,
            ProductId: order.ProductId,
            ProductName: order.ProductName,
            ProductThumbnailUrl: productThumbnailUrl,
            BuyerMemberId: order.BuyerMemberId,
            BuyerFullName: buyer.FullName,
            BuyerCompanyName: buyer.BusinessProfile?.CompanyName ?? buyer.FullName,
            BuyerEmail: buyer.Email,
            BuyerPhone: $"{buyer.CountryCode}{buyer.PhoneNumber}",
            SupplierMemberId: order.SupplierMemberId,
            SupplierFullName: supplier.FullName,
            SupplierCompanyName: supplier.BusinessProfile?.CompanyName ?? supplier.FullName,
            SupplierEmail: supplier.Email,
            SupplierPhone: $"{supplier.CountryCode}{supplier.PhoneNumber}",
            Quantity: order.Quantity,
            UnitOfMeasurement: order.UnitOfMeasurement,
            UnitPrice: order.UnitPrice,
            Subtotal: order.Subtotal,
            TaxRatePercent: order.TaxRatePercent,
            TaxAmount: order.TaxAmount,
            ShippingCharges: order.ShippingCharges,
            TotalAmount: order.TotalAmount,
            TermsAndConditionsSnapshot: order.TermsAndConditionsSnapshot,
            DeliveryAddress: order.DeliveryAddress,
            ExpectedDeliveryDateUtc: order.ExpectedDeliveryDateUtc,
            CarrierName: order.CarrierName,
            TrackingNumber: order.TrackingNumber,
            TrackingUrl: order.TrackingUrl,
            ShippedAtUtc: order.ShippedAtUtc,
            DeliveredAtUtc: order.DeliveredAtUtc,
            Status: order.Status.ToString(),
            CancellationReason: order.CancellationReason,
            RejectionReason: order.RejectionReason,
            Notes: order.Notes,
            CreatedAtUtc: order.CreatedAtUtc,
            UpdatedAtUtc: order.UpdatedAtUtc,
            ConfirmedAtUtc: order.ConfirmedAtUtc,
            CancelledAtUtc: order.CancelledAtUtc,
            StatusHistory: historyDtos,
            IsBuyer: isBuyer,
            IsSupplier: isSupplier
        );
    }
}


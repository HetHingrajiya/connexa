namespace Connexa.Api.Entities;

public enum OrderStatus
{
    PendingConfirmation = 1,
    Confirmed = 2,
    Processing = 3,
    Shipped = 4,
    Delivered = 5,
    Cancelled = 6,
    Rejected = 7
}

public class Order
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public int QuotationId { get; set; }
    public int RfqId { get; set; }
    public int ProductId { get; set; }
    public int BuyerMemberId { get; set; }
    public int SupplierMemberId { get; set; }

    // Commercial and Product Snapshot
    public string ProductName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string UnitOfMeasurement { get; set; } = "Units";
    public decimal UnitPrice { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TaxRatePercent { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal ShippingCharges { get; set; }
    public decimal TotalAmount { get; set; }
    public string? TermsAndConditionsSnapshot { get; set; }

    // Delivery & Shipment Details
    public string DeliveryAddress { get; set; } = string.Empty;
    public DateTime? ExpectedDeliveryDateUtc { get; set; }
    public string? CarrierName { get; set; }
    public string? TrackingNumber { get; set; }
    public string? TrackingUrl { get; set; }
    public DateTime? ShippedAtUtc { get; set; }
    public DateTime? DeliveredAtUtc { get; set; }

    // Lifecycle & Meta
    public OrderStatus Status { get; set; } = OrderStatus.PendingConfirmation;
    public string? CancellationReason { get; set; }
    public string? RejectionReason { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
    public DateTime? ConfirmedAtUtc { get; set; }
    public DateTime? CancelledAtUtc { get; set; }

    // Navigation properties
    public Quotation Quotation { get; set; } = null!;
    public Rfq Rfq { get; set; } = null!;
    public Product Product { get; set; } = null!;
    public Member BuyerMember { get; set; } = null!;
    public Member SupplierMember { get; set; } = null!;
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}


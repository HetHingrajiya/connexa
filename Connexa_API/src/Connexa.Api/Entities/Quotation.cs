namespace Connexa.Api.Entities;

public enum QuotationStatus
{
    Draft = 1,
    Submitted = 2,
    Revised = 3,
    Accepted = 4,
    Rejected = 5,
    Expired = 6
}

public class Quotation
{
    public int Id { get; set; }
    public int RfqId { get; set; }
    public string QuotationNumber { get; set; } = string.Empty;
    public int Version { get; set; } = 1;
    public int SupplierMemberId { get; set; }
    public int BuyerMemberId { get; set; }

    public decimal UnitPrice { get; set; }
    public decimal Quantity { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TaxRatePercent { get; set; } = 18.00m;
    public decimal TaxAmount { get; set; }
    public decimal ShippingCharges { get; set; } = 0.00m;
    public decimal TotalAmount { get; set; }

    public DateTime ValidUntilUtc { get; set; }
    public string EstimatedDeliveryTime { get; set; } = string.Empty;
    public string? TermsAndConditions { get; set; }
    public string? DocumentUrl { get; set; }

    public QuotationStatus Status { get; set; } = QuotationStatus.Submitted;
    public string? RejectionReason { get; set; }
    public string? RevisionNotes { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? SubmittedAtUtc { get; set; }
    public DateTime? DecidedAtUtc { get; set; }

    // Navigation properties
    public Rfq Rfq { get; set; } = null!;
    public Member SupplierMember { get; set; } = null!;
    public Member BuyerMember { get; set; } = null!;
    public Order? Order { get; set; }
}


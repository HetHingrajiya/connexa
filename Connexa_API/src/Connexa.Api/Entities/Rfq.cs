namespace Connexa.Api.Entities;

public enum RfqStatus
{
    Open = 1,
    QuotationReceived = 2,
    Closed = 3,
    Cancelled = 4
}

public class Rfq
{
    public int Id { get; set; }
    public string RfqNumber { get; set; } = string.Empty;
    public int ProductId { get; set; }
    public int BuyerMemberId { get; set; }
    public int SupplierMemberId { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string UnitOfMeasurement { get; set; } = "Units";
    public decimal? TargetPrice { get; set; }
    public DateTime? RequiredDeliveryDateUtc { get; set; }
    public string DeliveryLocation { get; set; } = string.Empty;
    public string? AdditionalSpecifications { get; set; }
    public string? AttachmentUrl { get; set; }
    public RfqStatus Status { get; set; } = RfqStatus.Open;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
    public DateTime? ClosedAtUtc { get; set; }
    public int? ProductInquiryId { get; set; }

    // Navigation properties
    public Product Product { get; set; } = null!;
    public Member BuyerMember { get; set; } = null!;
    public Member SupplierMember { get; set; } = null!;
    public ProductInquiry? ProductInquiry { get; set; }
    public ICollection<Quotation> Quotations { get; set; } = new List<Quotation>();
}


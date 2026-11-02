namespace Connexa.Api.Entities;

public enum JobWorkOrderStatus
{
    PendingConfirmation = 1,
    Confirmed = 2,
    Processing = 3,
    Completed = 4,
    Cancelled = 5,
    Rejected = 6
}

public class JobWorkOrder
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty; // e.g. "JWO-20261102-9012"
    public int JobWorkRequirementId { get; set; }
    public int JobWorkQuotationId { get; set; } // 1:1 relationship with accepted quotation
    public int BuyerMemberId { get; set; }
    public int ContractorMemberId { get; set; }

    // Job Snapshot
    public string JobTitle { get; set; } = string.Empty;
    public string Process { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string UnitOfMeasurement { get; set; } = "Pieces";

    // Financial Breakdown
    public decimal AgreedUnitPrice { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal OtherCharges { get; set; }
    public decimal TotalAmount { get; set; }

    // Execution & Delivery
    public int LeadTimeDays { get; set; }
    public string DeliveryLocation { get; set; } = string.Empty;

    // Lifecycle
    public JobWorkOrderStatus Status { get; set; } = JobWorkOrderStatus.PendingConfirmation;
    public DateTime? ConfirmedAtUtc { get; set; }
    public DateTime? ProcessingStartedAtUtc { get; set; }
    public DateTime? CompletedAtUtc { get; set; }
    public string? CancellationReason { get; set; }
    public string? RejectionReason { get; set; }
    public string? Notes { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public JobWorkRequirement Requirement { get; set; } = null!;
    public JobWorkQuotation Quotation { get; set; } = null!;
    public Member BuyerMember { get; set; } = null!;
    public Member ContractorMember { get; set; } = null!;
    public ICollection<JobWorkOrderStatusHistory> StatusHistory { get; set; } = new List<JobWorkOrderStatusHistory>();
}

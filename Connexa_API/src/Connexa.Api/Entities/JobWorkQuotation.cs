namespace Connexa.Api.Entities;

public enum JobWorkQuotationStatus
{
    Submitted = 1,
    RevisionRequested = 2,
    Accepted = 3,
    Rejected = 4,
    Withdrawn = 5
}

public class JobWorkQuotation
{
    public int Id { get; set; }
    public string QuotationNumber { get; set; } = string.Empty; // e.g. "JWQ-20261102-5678"
    public int JobWorkRequirementId { get; set; }
    public int ContractorMemberId { get; set; }

    // Commercial Breakdown
    public decimal OfferedUnitPrice { get; set; }
    public decimal Quantity { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TaxRatePercent { get; set; } = 18.00m;
    public decimal TaxAmount { get; set; }
    public decimal OtherCharges { get; set; } = 0.00m; // Tooling, fixturing, freight
    public decimal TotalAmount { get; set; }

    // Technical & Timeline
    public int LeadTimeDays { get; set; }
    public string? MachineProposed { get; set; }
    public string? TechnicalRemarks { get; set; }
    public string? TermsAndConditions { get; set; }

    // Lifecycle
    public JobWorkQuotationStatus Status { get; set; } = JobWorkQuotationStatus.Submitted;
    public int RevisionNumber { get; set; } = 1;
    public string? RejectionReason { get; set; }
    public string? RevisionNotes { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public JobWorkRequirement Requirement { get; set; } = null!;
    public Member ContractorMember { get; set; } = null!;
    public ICollection<JobWorkAttachment> Attachments { get; set; } = new List<JobWorkAttachment>();
    public JobWorkOrder? Order { get; set; }
}


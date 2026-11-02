namespace Connexa.Api.Entities;

public enum JobWorkRequirementStatus
{
    Open = 1,
    Closed = 2,
    Cancelled = 3
}

public enum MaterialResponsibility
{
    BuyerSupplied = 1,
    ContractorSupplied = 2,
    SharedOrNegotiable = 3
}

public class JobWorkRequirement
{
    public int Id { get; set; }
    public string RequirementNumber { get; set; } = string.Empty; // e.g. "JWR-20261102-1234"
    public int OwnerMemberId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    // Categorization
    public int IndustryId { get; set; }
    public int? BusinessGroupId { get; set; }
    public int? SubGroupId { get; set; }
    public int? CategoryId { get; set; }
    public string JobWorkProcess { get; set; } = string.Empty; // e.g. CNC Milling, CNC Turning, Laser Cutting, Sheet Metal Fabrication

    // Machine & Technical requirements
    public string? MachineType { get; set; } // e.g. "VMC 4-Axis", "Fiber Laser", "CNC Lathe", "Press Brake"
    public string? MachineCategory { get; set; }
    public string? RequiredMachineCapacity { get; set; } // e.g. "800 x 500 x 500 mm", "3 kW, 12mm MS"
    public int? NumberOfAxes { get; set; }
    public string? TechnicalSpecifications { get; set; }
    public string? RequiredTolerance { get; set; } // e.g. "+/- 0.01 mm", "+/- 5 microns"
    public string? MaterialType { get; set; } // e.g. "Aluminium 6061-T6", "SS 304", "Mild Steel"
    public MaterialResponsibility MaterialResponsibility { get; set; } = MaterialResponsibility.BuyerSupplied;

    // Quantity & Commercial
    public decimal Quantity { get; set; }
    public string UnitOfMeasurement { get; set; } = "Pieces";
    public decimal? TargetBudget { get; set; }
    public DateTime? ExpectedCompletionDate { get; set; }
    public string Location { get; set; } = string.Empty;
    public string? DeliveryTerms { get; set; }

    // Lifecycle
    public JobWorkRequirementStatus Status { get; set; } = JobWorkRequirementStatus.Open;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public Member OwnerMember { get; set; } = null!;
    public Industry Industry { get; set; } = null!;
    public BusinessGroup? BusinessGroup { get; set; }
    public SubGroup? SubGroup { get; set; }
    public Category? Category { get; set; }
    public ICollection<JobWorkAttachment> Attachments { get; set; } = new List<JobWorkAttachment>();
    public ICollection<JobWorkQuotation> Quotations { get; set; } = new List<JobWorkQuotation>();
    public JobWorkOrder? Order { get; set; }
}

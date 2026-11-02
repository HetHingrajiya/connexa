namespace Connexa.Api.Entities;

public enum ServiceInquiryStatus
{
    Pending = 1,
    UnderReview = 2,
    Responded = 3,
    Accepted = 4,
    Declined = 5,
    Closed = 6
}

public class ServiceInquiry
{
    public int Id { get; set; }
    public string InquiryNumber { get; set; } = string.Empty; // e.g. "SINQ-20261102-1234"
    public int ServiceId { get; set; }
    public int SenderMemberId { get; set; }
    public int RecipientMemberId { get; set; }

    public string Subject { get; set; } = string.Empty;
    public string RequirementDescription { get; set; } = string.Empty;
    public string? ScopeOfWork { get; set; }
    public string? Location { get; set; }
    public DateTime? PreferredStartDate { get; set; }
    public decimal? EstimatedBudget { get; set; }
    public string Urgency { get; set; } = "Normal"; // "Normal", "Urgent", "Emergency"

    public ServiceInquiryStatus Status { get; set; } = ServiceInquiryStatus.Pending;
    public string? ResponseMessage { get; set; }
    public DateTime? RespondedAtUtc { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }

    // Navigation properties
    public BusinessService Service { get; set; } = null!;
    public Member SenderMember { get; set; } = null!;
    public Member RecipientMember { get; set; } = null!;
    public ICollection<ServiceInquiryStatusHistory> StatusHistory { get; set; } = new List<ServiceInquiryStatusHistory>();
}


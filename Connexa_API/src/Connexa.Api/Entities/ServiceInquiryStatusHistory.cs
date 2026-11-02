namespace Connexa.Api.Entities;

public class ServiceInquiryStatusHistory
{
    public int Id { get; set; }
    public int ServiceInquiryId { get; set; }
    public ServiceInquiryStatus? PreviousStatus { get; set; }
    public ServiceInquiryStatus NewStatus { get; set; }
    public int ChangedByMemberId { get; set; }
    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
    public string? Remarks { get; set; }

    // Navigation properties
    public ServiceInquiry ServiceInquiry { get; set; } = null!;
    public Member ChangedByMember { get; set; } = null!;
}


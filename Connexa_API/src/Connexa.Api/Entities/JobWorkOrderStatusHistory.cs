namespace Connexa.Api.Entities;

public class JobWorkOrderStatusHistory
{
    public int Id { get; set; }
    public int JobWorkOrderId { get; set; }
    public JobWorkOrderStatus? PreviousStatus { get; set; }
    public JobWorkOrderStatus NewStatus { get; set; }
    public int ChangedByMemberId { get; set; }
    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
    public string? Remarks { get; set; }

    // Navigation properties
    public JobWorkOrder Order { get; set; } = null!;
    public Member ChangedByMember { get; set; } = null!;
}


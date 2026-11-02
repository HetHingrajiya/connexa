namespace Connexa.Api.Entities;

public class OrderStatusHistory
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public OrderStatus? PreviousStatus { get; set; }
    public OrderStatus NewStatus { get; set; }
    public int ChangedByMemberId { get; set; }
    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
    public string? Remarks { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
    public Member ChangedByMember { get; set; } = null!;
}


namespace Connexa.Api.Entities;

public class JobApplicationStatusHistory
{
    public int Id { get; set; }

    public int JobApplicationId { get; set; }
    public JobApplication JobApplication { get; set; } = null!;

    public JobApplicationStatus? PreviousStatus { get; set; }
    public JobApplicationStatus NewStatus { get; set; }

    public int ChangedByMemberId { get; set; }
    public Member ChangedByMember { get; set; } = null!;

    public string? Remarks { get; set; }
    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
}


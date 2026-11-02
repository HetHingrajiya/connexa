namespace Connexa.Api.Entities;

public class ProductInquiry
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public int SenderMemberId { get; set; }
    public int RecipientMemberId { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // "Pending", "Read", "Responded"
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAtUtc { get; set; }
    public string? ResponseMessage { get; set; }

    // Navigation properties
    public Product Product { get; set; } = null!;
    public Member SenderMember { get; set; } = null!;
    public Member RecipientMember { get; set; } = null!;
}

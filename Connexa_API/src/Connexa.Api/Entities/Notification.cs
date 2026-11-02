namespace Connexa.Api.Entities;

public enum NotificationEventType
{
    ConnectionRequestReceived = 1,
    ConnectionRequestAccepted = 2,
    ConnectionRequestRejected = 3,
    ProductInquiryReceived = 4,
    ProductInquiryResponded = 5,
    VerificationStatusChanged = 6,
    SystemAnnouncement = 7,
    RfqReceived = 8,
    QuotationReceived = 9,
    QuotationRevised = 10,
    QuotationAccepted = 11,
    QuotationRejected = 12,
    QuotationRevisionRequested = 13,
    RfqStatusChanged = 14,
    OrderCreated = 15,
    OrderConfirmed = 16,
    OrderRejected = 17,
    OrderProcessing = 18,
    OrderShipped = 19,
    OrderDelivered = 20,
    OrderCancelled = 21,
    JobWorkRequirementPublished = 22,
    JobWorkQuotationReceived = 23,
    JobWorkQuotationRevised = 24,
    JobWorkQuotationAccepted = 25,
    JobWorkQuotationRejected = 26,
    JobWorkQuotationRevisionRequested = 27,
    JobWorkOrderCreated = 28,
    JobWorkOrderConfirmed = 29,
    JobWorkOrderProcessing = 30,
    JobWorkOrderCompleted = 31,
    JobWorkOrderCancelled = 32
}

public class Notification
{
    public int Id { get; set; }
    public int RecipientMemberId { get; set; }
    public int? ActorMemberId { get; set; }
    public NotificationEventType EventType { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public DateTime? ReadAtUtc { get; set; }
    public string? ReferenceType { get; set; } // "connection", "product", "inquiry", "verification"
    public int? ReferenceId { get; set; }
    public string? PayloadJson { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Member RecipientMember { get; set; } = null!;
    public Member? ActorMember { get; set; }
}

namespace Connexa.Api.DTOs;

public record CreateOrderDto(
    int QuotationId,
    string DeliveryAddress,
    DateTime? ExpectedDeliveryDateUtc = null,
    string? Notes = null
);

public record ConfirmOrderDto(
    string? Remarks = null
);

public record RejectOrderDto(
    string Reason,
    string? Remarks = null
);

public record ProcessOrderDto(
    string? Remarks = null
);

public record ShipOrderDto(
    string CarrierName,
    string TrackingNumber,
    string? TrackingUrl = null,
    string? Remarks = null
);

public record DeliverOrderDto(
    string? Remarks = null
);

public record CancelOrderDto(
    string Reason,
    string? Remarks = null
);

public record OrderStatusHistoryDto(
    int Id,
    int OrderId,
    string? PreviousStatus,
    string NewStatus,
    int ChangedByMemberId,
    string ChangedByMemberName,
    string? ChangedByCompanyName,
    DateTime ChangedAtUtc,
    string? Remarks
);

public record OrderDto(
    int Id,
    string OrderNumber,
    int QuotationId,
    string QuotationNumber,
    int RfqId,
    string RfqNumber,
    int ProductId,
    string ProductName,
    string? ProductThumbnailUrl,
    int BuyerMemberId,
    string BuyerFullName,
    string BuyerCompanyName,
    string? BuyerEmail,
    string? BuyerPhone,
    int SupplierMemberId,
    string SupplierFullName,
    string SupplierCompanyName,
    string? SupplierEmail,
    string? SupplierPhone,
    decimal Quantity,
    string UnitOfMeasurement,
    decimal UnitPrice,
    decimal Subtotal,
    decimal TaxRatePercent,
    decimal TaxAmount,
    decimal ShippingCharges,
    decimal TotalAmount,
    string? TermsAndConditionsSnapshot,
    string DeliveryAddress,
    DateTime? ExpectedDeliveryDateUtc,
    string? CarrierName,
    string? TrackingNumber,
    string? TrackingUrl,
    DateTime? ShippedAtUtc,
    DateTime? DeliveredAtUtc,
    string Status,
    string? CancellationReason,
    string? RejectionReason,
    string? Notes,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    DateTime? ConfirmedAtUtc,
    DateTime? CancelledAtUtc,
    List<OrderStatusHistoryDto> StatusHistory,
    bool IsBuyer = false,
    bool IsSupplier = false
);

public record OrderFilterDto(
    string? Search = null,
    string? Status = null,
    int Page = 1,
    int PageSize = 10
);

public record OrderListResponseDto(
    List<OrderDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages
);


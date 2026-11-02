using Connexa.Api.DTOs;

namespace Connexa.Api.Services.Orders;

public interface IOrderService
{
    Task<(bool Success, string Message, OrderDto? Order)> CreateOrderAsync(
        int buyerMemberId,
        CreateOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<OrderListResponseDto> GetMyOrdersAsync(
        int buyerMemberId,
        OrderFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<OrderListResponseDto> GetReceivedOrdersAsync(
        int supplierMemberId,
        OrderFilterDto filter,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> GetOrderByIdAsync(
        int orderId,
        int currentMemberId,
        bool isAdmin = false,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> ConfirmOrderAsync(
        int orderId,
        int supplierMemberId,
        ConfirmOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> RejectOrderAsync(
        int orderId,
        int supplierMemberId,
        RejectOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> ProcessOrderAsync(
        int orderId,
        int supplierMemberId,
        ProcessOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> ShipOrderAsync(
        int orderId,
        int supplierMemberId,
        ShipOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> DeliverOrderAsync(
        int orderId,
        int currentMemberId,
        DeliverOrderDto dto,
        CancellationToken cancellationToken = default);

    Task<(bool Success, string Message, OrderDto? Order)> CancelOrderAsync(
        int orderId,
        int currentMemberId,
        CancelOrderDto dto,
        CancellationToken cancellationToken = default);
}


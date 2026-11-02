import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/features/orders/models/order_models.dart';
import 'package:connexa/features/orders/services/order_service.dart';

/// Provider for single Order details by ID.
final AutoDisposeFutureProviderFamily<Order, int> orderDetailsProvider =
    FutureProvider.autoDispose.family<Order, int>((Ref ref, int id) async {
  final OrderService service = ref.watch(orderServiceProvider);
  return service.getOrderById(id);
});

/// Async notifier managing Buyer's Orders (My Orders).
final AsyncNotifierProvider<MyOrdersNotifier, OrderListResponse> myOrdersProvider =
    AsyncNotifierProvider<MyOrdersNotifier, OrderListResponse>(MyOrdersNotifier.new);

class MyOrdersNotifier extends AsyncNotifier<OrderListResponse> {
  String? _search;
  String? _status;
  int _page = 1;

  @override
  Future<OrderListResponse> build() async {
    final OrderService service = ref.watch(orderServiceProvider);
    return service.getMyOrders(
      search: _search,
      status: _status,
      page: _page,
    );
  }

  Future<void> setFilters({String? search, String? status}) async {
    _search = search;
    _status = status;
    _page = 1;
    await refresh();
  }

  Future<void> setPage(int page) async {
    if (page == _page) return;
    _page = page;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue<OrderListResponse>.loading();
    state = await AsyncValue.guard(() async {
      final OrderService service = ref.read(orderServiceProvider);
      return service.getMyOrders(
        search: _search,
        status: _status,
        page: _page,
      );
    });
  }

  Future<Order> createOrder(CreateOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.createOrder(request);
    await refresh();
    ref.read(receivedOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> cancelOrder(int orderId, CancelOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.cancelOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(receivedOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> deliverOrder(int orderId, DeliverOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.deliverOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(receivedOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> completeOrder(int orderId, DeliverOrderRequest request) =>
      deliverOrder(orderId, request);
}

/// Async notifier managing Supplier's Received Orders.
final AsyncNotifierProvider<ReceivedOrdersNotifier, OrderListResponse>
    receivedOrdersProvider =
    AsyncNotifierProvider<ReceivedOrdersNotifier, OrderListResponse>(
        ReceivedOrdersNotifier.new);

class ReceivedOrdersNotifier extends AsyncNotifier<OrderListResponse> {
  String? _search;
  String? _status;
  int _page = 1;

  @override
  Future<OrderListResponse> build() async {
    final OrderService service = ref.watch(orderServiceProvider);
    return service.getReceivedOrders(
      search: _search,
      status: _status,
      page: _page,
    );
  }

  Future<void> setFilters({String? search, String? status}) async {
    _search = search;
    _status = status;
    _page = 1;
    await refresh();
  }

  Future<void> setPage(int page) async {
    if (page == _page) return;
    _page = page;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue<OrderListResponse>.loading();
    state = await AsyncValue.guard(() async {
      final OrderService service = ref.read(orderServiceProvider);
      return service.getReceivedOrders(
        search: _search,
        status: _status,
        page: _page,
      );
    });
  }

  Future<Order> confirmOrder(int orderId, ConfirmOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.confirmOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(myOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> rejectOrder(int orderId, RejectOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.rejectOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(myOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> processOrder(int orderId, ProcessOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.processOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(myOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> shipOrder(int orderId, ShipOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.shipOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(myOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> deliverOrder(int orderId, DeliverOrderRequest request) async {
    final OrderService service = ref.read(orderServiceProvider);
    final Order order = await service.deliverOrder(orderId, request);
    await refresh();
    ref.invalidate(orderDetailsProvider(orderId));
    ref.read(myOrdersProvider.notifier).refresh();
    return order;
  }

  Future<Order> completeOrder(int orderId, DeliverOrderRequest request) =>
      deliverOrder(orderId, request);
}


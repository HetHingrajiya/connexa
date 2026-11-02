import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/orders/models/order_models.dart';

final Provider<OrderService> orderServiceProvider = Provider<OrderService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return OrderService(dio);
});

class OrderService {
  const OrderService(this._dio);

  final Dio _dio;

  Future<OrderListResponse> getMyOrders({
    String? search,
    String? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/orders/my',
        queryParameters: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
            'status': status,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        final dynamic rawData = data['data'];
        final int? totalCount = (data['totalCount'] as num?)?.toInt();
        return OrderListResponse.fromResponseData(rawData, totalCount);
      }

      return const OrderListResponse(
        items: <Order>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load My Orders (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<OrderListResponse> getReceivedOrders({
    String? search,
    String? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/orders/received',
        queryParameters: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
            'status': status,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        final dynamic rawData = data['data'];
        final int? totalCount = (data['totalCount'] as num?)?.toInt();
        return OrderListResponse.fromResponseData(rawData, totalCount);
      }

      return const OrderListResponse(
        items: <Order>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load Received Orders (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Order> getOrderById(int orderId, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/orders/$orderId',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Unexpected response format when fetching order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load order #$orderId (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Order> createOrder(CreateOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to parse created order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to create order.');
    }
  }

  Future<Order> confirmOrder(int orderId, ConfirmOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/confirm',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to confirm order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to confirm order.');
    }
  }

  Future<Order> rejectOrder(int orderId, RejectOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/reject',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to reject order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to reject order.');
    }
  }

  Future<Order> processOrder(int orderId, ProcessOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/process',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update order to processing.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to update order to processing.');
    }
  }

  Future<Order> shipOrder(int orderId, ShipOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/ship',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to ship order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to ship order.');
    }
  }

  Future<Order> deliverOrder(int orderId, DeliverOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/deliver',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to deliver order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to deliver order.');
    }
  }

  Future<Order> completeOrder(int orderId, DeliverOrderRequest request) async {
    return deliverOrder(orderId, request);
  }

  Future<Order> cancelOrder(int orderId, CancelOrderRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/orders/$orderId/cancel',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Order.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to cancel order.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(msg ?? 'Failed to cancel order.');
    }
  }
}


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/notifications/models/notification_models.dart';

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return NotificationService(dio);
    });

class NotificationService {
  const NotificationService(this._dio);

  final Dio _dio;

  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
    CancelToken? cancelToken,
  }) async {
    try {
      final Map<String, dynamic> queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (unreadOnly != null) {
        queryParams['unreadOnly'] = unreadOnly;
      }

      final Response<dynamic> response = await _dio.get(
        '/api/v1/notifications',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return NotificationListResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      return const NotificationListResponse(
        items: <AppNotification>[],
        totalCount: 0,
        unreadCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 1,
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load notifications (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<int> getUnreadCount({CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/notifications/unread-count',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return (data['data'] as Map<String, dynamic>)['unreadCount'] as int? ?? 0;
      }

      return 0;
    } on DioException {
      return 0;
    }
  }

  Future<int> markAsRead({
    List<int>? notificationIds,
    bool markAll = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/notifications/mark-read',
        data: <String, dynamic>{
          'notificationIds': notificationIds,
          'markAll': markAll,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return (data['data'] as Map<String, dynamic>)['markedCount'] as int? ?? 0;
      }

      return 0;
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to mark notifications as read (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<bool> registerDeviceToken(
    String token, {
    String platform = 'android',
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/notifications/device-tokens',
        data: <String, dynamic>{
          'token': token,
          'platform': platform,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Future<bool> unregisterDeviceToken(
    String token, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '/api/v1/notifications/device-tokens',
        queryParameters: <String, dynamic>{'token': token},
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException {
      return false;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/connections/models/connection_models.dart';

final Provider<ConnectionService> connectionServiceProvider =
    Provider<ConnectionService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return ConnectionService(dio);
    });

class ConnectionService {
  const ConnectionService(this._dio);

  final Dio _dio;

  /// Sends a connection request to another business member.
  Future<void> sendRequest({
    required int recipientMemberId,
    String? note,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/connections/requests',
        data: <String, dynamic>{
          'recipientMemberId': recipientMemberId,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to send connection request.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Connection request failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves received pending connection requests.
  Future<PaginatedList<ConnectionRequestItem>> getReceivedRequests({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/connections/requests/received',
        queryParameters: <String, dynamic>{'page': page, 'pageSize': pageSize},
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> payload =
            data['data'] as Map<String, dynamic>;
        final List<dynamic> rawItems =
            (payload['items'] as List<dynamic>?) ?? <dynamic>[];
        final List<ConnectionRequestItem> items = rawItems
            .map(
              (dynamic item) =>
                  ConnectionRequestItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return PaginatedList<ConnectionRequestItem>(
          items: items,
          totalCount: (payload['totalCount'] as num?)?.toInt() ?? 0,
          page: (payload['page'] as num?)?.toInt() ?? 1,
          pageSize: (payload['pageSize'] as num?)?.toInt() ?? 10,
          totalPages: (payload['totalPages'] as num?)?.toInt() ?? 1,
        );
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to load received requests.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load received requests (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves sent pending connection requests.
  Future<PaginatedList<ConnectionRequestItem>> getSentRequests({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/connections/requests/sent',
        queryParameters: <String, dynamic>{'page': page, 'pageSize': pageSize},
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> payload =
            data['data'] as Map<String, dynamic>;
        final List<dynamic> rawItems =
            (payload['items'] as List<dynamic>?) ?? <dynamic>[];
        final List<ConnectionRequestItem> items = rawItems
            .map(
              (dynamic item) =>
                  ConnectionRequestItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return PaginatedList<ConnectionRequestItem>(
          items: items,
          totalCount: (payload['totalCount'] as num?)?.toInt() ?? 0,
          page: (payload['page'] as num?)?.toInt() ?? 1,
          pageSize: (payload['pageSize'] as num?)?.toInt() ?? 10,
          totalPages: (payload['totalPages'] as num?)?.toInt() ?? 1,
        );
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to load sent requests.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load sent requests (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Accepts a pending connection request.
  Future<void> acceptRequest(int requestId) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/connections/requests/$requestId/accept',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to accept connection request.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to accept request (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Rejects a pending connection request.
  Future<void> rejectRequest(int requestId) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/connections/requests/$requestId/reject',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to reject connection request.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to reject request (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Cancels a pending connection request sent by current member.
  Future<void> cancelRequest(int requestId) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/connections/requests/$requestId/cancel',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to cancel connection request.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to cancel request (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves accepted connections (My Network).
  Future<PaginatedList<ConnectedMemberItem>> getMyConnections({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/connections',
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'page': page,
          'pageSize': pageSize,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> payload =
            data['data'] as Map<String, dynamic>;
        final List<dynamic> rawItems =
            (payload['items'] as List<dynamic>?) ?? <dynamic>[];
        final List<ConnectedMemberItem> items = rawItems
            .map(
              (dynamic item) =>
                  ConnectedMemberItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return PaginatedList<ConnectedMemberItem>(
          items: items,
          totalCount: (payload['totalCount'] as num?)?.toInt() ?? 0,
          page: (payload['page'] as num?)?.toInt() ?? 1,
          pageSize: (payload['pageSize'] as num?)?.toInt() ?? 10,
          totalPages: (payload['totalPages'] as num?)?.toInt() ?? 1,
        );
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to load connections.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to load connections (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Removes an active connection with a member.
  Future<void> removeConnection(int memberId) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '/api/v1/connections/$memberId',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to remove connection.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Failed to remove connection (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves connections summary counts.
  Future<ConnectionsSummary> getSummary() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/connections/summary',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ConnectionsSummary.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      return const ConnectionsSummary();
    } on DioException {
      return const ConnectionsSummary();
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/directory/models/directory_models.dart';

final Provider<DirectoryService> directoryServiceProvider =
    Provider<DirectoryService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return DirectoryService(dio);
    });

class DirectoryService {
  const DirectoryService(this._dio);

  final Dio _dio;

  /// Retrieves paginated and filtered business directory records.
  Future<BusinessDirectoryResponse> searchBusinesses(
    BusinessDirectoryFilter filter, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/directory/businesses',
        queryParameters: filter.toQueryParams(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return BusinessDirectoryResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to load directory.',
      );
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ??
            'Directory request failed (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  /// Retrieves a specific business directory entry by Member ID.
  Future<BusinessDirectoryItem?> getBusinessById(
    int memberId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/directory/businesses/$memberId',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return BusinessDirectoryItem.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to load business profile.');
    }
  }
}

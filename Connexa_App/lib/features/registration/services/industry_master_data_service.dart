import 'package:dio/dio.dart';

import 'package:connexa/core/errors/app_exceptions.dart';
import 'package:connexa/features/registration/models/industry_master_data.dart';

/// Typed API service for fetching Industry Master Data hierarchy from the backend.
class IndustryMasterDataService {
  const IndustryMasterDataService(this._dio);

  final Dio _dio;

  /// Helper to safely extract a list of JSON maps from various API envelope conventions.
  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (responseData is Map) {
      final dynamic innerData =
          responseData['data'] ??
          responseData['items'] ??
          responseData['results'];
      if (innerData is List) {
        return innerData
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    throw const DataParsingException(
      'Invalid API response: Expected an array or a {data: [...]} payload envelope.',
    );
  }

  /// Fetches top-level industries.
  /// Endpoint: `GET /api/v1/master/industries`
  Future<List<Industry>> getIndustries({CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/master/industries',
        cancelToken: cancelToken,
      );
      final List<Map<String, dynamic>> list = _extractList(response.data);
      return list.map(Industry.fromJson).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DataParsingException('Failed to parse industries: $e', e);
    }
  }

  /// Fetches business groups for a given [industryId].
  /// Primary endpoint: `GET /api/v1/master/industries/{industryId}/business-groups`
  /// Query fallback: `GET /api/v1/master/business-groups?industryId={industryId}`
  Future<List<BusinessGroup>> getBusinessGroups(
    String industryId, {
    CancelToken? cancelToken,
  }) async {
    if (industryId.trim().isEmpty) {
      return const <BusinessGroup>[];
    }
    try {
      Response<dynamic> response;
      try {
        response = await _dio.get<dynamic>(
          '/api/v1/master/industries/$industryId/business-groups',
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Fallback to query parameter endpoint
          response = await _dio.get<dynamic>(
            '/api/v1/master/business-groups',
            queryParameters: <String, dynamic>{'industryId': industryId},
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }

      final List<Map<String, dynamic>> list = _extractList(response.data);
      return list.map(BusinessGroup.fromJson).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DataParsingException('Failed to parse business groups: $e', e);
    }
  }

  /// Fetches sub-groups for a given [businessGroupId].
  /// Primary endpoint: `GET /api/v1/master/business-groups/{businessGroupId}/sub-groups`
  /// Query fallback: `GET /api/v1/master/sub-groups?businessGroupId={businessGroupId}`
  Future<List<SubGroup>> getSubGroups(
    String businessGroupId, {
    CancelToken? cancelToken,
  }) async {
    if (businessGroupId.trim().isEmpty) {
      return const <SubGroup>[];
    }
    try {
      Response<dynamic> response;
      try {
        response = await _dio.get<dynamic>(
          '/api/v1/master/business-groups/$businessGroupId/sub-groups',
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get<dynamic>(
            '/api/v1/master/sub-groups',
            queryParameters: <String, dynamic>{
              'businessGroupId': businessGroupId,
            },
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }

      final List<Map<String, dynamic>> list = _extractList(response.data);
      return list.map(SubGroup.fromJson).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DataParsingException('Failed to parse sub-groups: $e', e);
    }
  }

  /// Fetches categories for a given [subGroupId].
  /// Primary endpoint: `GET /api/v1/master/sub-groups/{subGroupId}/categories`
  /// Query fallback: `GET /api/v1/master/categories?subGroupId={subGroupId}`
  Future<List<Category>> getCategories(
    String subGroupId, {
    CancelToken? cancelToken,
  }) async {
    if (subGroupId.trim().isEmpty) {
      return const <Category>[];
    }
    try {
      Response<dynamic> response;
      try {
        response = await _dio.get<dynamic>(
          '/api/v1/master/sub-groups/$subGroupId/categories',
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _dio.get<dynamic>(
            '/api/v1/master/categories',
            queryParameters: <String, dynamic>{'subGroupId': subGroupId},
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }

      final List<Map<String, dynamic>> list = _extractList(response.data);
      return list.map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DataParsingException('Failed to parse categories: $e', e);
    }
  }
}

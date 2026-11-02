import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/services/models/service_models.dart';

final Provider<ServicesMarketplaceService> servicesMarketplaceServiceProvider =
    Provider<ServicesMarketplaceService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return ServicesMarketplaceService(dio);
});

class ServicesMarketplaceService {
  ServicesMarketplaceService(this._dio);

  final Dio _dio;

  Future<(List<ServiceSummary> services, int totalCount)> searchServices({
    String? query,
    String? category,
    int? industryId,
    String? location,
    String? serviceType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/services',
        queryParameters: <String, dynamic>{
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null && category != 'All') 'category': category,
          if (industryId != null && industryId > 0) 'industryId': industryId,
          if (location != null && location.isNotEmpty) 'location': location,
          if (serviceType != null && serviceType != 'All')
            'serviceType': serviceType,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        final List<ServiceSummary> list = (data['data'] as List)
            .map((item) => ServiceSummary.fromJson(item as Map<String, dynamic>))
            .toList();
        final int totalCount = data['totalCount'] as int? ?? list.length;
        return (list, totalCount);
      }

      return (<ServiceSummary>[], 0);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/services/categories',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List).map((e) => e.toString()).toList();
      }

      return <String>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceDetail> getServiceById(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/services/$id',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceDetail.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Service not found.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ServiceSummary>> getMyServices() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/services/my',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((item) => ServiceSummary.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return <ServiceSummary>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceDetail> createService(CreateServiceRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/services',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceDetail.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to publish service.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceDetail> updateService(int id, UpdateServiceRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/services/$id',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceDetail.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to update service.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '/api/v1/services/$id',
      );

      final dynamic data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceInquiry> createInquiry(CreateServiceInquiryRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/service-inquiries',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to send inquiry.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceInquiry> getInquiryById(int id) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/service-inquiries/$id',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Inquiry not found.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ServiceInquiry>> getMySentInquiries() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/service-inquiries/sent',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((item) => ServiceInquiry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return <ServiceInquiry>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ServiceInquiry>> getMyReceivedInquiries() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/service-inquiries/received',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((item) => ServiceInquiry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return <ServiceInquiry>[];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceInquiry> respondInquiry(
    int id,
    RespondServiceInquiryRequest request,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/service-inquiries/$id/respond',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to respond to inquiry.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServiceInquiry> updateInquiryStatus(
    int id,
    ServiceInquiryStatus status,
    String? remarks,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/service-inquiries/$id/status',
        data: <String, dynamic>{
          'status': status.toInt(),
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ServiceInquiry.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to update inquiry status.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AuthException _handleError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final dynamic data = e.response?.data;
    String? serverMessage;

    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString();
    }

    return AuthException(
      serverMessage ?? 'An error occurred while communicating with services.',
      statusCode: statusCode,
    );
  }
}

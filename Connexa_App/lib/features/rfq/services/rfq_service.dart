import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/rfq/models/rfq_models.dart';

final Provider<RfqService> rfqServiceProvider = Provider<RfqService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return RfqService(dio);
});

class RfqService {
  const RfqService(this._dio);

  final Dio _dio;

  Future<RfqListResponse> getMyRfqs({
    String? search,
    String? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/rfqs/my',
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
      if (data is Map<String, dynamic> && data['data'] != null) {
        return RfqListResponse.fromJson(data['data'] as Map<String, dynamic>);
      }

      return const RfqListResponse(
        items: <Rfq>[],
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
        msg ?? 'Failed to load My RFQs (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<RfqListResponse> getReceivedRfqs({
    String? search,
    String? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/rfqs/received',
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
      if (data is Map<String, dynamic> && data['data'] != null) {
        return RfqListResponse.fromJson(data['data'] as Map<String, dynamic>);
      }

      return const RfqListResponse(
        items: <Rfq>[],
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
        msg ?? 'Failed to load Received RFQs (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Rfq> getRfqById(int id, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/rfqs/$id',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Rfq.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('RFQ not found.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to retrieve RFQ details (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Rfq> createRfq(CreateRfqRequest request, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/rfqs',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Rfq.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('Unexpected server response.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to create RFQ (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Rfq> cancelRfq(int rfqId, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/rfqs/$rfqId/cancel',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Rfq.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('Unexpected server response.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to cancel RFQ (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Quotation> submitQuotation(
    int rfqId,
    SubmitQuotationRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/rfqs/$rfqId/quotations',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Quotation.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('Unexpected server response.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to submit quotation (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<List<Quotation>> getQuotationsForRfq(int rfqId, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/rfqs/$rfqId/quotations',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List<dynamic>)
            .map((dynamic item) => Quotation.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return <Quotation>[];
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load quotations (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Quotation> getQuotationById(int quotationId, {CancelToken? cancelToken}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/rfqs/quotations/$quotationId',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Quotation.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('Quotation not found.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to load quotation details (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }

  Future<Quotation> decideQuotation(
    int quotationId,
    DecideQuotationRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/rfqs/quotations/$quotationId/decide',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Quotation.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw Exception('Unexpected server response.');
    } on DioException catch (e) {
      final String? msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data as Map<String, dynamic>)['message']?.toString()
          : null;
      throw Exception(
        msg ?? 'Failed to process quotation decision (${e.response?.statusCode ?? 'network'}).',
      );
    }
  }
}


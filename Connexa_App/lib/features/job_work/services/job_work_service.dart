import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/job_work/models/job_work_models.dart';

final Provider<JobWorkService> jobWorkServiceProvider =
    Provider<JobWorkService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return JobWorkService(dio);
});

class JobWorkService {
  const JobWorkService(this._dio);

  final Dio _dio;

  // --- Requirements ---

  Future<JobWorkRequirementListResponse> getMarketplaceRequirements({
    String? search,
    String? process,
    String? machineType,
    int? industryId,
    String? location,
    MaterialResponsibility? materialResponsibility,
    JobWorkRequirementStatus? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/requirements/marketplace',
        queryParameters: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (process != null && process.isNotEmpty) 'process': process,
          if (machineType != null && machineType.isNotEmpty)
            'machineType': machineType,
          if (industryId != null && industryId > 0) 'industryId': industryId,
          if (location != null && location.isNotEmpty) 'location': location,
          if (materialResponsibility != null)
            'materialResponsibility': materialResponsibility.apiValue,
          if (status != null) 'status': status.name,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkRequirementListResponse.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return const JobWorkRequirementListResponse(
        items: <JobWorkRequirement>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkRequirementListResponse> getMyRequirements({
    String? search,
    JobWorkRequirementStatus? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/requirements/my',
        queryParameters: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status.name,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkRequirementListResponse.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return const JobWorkRequirementListResponse(
        items: <JobWorkRequirement>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkRequirement> getRequirementById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/requirements/$id',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkRequirement.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to load requirement details.');
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkRequirement> createRequirement({
    required String title,
    required String description,
    required int industryId,
    int? businessGroupId,
    int? subGroupId,
    int? categoryId,
    required String jobWorkProcess,
    String? machineType,
    String? machineCategory,
    String? requiredMachineCapacity,
    String? technicalSpecifications,
    String? requiredTolerance,
    String? materialType,
    required MaterialResponsibility materialResponsibility,
    required double quantity,
    required String unitOfMeasurement,
    double? targetBudget,
    required String location,
    String? deliveryTerms,
    DateTime? targetCompletionDateUtc,
    List<int>? attachmentIds,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-works/requirements',
        data: <String, dynamic>{
          'title': title,
          'description': description,
          'industryId': industryId,
          'businessGroupId': ?businessGroupId,
          'subGroupId': ?subGroupId,
          'categoryId': ?categoryId,
          'jobWorkProcess': jobWorkProcess,
          if (machineType != null && machineType.isNotEmpty)
            'machineType': machineType,
          if (machineCategory != null && machineCategory.isNotEmpty)
            'machineCategory': machineCategory,
          if (requiredMachineCapacity != null &&
              requiredMachineCapacity.isNotEmpty)
            'requiredMachineCapacity': requiredMachineCapacity,
          if (technicalSpecifications != null &&
              technicalSpecifications.isNotEmpty)
            'technicalSpecifications': technicalSpecifications,
          if (requiredTolerance != null && requiredTolerance.isNotEmpty)
            'requiredTolerance': requiredTolerance,
          if (materialType != null && materialType.isNotEmpty)
            'materialType': materialType,
          'materialResponsibility': materialResponsibility.apiValue,
          'quantity': quantity,
          'unitOfMeasurement': unitOfMeasurement,
          'targetBudget': ?targetBudget,
          'location': location,
          if (deliveryTerms != null && deliveryTerms.isNotEmpty)
            'deliveryTerms': deliveryTerms,
          if (targetCompletionDateUtc != null)
            'targetCompletionDateUtc':
                targetCompletionDateUtc.toIso8601String(),
          if (attachmentIds != null && attachmentIds.isNotEmpty)
            'attachmentIds': attachmentIds,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkRequirement.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to create job work requirement.');
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cancelRequirement(int id) async {
    await _dio.post('/api/v1/job-works/requirements/$id/cancel');
  }

  Future<void> closeRequirement(int id) async {
    await _dio.post('/api/v1/job-works/requirements/$id/close');
  }

  // --- Quotations ---

  Future<JobWorkQuotation> submitQuotation({
    required int requirementId,
    required double offeredUnitPrice,
    required double quantity,
    double taxRatePercent = 18.0,
    double otherCharges = 0.0,
    int leadTimeDays = 7,
    String? machineProposed,
    String? technicalRemarks,
    String? termsAndConditions,
    DateTime? validUntilUtc,
    List<int>? attachmentIds,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-works/requirements/$requirementId/quotations',
        data: <String, dynamic>{
          'jobWorkRequirementId': requirementId,
          'offeredUnitPrice': offeredUnitPrice,
          'quantity': quantity,
          'taxRatePercent': taxRatePercent,
          'otherCharges': otherCharges,
          'leadTimeDays': leadTimeDays,
          if (machineProposed != null && machineProposed.isNotEmpty)
            'machineProposed': machineProposed,
          if (technicalRemarks != null && technicalRemarks.isNotEmpty)
            'technicalRemarks': technicalRemarks,
          if (termsAndConditions != null && termsAndConditions.isNotEmpty)
            'termsAndConditions': termsAndConditions,
          if (validUntilUtc != null)
            'validUntilUtc': validUntilUtc.toIso8601String(),
          if (attachmentIds != null && attachmentIds.isNotEmpty)
            'attachmentIds': attachmentIds,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkQuotation.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to submit quotation.');
    } catch (_) {
      rethrow;
    }
  }

  Future<List<JobWorkQuotation>> getQuotationsForRequirement(
    int requirementId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/requirements/$requirementId/quotations',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
        return (data['data'] as List<dynamic>)
            .map((dynamic e) =>
                JobWorkQuotation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const <JobWorkQuotation>[];
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkQuotationListResponse> getMyQuotations({
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/quotations/my',
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkQuotationListResponse.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return const JobWorkQuotationListResponse(
        items: <JobWorkQuotation>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> decideQuotation({
    required int quotationId,
    required String decision, // "Accept", "Reject", "RequestRevision"
    String? notes,
  }) async {
    await _dio.post(
      '/api/v1/job-works/quotations/$quotationId/decide',
      data: <String, dynamic>{
        'decision': decision,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> withdrawQuotation(int quotationId) async {
    await _dio.post('/api/v1/job-works/quotations/$quotationId/withdraw');
  }

  // --- Orders ---

  Future<JobWorkOrderListResponse> getOrders({
    required String role, // 'buyer' or 'contractor'
    JobWorkOrderStatus? status,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/orders',
        queryParameters: <String, dynamic>{
          'role': role,
          if (status != null) 'status': status.name,
          'page': page,
          'pageSize': pageSize,
        },
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkOrderListResponse.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return const JobWorkOrderListResponse(
        items: <JobWorkOrder>[],
        totalCount: 0,
        page: 1,
        pageSize: 10,
        totalPages: 0,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkOrder> getOrderById(
    int orderId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/job-works/orders/$orderId',
        cancelToken: cancelToken,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkOrder.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to load order details.');
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkOrder> updateOrderStatus({
    required int orderId,
    required JobWorkOrderStatus newStatus,
    String? remarks,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-works/orders/$orderId/status',
        data: <String, dynamic>{
          'newStatus': newStatus.apiValue,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkOrder.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update order status.');
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cancelOrder({
    required int orderId,
    required String reason,
  }) async {
    await _dio.post(
      '/api/v1/job-works/orders/$orderId/cancel',
      data: <String, dynamic>{'reason': reason},
    );
  }

  // --- Attachments ---

  Future<JobWorkAttachment> uploadAttachment(File file) async {
    try {
      final String fileName = file.path.split(Platform.pathSeparator).last;
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-works/attachments/upload',
        data: formData,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkAttachment.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to upload attachment.');
    } catch (_) {
      rethrow;
    }
  }

  Future<JobWorkAttachment> uploadAttachmentBytes(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final Response<dynamic> response = await _dio.post(
        '/api/v1/job-works/attachments/upload',
        data: formData,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return JobWorkAttachment.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to upload attachment.');
    } catch (_) {
      rethrow;
    }
  }
}


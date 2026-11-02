import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/profile/models/business_verification_models.dart';

final Provider<BusinessVerificationService> businessVerificationServiceProvider =
    Provider<BusinessVerificationService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return BusinessVerificationService(dio);
    });

class BusinessVerificationService {
  BusinessVerificationService(this._dio);

  final Dio _dio;

  /// Retrieves current verification status for the authenticated member.
  Future<VerificationStatusResponse> getVerificationStatus() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/business-verification/status',
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> statusData =
          data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return VerificationStatusResponse.fromJson(statusData);
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to load verification status.');
    }
  }

  /// Submits a business verification request with uploaded documents.
  Future<BusinessVerificationRequest> submitVerification({
    required String registrationNumber,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? notes,
    required List<DocumentUploadItem> documents,
  }) async {
    try {
      final FormData formData = FormData();

      formData.fields.addAll(<MapEntry<String, String>>[
        MapEntry<String, String>(
          'businessRegistrationNumber',
          registrationNumber,
        ),
        MapEntry<String, String>('registeredAddress', address),
        MapEntry<String, String>('city', city),
        MapEntry<String, String>('state', state),
        MapEntry<String, String>('pincode', pincode),
        if (notes != null && notes.isNotEmpty)
          MapEntry<String, String>('notes', notes),
      ]);

      for (int i = 0; i < documents.length; i++) {
        final DocumentUploadItem doc = documents[i];
        final MultipartFile file = MultipartFile.fromBytes(
          doc.bytes,
          filename: doc.fileName,
        );
        formData.files.add(MapEntry<String, MultipartFile>('documents', file));
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/business-verification/submit',
        data: formData,
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> resultData =
          data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return BusinessVerificationRequest.fromJson(resultData);
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to submit verification.');
    }
  }

  /// Lists verification applications for Admin review.
  Future<AdminVerificationListResponse> getAdminVerifications({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null && status.isNotEmpty && status != 'All') {
        query['status'] = status;
      }

      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/admin/verifications',
        queryParameters: query,
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> resultData =
          data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return AdminVerificationListResponse.fromJson(resultData);
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(
        msg?.toString() ?? 'Failed to load verification requests.',
      );
    }
  }

  /// Approves a verification request (Admin only).
  Future<BusinessVerificationRequest> approveVerification(int id) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/admin/verifications/$id/approve',
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> resultData =
          data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return BusinessVerificationRequest.fromJson(resultData);
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(
        msg?.toString() ?? 'Failed to approve verification request.',
      );
    }
  }

  /// Rejects a verification request with remarks (Admin only).
  Future<BusinessVerificationRequest> rejectVerification(
    int id,
    String reason,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/admin/verifications/$id/reject',
        data: <String, dynamic>{'reason': reason},
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> resultData =
          data['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

      return BusinessVerificationRequest.fromJson(resultData);
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(
        msg?.toString() ?? 'Failed to reject verification request.',
      );
    }
  }

  /// Uploads a business logo.
  Future<String> uploadLogo(List<int> bytes, String fileName) async {
    try {
      final FormData formData = FormData();
      formData.files.add(
        MapEntry<String, MultipartFile>(
          'file',
          MultipartFile.fromBytes(bytes, filename: fileName),
        ),
      );

      final Response<dynamic> response = await _dio.post<dynamic>(
        '/api/v1/business-verification/logo',
        data: formData,
      );

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      return data['data']?.toString() ?? '';
    } on DioException catch (e) {
      final dynamic msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg?.toString() ?? 'Failed to upload logo.');
    }
  }
}

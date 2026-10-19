import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/registration/models/verification_models.dart';

/// Riverpod provider for [PhoneVerificationService].
final Provider<PhoneVerificationService> phoneVerificationServiceProvider =
    Provider<PhoneVerificationService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return PhoneVerificationService(dio);
    });

/// Service responsible for executing WhatsApp OTP verification API calls.
class PhoneVerificationService {
  PhoneVerificationService(this._dio, {FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _sendEndpoint = '/api/v1/verification/whatsapp/send';
  static const String _resendEndpoint = '/api/v1/verification/whatsapp/resend';
  static const String _verifyEndpoint = '/api/v1/verification/whatsapp/verify';
  static const String _grantStorageKey = 'connexa_phone_verification_grant';

  /// Sends a WhatsApp verification OTP to the target phone number.
  Future<SendOtpResult> sendOtp(SendOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _sendEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return SendOtpResult.fromJson(data['data'] as Map<String, dynamic>);
        }
        throw VerificationException(
          data['message']?.toString() ?? 'Failed to send OTP code.',
          statusCode: response.statusCode,
        );
      }
      throw const VerificationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Requests a fresh OTP code for an active challenge subject to cooldown limits.
  Future<ResendOtpResult> resendOtp(ResendOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _resendEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return ResendOtpResult.fromJson(data['data'] as Map<String, dynamic>);
        }
        throw VerificationException(
          data['message']?.toString() ?? 'Failed to resend OTP code.',
          statusCode: response.statusCode,
        );
      }
      throw const VerificationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Submits the 6-digit OTP code for server-side verification and issues a grant.
  Future<VerifyOtpResult> verifyOtp(VerifyOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _verifyEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final VerifyOtpResult result = VerifyOtpResult.fromJson(
            data['data'] as Map<String, dynamic>,
          );

          // Persist the opaque verification grant in secure storage for registration completion
          if (result.verificationGrant.isNotEmpty) {
            try {
              await _secureStorage.write(
                key: _grantStorageKey,
                value: result.verificationGrant,
              );
            } catch (_) {
              // Gracefully continue in environments where secure storage may be unavailable (e.g., tests/web)
            }
          }

          return result;
        }
        throw VerificationException(
          data['message']?.toString() ?? 'Verification failed.',
          statusCode: response.statusCode,
        );
      }
      throw const VerificationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Retrieves any previously stored verification grant.
  Future<String?> getStoredVerificationGrant() async {
    try {
      return await _secureStorage.read(key: _grantStorageKey);
    } catch (_) {
      return null;
    }
  }

  /// Clears any cached verification grant upon registration reset or logout.
  Future<void> clearStoredVerificationGrant() async {
    try {
      await _secureStorage.delete(key: _grantStorageKey);
    } catch (_) {
      // Ignored
    }
  }

  VerificationException _handleDioError(DioException e) {
    final dynamic responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic msg = responseData['message'] ?? responseData['error'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return VerificationException(
          msg.toString().trim(),
          statusCode: e.response?.statusCode,
        );
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const VerificationException(
        'Connection to verification server timed out. Please check your network.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const VerificationException(
        'Unable to reach Connexa verification service. Please verify server is running.',
      );
    }

    return VerificationException(
      e.message ?? 'An unexpected error occurred during phone verification.',
      statusCode: e.response?.statusCode,
    );
  }
}

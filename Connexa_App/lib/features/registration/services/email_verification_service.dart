import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/registration/models/verification_models.dart';

/// Riverpod provider for [EmailVerificationService].
final Provider<EmailVerificationService> emailVerificationServiceProvider =
    Provider<EmailVerificationService>((Ref ref) {
      final Dio dio = ref.watch(dioProvider);
      return EmailVerificationService(dio);
    });

/// Service responsible for executing Gmail SMTP email OTP verification API calls.
class EmailVerificationService {
  EmailVerificationService(this._dio, {FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _sendEndpoint = '/api/v1/verification/email/send';
  static const String _resendEndpoint = '/api/v1/verification/email/resend';
  static const String _verifyEndpoint = '/api/v1/verification/email/verify';
  static const String _grantStorageKey = 'connexa_email_verification_grant';

  /// Sends a Gmail SMTP email verification OTP to the target email.
  Future<SendEmailOtpResult> sendOtp(SendEmailOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _sendEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return SendEmailOtpResult.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
        throw VerificationException(
          data['message']?.toString() ??
              'Failed to send email verification code.',
          statusCode: response.statusCode,
        );
      }
      throw const VerificationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Requests a fresh OTP code for an active email challenge subject to cooldown limits.
  Future<ResendEmailOtpResult> resendOtp(ResendEmailOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _resendEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return ResendEmailOtpResult.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
        throw VerificationException(
          data['message']?.toString() ??
              'Failed to resend email verification code.',
          statusCode: response.statusCode,
        );
      }
      throw const VerificationException('Invalid server response format.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Submits the 6-digit OTP code for server-side verification and issues a grant.
  Future<VerifyEmailOtpResult> verifyOtp(VerifyEmailOtpRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        _verifyEndpoint,
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final VerifyEmailOtpResult result = VerifyEmailOtpResult.fromJson(
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
              // Gracefully continue in environments where secure storage may be unavailable
            }
          }

          return result;
        }
        throw VerificationException(
          data['message']?.toString() ?? 'Email verification failed.',
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
        'Connection to email verification server timed out. Please check your network.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const VerificationException(
        'Unable to reach Connexa verification service. Please verify server is running.',
      );
    }

    return VerificationException(
      e.message ?? 'An unexpected error occurred during email verification.',
      statusCode: e.response?.statusCode,
    );
  }
}

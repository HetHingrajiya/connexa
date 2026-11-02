import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/features/auth/models/auth_models.dart';
import 'package:connexa/features/auth/models/security_models.dart';

/// Riverpod provider for [SecurityService].
final Provider<SecurityService> securityServiceProvider =
    Provider<SecurityService>((Ref ref) {
  final Dio dio = ref.watch(dioProvider);
  return SecurityService(dio);
});

/// API service handling security, password management, sessions, and account lifecycle.
class SecurityService {
  SecurityService(this._dio);

  final Dio _dio;

  /// Initiates forgot-password OTP challenge.
  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/forgot-password',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return ForgotPasswordResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      throw AuthException(
        data['message']?.toString() ?? 'Unable to send password reset code.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verifies OTP and resets password.
  Future<bool> resetPassword(ResetPasswordRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/reset-password',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to reset password.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Authenticated change password.
  Future<bool> changePassword(ChangePasswordRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/members/me/change-password',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to update password.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Lists active sessions for current member.
  Future<List<ActiveSession>> getActiveSessions() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/members/me/sessions',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is List) {
        return (data['data'] as List)
            .map((item) => ActiveSession.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return <ActiveSession>[];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Revokes an individual session.
  Future<bool> revokeSession(int sessionId) async {
    try {
      final Response<dynamic> response = await _dio.delete(
        '/api/v1/members/me/sessions/$sessionId',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to revoke session.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Revokes all other active sessions except current.
  Future<bool> revokeAllOtherSessions() async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/members/me/sessions/revoke-others',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to revoke other sessions.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Deactivates account.
  Future<bool> deactivateAccount(DeactivateAccountRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/members/me/deactivate',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to deactivate account.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Submits account deletion request.
  Future<bool> requestAccountDeletion(DeleteAccountRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/members/me/delete-request',
        data: request.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return true;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Failed to submit deletion request.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches account status (activation and pending deletion requests).
  Future<AccountStatus> getAccountStatus() async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/api/v1/members/me/account-status',
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return AccountStatus.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Unable to retrieve account status.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AuthException _handleDioError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final dynamic data = e.response?.data;

    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString();
    }

    if (statusCode == 401) {
      return AuthException(
        serverMessage ?? 'Invalid credentials or expired session.',
        statusCode: 401,
      );
    }

    if (statusCode == 400) {
      return AuthException(
        serverMessage ?? 'Invalid input. Please check your details.',
        statusCode: 400,
      );
    }

    if (statusCode == 429) {
      return AuthException(
        serverMessage ?? 'Too many requests. Please wait before trying again.',
        statusCode: 429,
      );
    }

    return AuthException(
      serverMessage ?? 'An error occurred while processing your request.',
      statusCode: statusCode,
    );
  }
}


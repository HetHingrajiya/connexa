import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/network/api_client.dart';
import 'package:connexa/core/storage/auth_storage.dart';
import 'package:connexa/features/auth/models/auth_models.dart';

/// Riverpod provider for [AuthService].
final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final Dio dio = ref.watch(dioProvider);
  final AuthStorage authStorage = ref.watch(authStorageProvider);
  return AuthService(dio, authStorage);
});

/// API service managing authentication, credential setup, logout, and current member profile.
class AuthService {
  AuthService(this._dio, this._storage);

  final Dio _dio;
  final AuthStorage _storage;

  /// Authenticates member with login identifier and password.
  Future<AuthResponse> login(String identifier, String password) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/login',
        data: <String, dynamic>{
          'identifier': identifier.trim(),
          'password': password,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final AuthResponse authResponse = AuthResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );

        // Store tokens securely
        await _storage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          memberId: authResponse.member.memberId,
          memberName: authResponse.member.fullName,
          memberEmail: authResponse.member.email,
        );

        return authResponse;
      }

      throw AuthException(
        data['message']?.toString() ??
            'Login failed. Please check your credentials.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Sets password for a verified member using server-validated setup token or OTP grant.
  Future<AuthResponse> setupPassword({
    String? credentialSetupToken,
    String? verificationGrant,
    String? destination,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/setup-password',
        data: <String, dynamic>{
          'credentialSetupToken': credentialSetupToken,
          'verificationGrant': verificationGrant,
          'destination': destination,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final AuthResponse authResponse = AuthResponse.fromJson(
          data['data'] as Map<String, dynamic>,
        );

        await _storage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          memberId: authResponse.member.memberId,
          memberName: authResponse.member.fullName,
          memberEmail: authResponse.member.email,
        );

        return authResponse;
      }

      throw AuthException(
        data['message']?.toString() ?? 'Password setup failed.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Dispatches an OTP to a registered member's verified contact to authorize password setup.
  Future<RequestSetupOtpResult> requestSetupOtp({
    required String identifier,
    required String channel,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/request-setup-otp',
        data: <String, dynamic>{
          'identifier': identifier.trim(),
          'channel': channel,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return RequestSetupOtpResult.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      throw AuthException(
        data['message']?.toString() ??
            'Failed to dispatch setup verification code.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verifies setup OTP and receives a fresh single-use CredentialSetupToken.
  Future<VerifySetupOtpResult> verifySetupOtp({
    required int challengeId,
    required String flowId,
    required String otpCode,
    required String channel,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/api/v1/auth/verify-setup-otp',
        data: <String, dynamic>{
          'challengeId': challengeId,
          'flowId': flowId,
          'otpCode': otpCode.trim(),
          'channel': channel,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return VerifySetupOtpResult.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      throw AuthException(
        data['message']?.toString() ?? 'Verification failed. Please retry.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetches the real member profile from GET /api/v1/members/me.
  Future<MemberProfile> getMe() async {
    try {
      final Response<dynamic> response = await _dio.get('/api/v1/members/me');

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return MemberProfile.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Unable to retrieve member profile.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Updates member profile with server-side validation and ownership checks.
  Future<MemberProfile> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final Response<dynamic> response = await _dio.put(
        '/api/v1/members/me/profile',
        data: updateData,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        return MemberProfile.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw AuthException(
        data['message']?.toString() ?? 'Unable to update member profile.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Revokes active session and removes stored tokens.
  Future<void> logout() async {
    try {
      final String? refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          '/api/v1/auth/logout',
          data: <String, dynamic>{'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _storage.clear();
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
        serverMessage ?? 'Invalid email/phone number or password.',
        statusCode: 401,
      );
    }

    if (statusCode == 429) {
      return AuthException(
        serverMessage ?? 'Account temporarily locked. Please try again later.',
        statusCode: 429,
      );
    }

    if (statusCode == 400) {
      return AuthException(
        serverMessage ?? 'Invalid request. Please verify your inputs.',
        statusCode: 400,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AuthException(
        'Unable to reach Connexa servers. Please check your network connection.',
        statusCode: 503,
      );
    }

    return AuthException(
      serverMessage ?? 'An unexpected authentication error occurred.',
      statusCode: statusCode,
    );
  }
}

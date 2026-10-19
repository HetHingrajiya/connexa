import 'package:dio/dio.dart';
import 'package:connexa/core/constants/api_constants.dart';
import 'package:connexa/core/storage/auth_storage.dart';

/// Interceptor that attaches JWT Bearer tokens to requests and handles token rotation on HTTP 401.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.authStorage,
    required this.dio,
    this.onAuthenticationFailed,
  });

  final AuthStorage authStorage;
  final Dio dio;
  final void Function()? onAuthenticationFailed;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid attaching bearer token to public auth endpoints
    final String path = options.path;
    final bool isPublic =
        path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/setup-password') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/registration/submit') ||
        path.contains('/api/v1/verification/');

    if (!isPublic) {
      final String? token = await authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions req = err.requestOptions;
    final String path = req.path;

    // Only attempt refresh on 401 Unauthorized for non-auth endpoints
    final bool isAuthEndpoint =
        path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/setup-password') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/auth/logout');

    if (err.response?.statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
      final String? refreshToken = await authStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        _isRefreshing = true;
        try {
          // Create isolated Dio client to avoid recursive interceptor calls
          final Dio refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: <String, dynamic>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final Response<dynamic> refreshResponse = await refreshDio.post(
            '/api/v1/auth/refresh',
            data: <String, dynamic>{'refreshToken': refreshToken},
          );

          final dynamic responseData = refreshResponse.data;
          if (responseData is Map<String, dynamic> &&
              responseData['success'] == true &&
              responseData['data'] is Map<String, dynamic>) {
            final Map<String, dynamic> data =
                responseData['data'] as Map<String, dynamic>;
            final String newAccessToken = data['accessToken']?.toString() ?? '';
            final String newRefreshToken =
                data['refreshToken']?.toString() ?? '';

            if (newAccessToken.isNotEmpty) {
              await authStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry the original request with new token
              req.headers['Authorization'] = 'Bearer $newAccessToken';
              final Response<dynamic> retryResponse = await dio.fetch(req);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed or token expired
          await authStorage.clear();
          onAuthenticationFailed?.call();
        } finally {
          _isRefreshing = false;
        }
      } else {
        await authStorage.clear();
        onAuthenticationFailed?.call();
      }
    }

    return handler.next(err);
  }
}

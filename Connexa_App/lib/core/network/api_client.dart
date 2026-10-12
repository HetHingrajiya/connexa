import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/constants/api_constants.dart';

/// Riverpod provider for the global [Dio] HTTP client instance.
///
/// Can be overridden in widget/unit tests using `dioProvider.overrideWithValue(mockDio)`.
final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final BaseOptions options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final Dio dio = Dio(options);

  // Add standard logging / request interceptor in debug mode
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions req, RequestInterceptorHandler handler) {
        return handler.next(req);
      },
      onResponse:
          (Response<dynamic> response, ResponseInterceptorHandler handler) {
            return handler.next(response);
          },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        return handler.next(error);
      },
    ),
  );

  return dio;
});

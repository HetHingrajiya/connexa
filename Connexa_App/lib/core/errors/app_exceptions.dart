import 'package:dio/dio.dart';

/// Base exception class for application errors.
abstract class AppException implements Exception {
  const AppException(this.message, [this.details]);

  final String message;
  final dynamic details;

  /// Factory translating any [DioException] into an appropriate typed [AppException].
  factory AppException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkException(
          'Connection timeout: Unable to reach the server in a timely manner. Please check your network connection.',
        );
      case DioExceptionType.sendTimeout:
        return const NetworkException(
          'Send timeout: Request could not be sent to the server in time.',
        );
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Receive timeout: Server took too long to respond.',
        );
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        final dynamic data = error.response?.data;
        String serverMessage = 'Server error ($statusCode)';
        if (data is Map && data['message'] is String) {
          serverMessage = data['message'] as String;
        } else if (data is String && data.isNotEmpty) {
          serverMessage = data;
        }
        return ApiException(
          serverMessage,
          statusCode: statusCode,
          details: error.response?.data,
        );
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled.');
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to connect to the backend API. Please verify that the server is online and reachable.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException('Security certificate error.');
      default:
        return NetworkException(
          'An unexpected network error occurred: ${error.message ?? 'Unknown error'}',
          error,
        );
    }
  }

  @override
  String toString() => message;
}

/// Network-level communication failure (e.g., connection timed out, no internet).
class NetworkException extends AppException {
  const NetworkException(super.message, [super.details]);
}

/// Server-side API error with status code and payload details.
class ApiException extends AppException {
  const ApiException(String message, {this.statusCode, dynamic details})
    : super(message, details);

  final int? statusCode;

  @override
  String toString() => statusCode != null ? '[$statusCode] $message' : message;
}

/// Response parsing or schema validation error.
class DataParsingException extends AppException {
  const DataParsingException(super.message, [super.details]);
}

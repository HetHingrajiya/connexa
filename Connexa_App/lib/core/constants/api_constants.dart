import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized API configuration.
///
/// Configurable via `--dart-define=API_BASE_URL=...` for remote staging/production.
/// Defaults to intelligent local host configurations based on runtime platform:
/// - Android emulator: `http://10.0.2.2:5104`
/// - Web / Windows desktop / macOS / Linux: `http://127.0.0.1:5104`
abstract final class ApiConstants {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5104';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5104';
      }
    } catch (_) {
      // Fallback if dart:io Platform is unavailable
    }
    return 'http://127.0.0.1:5104';
  }

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    final String url = _configuredBaseUrl.isNotEmpty
        ? _configuredBaseUrl
        : defaultBaseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

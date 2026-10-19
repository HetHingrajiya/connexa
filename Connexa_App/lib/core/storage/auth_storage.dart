import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for [AuthStorage].
final Provider<AuthStorage> authStorageProvider = Provider<AuthStorage>((
  Ref ref,
) {
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  return AuthStorage(secureStorage);
});

/// Secure token and session storage service using platform-appropriate secure storage.
class AuthStorage {
  AuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'connexa_jwt_access_token';
  static const String _keyRefreshToken = 'connexa_jwt_refresh_token';
  static const String _keyMemberId = 'connexa_member_id';
  static const String _keyMemberName = 'connexa_member_name';
  static const String _keyMemberEmail = 'connexa_member_email';

  // In-memory cache for fast synchronous access in interceptors
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  String? get cachedAccessToken => _cachedAccessToken;
  String? get cachedRefreshToken => _cachedRefreshToken;

  /// Saves access token, refresh token, and optional basic member details to secure storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? memberId,
    String? memberName,
    String? memberEmail,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;

    try {
      await Future.wait(<Future<void>>[
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
        if (memberId != null)
          _storage.write(key: _keyMemberId, value: memberId.toString()),
        if (memberName != null)
          _storage.write(key: _keyMemberName, value: memberName),
        if (memberEmail != null)
          _storage.write(key: _keyMemberEmail, value: memberEmail),
      ]).timeout(const Duration(milliseconds: 150), onTimeout: () => <void>[]);
    } catch (_) {
      // In testing environments without hardware secure storage, in-memory cache preserves tokens.
    }
  }

  /// Retrieves the active access token.
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    try {
      _cachedAccessToken = await _storage
          .read(key: _keyAccessToken)
          .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
      return _cachedAccessToken;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      _cachedRefreshToken = await _storage
          .read(key: _keyRefreshToken)
          .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
      return _cachedRefreshToken;
    } catch (_) {
      return null;
    }
  }

  /// Clears all stored tokens and session data.
  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    try {
      await Future.wait(<Future<void>>[
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keyMemberId),
        _storage.delete(key: _keyMemberName),
        _storage.delete(key: _keyMemberEmail),
      ]).timeout(const Duration(milliseconds: 150), onTimeout: () => <void>[]);
    } catch (_) {
      // Ignore cleanup exceptions
    }
  }

  /// Checks if an access token or refresh token is available.
  Future<bool> hasToken() async {
    final String? token = await getAccessToken();
    if (token != null && token.isNotEmpty) return true;
    final String? refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}

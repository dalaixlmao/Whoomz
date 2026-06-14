import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // Shared across all TokenStorage instances — cleared on app termination.
  static final Map<String, String> _memoryCache = {};
  static bool _sessionOnly = false;
  static bool get sessionOnly => _sessionOnly;

  Future<String?> readAccessToken() async =>
      _memoryCache[_accessKey] ?? await _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() async =>
      _memoryCache[_refreshKey] ?? await _storage.read(key: _refreshKey);

  Future<void> persist({
    required String accessToken,
    required String refreshToken,
    bool rememberMe = true,
  }) async {
    _memoryCache[_accessKey] = accessToken;
    _memoryCache[_refreshKey] = refreshToken;
    _sessionOnly = !rememberMe;
    if (rememberMe) {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> deleteAll() async {
    _memoryCache.clear();
    _sessionOnly = false;
    await _storage.deleteAll();
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';

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

  Future<void> persistUser({
    required String id,
    required String email,
    String? name,
  }) async {
    _memoryCache[_userIdKey] = id;
    _memoryCache[_userEmailKey] = email;
    if (name != null) _memoryCache[_userNameKey] = name;
    if (_sessionOnly) return;
    await _storage.write(key: _userIdKey, value: id);
    await _storage.write(key: _userEmailKey, value: email);
    if (name != null) await _storage.write(key: _userNameKey, value: name);
  }

  Future<({String id, String email, String? name})?> readUser() async {
    final id = _memoryCache[_userIdKey] ?? await _storage.read(key: _userIdKey);
    final email =
        _memoryCache[_userEmailKey] ?? await _storage.read(key: _userEmailKey);
    if (id == null || email == null) return null;
    final name =
        _memoryCache[_userNameKey] ?? await _storage.read(key: _userNameKey);
    return (id: id, email: email, name: name);
  }

  /// Turning remember-me off keeps the session alive in memory but wipes the
  /// disk, so the next launch starts signed out. Turning it on re-persists
  /// the in-memory session.
  Future<void> setRememberMe(bool remember) async {
    _sessionOnly = !remember;
    if (!remember) {
      await _storage.deleteAll();
      return;
    }
    final access = _memoryCache[_accessKey];
    final refresh = _memoryCache[_refreshKey];
    if (access == null || refresh == null) return;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    for (final key in [_userIdKey, _userEmailKey, _userNameKey]) {
      final value = _memoryCache[key];
      if (value != null) await _storage.write(key: key, value: value);
    }
  }

  Future<void> deleteAll() async {
    _memoryCache.clear();
    _sessionOnly = false;
    await _storage.deleteAll();
  }
}

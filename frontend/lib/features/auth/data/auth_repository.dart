import '../../../core/api/api_client.dart';
import '../../../core/auth/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  final _dio = ApiClient.dio;
  final _storage = TokenStorage();

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _storage.deleteAll();
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await _persist(auth);
    return auth;
  }

  Future<void> _persist(AuthResponse auth) => _storage.persist(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
}

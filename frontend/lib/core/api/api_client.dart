import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class ApiClient {
  static const _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static final _tokenStorage = TokenStorage();

  static final Dio dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final token = await _tokenStorage.readAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final retry = await dio.fetch(error.requestOptions);
              return handler.resolve(retry);
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '$_baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await _tokenStorage.persist(
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

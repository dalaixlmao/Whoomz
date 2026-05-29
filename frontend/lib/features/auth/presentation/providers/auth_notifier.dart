import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/providers.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.loading = false,
  });

  final AuthStatus status;
  final UserInfo? user;
  final String? error;
  final bool loading;

  AuthState copyWith({
    AuthStatus? status,
    UserInfo? user,
    String? error,
    bool? loading,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
        loading: loading ?? this.loading,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  static const _onboardedKey = 'whoomz.onboarded';
  static const _userNameKey = 'whoomz.userName';

  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> _init() async {
    final token = await _storage.readAccessToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_userNameKey) ?? 'You';
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserInfo(id: '', email: '', name: name),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _repo.signup(name: name, email: email, password: password);
      await _persistUser(res);
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? (data['detail'] as String?) : null;
      state = state.copyWith(loading: false, error: msg ?? 'Sign up failed');
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await _repo.login(email: email, password: password);
      await _persistUser(res);
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? (data['detail'] as String?) : null;
      state = state.copyWith(loading: false, error: msg ?? 'Login failed');
      return false;
    }
  }

  Future<void> logout() async {
    try { await _repo.logout(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardedKey);
    state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
  }

  Future<void> _persistUser(AuthResponse res) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, res.user.name ?? 'You');
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: res.user,
      loading: false,
    );
  }

  Future<bool> get isOnboarded async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  Future<void> completeOnboarding(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
    await prefs.setString(_userNameKey, name);
    state = state.copyWith(
      user: UserInfo(id: state.user?.id ?? '', email: state.user?.email ?? '', name: name),
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

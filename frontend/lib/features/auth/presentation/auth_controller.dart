import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_models.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserInfo?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<UserInfo?> {
  @override
  Future<UserInfo?> build() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readAccessToken();
    if (token == null) return null;
    final user = await storage.readUser();
    if (user == null) return null;
    return UserInfo(id: user.id, email: user.email, name: user.name);
  }

  Future<void> signIn({required String email, required String password}) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    await _persist(auth);
    state = AsyncData(auth.user);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .signup(name: name, email: email, password: password);
    await _persist(auth);
    state = AsyncData(auth.user);
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Local sign-out proceeds even if the server call fails.
    }
    await ref.read(tokenStorageProvider).deleteAll();
    state = const AsyncData(null);
  }

  Future<void> _persist(AuthResponse auth) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.persist(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await storage.persistUser(
      id: auth.user.id,
      email: auth.user.email,
      name: auth.user.name,
    );
  }
}

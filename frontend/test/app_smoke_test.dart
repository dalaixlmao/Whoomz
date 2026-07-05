import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whoomz/core/auth/token_storage.dart';
import 'package:whoomz/core/providers.dart';
import 'package:whoomz/main.dart';

class _EmptyStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<({String id, String email, String? name})?> readUser() async => null;
}

void main() {
  testWidgets('boots to the auth screen with no stored session', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_EmptyStorage())],
        child: const WhoomzApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Whoomz'), findsOneWidget);
    expect(find.text('Conversation-first fitness.'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });
}

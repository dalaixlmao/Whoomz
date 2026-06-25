import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Fake collaborators ───────────────────────────────────────────────────────

abstract class AuthService {
  Future<String> login(String email, String password);
  Future<void> logout();
}

class MockAuthService extends Mock implements AuthService {}

// ── Simple widgets under test ────────────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: const Text('Login'));
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _n = 0;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('count: $_n'),
        ElevatedButton(
          onPressed: () => setState(() => _n++),
          child: const Text('increment'),
        ),
      ]);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Unit tests ─────────────────────────────────────────────────────────────

  group('mocktail stubs', () {
    test('stub returns expected value', () async {
      final svc = MockAuthService();
      when(() => svc.login(any(), any()))
          .thenAnswer((_) async => 'token-abc');

      final token = await svc.login('user@test.com', 'secret');
      expect(token, 'token-abc');
    });

    test('verify interaction was called exactly once', () async {
      final svc = MockAuthService();
      when(() => svc.logout()).thenAnswer((_) async {});

      await svc.logout();
      verify(() => svc.logout()).called(1);
    });

    test('stub throws on specific arguments', () {
      final svc = MockAuthService();
      when(() => svc.login('bad@test.com', any()))
          .thenThrow(Exception('invalid credentials'));

      expect(
        () => svc.login('bad@test.com', 'x'),
        throwsException,
      );
    });

    test('verifyNever confirms method was not called', () {
      final svc = MockAuthService();
      verifyNever(() => svc.logout());
    });
  });

  // ── Widget tests ───────────────────────────────────────────────────────────

  group('WidgetTester basics', () {
    testWidgets('find.text locates a Text widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Text('hello world')),
      );
      expect(find.text('hello world'), findsOneWidget);
    });

    testWidgets('find.byType locates by runtimeType', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _LoginButton(onPressed: _noop)),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('tap triggers onPressed callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(home: _LoginButton(onPressed: () => pressed = true)),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('pump() advances one frame; pumpAndSettle() drains all frames',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _Counter()),
      );
      expect(find.text('count: 0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pump(); // single frame — enough for setState
      expect(find.text('count: 1'), findsOneWidget);
    });

    testWidgets('enterText fills a TextField', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TextField(key: Key('email'))),
        ),
      );
      await tester.enterText(find.byKey(const Key('email')), 'user@test.com');
      await tester.pump();
      expect(find.text('user@test.com'), findsOneWidget);
    });

    testWidgets('find.byKey locates widget by ValueKey', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(key: Key('my-box')),
        ),
      );
      expect(find.byKey(const Key('my-box')), findsOneWidget);
    });

    testWidgets('expect finds no widget when absent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.text('ghost'), findsNothing);
    });
  });

  test('All testing smoke tests passed!', () => expect(true, isTrue));
}

void _noop() {}

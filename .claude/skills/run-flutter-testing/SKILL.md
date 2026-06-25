---
name: run-flutter-testing
description: Run, test, and smoke-check Flutter unit & widget testing — flutter_test, WidgetTester, pump() vs pumpAndSettle(), find finders (text/type/key), mocking with mocktail (stub/verify/verifyNever), tap/enterText interactions. Use when asked to run Flutter tests, verify test patterns, check mocktail stubs, or exercise WidgetTester interactions.
---

Flutter 3.44.0 + `mocktail ^1.0.4` (both already in this project's pubspec). Runs headlessly via `flutter test` — no device needed.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-testing/smoke_test.dart --reporter expanded
```

Expected output (11 tests, under 2 seconds):

```
00:00 +0: mocktail stubs stub returns expected value
00:00 +1: mocktail stubs verify interaction was called exactly once
00:00 +2: mocktail stubs stub throws on specific arguments
00:00 +3: mocktail stubs verifyNever confirms method was not called
00:00 +4: WidgetTester basics find.text locates a Text widget
00:00 +5: WidgetTester basics find.byType locates by runtimeType
00:00 +6: WidgetTester basics tap triggers onPressed callback
00:00 +7: WidgetTester basics pump() advances one frame; pumpAndSettle() drains all frames
00:00 +8: WidgetTester basics enterText fills a TextField
00:00 +9: WidgetTester basics find.byKey locates widget by ValueKey
00:00 +10: WidgetTester basics expect finds no widget when absent
00:00 +11: All testing smoke tests passed!
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| stub returns expected value | `when(() => mock.method()).thenAnswer(...)` |
| verify interaction once | `verify(() => mock.method()).called(1)` |
| stub throws | `thenThrow`, exception matching |
| verifyNever | `verifyNever()`, absence assertion |
| find.text | `find.text`, `findsOneWidget` |
| find.byType | `find.byType`, `findsOneWidget` |
| tap onPressed | `tester.tap`, `pump()`, side-effect check |
| pump vs pumpAndSettle | single frame vs drain-all-frames |
| enterText | `tester.enterText`, text field input |
| find.byKey | `find.byKey`, `ValueKey` / `Key` |
| finds nothing | `findsNothing` |

## Key patterns

### Mock class setup
```dart
import 'package:mocktail/mocktail.dart';

abstract class UserRepository {
  Future<User> findById(String id);
}

class MockUserRepository extends Mock implements UserRepository {}
```

### Stub with matchers
```dart
final repo = MockUserRepository();

// any() matches any argument
when(() => repo.findById(any())).thenAnswer((_) async => fakeUser);

// specific argument
when(() => repo.findById('uid-42')).thenAnswer((_) async => specificUser);

// throw
when(() => repo.findById('bad')).thenThrow(NotFoundException());
```

### Verify call counts
```dart
verify(() => repo.findById('uid-42')).called(1);
verifyNever(() => repo.findById('other'));
```

### Widget test structure
```dart
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: MyWidget()),
  );

  // find
  expect(find.text('Submit'), findsOneWidget);

  // interact
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump(); // re-render

  // assert result
  expect(find.text('Done'), findsOneWidget);
});
```

### pump() vs pumpAndSettle()
```dart
// pump() — one frame; use after setState, tap, or to step through an animation
await tester.pump();

// pump(duration) — advance clock by duration
await tester.pump(const Duration(milliseconds: 300));

// pumpAndSettle() — keeps pumping until no more pending frames (animations done)
// WARNING: hangs forever if an infinite animation is running
await tester.pumpAndSettle();
```

### Finders
```dart
find.text('Login')                    // exact text match
find.textContaining('Log')           // substring
find.byType(ElevatedButton)          // runtimeType
find.byKey(const Key('submit-btn'))  // ValueKey / ObjectKey
find.byWidget(specificInstance)      // identical reference
find.descendant(of: find.byType(Card), matching: find.byType(Text))
find.ancestor(of: find.text('x'), matching: find.byType(ListTile))
```

### Matcher shortcuts
```dart
findsOneWidget      // exactly 1
findsNothing        // 0
findsNWidgets(3)    // exactly N
findsAny            // ≥ 1 (Flutter 3.3+)
findsAtLeastNWidgets(2)
```

## Gotchas

- `mocktail` (unlike `mockito`) requires no code generation. Declare `class MockFoo extends Mock implements Foo {}` and use it immediately.
- `thenAnswer` receives an `Invocation` and must return the correct type — use `(_) async => value` for `Future`-returning methods.
- `pump()` after `tap()` is almost always needed. `tap()` does not re-render; it only dispatches the gesture event. The `setState` or stream update that follows needs a frame.
- `pumpAndSettle()` will timeout (default 100 frames) if an animation loops forever. For infinite animations, use `pump(duration)` instead.
- `find.text` matches the `data` property of `Text` widgets, not `RichText` spans. Use `find.byWidgetPredicate` for `RichText`.
- When testing widgets that use `context.read<X>()` or `Provider.of<X>()`, wrap with the appropriate `ProviderScope` or `Provider` ancestor.

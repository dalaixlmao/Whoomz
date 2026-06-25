---
name: run-flutter-integration-testing
description: Reference and code-generation skill for Flutter integration testing — integration_test package, running on real devices/emulators, WidgetTester in integration context, finding and interacting with real widgets, taking screenshots, and patrol for native interactions. Use when writing end-to-end tests, automating a real device smoke test, or verifying a full user flow.
---

`integration_test` ships with the Flutter SDK — no extra pub dependency needed. Add it to `pubspec.yaml` as a dev dependency:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

## File structure

```
integration_test/
  app_test.dart          # integration test entry point
test_driver/
  integration_test.dart  # test driver (boilerplate, rarely changed)
```

## test_driver/integration_test.dart (boilerplate)

```dart
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();
```

## integration_test/app_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whoomz/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login flow', () {
    testWidgets('user can sign in and reach home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Type credentials
      await tester.enterText(find.byKey(const Key('email-field')), 'test@whoomz.com');
      await tester.enterText(find.byKey(const Key('password-field')), 'Test1234!');
      await tester.tap(find.byKey(const Key('login-button')));

      // Wait for navigation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byKey(const Key('home-screen')), findsOneWidget);
    });
  });
}
```

## Run on a connected device or simulator

```bash
# List available devices
~/flutter/bin/flutter devices

# Run integration tests on a specific device
~/flutter/bin/flutter test integration_test/app_test.dart \
  --device-id <device-id>

# Run all integration tests
~/flutter/bin/flutter test integration_test/ --device-id <device-id>
```

## Run headlessly (Chrome / web)

```bash
~/flutter/bin/flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

## Take a screenshot during test

```dart
import 'package:integration_test/integration_test.dart';

final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

testWidgets('screenshot home screen', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  await binding.takeScreenshot('home_screen');
});
```

## Patrol — native interactions (optional)

`patrol` extends integration tests to tap native UI (system alerts, notifications, permissions dialogs):

```bash
~/flutter/bin/flutter pub add --dev patrol
dart run patrol bootstrap  # sets up native runners
```

```dart
import 'package:patrol/patrol.dart';

patrolTest('grants camera permission', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(#cameraButton).tap();
  await $.native.grantPermissionWhenInUse(); // taps native iOS dialog
});
```

## Key differences from unit/widget tests

| Aspect | Widget test | Integration test |
|---|---|---|
| Environment | Dart VM, fake renderer | Real device, real Flutter engine |
| Speed | ~100 ms | ~10–60 s |
| Network | Stubbed (mocktail) | Real (or proxied) |
| Native code | `setMockMethodCallHandler` | Real plugins run |
| Use case | Component correctness | Full user flow, E2E |

## Gotchas

- `pumpAndSettle` in integration tests can time out if network calls take too long — pass a generous timeout: `pumpAndSettle(const Duration(seconds: 10))`.
- Tag integration tests in CI with a separate job — they need a device/emulator attached and are slow. Don't run them on every PR; run on merge to main or nightly.
- `app.main()` boots the real app — ensure test data / env vars are set correctly. Use a separate `--dart-define=ENV=test` flag and branch inside `main()` to load a test configuration.
- `find.byKey` is the most reliable finder in integration tests — text can change with i18n, types are fragile. Add `Key` annotations to important interactive widgets.
- Flakiness is common in integration tests due to timing. Prefer `pumpAndSettle` over fixed `pump(duration)` sleeps; use `patrol` for retryable taps on native elements.

---
name: run-flutter-platform-channels
description: Run, test, and smoke-check Flutter platform channels — MethodChannel (invoke/mock), EventChannel, BasicMessageChannel, PlatformException handling, and mock-handler setup in flutter_test. Use when asked to run platform channel tests, verify native method mocking, test PlatformException propagation, or exercise MethodChannel argument passing.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. Platform channel tests run in the Dart VM via `flutter test` — the `TestDefaultBinaryMessengerBinding` lets you mock native responses without any iOS/Android code.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-platform-channels/smoke_test.dart --reporter expanded
```

Expected output (7 tests, under 2 seconds):

```
00:00 +0: MethodChannel invokeMethod returns mocked int result
00:00 +1: MethodChannel invokeMethod returns mocked string result
00:00 +2: MethodChannel PlatformException propagates from native side
00:00 +3: MethodChannel invokeMethod with arguments passes args correctly
00:00 +4: EventChannel EventChannel name is set correctly
00:00 +5: EventChannel BasicMessageChannel round-trips a string
00:00 +6: All platform-channel smoke tests passed!
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| invokeMethod returns int | `MethodChannel`, mock handler, typed return |
| invokeMethod returns string | Type-parameterised `invokeMethod<String>` |
| PlatformException propagates | `PlatformException`, code/message |
| invokeMethod with arguments | Argument map passing, `call.arguments` |
| EventChannel name | `EventChannel` construction |
| BasicMessageChannel round-trip | `BasicMessageChannel`, `StringCodec`, echo |

## Key patterns

### MethodChannel (Dart → native call)
```dart
// lib/core/platform/battery_channel.dart
class BatteryChannel {
  static const _channel = MethodChannel('com.whoomz/battery');

  Future<int> getBatteryLevel() async {
    try {
      return await _channel.invokeMethod<int>('getBatteryLevel') ?? -1;
    } on PlatformException catch (e) {
      throw Exception('Battery unavailable: ${e.message}');
    }
  }
}
```

### Native side — iOS (Swift)
```swift
// AppDelegate.swift
let channel = FlutterMethodChannel(name: "com.whoomz/battery",
                                   binaryMessenger: controller.binaryMessenger)
channel.setMethodCallHandler { (call, result) in
  if call.method == "getBatteryLevel" {
    result(UIDevice.current.batteryLevel * 100)
  } else {
    result(FlutterMethodNotImplemented)
  }
}
```

### Native side — Android (Kotlin)
```kotlin
// MainActivity.kt
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.whoomz/battery")
  .setMethodCallHandler { call, result ->
    if (call.method == "getBatteryLevel") {
      result.success(getBatteryLevel())
    } else {
      result.notImplemented()
    }
  }
```

### EventChannel (native → Dart stream)
```dart
// Dart
class SensorChannel {
  static const _channel = EventChannel('com.whoomz/heart-rate');

  Stream<int> get heartRateStream =>
      _channel.receiveBroadcastStream().map((e) => e as int);
}

// Usage
sensorChannel.heartRateStream.listen((bpm) => print('BPM: $bpm'));
```

### Mocking channels in tests
```dart
setUp(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getBatteryLevel') return 90;
    throw PlatformException(code: 'NOT_FOUND');
  });
});

tearDown(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null); // always clean up
});
```

## Gotchas

- Always call `TestWidgetsFlutterBinding.ensureInitialized()` at the top of test files that set mock handlers (non-widget tests don't call `pumpWidget` which normally does this).
- `invokeMethod` returns `Future<T?>` — the native side can return `null` for not-implemented. Handle gracefully with `?? fallback`.
- `PlatformException` carries `code`, `message`, and optional `details`. Log all three — the `code` is your switch key for error handling.
- `EventChannel` streams on the Dart side are broadcast streams (`receiveBroadcastStream`). Don't `await` them — `listen()` or `StreamBuilder` only.
- Passing complex objects across the channel requires types supported by the `StandardMessageCodec`: `null`, `bool`, `int`, `double`, `String`, `Uint8List`, `List`, `Map`. Serialize custom objects to a `Map<String, dynamic>` on both sides.
- Channel names are global strings — use a reverse-domain prefix (`com.yourapp/feature`) to avoid collisions with plugins.

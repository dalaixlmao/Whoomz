---
name: run-flutter-responsive
description: Run, test, and smoke-check Flutter responsive & adaptive UI — LayoutBuilder, MediaQuery (size, orientation, textScaler), SafeArea, platform detection via Theme.of().platform, FractionallySizedBox, and breakpoint switching. Use when asked to run responsive layout tests, verify breakpoint behaviour, check safe-area insets, or exercise adaptive widget rendering.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill drives responsive primitives via `flutter test` — no device needed. Tests run headlessly in the Dart VM; `MediaQueryData` is injected directly to simulate any screen size, orientation, or inset.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-responsive/smoke_test.dart --reporter expanded
```

Expected output (8 tests, under 1 second):

```
00:00 +0: LayoutBuilder exposes parent constraints
00:00 +1: LayoutBuilder can switch layout at a breakpoint
00:00 +2: MediaQuery.of returns screen size
00:00 +3: MediaQuery textScaler reflects text scale factor
00:00 +4: SafeArea pads child away from system insets
00:00 +5: Platform.isIOS detection via Theme.of().platform
00:00 +6: Orientation can be simulated via MediaQuery
00:00 +7: FractionallySizedBox sizes relative to parent
00:00 +8: All responsive smoke tests passed!
```

To run a single test:

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-responsive/smoke_test.dart --name 'breakpoint'
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| LayoutBuilder exposes parent constraints | `LayoutBuilder`, `BoxConstraints.maxWidth/maxHeight` |
| LayoutBuilder can switch layout at a breakpoint | Breakpoint pattern, 600 dp mobile/tablet split |
| MediaQuery.of returns screen size | `MediaQuery.sizeOf(context)` |
| MediaQuery textScaler reflects text scale factor | `MediaQuery.textScalerOf`, `TextScaler.linear` |
| SafeArea pads child away from system insets | `SafeArea`, `MediaQueryData.padding` |
| Platform.isIOS via Theme.of().platform | `Theme.of(ctx).platform`, `TargetPlatform` |
| Orientation can be simulated via MediaQuery | `MediaQuery.orientationOf`, `Orientation.landscape` |
| FractionallySizedBox sizes relative to parent | `FractionallySizedBox`, `widthFactor`/`heightFactor` |

## Key patterns

### Breakpoint helper
```dart
enum Breakpoint { mobile, tablet, desktop }

Breakpoint breakpointOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return Breakpoint.mobile;
  if (w < 1200) return Breakpoint.tablet;
  return Breakpoint.desktop;
}
```

### LayoutBuilder for local constraints
```dart
// Use LayoutBuilder when you need the *parent's* constraints, not the screen size.
// MediaQuery gives the full screen; LayoutBuilder gives the widget's own slot.
LayoutBuilder(builder: (_, constraints) {
  return constraints.maxWidth > 600
      ? const _WideLayout()
      : const _NarrowLayout();
})
```

### SafeArea + notch/home-bar
```dart
Scaffold(
  body: SafeArea(
    minimum: const EdgeInsets.symmetric(horizontal: 16),
    child: ...,
  ),
)
```

### Platform-adaptive widget
```dart
Widget buildSwitch(BuildContext context) {
  // Switch.adaptive renders CupertinoSwitch on iOS/macOS, Material Switch elsewhere
  return Switch.adaptive(value: _on, onChanged: _toggle);
}
```

### Simulate screen sizes in tests
```dart
await tester.pumpWidget(
  MediaQuery(
    data: const MediaQueryData(size: Size(375, 812)), // iPhone 14
    child: const MaterialApp(home: MyScreen()),
  ),
);
```

## Gotchas

- `MediaQuery.sizeOf(context)` (Flutter 3.10+) is more efficient than `MediaQuery.of(context).size` — it only rebuilds when the size changes, not on every `MediaQuery` property update.
- `LayoutBuilder` is called during layout, not in `build`. Avoid calling `setState` inside its builder.
- `SafeArea` reads `MediaQuery.of(context).padding`. In tests inject `MediaQueryData(padding: ...)` to simulate notch/home-bar insets.
- `Theme.of(ctx).platform` is the idiomatic Flutter way to branch on platform in widget code. Avoid `dart:io` `Platform.isIOS` in UI code — it breaks on web and is harder to override in tests.
- `tester.binding.window.physicalSizeTestValue` (deprecated) → use a wrapping `MediaQuery` widget in new tests instead.

---
name: run-flutter-theming
description: Run, test, and smoke-check Flutter Material 3 & Cupertino theming — ThemeData, ColorScheme.fromSeed, dark mode, adaptive widgets (Switch.adaptive, AlertDialog.adaptive), CupertinoThemeData. Use when asked to run theming tests, verify dark mode, check ColorScheme roles, or exercise platform-adaptive widget behaviour.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill drives Flutter as a library via `flutter test` — no device, no simulator needed. The driver is a widget test file in this skill directory that runs headlessly in the Dart VM with a fake render tree.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-theming/smoke_test.dart --reporter expanded
```

Expected output (runs in under 1 second):

```
00:00 +0: useMaterial3: true is reflected in Theme.of
00:00 +1: ColorScheme.fromSeed produces a non-null palette
00:00 +2: ThemeMode.dark switches ColorScheme brightness to dark
00:00 +3: Theme.of reads the nearest ancestor ThemeData
00:00 +4: ElevatedButton background comes from colorScheme.primary
00:00 +5: Switch.adaptive renders without error
00:00 +6: CupertinoThemeData: primaryColor is accessible via CupertinoTheme.of
00:00 +7: showAdaptiveDialog renders AlertDialog on Material host
00:00 +8: Theme.of.textTheme.displayLarge has a non-null fontSize
00:00 +9: All tests passed!
```

To test a specific concept, pass `--name` with a substring:

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-theming/smoke_test.dart --name 'dark'
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| useMaterial3: true is reflected in Theme.of | `ThemeData(useMaterial3: true)` |
| ColorScheme.fromSeed produces a non-null palette | `ColorScheme.fromSeed`, M3 color roles |
| ThemeMode.dark switches ColorScheme brightness | `darkTheme`, `ThemeMode.dark`, `Brightness.dark` |
| Theme.of reads the nearest ancestor ThemeData | `Theme` widget, InheritedWidget lookup, theme override |
| ElevatedButton background comes from colorScheme.primary | M3 component theming |
| Switch.adaptive renders without error | `Switch.adaptive`, platform-adaptive widgets |
| CupertinoThemeData: primaryColor via CupertinoTheme.of | `CupertinoApp`, `CupertinoThemeData`, `CupertinoTheme.of` |
| showAdaptiveDialog renders AlertDialog on Material host | `showAdaptiveDialog`, `AlertDialog.adaptive` |
| Theme.of.textTheme.displayLarge has a non-null fontSize | M3 type scale, `TextTheme` |

## Prerequisites

No installs beyond the existing Flutter SDK. Run `~/flutter/bin/flutter pub get` if packages are missing.

## Run (full test suite)

```bash
~/flutter/bin/flutter test --reporter expanded
```

## Gotchas

- `flutter test` prints two Swift Package Manager warnings about `flutter_secure_storage` to stderr on every run — this is noise, not an error.
- `ColorScheme.fromSeed` derives the full M3 tonal palette from one seed color. The generated colors are deterministic but may not match your intuition — always read the palette from `Theme.of(context).colorScheme`, never hardcode hex values for M3 roles.
- `ThemeMode.system` in widget tests resolves to `ThemeMode.light` because the test environment has no platform brightness signal. Use `ThemeMode.dark` explicitly to test dark mode paths.
- `Switch.adaptive` renders a `CupertinoSwitch` on iOS/macOS and a Material `Switch` elsewhere. In widget tests (host = Linux/macOS desktop), it renders the Material variant. Use `find.byType(Switch)` to locate it.
- `showAdaptiveDialog` picks `CupertinoAlertDialog` when `Theme.of(context).platform` is `TargetPlatform.iOS` or `TargetPlatform.macOS`. Widget tests default to the host OS platform, so on a macOS dev machine it may render Cupertino — wrap the test app in `Theme(data: ThemeData(platform: TargetPlatform.android))` to force Material.
- `CupertinoApp` and `MaterialApp` maintain separate theme trees. `Theme.of` throws inside a pure `CupertinoApp`; use `CupertinoTheme.of` there instead.

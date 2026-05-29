---
name: run-flutter-widgets
description: Run, test, and smoke-check Flutter widget tree concepts — StatelessWidget, StatefulWidget, BuildContext, Keys, widget lifecycle (initState/dispose), and element tree internals. Use when asked to run Flutter widget tests, verify widget behaviour, or exercise Flutter SDK internals.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill drives Flutter as a library via `flutter test` — no device, no simulator needed. The driver is a widget test file in this skill directory that runs headlessly in the Dart VM with a fake render tree.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-widgets/smoke_test.dart --reporter expanded
```

Expected output (runs in under 1 second):

```
00:00 +0: StatelessWidget renders from props
00:00 +1: StatefulWidget: initState called, setState updates UI
00:00 +2: dispose is called when widget leaves the tree
00:00 +3: BuildContext carries inherited data (Theme.of)
00:00 +4: ValueKey preserves State identity across list reorder
00:00 +5: element tree: widget, element, renderObject are distinct layers
00:00 +6: All tests passed!
```

To test a specific concept in isolation, pass `--name` with a substring of the test description:

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-widgets/smoke_test.dart --name 'dispose'
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| StatelessWidget renders from props | `StatelessWidget.build`, `const` constructor |
| StatefulWidget: initState called, setState updates UI | `StatefulWidget`, `State`, `initState`, `setState` |
| dispose is called when widget leaves the tree | `dispose` lifecycle, widget removal |
| BuildContext carries inherited data (Theme.of) | `BuildContext`, `InheritedWidget` lookup via `Theme.of` |
| ValueKey preserves State identity across list reorder | `Key`, `ValueKey`, element-tree identity |
| element tree: widget, element, renderObject are distinct layers | `Element`, `RenderObject`, three-tree architecture |

## Prerequisites

No installs beyond the existing Flutter SDK. Run `~/flutter/bin/flutter pub get` if packages are missing.

## Run (full test suite)

```bash
~/flutter/bin/flutter test --reporter expanded
```

## Gotchas

- `flutter test` prints two Swift Package Manager warnings about `flutter_secure_storage` to stderr on every run — this is noise, not an error.
- `GlobalKey<StateType>` is the only way to reach a `State` object from a test for direct method calls. Using `tester.state<T>(finder)` is fine for read-only access.
- `identical(stateA, stateB)` (not `==`) is the right check for element identity across rebuilds — Dart's default `==` on `State` falls back to `identical` anyway, but being explicit avoids confusion.
- Widget tests run in a fake async zone. Call `await tester.pump()` after any `setState` or you will not see UI updates.
- `tester.element(finder)` returns the `Element`, not the `Widget`. Access the widget via `element.widget` and the render object via `element.renderObject`.

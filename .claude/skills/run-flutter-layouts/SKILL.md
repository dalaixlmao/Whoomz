---
name: run-flutter-layouts
description: Run, test, and smoke-check Flutter layout widgets — Row, Column, Stack, Flex, SliverList, CustomScrollView, and the constraints model. Use when asked to run Flutter layout tests, verify layout behaviour, test constraint propagation, or exercise sliver widgets.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill drives Flutter layout primitives via `flutter test` — no device needed. The driver is a widget test file that runs headlessly in the Dart VM with a fake render tree.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-layouts/smoke_test.dart --reporter expanded
```

Expected output (9 tests, under 1 second):

```
00:00 +0: Row lays children out horizontally
00:00 +1: Column lays children out vertically
00:00 +2: Stack overlaps children at the same origin by default
00:00 +3: Positioned inside Stack offsets child from stack origin
00:00 +4: Flex with Expanded distributes remaining space
00:00 +5: SizedBox imposes tight constraints on its child
00:00 +6: Center passes loose constraints to its child
00:00 +7: SliverList inside CustomScrollView renders items lazily
00:00 +8: SliverAppBar collapses on scroll
00:00 +9: All tests passed!
```

To run a single test by name:

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-layouts/smoke_test.dart --name 'Flex'
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| Row lays children out horizontally | `Row` — children advance on the X axis, share Y origin |
| Column lays children out vertically | `Column` — children advance on the Y axis, share X origin |
| Stack overlaps children at the same origin | `Stack` — all children at topStart by default |
| Positioned inside Stack offsets child | `Positioned` — `left`/`top` offset from stack's top-left |
| Flex with Expanded distributes remaining space | `Flex(direction: Axis.horizontal)` + `Expanded` fills leftover width |
| SizedBox imposes tight constraints on its child | Constraints model — tight means minWidth==maxWidth; verified via `LayoutBuilder` |
| Center passes loose constraints to its child | Constraints model — `Center` sets minWidth=0/minHeight=0 regardless of its own constraints |
| SliverList renders items lazily | `SliverList` + `SliverChildBuilderDelegate` — item 29 absent before scroll, present after |
| SliverAppBar collapses on scroll | `CustomScrollView` + `SliverAppBar(pinned:true)` — height shrinks after drag |

## Gotchas

- **`SliverAppBar`'s render object is `_RenderSliverPinnedPersistentHeaderForWidgets`**, not a `RenderBox`. Calling `tester.renderObject<RenderBox>(find.byType(SliverAppBar))` throws a type cast error. Measure the inner `AppBar` instead: `tester.getSize(find.byType(AppBar).first)`.
- **Tight constraints from parent override `SizedBox`** — if `SizedBox(width: 120)` is inside a parent with tight constraints at 400px, the SizedBox becomes 400px. Use `UnconstrainedBox` as a wrapper and `LayoutBuilder` to capture the constraints actually passed to the child.
- **`tester.renderObject<RenderBox>(find.byType(SizedBox))`** fails with "too many elements" when multiple `SizedBox` widgets exist in the tree (there are always some from framework internals). Always use a `Key` or more specific finder.
- **`LayoutBuilder` captures constraints at build time** — call it synchronously inside the builder; `captured` will be set after `pumpWidget` returns.
- The Swift Package Manager warning about `flutter_secure_storage` on every run is noise, not an error.

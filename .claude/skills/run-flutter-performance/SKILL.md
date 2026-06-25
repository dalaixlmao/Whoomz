---
name: run-flutter-performance
description: Run, test, and smoke-check Flutter performance patterns — compute() for background work, Isolate.run, const widgets to skip rebuilds, RepaintBoundary, lazy ListView.builder, and AutomaticKeepAliveClientMixin. Use when asked to run performance tests, verify isolate behaviour, check lazy rendering, or exercise const widget optimisation.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill exercises performance primitives via `flutter test` — no device needed. `compute()` and `Isolate.run` work in the test VM; rendering tests verify lazy build and repaint isolation.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-performance/smoke_test.dart --reporter expanded
```

Expected output (8 tests, under 5 seconds):

```
00:00 +0: compute() offloads work to a background isolate
00:00 +1: compute() can handle a string transformation
00:00 +2: Isolate.run executes closure in a background isolate
00:00 +3: Isolate.run supports async closures
00:00 +4: const widget does not rebuild parent
00:00 +5: RepaintBoundary isolates repaints
00:00 +6: ListView.builder renders items lazily
00:00 +7: AutomaticKeepAliveClientMixin keeps page alive
00:00 +8: All performance smoke tests passed!
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| compute() offloads work | `compute(fn, message)`, background isolate |
| compute() string transform | Any top-level function works with `compute` |
| Isolate.run closure | `Isolate.run(() => ...)`, no message-passing boilerplate |
| Isolate.run async | Async closures in isolates |
| const widget skips rebuild | `const` widget, Flutter element-tree diffing |
| RepaintBoundary isolates | `RepaintBoundary`, layer tree isolation |
| ListView.builder lazy | Only viewport items built |
| AutomaticKeepAliveClientMixin | PageView / TabBarView page caching |

## Key patterns

### compute() — send work off the main isolate
```dart
// Must be a top-level or static function (closures can't cross isolate boundary)
List<int> _parseLargeJson(String json) => /* heavy work */;

final result = await compute(_parseLargeJson, rawJsonString);
```

### Isolate.run — modern alternative (Dart 2.19+)
```dart
// Supports closures; no need for top-level functions
final sorted = await Isolate.run(() {
  final list = hugeList.toList();
  list.sort();
  return list;
});
```

### When to use each
| Scenario | Choice |
|---|---|
| Simple transform, already a function | `compute` |
| Closure with captured vars | `Isolate.run` |
| Long-lived background worker | `Isolate.spawn` + `SendPort` |
| JSON decode of large payload | `compute(jsonDecode, rawString)` |

### const widgets
```dart
// Good — Flutter can skip this subtree during rebuild
const Text('Static label')
const Icon(Icons.home)
const SizedBox(height: 16)
const EdgeInsets.all(16)

// Bad — new instance every build, forces diff
Text('Static label')        // no const
SizedBox(height: 16)        // no const
```

### RepaintBoundary — isolate expensive repaints
```dart
// Wrap frequently-animating subtrees so they repaint independently
RepaintBoundary(
  child: AnimatedWidget(...),  // this layer won't dirty the parent layer
)
```

### ListView.builder — lazy construction
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
  // Only items in the viewport are built. Use ListView(children:[...]) only
  // for short, fixed-length lists.
)
```

### AutomaticKeepAliveClientMixin — preserve page state
```dart
class _MyPageState extends State<MyPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required
    return const ExpensiveWidget();
  }
}
```

## DevTools profiling workflow

1. Run app in profile mode: `flutter run --profile`
2. Open DevTools: `flutter pub global run devtools` or from IDE
3. **Performance tab** → record a trace; look for long UI/GPU frames (>16ms for 60fps, >8ms for 120fps)
4. **Widget rebuild counts** → enable in DevTools → identify widgets rebuilding too often
5. **Memory tab** → look for growing heap; use `dart:developer`'s `Timeline` for custom events

## Gotchas

- `compute()` only accepts **top-level or static functions** — closures that capture variables from the enclosing scope will throw at runtime. Use `Isolate.run` for closures.
- `Isolate.run` was added in Dart 2.19 / Flutter 3.7. Check your SDK minimum if supporting older Flutter.
- `const` only compiles down to a single cached instance when the **entire** subtree has compile-time-constant arguments. One non-const descendant breaks the optimisation.
- `RepaintBoundary` adds a new compositing layer — for simple widgets that rarely animate, the overhead of an extra layer is worse than the savings. Profile before adding.
- `pumpAndSettle` hangs if a `RepeatAnimation` or infinite `AnimationController` is running inside the widget tree. Use `pump(duration)` instead.

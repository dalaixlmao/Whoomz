---
name: run-flutter-animations
description: Run, test, and smoke-check Flutter animations — AnimationController, Tween, CurvedAnimation, Hero, implicit animations (AnimatedContainer, AnimatedOpacity), and AnimatedBuilder. Use when asked to run animation tests, verify tween interpolation, check implicit animation behaviour, or exercise AnimatedBuilder rebuilds.
---

Flutter 3.44.0 at `~/flutter/bin/flutter`. This skill drives Flutter animation primitives via `flutter test` — no device or simulator needed. Tests run headlessly in the Dart VM with a fake render tree and a synthetic vsync ticker.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-animations/smoke_test.dart --reporter expanded
```

Expected output (9 tests, under 1 second):

```
00:00 +0: AnimationController drives value from 0.0 to 1.0
00:00 +1: Tween<double> lerps between begin and end
00:00 +2: ColorTween interpolates between two colors
00:00 +3: TweenAnimationBuilder drives child through full range
00:00 +4: AnimatedContainer transitions width smoothly
00:00 +5: Hero widget exists in the tree with correct tag
00:00 +6: AnimatedBuilder rebuilds on controller tick
00:00 +7: CurvedAnimation applies easeIn curve
00:00 +8: AnimatedOpacity fades child to target opacity
00:00 +9: All animation smoke tests passed!
```

To run a single test:

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-animations/smoke_test.dart --name 'Tween'
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| AnimationController drives value from 0.0 to 1.0 | `AnimationController`, `SingleTickerProviderStateMixin`, `forward()` |
| Tween<double> lerps between begin and end | `Tween`, `lerp()`, linear interpolation |
| ColorTween interpolates between two colors | `ColorTween`, color interpolation |
| TweenAnimationBuilder drives child through full range | `TweenAnimationBuilder`, builder callback |
| AnimatedContainer transitions width smoothly | Implicit animation, `AnimatedContainer` |
| Hero widget exists in the tree with correct tag | `Hero`, shared-element transitions, `tag` |
| AnimatedBuilder rebuilds on controller tick | `AnimatedBuilder`, `Listenable`-driven rebuilds |
| CurvedAnimation applies easeIn curve | `CurvedAnimation`, `Curves.easeIn`, non-linear time |
| AnimatedOpacity fades child to target opacity | `AnimatedOpacity`, implicit fade |

## Key concepts

### AnimationController + Tween
```dart
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(ms: 400));
    _anim = Tween<double>(begin: 0.0, end: 200.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose(); // always dispose
    super.dispose();
  }
}
```

### AnimatedBuilder
```dart
AnimatedBuilder(
  animation: _ctrl,
  builder: (context, child) => Transform.rotate(
    angle: _ctrl.value * 2 * pi,
    child: child,          // child is built once, not on every tick
  ),
  child: const Icon(Icons.refresh),
)
```

### Hero transition
```dart
// Page A
Hero(tag: 'profile-pic', child: CircleAvatar(...))

// Page B — same tag causes a shared-element flight between pages
Hero(tag: 'profile-pic', child: Image.network(...))
```

### Implicit animations (no controller needed)
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: _expanded ? 300 : 100,
  color: _active ? Colors.blue : Colors.grey,
)

AnimatedOpacity(opacity: _visible ? 1.0 : 0.0, duration: 200.ms)
AnimatedSlide(offset: _hidden ? const Offset(0, 1) : Offset.zero, duration: 200.ms)
```

### Lottie (not in this project's pubspec — add if needed)
```yaml
dependencies:
  lottie: ^3.0.0
```
```dart
import 'package:lottie/lottie.dart';
Lottie.asset('assets/loading.json', repeat: true)
```

## Gotchas

- `AnimationController` requires a `TickerProvider` (`vsync`). Use `SingleTickerProviderStateMixin` for one controller, `TickerProviderStateMixin` for multiple.
- Always `dispose()` an `AnimationController` in `dispose()` — it holds a native timer.
- In widget tests, the framework uses a synthetic vsync; call `tester.pumpAndSettle()` to advance all animations to completion. Use `tester.pump(duration)` to advance by a specific time slice.
- `CurvedAnimation` at `t=0.5` with `Curves.easeIn` returns a value _less_ than 0.5 — the curve is slow at the start. Use `Curves.easeOut` for slow at the end, `Curves.easeInOut` for both.
- `Hero` animations only fire during route transitions. Inside a single `MaterialApp` with `Navigator`, wrap the destination in a new `Route` — they will not animate if both pages are simultaneously in the widget tree.
- `TweenAnimationBuilder` is fire-and-forget — it cannot be reversed or paused. Use an explicit `AnimationController` when you need bidirectional or repeating control.

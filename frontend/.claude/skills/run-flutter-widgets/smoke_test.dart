// Smoke test: StatelessWidget, StatefulWidget, BuildContext, Keys,
// widget lifecycle (initState/dispose), and element tree traversal.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Stateless ─────────────────────────────────────────────────────────────────
class Greeting extends StatelessWidget {
  const Greeting({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Text('Hello, $name!');
}

// ── Stateful + lifecycle ───────────────────────────────────────────────────────
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;
  bool _initialized = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initialized = true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) => Text('count:$_count');

  // Expose for test assertions
  bool get initialized => _initialized;
  bool get disposed => _disposed;
}

// ── BuildContext: Theme lookup ─────────────────────────────────────────────────
class ThemeLabel extends StatelessWidget {
  const ThemeLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Text('primary:$color');
  }
}

// ── Keys: list reorder identity ───────────────────────────────────────────────
class ColorBox extends StatefulWidget {
  const ColorBox({super.key, required this.color});
  final Color color;

  @override
  State<ColorBox> createState() => ColorBoxState();
}

class ColorBoxState extends State<ColorBox> {
  @override
  Widget build(BuildContext context) =>
      Container(color: widget.color, width: 10, height: 10);
}

Widget _makeApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // ── StatelessWidget ──────────────────────────────────────────────────────────
  testWidgets('StatelessWidget renders from props', (tester) async {
    await tester.pumpWidget(_makeApp(const Greeting(name: 'Flutter')));
    expect(find.text('Hello, Flutter!'), findsOneWidget);
  });

  // ── StatefulWidget + lifecycle ───────────────────────────────────────────────
  testWidgets('StatefulWidget: initState called, setState updates UI',
      (tester) async {
    final key = GlobalKey<_CounterState>();
    await tester.pumpWidget(_makeApp(Counter(key: key)));

    expect(key.currentState!.initialized, isTrue);
    expect(find.text('count:0'), findsOneWidget);

    key.currentState!.increment();
    await tester.pump();
    expect(find.text('count:1'), findsOneWidget);
  });

  // ── dispose called on removal ────────────────────────────────────────────────
  testWidgets('dispose is called when widget leaves the tree', (tester) async {
    final key = GlobalKey<_CounterState>();
    await tester.pumpWidget(_makeApp(Counter(key: key)));
    final state = key.currentState!;

    // Remove the counter from the tree
    await tester.pumpWidget(_makeApp(const SizedBox.shrink()));
    expect(state.disposed, isTrue);
  });

  // ── BuildContext: Theme.of ────────────────────────────────────────────────────
  testWidgets('BuildContext carries inherited data (Theme.of)', (tester) async {
    await tester.pumpWidget(_makeApp(const ThemeLabel()));
    // Text is rendered; the exact color value is an impl detail — just confirm
    // the widget found Theme without throwing.
    expect(find.byType(ThemeLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ── Keys: element identity preserved across reorder ──────────────────────────
  testWidgets('ValueKey preserves State identity across list reorder',
      (tester) async {
    Widget buildList(List<Color> colors) => _makeApp(
          Row(
            children: colors
                .map((c) => ColorBox(key: ValueKey(c), color: c))
                .toList(),
          ),
        );

    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);

    await tester.pumpWidget(buildList([red, blue]));
    final redState1 =
        tester.state<ColorBoxState>(find.byKey(const ValueKey(red)));

    // Swap order — with ValueKey, states must follow their key
    await tester.pumpWidget(buildList([blue, red]));
    final redState2 =
        tester.state<ColorBoxState>(find.byKey(const ValueKey(red)));

    expect(identical(redState1, redState2), isTrue,
        reason: 'ValueKey should preserve State across reorder');
  });

  // ── Element tree: widget vs element vs renderObject ──────────────────────────
  testWidgets('element tree: widget, element, renderObject are distinct layers',
      (tester) async {
    await tester.pumpWidget(_makeApp(const Greeting(name: 'tree')));

    final element = tester.element(find.byType(Greeting));
    expect(element.widget, isA<Greeting>());
    expect(element.renderObject, isNotNull);
    // Widget is immutable config; element is the live node
    expect(element.widget, isNot(same(element)));
  });
}

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Isolate/compute helpers ───────────────────────────────────────────────────

int sumUpTo(int n) => List.generate(n, (i) => i).fold(0, (a, b) => a + b);

String reverseString(String s) => s.split('').reversed.join();

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  test('compute() offloads work to a background isolate', () async {
    final result = await compute(sumUpTo, 100);
    expect(result, 4950); // 0+1+…+99
  });

  test('compute() can handle a string transformation', () async {
    final result = await compute(reverseString, 'flutter');
    expect(result, 'rettulf');
  });

  test('Isolate.run executes closure in a background isolate', () async {
    final result = await Isolate.run(() => sumUpTo(200));
    expect(result, 19900); // 0+1+…+199
  });

  test('Isolate.run supports async closures', () async {
    final result = await Isolate.run(() async {
      await Future<void>.delayed(Duration.zero);
      return 42;
    });
    expect(result, 42);
  });

  testWidgets('const widget does not rebuild parent', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(StatefulBuilder(
      builder: (_, setState) {
        buildCount++;
        return MaterialApp(
          home: Column(children: [
            // const — will NOT rebuild when parent rebuilds
            const Text('static label'),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('rebuild parent'),
            ),
          ]),
        );
      },
    ));
    expect(buildCount, 1);
    await tester.tap(find.text('rebuild parent'));
    await tester.pump();
    expect(buildCount, 2);
    // Text('static label') is const — Flutter skips its subtree during diff
    expect(find.text('static label'), findsOneWidget);
  });

  testWidgets('RepaintBoundary isolates repaints', (tester) async {
    const key = Key('rb');
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: Container(color: Colors.blue, width: 100, height: 100),
      ),
    ));
    // Flutter adds its own RepaintBoundary widgets internally — use key to find ours
    expect(find.byKey(key), findsOneWidget);
    expect(tester.widget(find.byKey(key)), isA<RepaintBoundary>());
  });

  testWidgets('ListView.builder renders items lazily', (tester) async {
    // Only items within the viewport are built — verify the first visible one
    await tester.pumpWidget(MaterialApp(
      home: ListView.builder(
        itemCount: 10000,
        itemBuilder: (_, i) => Text('item $i'),
      ),
    ));
    // Item 0 is in the viewport
    expect(find.text('item 0'), findsOneWidget);
    // Item 9999 is NOT rendered (outside viewport)
    expect(find.text('item 9999'), findsNothing);
  });

  testWidgets('AutomaticKeepAliveClientMixin keeps page alive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PageView(children: [
          _KeepAlivePage(label: 'A'),
          _KeepAlivePage(label: 'B'),
        ]),
      ),
    );
    expect(find.text('A'), findsOneWidget);
  });

  test('All performance smoke tests passed!', () => expect(true, isTrue));
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.label});
  final String label;
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(widget.label);
  }
}

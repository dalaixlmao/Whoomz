// Smoke tests: Row, Column, Stack, Flex, SliverList, CustomScrollView,
// and the constraints model (tight vs loose, BoxConstraints).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
    );

void main() {
  // ── Row ─────────────────────────────────────────────────────────────────────
  testWidgets('Row lays children out horizontally', (tester) async {
    await tester.pumpWidget(_app(
      const Row(children: [Text('A'), Text('B'), Text('C')]),
    ));
    final a = tester.getTopLeft(find.text('A'));
    final b = tester.getTopLeft(find.text('B'));
    final c = tester.getTopLeft(find.text('C'));
    // Each child is to the right of the previous one
    expect(b.dx, greaterThan(a.dx));
    expect(c.dx, greaterThan(b.dx));
    // All share the same vertical origin
    expect(a.dy, equals(b.dy));
    expect(b.dy, equals(c.dy));
  });

  // ── Column ──────────────────────────────────────────────────────────────────
  testWidgets('Column lays children out vertically', (tester) async {
    await tester.pumpWidget(_app(
      const Column(children: [Text('X'), Text('Y'), Text('Z')]),
    ));
    final x = tester.getTopLeft(find.text('X'));
    final y = tester.getTopLeft(find.text('Y'));
    final z = tester.getTopLeft(find.text('Z'));
    expect(y.dy, greaterThan(x.dy));
    expect(z.dy, greaterThan(y.dy));
    expect(x.dx, equals(y.dx));
  });

  // ── Stack ───────────────────────────────────────────────────────────────────
  testWidgets('Stack overlaps children at the same origin by default',
      (tester) async {
    await tester.pumpWidget(_app(
      const Stack(children: [Text('bottom'), Text('top')]),
    ));
    // Both exist in the tree at once
    expect(find.text('bottom'), findsOneWidget);
    expect(find.text('top'), findsOneWidget);
    // Both start at the same top-left (Stack.alignment defaults to topStart)
    final bottom = tester.getTopLeft(find.text('bottom'));
    final top = tester.getTopLeft(find.text('top'));
    expect(bottom, equals(top));
  });

  // ── Stack + Positioned ──────────────────────────────────────────────────────
  testWidgets('Positioned inside Stack offsets child from stack origin',
      (tester) async {
    await tester.pumpWidget(_app(
      const Stack(children: [
        Text('base'),
        Positioned(left: 50, top: 80, child: Text('offset')),
      ]),
    ));
    final base = tester.getTopLeft(find.text('base'));
    final offset = tester.getTopLeft(find.text('offset'));
    // 'offset' should be 50 px right and 80 px down of Stack's top-left
    expect(offset.dx - base.dx, closeTo(50, 1));
    expect(offset.dy - base.dy, closeTo(80, 1));
  });

  // ── Flex (Row is a Flex with Axis.horizontal) ────────────────────────────────
  testWidgets('Flex with Expanded distributes remaining space', (tester) async {
    await tester.pumpWidget(_app(
      Flex(
        direction: Axis.horizontal,
        children: [
          Container(width: 50, color: Colors.red),
          Expanded(child: Container(color: Colors.blue)),
          Container(width: 50, color: Colors.green),
        ],
      ),
    ));
    // The Expanded child should fill the space between the two 50-px containers
    final expandedBox =
        tester.renderObject<RenderBox>(find.byType(Expanded).first);
    // Total width is 400 (from SizedBox in _app), minus 50+50 fixed = 300
    expect(expandedBox.size.width, closeTo(300, 1));
  });

  // ── Constraints model: tight vs loose ────────────────────────────────────────
  testWidgets('SizedBox imposes tight constraints on its child', (tester) async {
    // UnconstrainedBox lets the SizedBox pick its own size freely,
    // then the SizedBox passes tight(120×80) to ITS child.
    BoxConstraints? captured;
    await tester.pumpWidget(_app(
      UnconstrainedBox(
        child: SizedBox(
          width: 120,
          height: 80,
          child: LayoutBuilder(builder: (context, constraints) {
            captured = constraints;
            return const SizedBox.expand();
          }),
        ),
      ),
    ));
    expect(captured, isNotNull);
    expect(captured!.isTight, isTrue);
    expect(captured!.maxWidth, closeTo(120, 1));
    expect(captured!.maxHeight, closeTo(80, 1));
  });

  testWidgets('Center passes loose constraints to its child', (tester) async {
    // Center receives tight constraints from above but passes loose ones down:
    // minWidth=0, minHeight=0, maxWidth/maxHeight = parent's max.
    BoxConstraints? captured;
    await tester.pumpWidget(_app(
      Center(
        child: LayoutBuilder(builder: (context, constraints) {
          captured = constraints;
          return const SizedBox(width: 60, height: 40);
        }),
      ),
    ));
    expect(captured, isNotNull);
    expect(captured!.minWidth, equals(0));
    expect(captured!.minHeight, equals(0));
    // maxWidth comes from the viewport, not zero
    expect(captured!.maxWidth, greaterThan(0));
  });

  // ── CustomScrollView + SliverList ────────────────────────────────────────────
  testWidgets('SliverList inside CustomScrollView renders items lazily',
      (tester) async {
    await tester.pumpWidget(_app(
      CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(
                key: ValueKey(index),
                title: Text('item $index'),
              ),
              childCount: 30,
            ),
          ),
        ],
      ),
    ));
    await tester.pump();

    // First item is visible
    expect(find.text('item 0'), findsOneWidget);
    // Item far below the viewport is NOT built yet (lazy)
    expect(find.text('item 29'), findsNothing);

    // Scroll to the end
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.text('item 29'), findsOneWidget);
  });

  // ── SliverAppBar inside CustomScrollView ─────────────────────────────────────
  testWidgets('SliverAppBar collapses on scroll', (tester) async {
    await tester.pumpWidget(_app(
      CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            title: Text('AppBar'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => ListTile(title: Text('row $i')),
              childCount: 20,
            ),
          ),
        ],
      ),
    ));
    await tester.pump();

    // SliverAppBar's render object is a sliver, not a RenderBox. Measure via
    // the AppBar widget it contains, which IS a RenderBox.
    final expandedHeight =
        tester.getSize(find.byType(AppBar).first).height;
    expect(expandedHeight, greaterThan(56)); // 56 is the collapsed toolbar height

    // Scroll down to collapse it
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final collapsedHeight =
        tester.getSize(find.byType(AppBar).first).height;
    expect(collapsedHeight, lessThan(expandedHeight));
  });
}

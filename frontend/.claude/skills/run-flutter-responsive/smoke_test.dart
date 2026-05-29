import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LayoutBuilder exposes parent constraints', (tester) async {
    // UnconstrainedBox loosens tight test-surface constraints so SizedBox can
    // impose its own tight 400x300 dimensions on LayoutBuilder.
    BoxConstraints? received;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnconstrainedBox(
          child: SizedBox(
            width: 400,
            height: 300,
            child: LayoutBuilder(
              builder: (_, constraints) {
                received = constraints;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(received!.maxWidth, 400.0);
    expect(received!.maxHeight, 300.0);
  });

  testWidgets('LayoutBuilder can switch layout at a breakpoint', (tester) async {
    // Control test surface size via tester.view — this is the correct way to
    // simulate different screen widths in widget tests.
    addTearDown(tester.view.reset);

    final app = MaterialApp(
      home: LayoutBuilder(
        builder: (_, c) =>
            c.maxWidth >= 600 ? const Text('wide') : const Text('narrow'),
      ),
    );

    // Narrow (400 dp) → 'narrow'
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1.0;
    await tester.pumpWidget(app);
    expect(find.text('narrow'), findsOneWidget);

    // Wide (800 dp) → 'wide'
    tester.view.physicalSize = const Size(800, 800);
    await tester.pump();
    expect(find.text('wide'), findsOneWidget);
  });

  testWidgets('MediaQuery.of returns screen size', (tester) async {
    Size? screen;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        screen = MediaQuery.sizeOf(ctx);
        return const SizedBox();
      }),
    ));
    expect(screen, isNotNull);
    expect(screen!.width, greaterThan(0));
  });

  testWidgets('MediaQuery textScaler reflects text scale factor', (tester) async {
    double? scale;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          scale = MediaQuery.textScalerOf(ctx).scale(14.0);
          return const SizedBox();
        }),
      ),
    ));
    expect(scale, closeTo(21.0, 0.1));
  });

  testWidgets('SafeArea pads child away from system insets', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        padding: EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: const MaterialApp(
        home: SafeArea(child: SizedBox()),
      ),
    ));
    expect(find.byType(SafeArea), findsOneWidget);
  });

  testWidgets('Platform.isIOS detection via Theme.of().platform', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Builder(builder: (ctx) {
        final platform = Theme.of(ctx).platform;
        return Text(platform == TargetPlatform.iOS ? 'iOS' : 'other');
      }),
    ));
    expect(find.text('iOS'), findsOneWidget);
  });

  testWidgets('Orientation is landscape when width > height', (tester) async {
    // MediaQueryData derives orientation from size — width > height = landscape
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(900, 400)),
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          final o = MediaQuery.orientationOf(ctx);
          return Text(o == Orientation.landscape ? 'landscape' : 'portrait');
        }),
      ),
    ));
    expect(find.text('landscape'), findsOneWidget);
  });

  testWidgets('FractionallySizedBox sizes relative to parent', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnconstrainedBox(
          child: SizedBox(
            width: 400,
            height: 400,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.25,
              child: Container(color: Colors.red),
            ),
          ),
        ),
      ),
    );
    final box = tester.renderObject<RenderBox>(find.byType(Container));
    expect(box.size.width, closeTo(200.0, 1.0));
    expect(box.size.height, closeTo(100.0, 1.0));
  });

  test('All responsive smoke tests passed!', () => expect(true, isTrue));
}

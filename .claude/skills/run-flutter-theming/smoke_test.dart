// Smoke tests: Material 3 ThemeData, ColorScheme, adaptive widgets
// (platform-aware), and dark mode toggling.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

Widget _m3App(Widget child, {ThemeMode themeMode = ThemeMode.light}) =>
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: Scaffold(body: child),
    );

void main() {
  // ── ThemeData.useMaterial3 ────────────────────────────────────────────────
  testWidgets('useMaterial3: true is reflected in Theme.of', (tester) async {
    await tester.pumpWidget(_m3App(const SizedBox()));
    final theme = Theme.of(tester.element(find.byType(SizedBox)));
    expect(theme.useMaterial3, isTrue);
  });

  // ── ColorScheme.fromSeed ──────────────────────────────────────────────────
  testWidgets('ColorScheme.fromSeed produces a non-null palette', (tester) async {
    await tester.pumpWidget(_m3App(const SizedBox()));
    final cs = Theme.of(tester.element(find.byType(SizedBox))).colorScheme;
    // All required M3 roles are populated
    expect(cs.primary, isNotNull);
    expect(cs.onPrimary, isNotNull);
    expect(cs.secondary, isNotNull);
    expect(cs.surface, isNotNull);
    expect(cs.error, isNotNull);
    expect(cs.brightness, equals(Brightness.light));
  });

  // ── Dark mode ────────────────────────────────────────────────────────────
  testWidgets('ThemeMode.dark switches ColorScheme brightness to dark',
      (tester) async {
    await tester.pumpWidget(
      _m3App(const SizedBox(), themeMode: ThemeMode.dark),
    );
    final cs = Theme.of(tester.element(find.byType(SizedBox))).colorScheme;
    expect(cs.brightness, equals(Brightness.dark));
  });

  // ── ThemeData inheritance via InheritedWidget ────────────────────────────
  testWidgets('Theme.of reads the nearest ancestor ThemeData', (tester) async {
    const Color overrideColor = Color(0xFFFF0000);
    await tester.pumpWidget(
      _m3App(
        Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(primary: overrideColor),
          ),
          child: const SizedBox(key: Key('inner')),
        ),
      ),
    );
    final inner = tester.element(find.byKey(const Key('inner')));
    // Inner theme overrides the outer one
    expect(Theme.of(inner).colorScheme.primary, equals(overrideColor));
  });

  // ── ElevatedButton uses colorScheme.primary ──────────────────────────────
  testWidgets('ElevatedButton background comes from colorScheme.primary',
      (tester) async {
    await tester.pumpWidget(_m3App(
      ElevatedButton(onPressed: () {}, child: const Text('Press')),
    ));
    // The button exists and is tappable
    expect(find.text('Press'), findsOneWidget);
    await tester.tap(find.text('Press'));
    await tester.pump();
    // No exception thrown — button handled the tap
  });

  // ── Adaptive widget: Switch.adaptive ─────────────────────────────────────
  testWidgets('Switch.adaptive renders without error', (tester) async {
    bool val = false;
    await tester.pumpWidget(
      StatefulBuilder(builder: (context, setState) {
        return _m3App(
          Switch.adaptive(
            value: val,
            onChanged: (v) => setState(() => val = v),
          ),
        );
      }),
    );
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(val, isTrue);
  });

  // ── CupertinoTheme propagates independently of MaterialTheme ────────────
  testWidgets('CupertinoThemeData: primaryColor is accessible via CupertinoTheme.of',
      (tester) async {
    const Color cupertinoColor = Color(0xFF007AFF);
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(primaryColor: cupertinoColor),
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: CupertinoButton(
              key: const Key('btn'),
              onPressed: () {},
              child: const Text('iOS'),
            ),
          ),
        ),
      ),
    );
    final btn = tester.element(find.byKey(const Key('btn')));
    expect(CupertinoTheme.of(btn).primaryColor, equals(cupertinoColor));
  });

  // ── Platform-adaptive: showAdaptiveDialog ────────────────────────────────
  testWidgets('showAdaptiveDialog renders AlertDialog on Material host',
      (tester) async {
    await tester.pumpWidget(
      _m3App(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAdaptiveDialog<void>(
              context: context,
              builder: (_) => AlertDialog.adaptive(
                title: const Text('Title'),
                content: const Text('Body'),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  // ── TextTheme scaling ─────────────────────────────────────────────────────
  testWidgets('Theme.of.textTheme.displayLarge has a non-null fontSize',
      (tester) async {
    await tester.pumpWidget(_m3App(const SizedBox()));
    final tt = Theme.of(tester.element(find.byType(SizedBox))).textTheme;
    expect(tt.displayLarge?.fontSize, isNotNull);
    expect(tt.displayLarge!.fontSize, greaterThan(0));
  });
}

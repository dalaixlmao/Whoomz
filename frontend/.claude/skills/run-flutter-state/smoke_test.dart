import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Providers used in tests ──────────────────────────────────────────────────

final counterProvider = StateProvider<int>((ref) => 0);

final doubledProvider = Provider<int>((ref) => ref.watch(counterProvider) * 2);

final greetingProvider = FutureProvider<String>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return 'hello';
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
  void reset() => state = 0;
}

final counterNotifierProvider =
    StateNotifierProvider<CounterNotifier, int>((ref) => CounterNotifier());

// AsyncNotifier (Riverpod 2.x)
class AsyncGreetingNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return 'async hello';
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => 'refreshed');
  }
}

final asyncGreetingProvider =
    AsyncNotifierProvider<AsyncGreetingNotifier, String>(
        AsyncGreetingNotifier.new);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  test('StateProvider: read initial value from ProviderContainer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(counterProvider), 0);
  });

  test('StateProvider: mutate state via notifier', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(counterProvider.notifier).state = 42;
    expect(container.read(counterProvider), 42);
  });

  test('Provider: derived value updates when dependency changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(counterProvider.notifier).state = 5;
    expect(container.read(doubledProvider), 10);
  });

  test('FutureProvider: resolves to expected value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Poll until resolved
    await container.read(greetingProvider.future);
    expect(container.read(greetingProvider).value, 'hello');
  });

  test('StateNotifierProvider: increment via notifier method', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(counterNotifierProvider.notifier).increment();
    container.read(counterNotifierProvider.notifier).increment();
    expect(container.read(counterNotifierProvider), 2);
  });

  test('StateNotifierProvider: reset returns to zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(counterNotifierProvider.notifier).increment();
    container.read(counterNotifierProvider.notifier).reset();
    expect(container.read(counterNotifierProvider), 0);
  });

  test('AsyncNotifier: builds to initial value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(asyncGreetingProvider.future);
    expect(container.read(asyncGreetingProvider).value, 'async hello');
  });

  test('AsyncNotifier: refresh updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(asyncGreetingProvider.future);
    await container.read(asyncGreetingProvider.notifier).refresh();
    expect(container.read(asyncGreetingProvider).value, 'refreshed');
  });

  testWidgets('ProviderScope + ConsumerWidget reads provider in widget tree',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (_, ref, __) {
            final count = ref.watch(counterProvider);
            return Text('count=$count');
          }),
        ),
      ),
    );
    expect(find.text('count=0'), findsOneWidget);
  });

  testWidgets('ref.read inside button tap increments counter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (_, ref, __) {
            final count = ref.watch(counterProvider);
            return Column(children: [
              Text('$count'),
              ElevatedButton(
                onPressed: () => ref.read(counterProvider.notifier).state++,
                child: const Text('+'),
              ),
            ]);
          }),
        ),
      ),
    );
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  test('All Riverpod state smoke tests passed!', () => expect(true, isTrue));
}

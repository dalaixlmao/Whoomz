---
name: run-flutter-state
description: Run, test, and smoke-check Flutter state management with Riverpod 2.x — StateProvider, Provider (derived), FutureProvider, StateNotifierProvider, AsyncNotifier, ProviderContainer unit tests, and ConsumerWidget integration. Use when asked to run Riverpod tests, verify provider dependencies, check AsyncNotifier build/refresh, or exercise ConsumerWidget rebuilds.
---

Flutter 3.44.0 + `flutter_riverpod ^2.5.1` (already in this project's pubspec). This skill drives Riverpod primitives via `flutter test` — no device needed. Unit-test providers with `ProviderContainer`; widget-test with `ProviderScope`.

## Run (agent path)

```bash
~/flutter/bin/flutter test .claude/skills/run-flutter-state/smoke_test.dart --reporter expanded
```

Expected output (11 tests, under 2 seconds):

```
00:00 +0: StateProvider: read initial value from ProviderContainer
00:00 +1: StateProvider: mutate state via notifier
00:00 +2: Provider: derived value updates when dependency changes
00:00 +3: FutureProvider: resolves to expected value
00:00 +4: StateNotifierProvider: increment via notifier method
00:00 +5: StateNotifierProvider: reset returns to zero
00:00 +6: AsyncNotifier: builds to initial value
00:00 +7: AsyncNotifier: refresh updates state
00:00 +8: ProviderScope + ConsumerWidget reads provider in widget tree
00:00 +9: ref.read inside button tap increments counter
00:00 +10: All Riverpod state smoke tests passed!
```

## What smoke_test.dart covers

| Test | Concept |
|---|---|
| StateProvider initial value | `StateProvider`, `ProviderContainer.read` |
| StateProvider mutation | `counterProvider.notifier.state =` |
| Provider derived value | `Provider` watching another provider |
| FutureProvider resolution | `FutureProvider`, async data |
| StateNotifierProvider increment | `StateNotifier`, method dispatch |
| StateNotifierProvider reset | `StateNotifier`, imperative reset |
| AsyncNotifier build | `AsyncNotifier`, `AsyncValue.data` |
| AsyncNotifier refresh | `AsyncValue.guard`, state transition |
| ConsumerWidget reads provider | `ProviderScope`, `Consumer`, `ref.watch` |
| ref.read in gesture | `ref.read` (no rebuild), tap handler |

## Key patterns

### Unit testing providers (no widgets)
```dart
final container = ProviderContainer();
addTearDown(container.dispose);   // always clean up

expect(container.read(myProvider), expectedValue);
container.read(myProvider.notifier).doSomething();
```

### Override a provider in tests
```dart
final container = ProviderContainer(overrides: [
  repositoryProvider.overrideWithValue(FakeRepository()),
]);
```

### StateNotifier (imperative state)
```dart
class TodosNotifier extends StateNotifier<List<Todo>> {
  TodosNotifier() : super([]);

  void add(Todo t) => state = [...state, t];
  void remove(String id) => state = state.where((t) => t.id != id).toList();
}

final todosProvider = StateNotifierProvider<TodosNotifier, List<Todo>>(
  (ref) => TodosNotifier(),
);
```

### AsyncNotifier (Riverpod 2.x preferred)
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() => ref.read(userRepositoryProvider).fetchCurrentUser();

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(User.anonymous());
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, User>(UserNotifier.new);
```

### ConsumerWidget
```dart
class UserCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
      data: (u) => Text(u.name),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### ref.watch vs ref.read
- `ref.watch` — inside `build`; subscribes, triggers rebuild on change.
- `ref.read` — inside callbacks/event handlers; one-shot, no subscription.
- `ref.listen` — side effects (show snackbar, navigate) without rebuilding.

## Gotchas

- `ProviderContainer` must be disposed after each test — use `addTearDown(container.dispose)`.
- `FutureProvider` starts loading immediately. Use `container.read(provider.future)` to `await` it in tests before asserting the value.
- `StateNotifier` must never mutate `state` in place — always assign a new object (`state = [...state, item]`), otherwise listeners won't fire.
- `AsyncNotifier.build()` is called once per `ProviderContainer` lifecycle. To re-trigger it, call `ref.invalidateSelf()`.
- Widget tests need a `ProviderScope` wrapping the `MaterialApp`. Don't put `ProviderScope` inside a `Consumer` — it needs to be an ancestor.
- `ref.read` inside a `build` method is a code smell — it won't rebuild when the provider changes. Use `ref.watch` in `build`.

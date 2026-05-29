---
name: run-flutter-supabase-mocking
description: Reference and code-generation skill for mocking the Supabase client in Flutter tests using mocktail — fake auth responses, stubbing PostgREST queries, mocking Storage, and testing Realtime subscription callbacks. Use when writing unit or widget tests for code that depends on Supabase.
---

Requires `supabase_flutter ^2.x` and `mocktail ^1.0.4` (mocktail is already in this project's pubspec):

```bash
~/flutter/bin/flutter pub add supabase_flutter
```

## Core mock classes

```dart
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}
class MockStorageFileApi extends Mock implements StorageFileApi {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
```

## Stubbing auth

```dart
final mockAuth = MockGoTrueClient();
final mockClient = MockSupabaseClient();

when(() => mockClient.auth).thenReturn(mockAuth);

// Fake a signed-in session
final fakeUser = User(
  id: 'uid-123',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);
when(() => mockAuth.currentUser).thenReturn(fakeUser);

// Fake sign-in response
when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => AuthResponse(
      session: Session(
        accessToken: 'fake-token',
        tokenType: 'bearer',
        user: fakeUser,
      ),
    ));

// Signed out
when(() => mockAuth.currentUser).thenReturn(null);
when(() => mockAuth.signOut()).thenAnswer((_) async {});
```

## Stubbing a SELECT query

```dart
final mockBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

when(() => mockClient.from('workouts')).thenReturn(mockQueryBuilder);
when(() => mockQueryBuilder.select()).thenReturn(mockBuilder);
when(() => mockBuilder.eq('user_id', any())).thenReturn(mockBuilder);
when(() => mockBuilder.order('created_at', ascending: false))
    .thenReturn(mockBuilder);
when(() => mockBuilder.then(any())).thenAnswer((_) async => [
  {'id': 'w1', 'name': 'Morning Run', 'user_id': 'uid-123'},
]);
```

> **Tip:** The PostgREST builder chain is deeply nested. For most tests it is easier to mock at the repository boundary (the repository method itself) rather than at the raw Supabase client level.

## Recommended approach — mock the repository, not the client

```dart
// lib/features/workouts/data/workout_repository.dart
abstract class WorkoutRepository {
  Future<List<WorkoutResponse>> listWorkouts({DateTime? date});
}

// test — mock the repository, not Supabase
class MockWorkoutRepository extends Mock implements WorkoutRepository {}

// In test
final repo = MockWorkoutRepository();
when(() => repo.listWorkouts()).thenAnswer((_) async => fakeWorkouts);
```

This keeps tests fast and independent of Supabase client API changes.

## Stubbing Storage

```dart
final mockStorageFileApi = MockStorageFileApi();
when(() => mockClient.storage.from('profiles'))
    .thenReturn(mockStorageFileApi);
when(() => mockStorageFileApi.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
    .thenAnswer((_) async => 'profiles/avatars/uid.jpg');
```

## Testing an auth state change listener

```dart
final controller = StreamController<AuthState>();
when(() => mockAuth.onAuthStateChange)
    .thenAnswer((_) => controller.stream);

// Trigger sign-in event in test
controller.add(AuthState(AuthChangeEvent.signedIn, fakeSession));

// Trigger sign-out event
controller.add(AuthState(AuthChangeEvent.signedOut, null));

addTearDown(controller.close);
```

## Full test example

```dart
group('WorkoutsNotifier', () {
  late MockWorkoutRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockWorkoutRepository();
    container = ProviderContainer(overrides: [
      workoutRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('loads workouts on build', () async {
    when(() => repo.listWorkouts()).thenAnswer((_) async => [fakeWorkout]);

    await container.read(workoutsProvider.future);
    expect(container.read(workoutsProvider).value, [fakeWorkout]);
    verify(() => repo.listWorkouts()).called(1);
  });
});
```

## Gotchas

- The `SupabaseQueryBuilder` chain (`.from().select().eq().order()`) returns a new builder object at each step. You need to stub every step in the chain, which is tedious. Prefer mocking at the repository interface level.
- `mocktail` uses `any()` for positional args and `any(named: 'name')` for named parameters. If you forget `named:`, the stub won't match and the call will throw a `MissingStubError`.
- `AuthResponse` requires a valid `Session` shape — the Supabase SDK validates fields. Use the exact field names from the `Session` constructor or the test may fail at deserialization.
- `GoTrueClient.onAuthStateChange` is a `Stream<AuthState>` — stub it with a `StreamController` so you can push events during the test.
- Always call `container.dispose()` in `tearDown` — Riverpod providers that listen to Supabase streams can leak if not properly closed.

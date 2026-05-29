---
name: run-flutter-navigation
description: Reference and code-generation skill for Flutter navigation & routing with go_router — shell routes, nested navigation, deep links, redirect guards, passing typed arguments, and query parameters. Use when building navigation stacks, setting up deep links, adding auth redirect guards, or generating go_router route configuration for the Whoomz app.
---

This skill covers `go_router ^14.x`. The package is **not yet in this project's pubspec** — add it before running any code:

```bash
~/flutter/bin/flutter pub add go_router
```

Then generate/run as normal.

## Key patterns

### Basic router setup
```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/profile/:userId',
      builder: (_, state) {
        final id = state.pathParameters['userId']!;
        return ProfileScreen(userId: id);
      },
    ),
  ],
);

// main.dart
MaterialApp.router(routerConfig: appRouter)
```

### Shell routes (persistent bottom nav)
```dart
ShellRoute(
  builder: (_, __, child) => ScaffoldWithBottomNav(body: child),
  routes: [
    GoRoute(path: '/feed',     builder: (_, __) => const FeedScreen()),
    GoRoute(path: '/workouts', builder: (_, __) => const WorkoutsScreen()),
    GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
  ],
)
```

### Auth redirect guard
```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    final isOnLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/home';
    return null; // no redirect
  },
  refreshListenable: authNotifier, // re-runs redirect when auth changes
  routes: [...],
)
```

### Typed extra arguments (no URL encoding)
```dart
// Navigate
context.go('/workout-detail', extra: workout);

// Receive
GoRoute(
  path: '/workout-detail',
  builder: (_, state) {
    final workout = state.extra as WorkoutResponse;
    return WorkoutDetailScreen(workout: workout);
  },
)
```

### Query parameters
```dart
// Navigate
context.go('/food-logs?date=2026-05-29');

// Receive
GoRoute(
  path: '/food-logs',
  builder: (_, state) {
    final date = state.uri.queryParameters['date'];
    return FoodLogsScreen(date: date);
  },
)
```

### Programmatic navigation
```dart
context.go('/home');           // replace stack
context.push('/settings');     // push onto stack
context.pop();                 // pop
context.goNamed('profile', pathParameters: {'userId': '42'});
```

### Named routes
```dart
GoRoute(
  name: 'workout-detail',
  path: '/workouts/:id',
  builder: (_, state) => WorkoutDetailScreen(id: state.pathParameters['id']!),
)
// Navigate
context.goNamed('workout-detail', pathParameters: {'id': workoutId});
```

### Deep links — Android
```xml
<!-- android/app/src/main/AndroidManifest.xml — inside <activity> -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="app.whoomz.com"/>
</intent-filter>
```

### Deep links — iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>FlutterDeepLinkingEnabled</key><true/>
```

## Gotchas

- `context.go` replaces the entire navigation stack. Use `context.push` when you want back-button support.
- `ShellRoute` renders the shell widget (bottom nav, drawer) on every child page. Don't put a `Scaffold` inside a `ShellRoute` child if the shell already provides one.
- `redirect` is called on every navigation event. Return `null` to allow the navigation; return a path string to redirect. Avoid async work inside `redirect` — use `refreshListenable` instead to re-trigger after async state settles.
- `state.extra` is not persisted across hot-restart or deep links — it lives only in memory. For deep-linkable routes, encode the key in path/query params and load data from the repository.
- `GoRouter` with Riverpod: pass a `Notifier` as `refreshListenable` and call `ref.invalidate` / notify listeners from inside the auth provider to trigger re-evaluation of redirect guards.

---
name: run-flutter-supabase
description: Reference and code-generation skill for the Supabase Flutter client — email/password auth, OAuth (Google/Apple), magic links, Realtime subscriptions, Row Level Security awareness, session management, and error handling. Use when building Supabase auth flows, subscribing to realtime tables, or handling Supabase errors in Flutter.
---

This skill covers `supabase_flutter ^2.x`. The package is **not in this project's pubspec** — add it before running any code:

```bash
~/flutter/bin/flutter pub add supabase_flutter
```

## Initialisation
```dart
// main.dart
await Supabase.initialize(
  url: 'https://xxxx.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);

// Access the client anywhere
final supabase = Supabase.instance.client;
```

## Auth patterns

### Email + password
```dart
// Sign up
final res = await supabase.auth.signUp(
  email: 'user@example.com',
  password: 's3cret',
);
final user = res.user; // null if email confirmation required

// Sign in
final session = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 's3cret',
);

// Sign out
await supabase.auth.signOut();
```

### OAuth (Google / Apple)
```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.supabase.yourapp://login-callback',
);
```

### Magic link
```dart
await supabase.auth.signInWithOtp(email: 'user@example.com');
// User taps link → app receives deep link → session is set automatically
```

### Session & user
```dart
final session = supabase.auth.currentSession;     // null if signed out
final user    = supabase.auth.currentUser;        // null if signed out

// React to auth state changes (good for navigation guard)
supabase.auth.onAuthStateChange.listen((data) {
  final event   = data.event;   // AuthChangeEvent.signedIn / signedOut / …
  final session = data.session;
});
```

## Database (PostgREST)

```dart
// SELECT
final rows = await supabase
    .from('workouts')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// INSERT
final row = await supabase
    .from('food_logs')
    .insert({'name': 'Oats', 'calories': 300, 'user_id': userId})
    .select()
    .single();

// UPDATE
await supabase
    .from('workouts')
    .update({'finished_at': DateTime.now().toIso8601String()})
    .eq('id', workoutId);

// DELETE
await supabase.from('workouts').delete().eq('id', workoutId);
```

## Realtime subscriptions

```dart
final channel = supabase
    .channel('public:workouts')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'workouts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) => print('Changed: $payload'),
    )
    .subscribe();

// Unsubscribe when done
await supabase.removeChannel(channel);
```

## Error handling

```dart
try {
  final data = await supabase.from('profiles').select().single();
} on AuthException catch (e) {
  // Auth errors (invalid token, not signed in, etc.)
  print('Auth error: ${e.message}');
} on PostgrestException catch (e) {
  // Database/RLS errors
  print('DB error ${e.code}: ${e.message}');
}
```

## Row Level Security

RLS policies live on the Supabase dashboard. Common pattern for user-scoped tables:

```sql
-- Allow users to read only their own rows
CREATE POLICY "select own rows"
  ON workouts FOR SELECT
  USING (auth.uid() = user_id);
```

The Flutter client automatically sends the JWT with every request — RLS filters rows silently. A `PostgrestException` with code `42501` (insufficient privilege) means a missing or failing RLS policy.

## Gotchas

- The `supabase_flutter` client auto-refreshes the access token — you don't need to manage token expiry manually.
- `onAuthStateChange` fires once on subscribe with the current event. Use it as the single source of truth for "is logged in".
- RLS is enforced on the **server** — the Flutter client cannot bypass it. Testing locally with `service_role` key bypasses RLS (dangerous in production — never ship the service key in app).
- For Realtime to fire, the table must have `REPLICA IDENTITY FULL` set in Postgres and Realtime must be enabled for the table in the Supabase dashboard.
- Deep links for OAuth / magic links require `supabase_flutter` URL handling setup in `AppDelegate.swift` (iOS) and `AndroidManifest.xml` (Android) — see the `supabase_flutter` README for exact config.

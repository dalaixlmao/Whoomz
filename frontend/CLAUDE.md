# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Whoomz** is a fitness tracking mobile app built with **Flutter/Dart**. Users track daily calorie intake, workouts, and get AI coaching via text and voice chat. This is the mobile frontend that consumes the Whoomz FastAPI backend at `https://<host>/api/v1`.

---

## Tech Stack

- **Language:** Dart 3.x
- **Framework:** Flutter
- **State Management:** Riverpod 2.x
- **HTTP Client:** Dio 5.x (with interceptors for auth)
- **Secure Storage:** flutter_secure_storage (JWT tokens)
- **Code Generation:** freezed + json_serializable (immutable models)
- **Build Runner:** build_runner

---

## Setup

```bash
# Install dependencies
flutter pub get

# Generate freezed/json_serializable code
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device or simulator
flutter run

# Run in release mode
flutter run --release
```

---

## Common Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/features/auth/auth_repository_test.dart

# Lint
flutter analyze

# Format
dart format lib/ test/

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs
```

---

## Folder Structure

Feature-based architecture. Each feature owns its data, domain, and presentation layers.

```
lib/
  core/
    api/
      api_client.dart        # Dio instance + auth interceptor + token refresh
      api_endpoints.dart     # endpoint path constants
      api_error.dart         # ApiError wraps DioException
    auth/
      token_storage.dart     # FlutterSecureStorage wrapper
  features/
    auth/
      data/
        auth_repository.dart
        auth_models.dart
    food_logs/
      data/
        food_log_repository.dart
        food_log_models.dart
    workouts/
      data/
        workout_repository.dart
        workout_models.dart
    chat/
      data/
        chat_repository.dart   # SSE stream
    voice/
      data/
        voice_repository.dart  # SSE stream
test/
  features/
    auth/
    food_logs/
    workouts/
```

---

## State Management (Riverpod)

- All business state is managed via Riverpod providers.
- Repositories are provided as `Provider` (not `StateNotifierProvider`) — they are stateless service objects.
- Screen state (loading, error, data) uses `AsyncNotifierProvider` or `FutureProvider`.
- Never call repositories directly from widgets — always go through a provider.

```dart
// Example provider
final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

final currentUserProvider = FutureProvider<UserInfo?>((ref) async {
  // read token from storage and return user or null
});
```

---

## Auth Tokens

- Access and refresh tokens are stored via `flutter_secure_storage` under keys `access_token` and `refresh_token`.
- The Dio interceptor in `ApiClient` automatically injects `Authorization: Bearer <token>` on every request.
- On a **401** response, the interceptor calls `POST /auth/refresh` using a fresh `Dio` instance (not the intercepted one), persists the new tokens, and retries the original request once.
- Repositories never handle 401 manually — that is entirely the interceptor's responsibility.
- On logout, all stored keys are deleted via `_storage.deleteAll()`.

---

## Code Conventions

### Naming
- Files and variables: `snake_case`
- Classes: `PascalCase`
- Private members: `_camelCase`
- Riverpod providers: `<feature>RepositoryProvider`, `<feature>Provider`

### Model Pattern
- `<Resource>Response` — deserialized from API JSON via `fromJson`
- `<Resource>Create` — serialized to API JSON via `toJson`; only send non-null fields
- Enums map to/from snake_case strings (e.g., `MealType.breakfast` ↔ `"breakfast"`)
- `WorkoutResponse.isInProgress` is a computed getter: `finishedAt == null`

### Error Handling
- All repository calls throw `DioException` on failure.
- Wrap in `ApiError.fromDio(e)` at the provider/notifier layer — never in the widget.
- `ApiError` extracts the `detail` field from the FastAPI error response body.

### SSE Streaming (Chat & Voice)
- Use `ResponseType.stream` in Dio options.
- Each SSE line starts with `data: `. Strip the prefix, yield the payload.
- The stream ends with `data: [DONE]` — always `break` on this sentinel.
- Generate a UUID per conversation session with `package:uuid`; reuse the same `session_id` across all turns in that session.

---

## API Reference (19 Endpoints)

Full request/response shapes and repository implementations are in the `/flutter-integration` skill. Summary:

| Feature | Endpoints |
|---|---|
| Auth | POST signup, login, logout, refresh |
| Food Logs | POST create, GET list (by date), DELETE |
| Workouts | POST create, GET list/detail, PATCH update, DELETE; POST/PATCH/DELETE exercises |
| Chat | POST → SSE stream |
| Voice | POST → SSE stream |

Key gotchas:
- Date query params use `YYYY-MM-DD`, not ISO 8601 with time.
- PATCH is partial — omit fields you don't want to change.
- To complete a workout, PATCH it with `finished_at: DateTime.now().toIso8601String()`.
- Exercise `metrics` shape varies by `tracking_type` (see skill for exact shapes).

---

## Testing

- Test files mirror the feature structure: `test/features/<feature>/<name>_test.dart`.
- Mock Dio with `mockito` or `mocktail` — do not make real HTTP calls in tests.
- Each test should be fully isolated (no shared mutable state).

---

## What NOT to Do

- Do not call repositories from widgets — use Riverpod providers.
- Do not handle 401 in repositories — the `ApiClient` interceptor owns that.
- Do not use `dio` directly outside of `ApiClient` (except in the `_tryRefresh` method which intentionally bypasses interceptors).
- Do not send explicit `null` values in PATCH bodies — this may overwrite data on the server.
- Do not hardcode the base URL in multiple places — use `ApiClient._baseUrl`.
- Do not put business logic in UI widgets.

---

## Skills Reference

| Skill | When to Use |
|---|---|
| `/flutter-integration` | Generating repository code, API models, SSE streaming, or auth flows for the Whoomz backend |
| `/context7-mcp` | Looking up docs for Flutter, Riverpod, Dio, freezed, flutter_secure_storage, or any other package |
| `/verify` | Confirming a fix or feature works end-to-end on the simulator or device |
| `/run` | Starting the app and observing live behaviour |
| `/simplify` | Refactoring changed code for clarity and efficiency after a feature is complete |
| `/review` | Reviewing a pull request before merging |
| `/security-review` | Auditing token storage, auth flows, or input handling |
| `/update-config` | Changing Claude Code permissions, hooks, or harness settings |
| `/fewer-permission-prompts` | Reducing repetitive permission prompts by allowlisting common read-only commands |

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

Use these skills and tools when they fit the task:

| Skill / Tool | When to Use |
|---|---|
| `/flutter-integration` | Generate repository code, API models, SSE streaming, or auth flows for the Whoomz backend |
| `/context7-mcp` | Look up package documentation for Flutter, Riverpod, Dio, freezed, flutter_secure_storage, or related dependencies |
| `/verify` | Confirm a fix or feature works end-to-end on a simulator or device |
| `/run` | Start the app and observe live behavior |
| `/simplify` | Refactor changed code for clarity and efficiency after a feature is complete |
| `/review` | Review a pull request or local diff before merging |
| `/security-review` | Audit token storage, auth flows, API calls, or input handling |
| `/update-config` | Change Claude Code permissions, hooks, or harness settings |
| `/fewer-permission-prompts` | Reduce repetitive permission prompts by allowlisting common read-only commands |
| `imagegen` | Create or edit bitmap assets, mockups, sprites, textures, or visual references when the app needs generated imagery |
| `browser-use` | Inspect, navigate, screenshot, or test local browser targets such as `localhost`, `127.0.0.1`, or `file://` URLs |
| `documents` | Create, edit, render, and verify `.docx` files |
| `presentations` | Create, edit, render, verify, or export PowerPoint decks |
| `spreadsheets` | Create, edit, analyze, visualize, or export spreadsheets and CSV/TSV files |
| `openai-docs` | Use current official OpenAI documentation for OpenAI API or ChatGPT implementation questions |
| `skill-creator` | Create or update Codex skills with specialized workflows or knowledge |
| `skill-installer` | List or install Codex skills from curated sources or GitHub repos |
| `plugin-creator` | Scaffold personal Codex plugins and marketplace metadata |

### Repo-local `.claude/skills`

| Skill | When to Use |
|---|---|
| `flutter-code-quality` | Review Flutter/Dart code quality, SOLID principles, code smells, architecture, or low-level design |
| `flutter-integration` | Generate Flutter client code for Whoomz API services, models, repositories, auth, and SSE streaming |
| `run-dart` | Run Dart snippets or smoke-check Dart language features like null safety, async, streams, generics, and extensions |
| `run-flutter-animations` | Run animation smoke tests for `AnimationController`, tweens, Hero, implicit animations, and `AnimatedBuilder` |
| `run-flutter-integration-testing` | Write or run end-to-end Flutter integration tests on a real device or emulator |
| `run-flutter-layouts` | Test layout behavior for `Row`, `Column`, `Stack`, `Flex`, slivers, and Flutter constraints |
| `run-flutter-linting` | Run or configure `flutter analyze`, `dart format`, `flutter_lints`, and stricter lint rules |
| `run-flutter-local-storage` | Add or design local storage with SharedPreferences, Hive, Isar, or persisted state |
| `run-flutter-navigation` | Build navigation with `go_router`, shell routes, nested navigation, deep links, redirects, and typed route data |
| `run-flutter-performance` | Test performance patterns like `compute`, `Isolate.run`, `const` widgets, `RepaintBoundary`, lazy lists, and keep-alive pages |
| `run-flutter-platform-channels` | Test or mock `MethodChannel`, `EventChannel`, `BasicMessageChannel`, and `PlatformException` behavior |
| `run-flutter-responsive` | Test adaptive UI with `LayoutBuilder`, `MediaQuery`, `SafeArea`, platform detection, and breakpoint switching |
| `run-flutter-state` | Run Riverpod provider tests for `StateProvider`, `Provider`, `FutureProvider`, `StateNotifierProvider`, and `AsyncNotifier` |
| `run-flutter-supabase` | Build Supabase auth, Realtime subscriptions, session handling, and Flutter client error handling |
| `run-flutter-supabase-mocking` | Mock Supabase auth, PostgREST queries, Storage, and Realtime callbacks in Flutter tests |
| `run-flutter-supabase-storage` | Implement Supabase Storage uploads, downloads, signed URLs, public URLs, and cached remote images |
| `run-flutter-testing` | Run Flutter unit/widget tests with `flutter_test`, `WidgetTester`, finders, interactions, and mocktail |
| `run-flutter-theming` | Test Material 3, Cupertino, dark mode, color schemes, adaptive widgets, and theme lookup |
| `run-flutter-widgets` | Test widget tree fundamentals, lifecycle, `BuildContext`, keys, and element tree behavior |

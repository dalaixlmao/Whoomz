# Whoomz — CLAUDE.md

**Whoomz** is a fitness tracking app with a **Python/FastAPI REST API backend** and a **Flutter/Dart mobile frontend**. Users track daily fitness goals (calorie intake, weight, calories burnt) and receive AI coaching via text/voice chat.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Mobile App                │
│          (Dart 3.x, Riverpod, Dio, General Sans)     │
└────────────────┬────────────────────────────────────┘
                 │ HTTP (Dio + Auth Interceptor)
                 ↓
┌─────────────────────────────────────────────────────┐
│             FastAPI Backend (Python 3.11+)          │
│       (Supabase Auth, Pydantic, pytest + httpx)    │
└────────────────┬────────────────────────────────────┘
                 │ Supabase (Auth + Realtime)
                 ↓
┌─────────────────────────────────────────────────────┐
│                    Supabase                         │
│         (PostgreSQL, Auth, Row-Level Security)      │
└─────────────────────────────────────────────────────┘
```

**API Endpoints:** 19 endpoints across Auth, Food Logs, Workouts, Chat (SSE), Voice (SSE).

---

## Tech Stack

### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **Database & Auth:** Supabase (PostgreSQL, Auth, RLS)
- **Validation:** Pydantic v2
- **Testing:** pytest + httpx (async test client)

### Frontend
- **Language:** Dart 3.x
- **Framework:** Flutter
- **State Management:** Riverpod 2.x
- **HTTP Client:** Dio 5.x (with auth interceptor + token refresh)
- **Secure Storage:** flutter_secure_storage
- **Models:** hand-written `fromJson`/`toJson` (no codegen)
- **Voice:** speech_to_text (STT) + flutter_tts (spoken replies)
- **Design system:** "Whoomz AI" board — General Sans only, `#FAF9F6` paper / `#111110` ink / `#2635F0` accent, no tab bar (conversation is the navigation)

---

## Setup

### Backend

```bash
# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy env file
cp .env.example .env  # Fill SUPABASE_URL and SUPABASE_KEY

# Start dev server
uvicorn app.main:app --reload
```

### Frontend

```bash
# Install dependencies
flutter pub get

# Run on simulator
flutter run

# Run in release mode
flutter run --release
```

---

## Logging (Backend)

Structured logging in the **FastAPI backend** is configured automatically via `app/logging_config.py` on startup. No manual setup required.

### Log Levels & Usage

| Level | Use Case | Example |
|---|---|---|
| `DEBUG` | Service internals, state transitions | `User authenticated — user_id: 550e8400-...` |
| `INFO` | User requests, successful operations, lifecycle | `Signup request — email: user@example.com` |
| `WARNING` | Auth failures, validation errors, access denied | `Login service error — email: user@example.com` |
| `ERROR` | Exceptions, unexpected null, DB errors | `Failed to create food log — error: Unique constraint violated` |

**Format:** `[LEVEL] YYYY-MM-DD HH:MM:SS — logger_name — message`

### Backend: Router Logging Pattern

```python
# FastAPI router — routers/food_logs.py
import logging
logger = logging.getLogger(__name__)

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_food_log(body: FoodLogCreate, user: CurrentUser, supabase: SupabaseClient) -> FoodLogResponse:
    logger.info("Create food log — user_id: %s, food: %s, calories: %d", user["id"], body.name, body.calories)
    result = await food_log_service.create(user["id"], body, supabase)
    logger.info("Food log created — id: %s", result.id)
    return result
```

### Backend: Service Logging Pattern

```python
# FastAPI service — services/food_log_service.py
async def create(user_id: str, data: FoodLogCreate, supabase: Client) -> FoodLogResponse:
    logger.debug("Creating food log — user_id: %s, food: %s", user_id, data.name)
    try:
        result = supabase.table("food_logs").insert(payload).execute()
        logger.debug("Food log created — id: %s", result.data[0]["id"])
        return FoodLogResponse(**result.data[0])
    except Exception as exc:
        logger.error("Failed to create food log — user_id: %s, error: %s", user_id, str(exc))
        raise HTTPException(...) from exc
```

### Best Practices

- Use `%s` formatting (lazy evaluation, not f-strings)
- Always include `user_id` for request tracing
- Log at router (request/response) and service (critical ops) levels
- **Never** log passwords, full tokens, or sensitive credentials
- Use consistent message format: `Action — key: value, key: value`

### Currently Logged

- ✅ Auth: signup, login, logout, refresh (requests + responses)
- ✅ Food Logs: create, list, delete
- ✅ Workouts: create
- ✅ Weight Logs: create
- ✅ Chat & Voice: requests + validation
- ✅ Scheduler: daily notes job
- ✅ App Lifecycle: startup, shutdown, scheduler status

---

## Backend Details

### Data Model

**`users`** — Owned by Supabase Auth, referenced everywhere via `user_id`.

**`food_logs`**
| id (uuid PK) | user_id (uuid FK) | name | calories (int) | protein_g | carbs_g | fat_g | meal_type (enum) | logged_at (timestamptz) |

**`workouts`**
| id (uuid PK) | user_id (uuid FK) | name | notes | started_at (timestamptz) | finished_at (nullable) |

**`workout_exercises`**
| id (uuid PK) | workout_id (uuid FK) | exercise_name | tracking_type (enum) | metrics (jsonb) | order (int) | notes |

**`metrics` by `tracking_type`:**
- `sets_reps_weight` → `{ sets: [{set_number, reps, weight_kg}] }`
- `distance_duration` → `{ distance_km, duration_seconds, avg_heart_rate? }`
- `laps` → `{ laps: [{lap_number, lap_time_seconds, distance_m?}] }`
- `duration_only` → `{ duration_seconds }`
- `freeform` → `{}`

### Code Conventions
- **Async everywhere** — all route handlers and DB calls use `async def`
- **Router prefix** — versioned: `/api/v1/...`
- **Schemas** — separate `Create`, `Update`, `Response` Pydantic models
- **Services** — business logic in `services/`, not routers
- **Dependencies** — use FastAPI `Depends()` for auth and Supabase injection
- **Error handling** — raise `HTTPException` with status codes, never expose raw DB errors
- **Naming** — snake_case files/variables, PascalCase classes

### Testing

```bash
pytest                                    # Run all tests
pytest --cov=app --cov-report=term-missing  # With coverage
pytest tests/test_<name>.py -v            # Specific test file
```

- Use `AsyncClient` from `httpx` for endpoint testing
- Each test fully isolated
- Test files: `tests/test_<router>.py`

---

## Frontend Details

### Folder Structure (Feature-Based)

```
lib/
  core/
    api/
      api_client.dart        # Dio + auth interceptor + token refresh
      api_endpoints.dart     # endpoint constants
      api_error.dart         # ApiError wraps DioException
    auth/
      token_storage.dart     # FlutterSecureStorage wrapper
  features/
    auth/
    food_logs/
    workouts/
    chat/
    voice/
test/
  features/
    auth/
    food_logs/
    workouts/
```

### State Management (Riverpod)

```dart
final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

final currentUserProvider = FutureProvider<UserInfo?>((ref) async {
  // read token and return user or null
});
```

- All business state via Riverpod providers
- Repositories: stateless `Provider` (not `StateNotifierProvider`)
- Screen state: `AsyncNotifierProvider` or `FutureProvider`
- **Never** call repositories from widgets—use providers

### Auth Tokens

- **Storage:** `access_token` and `refresh_token` via `flutter_secure_storage`
- **Injection:** Dio interceptor automatically adds `Authorization: Bearer <token>` to all requests
- **Token Refresh:** On **401**, interceptor calls `POST /auth/refresh` with fresh Dio instance (no interceptors), persists tokens, retries once
- **Repositories** never handle 401—`ApiClient` interceptor owns it
- **Logout:** Delete all stored keys via `_storage.deleteAll()`

### Code Conventions

**Naming:** snake_case files/variables, PascalCase classes, `_camelCase` private, `<feature>RepositoryProvider` for providers.

**Models:**
- `<Resource>Response` — deserialized from API JSON via `fromJson`
- `<Resource>Create` — serialized to API JSON via `toJson`; send only non-null fields
- Enums: snake_case strings (e.g., `MealType.breakfast` ↔ `"breakfast"`)
- `WorkoutResponse.isInProgress` → computed getter: `finishedAt == null`

**Error Handling:**
- Repository calls throw `DioException` on failure
- Wrap in `ApiError.fromDio(e)` at provider/notifier layer (never widget)
- `ApiError` extracts `detail` field from FastAPI error response

**SSE Streaming (Chat & Voice):**
- Use `ResponseType.stream` in Dio options
- Each SSE line starts with `data: ` — strip prefix, yield payload
- Stream ends with `data: [DONE]` — always `break` on this sentinel
- Generate UUID per session via `package:uuid`; reuse `session_id` across all turns

### API Endpoints (19)

| Feature | Endpoints |
|---|---|
| Auth | POST signup, login, logout, refresh |
| Food Logs | POST create, GET list (by date), DELETE |
| Workouts | POST create, GET list/detail, PATCH update, DELETE; POST/PATCH/DELETE exercises |
| Chat | POST → SSE stream |
| Voice | POST → SSE stream |

**Key Gotchas:**
- Date query params: `YYYY-MM-DD` (not ISO 8601 with time)
- PATCH is partial—omit fields you don't want to change
- Complete workout: `PATCH` with `finished_at: DateTime.now().toIso8601String()`
- Don't send explicit `null` in PATCH bodies—overwrites server data

### Testing

```bash
flutter test                                           # Run all
flutter test test/features/auth/auth_repository_test.dart  # Single file
flutter analyze                                       # Lint
dart format lib/ test/                                # Format
```

- Mock Dio with `mockito` or `mocktail`—no real HTTP calls in tests
- Each test fully isolated
- Test files: `test/features/<feature>/<name>_test.dart`

---

## Code Conventions (Both)

### Naming
- **Files/Variables:** snake_case
- **Classes:** PascalCase
- **Private:** `_camelCase` (Dart), `_private` (Python)
- **Enums:** snake_case values

### Type Hints
- **Python:** Full type hints on all functions
- **Dart:** Full type hints; leverage null safety

### Error Handling
- **Python:** Raise `HTTPException` with appropriate status codes
- **Dart:** Wrap `DioException` in `ApiError` at provider layer
- Never expose raw DB or HTTP errors to clients

### Comments
- Default: no comments (self-documenting code)
- Only add if WHY is non-obvious (hidden constraint, subtle invariant, workaround)

---

## Security Rules (Both)

### Backend
- All user-specific routes must be authenticated via Supabase Auth
- Users can only access their own data—enforce at query level
- Validate all input via Pydantic schemas—reject extra fields
- Never commit `.env` or secrets

### Frontend
- Store tokens securely via `flutter_secure_storage` (not SharedPreferences)
- Never call repositories directly from widgets—always use Riverpod providers
- Don't handle 401 in repositories—`ApiClient` interceptor owns it
- Don't use `dio` directly outside `ApiClient` (except `_tryRefresh`)
- Don't send explicit `null` in PATCH bodies

### Both
- Row-level security (RLS) enforced at database level
- Input validation at system boundaries (user input, external APIs)

---

## What NOT to Do

### Backend
- Don't put business logic in routers—use services
- Don't commit `.env` or secrets
- Don't return raw Supabase response objects—serialize via Pydantic

### Frontend
- Don't call repositories from widgets—use Riverpod providers
- Don't handle 401 in repositories—`ApiClient` interceptor owns it
- Don't use `dio` directly outside `ApiClient`
- Don't send explicit `null` in PATCH bodies
- Don't hardcode base URL in multiple places
- Don't put business logic in UI widgets

---

## Testing

### Backend
```bash
pytest                                           # All tests
pytest --cov=app --cov-report=term-missing     # Coverage
pytest tests/test_<name>.py -v                 # Single file
```

### Frontend
```bash
flutter test                                    # All tests
flutter test test/features/<feature>/<name>_test.dart  # Single
flutter analyze                                 # Lint
```

**Principles:**
- Use official async test clients (`httpx.AsyncClient` for backend, `mockito` for frontend)
- Each test fully isolated (no shared mutable state)
- Mirror test structure to source structure
- Don't make real HTTP calls in tests (mock everything)

---

## Skills Reference

### Backend

| Skill | When to Use |
|---|---|
| `/fast-api` | Creating routes, schemas, dependencies, middleware, auth, or tests |
| `/context7-mcp` | Library/framework documentation (FastAPI, Pydantic, Supabase, httpx, pytest) |
| `/clean-code-habits` | Code quality, naming, type hints, Python conventions |
| `/engineering-principles` | Service design, SOLID, KISS, DRY, design patterns |
| `/security-review` | Auth flows, Supabase RLS, input validation, secrets |
| `/verify` | Confirm fix/feature works end-to-end against running server |
| `/run` | Start dev server and observe behavior |
| `/simplify` | Refactor for clarity and efficiency |
| `/review` | Review PR before merging |
| `/code-review` | Deep code review for bugs and improvements |

### Frontend

| Skill | When to Use |
|---|---|
| `/flutter-integration` | Generate Flutter client code, models, repos, auth, SSE for Whoomz API |
| `/flutter-code-quality` | Code quality, SOLID, code smells, architecture for Flutter |
| `/context7-mcp` | Library docs (Flutter, Riverpod, Dio, speech_to_text, flutter_secure_storage) |
| `/run-flutter-*` | Animation, layouts, linting, local storage, navigation, performance, platform channels, responsive, state, Supabase, testing, theming, widgets |
| `/verify` | Confirm fix/feature works end-to-end on simulator/device |
| `/run` | Start app and observe behavior |
| `/simplify` | Refactor for clarity and efficiency |
| `/review` | Review PR before merging |
| `/code-review` | Deep code review for bugs and improvements |

### Cross-Project

| Skill | When to Use |
|---|---|
| `/context7-mcp` | Library/framework documentation (any language/framework) |
| `/security-review` | Auth flows, token handling, input validation, secrets |
| `/update-config` | Harness settings, permissions, hooks, env vars |
| `/fewer-permission-prompts` | Reduce repetitive prompts via allowlist in settings.json |

---

## Environment Variables

| Variable | Backend/Frontend | Description |
|---|---|---|
| `SUPABASE_URL` | Both | Supabase project URL |
| `SUPABASE_KEY` | Backend (service role), Frontend (anon key) | Supabase API key |

---

## Integration Points

1. **Auth Flow:**
   - Frontend: User signs up/logs in → stored tokens in secure storage
   - Backend: Validates token via Supabase Auth → returns user info
   - Frontend: Dio interceptor injects token on all requests
   - Backend: Depends() validates token, returns user_id

2. **Data Fetch:**
   - Frontend: Repository calls Dio → GET `/api/v1/<resource>`
   - Backend: Service queries Supabase → returns Pydantic response
   - Frontend: model fromJson deserializes JSON → state via Riverpod

3. **Token Refresh:**
   - Frontend: Dio interceptor detects 401
   - Fresh Dio instance (no interceptors) calls `POST /auth/refresh`
   - Backend: Validates refresh token → issues new access + refresh tokens
   - Frontend: Persists tokens, retries original request once

4. **SSE Streaming (Chat/Voice):**
   - Frontend: POST to `/api/v1/chat` or `/api/v1/voice` with `ResponseType.stream`
   - Backend: yields `data: <json>\n\n` per token, ends with `data: [DONE]\n\n`
   - Frontend: strips `data: ` prefix, yields payload, breaks on `[DONE]`

---

## Summary

| Aspect | Backend | Frontend |
|---|---|---|
| **Language** | Python 3.11+ | Dart 3.x |
| **Framework** | FastAPI | Flutter |
| **State Mgmt** | N/A (stateless API) | Riverpod |
| **Auth** | Supabase Auth (RLS at DB) | Token-based (Dio interceptor) |
| **Testing** | pytest + httpx | flutter_test + mocktail |
| **Conventions** | Async, router prefix, services | Providers, hand-written models, no direct repos |

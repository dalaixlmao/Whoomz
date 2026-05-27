# Whoomz Backend — CLAUDE.md

## Project Overview

**Whoomz** is a fitness tracking app backend built with **Python + FastAPI**. Users track daily fitness goals including calorie intake, weight changes, and calories burnt. This is the REST API layer that powers the Whoomz mobile/web app.

---

## Tech Stack

- **Language:** Python 3.11+
- **Framework:** FastAPI
- **Database & Auth:** Supabase
- **Validation:** Pydantic v2
- **Testing:** pytest + httpx (async test client)

---

## Setup

```bash
# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy env file and fill in values
cp .env.example .env

# Start dev server
uvicorn app.main:app --reload
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_KEY` | Supabase service role or anon key |

---

## Data Model

### `users`
Owned by Supabase Auth. Referenced everywhere via `user_id`.

---

### `food_logs`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | |
| name | text | "Chicken Rice Bowl" |
| calories | int | kcal |
| protein_g | float | optional |
| carbs_g | float | optional |
| fat_g | float | optional |
| meal_type | enum | breakfast / lunch / dinner / snack |
| logged_at | timestamptz | defaults to now() |

---

### `workouts`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | |
| name | text | "Leg Day", "Boxing Session" |
| notes | text | optional |
| started_at | timestamptz | |
| finished_at | timestamptz | nullable — null means in progress |

---

### `workout_exercises`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| workout_id | uuid FK | |
| exercise_name | text | "Squat", "Jump Rope", "Open Water Swim" |
| tracking_type | enum | sets_reps_weight / distance_duration / laps / duration_only / freeform |
| metrics | jsonb | flexible payload per tracking_type (see below) |
| order | int | display order within session |
| notes | text | optional |

**`metrics` shape by `tracking_type`:**
- `sets_reps_weight` → `{ sets: [{set_number, reps, weight_kg}] }`
- `distance_duration` → `{ distance_km, duration_seconds, avg_heart_rate? }`
- `laps` → `{ laps: [{lap_number, lap_time_seconds, distance_m?}] }`
- `duration_only` → `{ duration_seconds }`
- `freeform` → `{}` (notes field carries everything)

---

## Code Conventions

- **Async everywhere** — use `async def` for all route handlers and DB calls
- **Router prefix** — each router has a versioned prefix: `/api/v1/...`
- **Schemas** — separate `Create`, `Update`, and `Response` Pydantic models per resource
- **Services** — business logic lives in `services/`, not in routers
- **Dependencies** — use FastAPI `Depends()` for auth and Supabase client injection
- **Error handling** — raise `HTTPException` with appropriate status codes; never expose raw DB errors
- **Naming** — snake_case for files/variables, PascalCase for classes

---

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=term-missing

# Run a specific test file
pytest tests/test_<name>.py -v
```

- Use `AsyncClient` from `httpx` for endpoint testing
- Each test should be isolated
- Test files mirror the router structure: `tests/test_<router>.py`

---

## Security Rules

- All user-specific routes must be authenticated via Supabase Auth
- Users can only access their own data — enforce at the query level
- Validate all input via Pydantic schemas — reject extra fields
- Never commit `.env` or any secrets

---

## What NOT to Do

- Do not put business logic in routers — use services
- Do not commit `.env` or secrets
- Do not return raw Supabase response objects — always serialize via Pydantic schemas

---

## Skills Reference

Use these skills (via `/skill-name`) for common tasks in this project:

| Skill | When to Use |
|---|---|
| `/fast-api` | Creating routes, routers, schemas, dependencies, middleware, auth guards, or tests in FastAPI |
| `/context7-mcp` | Looking up docs for FastAPI, Pydantic, Supabase, httpx, pytest, or any other library used here |
| `/clean-code-habits` | Reviewing naming conventions, function length, type hints, or general Python code quality |
| `/engineering-principles` | Designing services, applying SOLID/DRY/KISS, or structuring classes and patterns |
| `/security-review` | Auditing auth flows, Supabase row-level security, input validation, or secret handling |
| `/verify` | Confirming a fix or new feature actually works end-to-end against the running server |
| `/run` | Starting the dev server and observing live app behaviour |
| `/simplify` | Refactoring changed code for reuse, clarity, and efficiency after a feature is complete |
| `/review` | Reviewing a pull request before merging |
| `/update-config` | Changing Claude Code permissions, hooks, or harness settings (`settings.json`) |
| `/fewer-permission-prompts` | Reducing repetitive permission prompts by allowlisting common read-only commands |

---
name: fast-api
description: Best practices and patterns for building FastAPI apps in Python. Use when creating routes, routers, schemas, dependencies, error handling, auth, or tests in a FastAPI project.
---

# FastAPI Best Practices

## Routers

Split routes by domain using `APIRouter`. Register in `main.py`.

```python
# routers/goals.py
from fastapi import APIRouter
from app.schemas.goal import GoalResponse

router = APIRouter(prefix="/goals", tags=["goals"])

@router.get("/")
async def get_goals() -> list[GoalResponse]:
    ...
```

```python
# main.py
app.include_router(goals.router, prefix="/api/v1")

# Apply auth to entire router at registration
app.include_router(
    admin.router,
    prefix="/api/v1/admin",
    dependencies=[Depends(verify_token)],
)
```

## Dependency Injection

Use `Depends()` for auth, DB clients, and shared logic. Prefer `Annotated`.

```python
from typing import Annotated
from fastapi import Depends

async def get_current_user(token: str = Depends(oauth2_scheme)):
    ...

@router.get("/me")
async def read_me(user: Annotated[User, Depends(get_current_user)]) -> UserResponse:
    return user
```

Use `yield` for setup/teardown (e.g. DB sessions):

```python
async def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        await db.close()
```

If you need transactions, manage begin/commit/rollback inside the dependency so callers never need to think about it:

```python
async def get_db():
    async with SessionLocal.begin() as session:
        yield session  # auto-commits on exit, auto-rolls back on exception
```

### Dependency Precedence

Apply dependencies at the right layer. In order of preference:

| Layer | How | When to use |
|---|---|---|
| **1. `APIRouter(dependencies=...)`** | `router = APIRouter(dependencies=[Depends(get_current_user)])` | Auth or shared logic required by every route in the router |
| **2. `include_router(..., dependencies=...)`** | `app.include_router(router, dependencies=[Depends(verify_token)])` | Ad-hoc override at registration time; additive on top of router-level deps |
| **3. Route-level `dependencies=[...]`** | `@router.delete("/{id}", dependencies=[Depends(require_admin)])` | Single-route concerns (e.g. role checks) that don't apply to the whole router |
| **4. Route parameter `Depends()`** | `async def route(user=Depends(get_current_user))` | When you need the resolved value in the handler body |

```python
# (1) All routes in this router require a logged-in user
router = APIRouter(dependencies=[Depends(get_current_user)])

# (3) Only this route also requires admin — additive, not a replacement
@router.delete("/{id}", dependencies=[Depends(require_admin)])
async def delete_user(id: str): ...

# (4) Need the resolved user object in the handler
@router.get("/me")
async def get_me(user: Annotated[User, Depends(get_current_user)]) -> UserResponse:
    return UserResponse.model_validate(user)
```

## Schemas

Separate `Create`, `Update`, and `Response` models. Always declare `response_model` or use return type annotation on every route — it filters fields, validates output, and drives OpenAPI docs.

```python
class GoalCreate(BaseModel):
    calories_target: int

class GoalResponse(BaseModel):
    id: str
    calories_target: int
    model_config = {"from_attributes": True}

@router.post("/goals", status_code=status.HTTP_201_CREATED)
async def create_goal(body: GoalCreate) -> GoalResponse:
    ...
```

## Error Handling

Use `HTTPException` with `status.HTTP_*` constants. Never expose raw DB errors.

```python
from fastapi import HTTPException, status

raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
raise HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)
```

## Async

Write route handlers as `async def`. All I/O performed inside them (DB, HTTP, file) must use async library APIs. If only a sync library is available, offload it with `asyncio.to_thread()`. Service and repository functions should also be `async def` when they perform I/O directly.

```python
# ✅ async I/O
@router.get("/logs")
async def get_logs() -> list[LogResponse]:
    return await db.fetch_all()

# ✅ sync-only library — offload to a thread
@router.get("/report")
async def get_report() -> ReportResponse:
    result = await asyncio.to_thread(sync_pdf_lib.generate, ...)
    return result

# ❌ blocks the event loop
@router.get("/logs")
async def get_logs():
    return requests.get("...")
```

## Lifespan

Use `lifespan` for startup/shutdown instead of deprecated `@app.on_event`. If startup fails, re-raise to prevent the app from starting.

```python
import logging
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await db.connect()
    except Exception:
        logger.exception("DB connect failed — aborting startup")
        raise
    yield
    await db.disconnect()

app = FastAPI(lifespan=lifespan)
```

## Testing

Use `AsyncClient` with `ASGITransport`. Override dependencies via `app.dependency_overrides` and always reset them after each test to prevent state leaking between tests.

```python
import pytest
from fastapi import status
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.dependencies import get_current_user

@pytest.fixture(autouse=True)
def reset_overrides():
    yield
    app.dependency_overrides.clear()  # teardown: reset after every test

@pytest.fixture
def auth_override():
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-user"}

@pytest.mark.anyio
async def test_get_goals(auth_override):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/goals")
    assert res.status_code == status.HTTP_200_OK
```

**Test isolation rules:**
- Reset `app.dependency_overrides` after every test (use an `autouse` fixture).
- Keep each test independent — don't share mutable state between tests.
- For tests that write to a real DB, use transactions that roll back on teardown, or a dedicated test DB recreated per session.

## FastAPI Conventions

### Thin Routers

Keep route handlers minimal: validate input via Pydantic, call one service function for all business logic, handle any expected domain errors, and return the service result. Do **not** perform DB queries or complex logic in routers — no direct `supabase.table(...)` calls, no business rules, no multi-step data transformations.

```python
# ✅ thin router — wiring only
@router.post("/logs", status_code=status.HTTP_201_CREATED)
async def create_log(body: LogCreate, user=Depends(get_current_user)) -> LogResponse:
    return await log_service.create(user_id=user["id"], data=body)

# ❌ fat router — business logic and DB calls leaking in
@router.post("/logs")
async def create_log(body: LogCreate, user=Depends(get_current_user)):
    if body.calories < 0:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="calories must be ≥ 0")
    result = await supabase.table("logs").insert({...}).execute()
    return result.data[0]
```

### Schemas vs ORM/DB Models

| | Pydantic Schema | DB / ORM Model |
|---|---|---|
| **Purpose** | Validate input, shape output | Represent DB table structure |
| **Lives in** | `schemas/` | `models/` |
| **Used by** | Routers, services | Services, repositories |
| **Never** | Touch DB | Returned directly from a route |

Never return a raw DB row or ORM object from a route — always pass through a Pydantic `Response` schema.

```python
# ❌ leaks DB internals
return await supabase.table("users").select("*").eq("id", uid).execute()

# ✅ serialized through schema
raw = await supabase.table("users").select("*").eq("id", uid).single().execute()
return UserResponse(**raw.data)
```

### Exception Handling

Always raise `HTTPException` — never let raw exceptions bubble to the client. Map domain errors to HTTP status codes at the service boundary.

```python
# In service
async def get_goal(goal_id: str, user_id: str) -> Goal:
    result = await supabase.table("goals").select("*").eq("id", goal_id).maybe_single().execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    if result.data["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    return Goal(**result.data)
```

Register app-wide handlers for custom exception types in `main.py`:

```python
@app.exception_handler(AuthError)
async def auth_error_handler(request: Request, exc: AuthError):
    return JSONResponse(status_code=status.HTTP_401_UNAUTHORIZED, content={"detail": str(exc)})
```

### response_model

Declare `response_model` (or return type annotation) on **every** route — it filters fields, validates output, and drives OpenAPI docs.

```python
# Preferred — return type annotation
@router.get("/me")
async def get_me(user=Depends(get_current_user)) -> UserResponse:
    ...

# Also valid — explicit response_model
@router.get("/me", response_model=UserResponse)
async def get_me(user=Depends(get_current_user)):
    ...
```

Use `response_model_exclude_unset=True` when returning partial updates so unchanged fields are omitted.

---

## Rules

- Business logic goes in `services/` — routers only call services
- Never return raw DB objects — always serialize through Pydantic schemas
- Use `status.HTTP_*` constants instead of raw integers — in routes, services, exception handlers, **and** test assertions
- Keep `SECRET_KEY` and credentials in `.env` — never hardcode
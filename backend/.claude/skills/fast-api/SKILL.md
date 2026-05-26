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
router = APIRouter(prefix="/goals", tags=["goals"])

@router.get("/")
async def get_goals():
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
async def read_me(user: Annotated[User, Depends(get_current_user)]):
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

## Schemas

Separate `Create`, `Update`, and `Response` models. Always declare `response_model` or use return type annotation.

```python
class GoalCreate(BaseModel):
    calories_target: int

class GoalResponse(BaseModel):
    id: str
    calories_target: int
    model_config = {"from_attributes": True}

@router.post("/goals")
async def create_goal(body: GoalCreate) -> GoalResponse:
    ...
```

## Error Handling

Use `HTTPException` with status constants. Never expose raw DB errors.

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

Use `async def` for all route handlers and I/O calls. Never use blocking calls inside `async def`.

```python
# ✅
@router.get("/logs")
async def get_logs():
    return await db.fetch_all()

# ❌ blocks the event loop
@router.get("/logs")
async def get_logs():
    return requests.get("...")
```

## Lifespan

Use `lifespan` for startup/shutdown instead of deprecated `@app.on_event`.

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.connect()
    yield
    await db.disconnect()

app = FastAPI(lifespan=lifespan)
```

## Testing

Use `AsyncClient` with `ASGITransport`. Override dependencies via `app.dependency_overrides`.

```python
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

app.dependency_overrides[get_current_user] = lambda: {"id": "test-user"}

@pytest.mark.anyio
async def test_get_goals():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/goals")
    assert res.status_code == 200
```

## FastAPI Conventions

### Thin Routers
Routers are just wiring — no logic, no DB calls. One line per route: validate input, call a service, return a response.

```python
# ✅ thin router
@router.post("/logs", response_model=LogResponse, status_code=status.HTTP_201_CREATED)
async def create_log(body: LogCreate, user=Depends(get_current_user)):
    return await log_service.create(user_id=user.id, data=body)

# ❌ fat router — logic leaking in
@router.post("/logs")
async def create_log(body: LogCreate, user=Depends(get_current_user)):
    if body.calories < 0:
        raise HTTPException(...)
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

### Depends()

- Use for: auth, DB client injection, pagination params, shared query logic
- Nest dependencies freely — FastAPI resolves the graph automatically
- Use `yield`-based deps for anything needing teardown
- Apply at router level for blanket auth; at route level for granular control

```python
# Blanket auth on all routes in a router
router = APIRouter(dependencies=[Depends(get_current_user)])

# Granular — only this route requires admin
@router.delete("/{id}", dependencies=[Depends(require_admin)])
async def delete_user(id: str): ...
```

### Exception Handling

Always raise `HTTPException` — never let raw exceptions bubble to the client. Map domain errors to HTTP status at the service boundary.

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
    return JSONResponse(status_code=401, content={"detail": str(exc)})
```

### Async Rules

- `async def` for all route handlers and any I/O (DB, HTTP, file)
- Never call blocking code inside `async def` — use `asyncio.to_thread()` if unavoidable
- Supabase Python client: use the async client (`AsyncClient`) — not the sync one

### response_model

Declare `response_model` (or return type annotation) on every route — it filters fields, validates output, and drives OpenAPI docs.

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
- Use `status.HTTP_*` constants instead of raw integers
- Keep `SECRET_KEY` and credentials in `.env` — never hardcode
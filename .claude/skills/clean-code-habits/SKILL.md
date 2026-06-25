---
name: clean-code-habits
description: Clean code habits for Python — naming conventions, function length, fail fast, explicit over implicit, type hints, constants, and case conventions for variables, classes, JSON fields, and database fields.
---

# Clean Code Habits

## Naming Conventions by Context

| Context | Case | Example |
|---|---|---|
| Variable / parameter | `snake_case` | `user_id`, `calories_burnt` |
| Function / method | `snake_case` | `get_user_by_id()` |
| Class | `PascalCase` | `UserService`, `GoalCreate` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT` |
| Module / file | `snake_case` | `user_service.py` |
| Type alias | `PascalCase` | `UserId = str` |
| JSON field (API) | `camelCase` | `{ "caloriesBurnt": 300 }` — or `snake_case` if consistent across the API |
| DB column | `snake_case` | `calories_burnt`, `created_at` |
| DB table | `snake_case`, plural | `users`, `daily_logs` |
| Enum member | `UPPER_SNAKE_CASE` | `GoalStatus.IN_PROGRESS` |
| Private attribute | `_leading_underscore` | `self._cache` |

> **Rule:** Pick one JSON casing and enforce it project-wide. Never mix.

---

## Naming Quality

**Name for intent, not type:**
```python
# ❌
d = datetime.now()
lst = get_users()

# ✅
created_at = datetime.now()
active_users = get_users()
```

**Booleans read as questions:**
```python
# ❌
active = True
user_verified = False

# ✅
is_active = True
has_verified_email = False
```

**Functions are verbs, classes are nouns:**
```python
# ❌
class DataProcessor: ...   # vague
def user(id): ...          # noun, not a verb

# ✅
class LogAggregator: ...
def fetch_user(user_id): ...
```

**Avoid noise words:** `data`, `info`, `manager`, `handler`, `util` signal a missing abstraction.

---

## Function Length & Focus

- **One function, one thing.** If you need "and" to describe what it does, split it.
- **Aim for ≤ 20 lines.** If it's scrolling, it's doing too much.
- **Max one level of abstraction per function** — don't mix high-level orchestration with low-level detail.

```python
# ❌ — orchestrates AND does DB work AND sends email
async def register_user(data: UserCreate):
    hashed = bcrypt.hash(data.password)
    result = await db.table("users").insert({...}).execute()
    await smtp.send(data.email, "Welcome!")
    return result

# ✅ — each function does one thing
async def register_user(data: UserCreate):
    user = await user_repo.create(data)
    await email_service.send_welcome(user.email)
    return user
```

---

## Fail Fast

Validate and reject at the earliest point. Don't let bad state propagate.

```python
# ❌ — bad state travels deep before blowing up
async def update_weight(user_id: str, weight: float):
    user = await get_user(user_id)
    log = build_log(user, weight)
    await save_log(log)  # crashes here if weight < 0

# ✅ — reject immediately
async def update_weight(user_id: str, weight: float):
    if weight <= 0:
        raise HTTPException(status_code=422, detail="Weight must be positive")
    user = await get_user(user_id)
    ...
```

Use Pydantic validators as the first line of defence — they run before your code does:

```python
from pydantic import BaseModel, field_validator

class LogCreate(BaseModel):
    calories_burnt: int
    weight_kg: float

    @field_validator("weight_kg")
    @classmethod
    def weight_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("weight must be positive")
        return v
```

---

## Explicit over Implicit

No hidden magic. The reader should not have to guess.

```python
# ❌ — what does True mean here?
create_user(data, True, False)

# ✅ — obvious at the call site
create_user(data, send_email=True, notify_admin=False)
```

```python
# ❌ — implicit return of None on error is silent
def get_user(user_id: str):
    result = db.find(user_id)
    if not result:
        return  # caller won't know why

# ✅ — raise, don't hide
def get_user(user_id: str):
    result = db.find(user_id)
    if not result:
        raise HTTPException(status_code=404, detail="User not found")
    return result
```

Avoid `**kwargs` in internal APIs — it hides what's actually required.

---

## Type Hints

Type every function signature. No exceptions.

```python
# ❌
def calculate_bmi(weight, height):
    return weight / (height ** 2)

# ✅
def calculate_bmi(weight_kg: float, height_m: float) -> float:
    return weight_kg / (height_m ** 2)
```

Use `from __future__ import annotations` at the top of files to enable forward references cleanly.

Use `Optional[X]` only when `None` is a valid meaningful value — not as a lazy default:

```python
# ❌ — None means "I didn't bother"
def get_goal(user_id: str) -> Optional[Goal]:
    ...

# ✅ — None means "user has no goal set yet"
def get_active_goal(user_id: str) -> Goal | None:
    ...
```

Use type aliases for clarity:

```python
UserId = str
CalorieCount = int

def log_intake(user_id: UserId, calories: CalorieCount) -> None:
    ...
```

---

## Constants

Never use magic numbers or strings inline.

```python
# ❌
if bmi > 30:
    ...
await asyncio.sleep(5)

# ✅
BMI_OBESE_THRESHOLD = 30.0
RETRY_DELAY_SECONDS = 5

if bmi > BMI_OBESE_THRESHOLD:
    ...
await asyncio.sleep(RETRY_DELAY_SECONDS)
```

Group related constants in an `Enum` or a dedicated `constants.py`:

```python
from enum import Enum

class GoalStatus(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    ABANDONED = "abandoned"
```

---

## Quick Pre-Commit Checks

- Does every function have type hints? → **Type Hints**
- Any magic number or string literal in logic? → **Constants**
- Can you describe the function without using "and"? → **Function Focus**
- Does bad input get rejected at the top? → **Fail Fast**
- Are keyword arguments used for boolean/flag params? → **Explicit over Implicit**
- Do names reveal intent without needing a comment? → **Naming**
- Is the JSON field casing consistent across all endpoints? → **Naming Conventions**
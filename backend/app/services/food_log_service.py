from datetime import date

from fastapi import HTTPException, status
from supabase import Client

from app.schemas.food_log import FoodLogCreate, FoodLogResponse

TABLE = "food_logs"


async def create(user_id: str, data: FoodLogCreate, supabase: Client) -> FoodLogResponse:
    payload = data.model_dump(exclude_none=True)
    payload["user_id"] = user_id

    try:
        result = supabase.table(TABLE).insert(payload).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save food log",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save food log",
        )

    return FoodLogResponse(**result.data[0])


async def list_by_date(user_id: str, log_date: date, supabase: Client) -> list[FoodLogResponse]:
    # Match all rows whose `logged_at` falls within the given calendar date (UTC).
    day_start = f"{log_date}T00:00:00+00:00"
    day_end = f"{log_date}T23:59:59.999999+00:00"

    try:
        result = (
            supabase.table(TABLE)
            .select("*")
            .eq("user_id", user_id)
            .gte("logged_at", day_start)
            .lte("logged_at", day_end)
            .order("logged_at")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch food logs",
        ) from exc

    return [FoodLogResponse(**row) for row in result.data]


async def delete(user_id: str, log_id: str, supabase: Client) -> None:
    # Fetch first to enforce ownership — never delete another user's row.
    try:
        existing = (
            supabase.table(TABLE)
            .select("id, user_id")
            .eq("id", log_id)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch food log",
        ) from exc

    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food log not found")

    if existing.data["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    try:
        supabase.table(TABLE).delete().eq("id", log_id).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not delete food log",
        ) from exc

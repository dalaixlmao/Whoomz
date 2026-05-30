from datetime import date

from fastapi import HTTPException, status
from supabase import Client

from app.schemas.weight_log import WeightLogCreate, WeightLogResponse

TABLE = "weight_logs"


async def create(user_id: str, data: WeightLogCreate, supabase: Client) -> WeightLogResponse:
    payload = data.model_dump(exclude_none=True)
    payload["user_id"] = user_id

    try:
        result = supabase.table(TABLE).insert(payload).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save weight log",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save weight log",
        )

    return WeightLogResponse(**result.data[0])


async def list_by_range(
    user_id: str,
    start_date: date,
    end_date: date,
    supabase: Client,
) -> list[WeightLogResponse]:
    range_start = f"{start_date}T00:00:00+00:00"
    range_end = f"{end_date}T23:59:59.999999+00:00"

    try:
        result = (
            supabase.table(TABLE)
            .select("*")
            .eq("user_id", user_id)
            .gte("logged_at", range_start)
            .lte("logged_at", range_end)
            .order("logged_at")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch weight logs",
        ) from exc

    return [WeightLogResponse(**row) for row in result.data]


async def delete(user_id: str, log_id: str, supabase: Client) -> None:
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
            detail="Could not fetch weight log",
        ) from exc

    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Weight log not found")

    if existing.data["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    try:
        supabase.table(TABLE).delete().eq("id", log_id).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not delete weight log",
        ) from exc

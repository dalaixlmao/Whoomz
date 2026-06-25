import logging
from datetime import date

from fastapi import HTTPException, status
from supabase import Client

from app.schemas.food_log import FoodLogCreate, FoodLogResponse

logger = logging.getLogger(__name__)
TABLE = "food_logs"


async def create(user_id: str, data: FoodLogCreate, supabase: Client) -> FoodLogResponse:
    logger.debug("Creating food log — user_id: %s, food: %s", user_id, data.name)
    payload = data.model_dump(exclude_none=True)
    payload["user_id"] = user_id

    try:
        result = supabase.table(TABLE).insert(payload).execute()
    except Exception as exc:
        logger.error("Failed to create food log — user_id: %s, error: %s", user_id, str(exc))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save food log",
        ) from exc

    if not result.data:
        logger.error("Food log creation returned no data — user_id: %s", user_id)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save food log",
        )

    logger.debug("Food log created — user_id: %s, id: %s", user_id, result.data[0]["id"])
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
    logger.debug("Deleting food log — user_id: %s, log_id: %s", user_id, log_id)
    try:
        existing = (
            supabase.table(TABLE)
            .select("id, user_id")
            .eq("id", log_id)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        logger.error("Failed to fetch food log — user_id: %s, log_id: %s", user_id, log_id)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch food log",
        ) from exc

    if not existing.data:
        logger.warning("Food log not found — user_id: %s, log_id: %s", user_id, log_id)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food log not found")

    if existing.data["user_id"] != user_id:
        logger.warning("Access denied — user_id: %s tried to delete log_id: %s (owner: %s)",
                      user_id, log_id, existing.data["user_id"])
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    try:
        supabase.table(TABLE).delete().eq("id", log_id).execute()
        logger.debug("Food log deleted — user_id: %s, log_id: %s", user_id, log_id)
    except Exception as exc:
        logger.error("Failed to delete food log — user_id: %s, log_id: %s, error: %s",
                    user_id, log_id, str(exc))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not delete food log",
        ) from exc

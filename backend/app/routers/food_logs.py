import logging
from datetime import date

from fastapi import APIRouter, Query, status

from app.dependencies import CurrentUser, UserSupabaseClient
from app.schemas.food_log import FoodLogCreate, FoodLogResponse
from app.services import food_log_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/food-logs", tags=["food-logs"])


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_food_log(
    body: FoodLogCreate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> FoodLogResponse:
    logger.info("Create food log — user_id: %s, food: %s, calories: %d", user["id"], body.name, body.calories)
    result = await food_log_service.create(user["id"], body, supabase)
    logger.info("Food log created — id: %s", result.id)
    return result


@router.get("/")
async def list_food_logs(
    user: CurrentUser,
    supabase: UserSupabaseClient,
    log_date: date = Query(..., alias="date", description="Calendar date (YYYY-MM-DD)"),
) -> list[FoodLogResponse]:
    logger.info("List food logs — user_id: %s, date: %s", user["id"], log_date)
    result = await food_log_service.list_by_date(user["id"], log_date, supabase)
    logger.info("Food logs retrieved — count: %d", len(result))
    return result


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_food_log(
    log_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> None:
    logger.info("Delete food log — user_id: %s, log_id: %s", user["id"], log_id)
    await food_log_service.delete(user["id"], log_id, supabase)
    logger.info("Food log deleted — id: %s", log_id)

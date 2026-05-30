from datetime import date

from fastapi import APIRouter, Query, status

from app.dependencies import CurrentUser, UserSupabaseClient
from app.schemas.food_log import FoodLogCreate, FoodLogResponse
from app.services import food_log_service

router = APIRouter(prefix="/food-logs", tags=["food-logs"])


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_food_log(
    body: FoodLogCreate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> FoodLogResponse:
    return await food_log_service.create(user["id"], body, supabase)


@router.get("/")
async def list_food_logs(
    user: CurrentUser,
    supabase: UserSupabaseClient,
    log_date: date = Query(..., alias="date", description="Calendar date (YYYY-MM-DD)"),
) -> list[FoodLogResponse]:
    return await food_log_service.list_by_date(user["id"], log_date, supabase)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_food_log(
    log_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> None:
    await food_log_service.delete(user["id"], log_id, supabase)

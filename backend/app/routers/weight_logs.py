from datetime import date

from fastapi import APIRouter, Query, status

from app.dependencies import CurrentUser, UserSupabaseClient
from app.schemas.weight_log import WeightLogCreate, WeightLogResponse
from app.services import weight_log_service

router = APIRouter(prefix="/weight-logs", tags=["weight-logs"])


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_weight_log(
    body: WeightLogCreate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WeightLogResponse:
    return await weight_log_service.create(user["id"], body, supabase)


@router.get("/")
async def list_weight_logs(
    user: CurrentUser,
    supabase: UserSupabaseClient,
    start_date: date = Query(..., description="Range start date (YYYY-MM-DD)"),
    end_date: date = Query(..., description="Range end date (YYYY-MM-DD)"),
) -> list[WeightLogResponse]:
    return await weight_log_service.list_by_range(user["id"], start_date, end_date, supabase)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_weight_log(
    log_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> None:
    await weight_log_service.delete(user["id"], log_id, supabase)

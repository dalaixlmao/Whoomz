from fastapi import APIRouter

from app.dependencies import SupabaseClient
from app.services import scheduler_service

router = APIRouter(prefix="/scheduler", tags=["scheduler"])


@router.post("/run-daily-notes")
async def run_daily_notes(supabase: SupabaseClient) -> dict:
    return await scheduler_service.run_daily_notes_job(supabase)

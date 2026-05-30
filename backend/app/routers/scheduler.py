from fastapi import APIRouter

from app.dependencies import get_supabase_admin
from app.services import scheduler_service

router = APIRouter(prefix="/scheduler", tags=["scheduler"])


@router.post("/run-daily-notes")
async def run_daily_notes() -> dict:
    supabase = get_supabase_admin()
    return await scheduler_service.run_daily_notes_job(supabase)

from fastapi import APIRouter

from app.dependencies import CurrentUser, SupabaseClient
from app.schemas.daily_note import DailyNoteResponse
from app.services import daily_note_service

router = APIRouter(prefix="/daily-notes", tags=["daily-notes"])


@router.get("/{note_date}")
async def get_daily_note(
    note_date: str,
    user: CurrentUser,
    supabase: SupabaseClient,
) -> DailyNoteResponse:
    return await daily_note_service.get_by_date(user["id"], note_date, supabase)

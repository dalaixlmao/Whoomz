from fastapi import APIRouter, status

from app.dependencies import CurrentUser, SupabaseClient
from app.schemas.daily_note import DailyNoteResponse, DailyNoteUpsert
from app.services import daily_note_service

router = APIRouter(prefix="/daily-notes", tags=["daily-notes"])


@router.post("/{note_date}", status_code=status.HTTP_200_OK)
async def upsert_daily_note(
    note_date: str,
    body: DailyNoteUpsert,
    user: CurrentUser,
    supabase: SupabaseClient,
) -> DailyNoteResponse:
    return await daily_note_service.upsert(user["id"], note_date, body, supabase)


@router.get("/{note_date}")
async def get_daily_note(
    note_date: str,
    user: CurrentUser,
    supabase: SupabaseClient,
) -> DailyNoteResponse:
    return await daily_note_service.get_by_date(user["id"], note_date, supabase)

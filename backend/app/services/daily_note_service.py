from fastapi import HTTPException, status
from supabase import Client

from app.schemas.daily_note import DailyNoteResponse, DailyNoteUpsert

TABLE = "daily_notes"


async def upsert(user_id: str, date_str: str, data: DailyNoteUpsert, supabase: Client) -> DailyNoteResponse:
    payload = {
        "user_id": user_id,
        "date": date_str,
        "note": data.note,
    }

    try:
        result = (
            supabase.table(TABLE)
            .upsert(payload, on_conflict="user_id,date")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save daily note",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not save daily note",
        )

    return DailyNoteResponse(**result.data[0])


async def get_by_date(user_id: str, date_str: str, supabase: Client) -> DailyNoteResponse:
    try:
        result = (
            supabase.table(TABLE)
            .select("*")
            .eq("user_id", user_id)
            .eq("date", date_str)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch daily note",
        ) from exc

    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No note for this date")

    return DailyNoteResponse(**result.data)

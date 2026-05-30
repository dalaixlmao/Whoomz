from fastapi import HTTPException, status
from supabase import Client

from app.schemas.daily_note import DailyNoteResponse

TABLE = "daily_notes"


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


async def insert(user_id: str, date_str: str, note: str, supabase: Client) -> DailyNoteResponse | None:
    """Insert a note for a user+date. Returns None if a note already exists (skip silently)."""
    existing = (
        supabase.table(TABLE)
        .select("id")
        .eq("user_id", user_id)
        .eq("date", date_str)
        .maybe_single()
        .execute()
    )
    if existing.data:
        return None

    result = supabase.table(TABLE).insert({
        "user_id": user_id,
        "date": date_str,
        "note": note,
    }).execute()

    if not result.data:
        return None

    return DailyNoteResponse(**result.data[0])

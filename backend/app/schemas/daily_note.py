from datetime import date
from uuid import UUID

from pydantic import BaseModel


class DailyNoteResponse(BaseModel):
    id: UUID
    user_id: UUID
    date: date
    note: str

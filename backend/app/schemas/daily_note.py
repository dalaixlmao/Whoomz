from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class DailyNoteUpsert(BaseModel):
    model_config = ConfigDict(extra="forbid")

    note: str


class DailyNoteResponse(BaseModel):
    id: UUID
    user_id: UUID
    date: date
    note: str

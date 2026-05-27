from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class WorkoutCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str
    notes: str | None = None
    started_at: datetime


class WorkoutUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = None
    notes: str | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None


class WorkoutResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    notes: str | None
    started_at: datetime
    finished_at: datetime | None  # None = in progress

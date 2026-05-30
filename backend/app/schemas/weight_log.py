from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class WeightLogCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    weight_kg: float
    logged_at: datetime | None = None  # defaults to now() in DB


class WeightLogResponse(BaseModel):
    id: UUID
    user_id: UUID
    weight_kg: float
    logged_at: datetime

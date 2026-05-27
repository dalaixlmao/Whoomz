from enum import StrEnum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TrackingType(StrEnum):
    sets_reps_weight = "sets_reps_weight"
    distance_duration = "distance_duration"
    laps = "laps"
    duration_only = "duration_only"
    freeform = "freeform"


class WorkoutExerciseCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exercise_name: str
    tracking_type: TrackingType
    metrics: dict[str, Any] = {}
    order: int
    notes: str | None = None


class WorkoutExerciseUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exercise_name: str | None = None
    tracking_type: TrackingType | None = None
    metrics: dict[str, Any] | None = None
    order: int | None = None
    notes: str | None = None


class WorkoutExerciseResponse(BaseModel):
    id: UUID
    workout_id: UUID
    exercise_name: str
    tracking_type: TrackingType
    metrics: dict[str, Any]
    order: int
    notes: str | None

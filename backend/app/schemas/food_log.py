from datetime import datetime
from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class MealType(StrEnum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"
    snack = "snack"


class FoodLogCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str
    calories: int
    protein_g: float | None = None
    carbs_g: float | None = None
    fat_g: float | None = None
    meal_type: MealType
    logged_at: datetime | None = None  # defaults to now() in DB


class FoodLogUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = None
    calories: int | None = None
    protein_g: float | None = None
    carbs_g: float | None = None
    fat_g: float | None = None
    meal_type: MealType | None = None
    logged_at: datetime | None = None


class FoodLogResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    calories: int
    protein_g: float | None
    carbs_g: float | None
    fat_g: float | None
    meal_type: MealType
    logged_at: datetime

import logging
from datetime import date

from fastapi import APIRouter, Query, status

from app.dependencies import CurrentUser, UserSupabaseClient
from app.schemas.workout import WorkoutCreate, WorkoutDetailResponse, WorkoutResponse, WorkoutUpdate
from app.schemas.workout_exercise import (
    WorkoutExerciseCreate,
    WorkoutExerciseResponse,
    WorkoutExerciseUpdate,
)
from app.services import workout_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/workouts", tags=["workouts"])


# ---------------------------------------------------------------------------
# Workouts
# ---------------------------------------------------------------------------


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_workout(
    body: WorkoutCreate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WorkoutResponse:
    logger.info("Create workout — user_id: %s, name: %s", user["id"], body.name)
    result = await workout_service.create_workout(user["id"], body, supabase)
    logger.info("Workout created — id: %s", result.id)
    return result


@router.get("/")
async def list_workouts(
    user: CurrentUser,
    supabase: UserSupabaseClient,
    workout_date: date | None = Query(None, alias="date", description="Filter by date (YYYY-MM-DD)"),
) -> list[WorkoutResponse]:
    return await workout_service.list_workouts(user["id"], supabase, workout_date)


@router.get("/{workout_id}")
async def get_workout(
    workout_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WorkoutDetailResponse:
    return await workout_service.get_workout_detail(workout_id, user["id"], supabase)


@router.patch("/{workout_id}")
async def update_workout(
    workout_id: str,
    body: WorkoutUpdate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WorkoutResponse:
    return await workout_service.update_workout(workout_id, user["id"], body, supabase)


@router.delete("/{workout_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_workout(
    workout_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> None:
    await workout_service.delete_workout(workout_id, user["id"], supabase)


# ---------------------------------------------------------------------------
# Exercises (nested under workouts)
# ---------------------------------------------------------------------------


@router.post("/{workout_id}/exercises", status_code=status.HTTP_201_CREATED)
async def add_exercise(
    workout_id: str,
    body: WorkoutExerciseCreate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WorkoutExerciseResponse:
    return await workout_service.add_exercise(workout_id, user["id"], body, supabase)


@router.patch("/{workout_id}/exercises/{exercise_id}")
async def update_exercise(
    workout_id: str,
    exercise_id: str,
    body: WorkoutExerciseUpdate,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> WorkoutExerciseResponse:
    return await workout_service.update_exercise(workout_id, exercise_id, user["id"], body, supabase)


@router.delete("/{workout_id}/exercises/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_exercise(
    workout_id: str,
    exercise_id: str,
    user: CurrentUser,
    supabase: UserSupabaseClient,
) -> None:
    await workout_service.delete_exercise(workout_id, exercise_id, user["id"], supabase)

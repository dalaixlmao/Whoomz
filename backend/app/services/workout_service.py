from datetime import date

from fastapi import HTTPException, status
from supabase import Client

from app.schemas.workout import WorkoutCreate, WorkoutDetailResponse, WorkoutResponse, WorkoutUpdate
from app.schemas.workout_exercise import (
    WorkoutExerciseCreate,
    WorkoutExerciseResponse,
    WorkoutExerciseUpdate,
)

WORKOUTS_TABLE = "workouts"
EXERCISES_TABLE = "workout_exercises"


# ---------------------------------------------------------------------------
# Private helper
# ---------------------------------------------------------------------------


async def _assert_workout_owned(workout_id: str, user_id: str, supabase: Client) -> dict:
    """Fetch the workout row.  Raise 404 if absent, 403 if owned by someone else.
    Returns the raw row dict on success (callers may need it).
    """
    try:
        result = (
            supabase.table(WORKOUTS_TABLE)
            .select("id, user_id")
            .eq("id", workout_id)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch workout",
        ) from exc

    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workout not found")

    if result.data["user_id"] != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    return result.data


# ---------------------------------------------------------------------------
# Workouts
# ---------------------------------------------------------------------------


async def create_workout(user_id: str, data: WorkoutCreate, supabase: Client) -> WorkoutResponse:
    payload = data.model_dump(exclude_none=True, mode="json")
    payload["user_id"] = user_id

    try:
        result = supabase.table(WORKOUTS_TABLE).insert(payload).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create workout",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create workout",
        )

    return WorkoutResponse(**result.data[0])


async def list_workouts(
    user_id: str,
    supabase: Client,
    workout_date: date | None = None,
) -> list[WorkoutResponse]:
    try:
        query = supabase.table(WORKOUTS_TABLE).select("*").eq("user_id", user_id)

        if workout_date is not None:
            day_start = f"{workout_date}T00:00:00+00:00"
            day_end = f"{workout_date}T23:59:59.999999+00:00"
            query = query.gte("started_at", day_start).lte("started_at", day_end)

        result = query.order("started_at", desc=True).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch workouts",
        ) from exc

    return [WorkoutResponse(**row) for row in result.data]


async def get_workout_detail(
    workout_id: str,
    user_id: str,
    supabase: Client,
) -> WorkoutDetailResponse:
    await _assert_workout_owned(workout_id, user_id, supabase)

    try:
        workout_result = (
            supabase.table(WORKOUTS_TABLE)
            .select("*")
            .eq("id", workout_id)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch workout",
        ) from exc

    try:
        exercises_result = (
            supabase.table(EXERCISES_TABLE)
            .select("*")
            .eq("workout_id", workout_id)
            .order("order")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch exercises",
        ) from exc

    exercises = [WorkoutExerciseResponse(**row) for row in exercises_result.data]
    return WorkoutDetailResponse(**workout_result.data, exercises=exercises)


async def update_workout(
    workout_id: str,
    user_id: str,
    data: WorkoutUpdate,
    supabase: Client,
) -> WorkoutResponse:
    await _assert_workout_owned(workout_id, user_id, supabase)

    payload = data.model_dump(exclude_unset=True, mode="json")
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No fields provided for update",
        )

    try:
        result = (
            supabase.table(WORKOUTS_TABLE)
            .update(payload)
            .eq("id", workout_id)
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not update workout",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not update workout",
        )

    return WorkoutResponse(**result.data[0])


async def delete_workout(workout_id: str, user_id: str, supabase: Client) -> None:
    await _assert_workout_owned(workout_id, user_id, supabase)

    try:
        supabase.table(WORKOUTS_TABLE).delete().eq("id", workout_id).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not delete workout",
        ) from exc


# ---------------------------------------------------------------------------
# Exercises
# ---------------------------------------------------------------------------


async def add_exercise(
    workout_id: str,
    user_id: str,
    data: WorkoutExerciseCreate,
    supabase: Client,
) -> WorkoutExerciseResponse:
    await _assert_workout_owned(workout_id, user_id, supabase)

    payload = data.model_dump(exclude_none=True, mode="json")
    payload["workout_id"] = workout_id

    try:
        result = supabase.table(EXERCISES_TABLE).insert(payload).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not add exercise",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not add exercise",
        )

    return WorkoutExerciseResponse(**result.data[0])


async def update_exercise(
    workout_id: str,
    exercise_id: str,
    user_id: str,
    data: WorkoutExerciseUpdate,
    supabase: Client,
) -> WorkoutExerciseResponse:
    await _assert_workout_owned(workout_id, user_id, supabase)

    payload = data.model_dump(exclude_unset=True, mode="json")
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No fields provided for update",
        )

    try:
        result = (
            supabase.table(EXERCISES_TABLE)
            .update(payload)
            .eq("id", exercise_id)
            .eq("workout_id", workout_id)
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not update exercise",
        ) from exc

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    return WorkoutExerciseResponse(**result.data[0])


async def delete_exercise(
    workout_id: str,
    exercise_id: str,
    user_id: str,
    supabase: Client,
) -> None:
    await _assert_workout_owned(workout_id, user_id, supabase)

    try:
        existing = (
            supabase.table(EXERCISES_TABLE)
            .select("id")
            .eq("id", exercise_id)
            .eq("workout_id", workout_id)
            .maybe_single()
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not fetch exercise",
        ) from exc

    if not existing.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")

    try:
        supabase.table(EXERCISES_TABLE).delete().eq("id", exercise_id).execute()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not delete exercise",
        ) from exc

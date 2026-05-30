"""Daily notes cron job — generates AI-written fitness summaries for active users."""

import logging
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

import anthropic
from supabase import Client

from app.config import settings

logger = logging.getLogger(__name__)

_IST = ZoneInfo("Asia/Kolkata")
_anthropic = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
MODEL = "claude-sonnet-4-6"


def _yesterday_bounds() -> tuple[date, str, str]:
    yesterday = (datetime.now(_IST) - timedelta(days=1)).date()
    day_start = f"{yesterday}T00:00:00+00:00"
    day_end = f"{yesterday}T23:59:59.999999+00:00"
    return yesterday, day_start, day_end


def _active_user_ids(day_start: str, day_end: str, supabase: Client) -> set[str]:
    food_result = (
        supabase.table("food_logs")
        .select("user_id")
        .gte("logged_at", day_start)
        .lte("logged_at", day_end)
        .execute()
    )
    workout_result = (
        supabase.table("workouts")
        .select("user_id")
        .gte("started_at", day_start)
        .lte("started_at", day_end)
        .execute()
    )
    ids: set[str] = set()
    for row in food_result.data or []:
        ids.add(row["user_id"])
    for row in workout_result.data or []:
        ids.add(row["user_id"])
    return ids


def _build_food_summary(user_id: str, day_start: str, day_end: str, supabase: Client) -> str:
    result = (
        supabase.table("food_logs")
        .select("name, calories, meal_type")
        .eq("user_id", user_id)
        .gte("logged_at", day_start)
        .lte("logged_at", day_end)
        .order("logged_at")
        .execute()
    )
    if not result.data:
        return "No food logged."
    total = sum(r["calories"] for r in result.data)
    items = ", ".join(f"{r['name']} ({r['calories']} kcal)" for r in result.data)
    return f"Food: {items}. Total: {total} kcal."


def _build_workout_summary(user_id: str, day_start: str, day_end: str, supabase: Client) -> str:
    result = (
        supabase.table("workouts")
        .select("id, name")
        .eq("user_id", user_id)
        .gte("started_at", day_start)
        .lte("started_at", day_end)
        .execute()
    )
    if not result.data:
        return "No workouts logged."
    summaries = []
    for w in result.data:
        ex_result = (
            supabase.table("workout_exercises")
            .select("exercise_name")
            .eq("workout_id", w["id"])
            .order("order")
            .execute()
        )
        exercises = [e["exercise_name"] for e in (ex_result.data or [])]
        ex_str = f" ({', '.join(exercises)})" if exercises else ""
        summaries.append(f"{w['name']}{ex_str}")
    return f"Workouts: {'; '.join(summaries)}."


def _build_weight_summary(user_id: str, yesterday: date, supabase: Client) -> str | None:
    """Return weight progress line only on Tuesday runs."""
    if datetime.now(_IST).weekday() != 1:  # 1 = Tuesday
        return None

    yesterday_result = (
        supabase.table("weight_logs")
        .select("weight_kg, logged_at")
        .eq("user_id", user_id)
        .gte("logged_at", f"{yesterday}T00:00:00+00:00")
        .lte("logged_at", f"{yesterday}T23:59:59.999999+00:00")
        .order("logged_at", desc=True)
        .limit(1)
        .execute()
    )
    if not (yesterday_result.data):
        return None

    current_weight = yesterday_result.data[0]["weight_kg"]

    week_ago = yesterday - timedelta(days=7)
    old_result = (
        supabase.table("weight_logs")
        .select("weight_kg, logged_at")
        .eq("user_id", user_id)
        .lte("logged_at", f"{week_ago}T23:59:59.999999+00:00")
        .order("logged_at", desc=True)
        .limit(1)
        .execute()
    )
    if not old_result.data:
        return None

    old_weight = old_result.data[0]["weight_kg"]
    delta = current_weight - old_weight
    direction = "down" if delta < 0 else "up"
    return f"Weight: {current_weight} kg ({direction} {abs(delta):.1f} kg vs a week ago)."


async def _generate_note(context_lines: list[str]) -> str:
    context = "\n".join(context_lines)
    response = await _anthropic.messages.create(
        model=MODEL,
        max_tokens=120,
        system=(
            "You write short, punchy daily fitness progress notes for a fitness app. "
            "1-2 sentences max. Be motivating, specific, and catchy — like the kind of "
            "one-liner you'd see in a premium wellness app. No markdown, no bullet points. "
            "Speak directly to the user using 'you'."
        ),
        messages=[{"role": "user", "content": f"Write a progress note based on:\n{context}"}],
    )
    return response.content[0].text.strip()


async def run_daily_notes_job(supabase: Client) -> dict:
    """Generate and upsert AI daily notes for all users active yesterday.

    Requires the Supabase service role key to read across all users.
    """
    yesterday, day_start, day_end = _yesterday_bounds()
    logger.info("Daily notes job started for %s", yesterday)

    user_ids = _active_user_ids(day_start, day_end, supabase)
    if not user_ids:
        logger.info("No active users yesterday — skipping note generation")
        return {"users_processed": 0, "date": str(yesterday)}

    processed = 0
    for user_id in user_ids:
        try:
            context_lines = [
                _build_food_summary(user_id, day_start, day_end, supabase),
                _build_workout_summary(user_id, day_start, day_end, supabase),
            ]
            weight_line = _build_weight_summary(user_id, yesterday, supabase)
            if weight_line:
                context_lines.append(weight_line)

            note = await _generate_note(context_lines)

            supabase.table("daily_notes").upsert(
                {"user_id": user_id, "date": str(yesterday), "note": note},
                on_conflict="user_id,date",
            ).execute()

            processed += 1
            logger.info("Generated note for user %s: %s", user_id, note)
        except Exception:
            logger.exception("Failed to generate note for user %s", user_id)

    logger.info("Daily notes job complete — %d/%d users processed", processed, len(user_ids))
    return {"users_processed": processed, "date": str(yesterday)}

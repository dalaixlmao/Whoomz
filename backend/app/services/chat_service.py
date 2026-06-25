"""Fitness coach chat service — provider-agnostic, uses centralized AIService."""

import json
import logging
from datetime import date, datetime, timezone
from typing import AsyncIterator

from supabase import Client

from app.config import settings
from app.schemas.chat import Message
from app.schemas.food_log import FoodLogCreate
from app.schemas.workout import WorkoutCreate
from app.schemas.workout_exercise import WorkoutExerciseCreate
from app.services import food_log_service, workout_service
from app.services.ai.base import ToolCallRequest, ToolDefinition, ToolResult
from app.services.ai.service import AIProviderType, AIService

logger = logging.getLogger(__name__)

MAX_HISTORY = 20

_COACH_BASE = (
    "You are Whoomz, a friendly and motivating fitness coach AI. "
    "The user is tracking calories, workouts, and body weight. "
    "Give short, conversational responses — 1-3 sentences max unless the user asks for detail. "
    "No markdown, no bullet points. Speak like a coach, not a textbook. "
    "Use the live user context below (if present) to give personalised advice. "
    "When the user mentions eating or drinking anything, call log_food_item — even if they give no calories. "
    "Use your nutritional knowledge to estimate calories, protein_g, carbs_g, and fat_g. "
    "If no quantity is given, assume one standard serving: "
    "1 bowl dal (~150 kcal), 1 roti (~100 kcal), 1 plate rice (~250 kcal), "
    "1 banana (~90 kcal), 1 cup chai (~60 kcal), 1 egg (~80 kcal), "
    "1 samosa (~180 kcal), 1 cup sabzi (~80 kcal). "
    "Always include protein_g, carbs_g, fat_g estimates. "
    "When the user explicitly says they finished a workout, call log_workout to record it "
    "along with any exercises they mention. "
    "Never fabricate workout data — only log workouts the user explicitly describes."
)

_TOOL_DEFINITIONS: list[ToolDefinition] = [
    ToolDefinition(
        name="log_food_item",
        description=(
            "Log a food or drink item to the user's food diary. "
            "Call this whenever the user mentions eating or drinking something. "
            "Estimate calories and macros from your nutritional knowledge if the user does not provide them."
        ),
        parameters={
            "properties": {
                "name": {"type": "string", "description": "Food or drink name"},
                "calories": {"type": "integer", "description": "Calories in kcal"},
                "meal_type": {
                    "type": "string",
                    "enum": ["breakfast", "lunch", "dinner", "snack"],
                    "description": "Meal category",
                },
                "protein_g": {"type": "number", "description": "Protein in grams"},
                "carbs_g": {"type": "number", "description": "Carbohydrates in grams"},
                "fat_g": {"type": "number", "description": "Fat in grams"},
            }
        },
        required=["name", "calories", "meal_type"],
    ),
    ToolDefinition(
        name="log_workout",
        description=(
            "Log a completed workout session with exercises. "
            "Call this when the user says they finished a workout."
        ),
        parameters={
            "properties": {
                "name": {"type": "string", "description": "Workout name, e.g. 'Leg Day', 'Morning Run'"},
                "notes": {"type": "string", "description": "Optional notes about the session"},
                "started_at": {
                    "type": "string",
                    "description": "ISO 8601 datetime when the workout started. Use current time if unknown.",
                },
                "exercises": {
                    "type": "array",
                    "description": "Exercises performed during the workout",
                    "items": {
                        "type": "object",
                        "properties": {
                            "exercise_name": {"type": "string"},
                            "tracking_type": {
                                "type": "string",
                                "enum": ["sets_reps_weight", "distance_duration", "laps", "duration_only", "freeform"],
                            },
                            "metrics": {
                                "type": "object",
                                "description": (
                                    "sets_reps_weight: {sets:[{set_number,reps,weight_kg}]}. "
                                    "distance_duration: {distance_km,duration_seconds}. "
                                    "laps: {laps:[{lap_number,lap_time_seconds}]}. "
                                    "duration_only: {duration_seconds}. freeform: {}"
                                ),
                            },
                            "order": {"type": "integer", "description": "1-based display order"},
                            "notes": {"type": "string"},
                        },
                        "required": ["exercise_name", "tracking_type", "metrics", "order"],
                    },
                },
            }
        },
        required=["name", "exercises"],
    ),
]

# { session_id: (owner_user_id, [Message]) }
_history: dict[str, tuple[str, list[Message]]] = {}


# ---------------------------------------------------------------------------
# SSE helpers
# ---------------------------------------------------------------------------


def _sse(data: dict) -> str:
    return f"data: {json.dumps(data)}\n\n"


_SSE_DONE = 'data: {"done": true}\n\n'


# ---------------------------------------------------------------------------
# Session management
# ---------------------------------------------------------------------------


def validate_session(session_id: str, user_id: str) -> None:
    if session_id in _history:
        owner_id, _ = _history[session_id]
        if owner_id != user_id:
            raise ValueError("Session does not belong to this user.")


def _get_or_create_session(session_id: str, user_id: str) -> list[Message]:
    if session_id not in _history:
        _history[session_id] = (user_id, [])
    _, messages = _history[session_id]
    return messages


def _trim(messages: list[Message]) -> None:
    if len(messages) > MAX_HISTORY:
        del messages[:-MAX_HISTORY]


# ---------------------------------------------------------------------------
# Live context fetching
# ---------------------------------------------------------------------------


def _fetch_user_context(user_id: str, supabase: Client) -> str:
    today = date.today()
    day_start = f"{today}T00:00:00+00:00"
    day_end = f"{today}T23:59:59.999999+00:00"

    lines: list[str] = [f"[Today: {today.isoformat()}]"]

    try:
        food_result = (
            supabase.table("food_logs")
            .select("name, calories, meal_type")
            .eq("user_id", user_id)
            .gte("logged_at", day_start)
            .lte("logged_at", day_end)
            .order("logged_at")
            .execute()
        )
        if food_result.data:
            total_kcal = sum(r["calories"] for r in food_result.data)
            items = ", ".join(
                f"{r['name']} ({r['calories']} kcal, {r['meal_type']})" for r in food_result.data
            )
            lines.append(f"Today's food logs: {items}. Total: {total_kcal} kcal.")
        else:
            lines.append("No food logged today yet.")
    except Exception:
        logger.warning("Could not fetch food logs for context", exc_info=True)

    try:
        workout_result = (
            supabase.table("workouts")
            .select("id, name, started_at")
            .eq("user_id", user_id)
            .is_("finished_at", "null")
            .limit(1)
            .execute()
        )
        if workout_result.data:
            w = workout_result.data[0]
            lines.append(f"Active workout in progress: \"{w['name']}\" (started {w['started_at']}).")
        else:
            lines.append("No workout currently in progress.")
    except Exception:
        logger.warning("Could not fetch active workout for context", exc_info=True)

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Tool execution
# ---------------------------------------------------------------------------


async def _run_log_food(tool_input: dict, user_id: str, supabase: Client) -> tuple[str, str]:
    try:
        data = FoodLogCreate(**tool_input)
        log = await food_log_service.create(user_id, data, supabase)
        return (
            _sse({"action": "food_logged", "data": log.model_dump(mode="json")}),
            f"Logged: {log.name}, {log.calories} kcal ({log.meal_type})",
        )
    except Exception as exc:
        logger.warning("log_food_item tool failed: %s", exc, exc_info=True)
        return _sse({"action": "log_failed", "tool": "log_food_item"}), f"Failed to log food: {exc}"


async def _run_log_workout(tool_input: dict, user_id: str, supabase: Client) -> tuple[str, str]:
    try:
        exercises_raw: list[dict] = tool_input.get("exercises", [])
        started_at_raw = tool_input.get("started_at") or datetime.now(timezone.utc).isoformat()
        workout_data = WorkoutCreate(
            name=tool_input["name"],
            notes=tool_input.get("notes"),
            started_at=started_at_raw,
        )
        workout = await workout_service.create_workout(user_id, workout_data, supabase)

        exercises = []
        for i, ex in enumerate(exercises_raw):
            ex_data = WorkoutExerciseCreate(
                exercise_name=ex["exercise_name"],
                tracking_type=ex["tracking_type"],
                metrics=ex.get("metrics", {}),
                order=ex.get("order", i + 1),
                notes=ex.get("notes"),
            )
            exercise = await workout_service.add_exercise(str(workout.id), user_id, ex_data, supabase)
            exercises.append(exercise.model_dump(mode="json"))

        payload = workout.model_dump(mode="json")
        payload["exercises"] = exercises
        return (
            _sse({"action": "workout_logged", "data": payload}),
            f"Logged workout '{workout.name}' with {len(exercises)} exercise(s)",
        )
    except Exception as exc:
        logger.warning("log_workout tool failed: %s", exc)
        return _sse({"action": "log_failed", "tool": "log_workout"}), f"Failed to log workout: {exc}"


async def _execute_tool(tc: ToolCallRequest, user_id: str, supabase: Client) -> tuple[str, ToolResult]:
    if tc.name == "log_food_item":
        action_sse, result = await _run_log_food(tc.args, user_id, supabase)
    elif tc.name == "log_workout":
        action_sse, result = await _run_log_workout(tc.args, user_id, supabase)
    else:
        logger.warning("Unknown tool called by model: %s", tc.name)
        action_sse = _sse({"action": "unknown_tool", "tool": tc.name})
        result = "Unknown tool"

    return action_sse, ToolResult(name=tc.name, result=result)


# ---------------------------------------------------------------------------
# Public service function
# ---------------------------------------------------------------------------


async def chat(
    user_id: str,
    session_id: str,
    message: str,
    supabase: Client,
    token: str,
) -> AsyncIterator[str]:
    """Stream SSE events for a chat turn with live user context.

    Yields:
        ``data: {"text": "<sentence>"}\\n\\n``                     — streamed text
        ``data: {"action": "food_logged", "data": {...}}\\n\\n``   — food stored
        ``data: {"action": "workout_logged", "data": {...}}\\n\\n`` — workout stored
        ``data: {"action": "log_failed", "tool": "..."}\\n\\n``    — storage error
        ``data: {"done": true}\\n\\n``                             — terminal event
    """
    supabase.postgrest.auth(token)

    messages = _get_or_create_session(session_id, user_id)
    messages.append(Message(role="user", content=message))
    _trim(messages)

    live_context = _fetch_user_context(user_id, supabase)
    system_prompt = f"{_COACH_BASE}\n\nLive user context:\n{live_context}"
    api_messages = [{"role": m.role, "content": m.content} for m in messages]

    ai = AIService(provider=AIProviderType(settings.ai_provider))
    yielded: list[str] = []
    pending_tool_calls: list[ToolCallRequest] = []

    try:
        async for raw in ai.stream(api_messages, system_prompt, tools=_TOOL_DEFINITIONS):
            data = json.loads(raw[len("data: "):].strip())
            if data.get("__tool_call__"):
                pending_tool_calls.append(ToolCallRequest(name=data["name"], args=data["args"]))
            else:
                yield raw
                if text := data.get("text"):
                    yielded.append(text)

        if pending_tool_calls:
            logger.info("Tool use triggered: %s", [tc.name for tc in pending_tool_calls])
            tool_results: list[ToolResult] = []
            for tc in pending_tool_calls:
                logger.info("Executing tool: %s with args: %s", tc.name, tc.args)
                action_sse, tool_result = await _execute_tool(tc, user_id, supabase)
                yield action_sse
                tool_results.append(tool_result)

            async for raw in ai.stream_after_tools(api_messages, system_prompt, pending_tool_calls, tool_results):
                data = json.loads(raw[len("data: "):].strip())
                yield raw
                if text := data.get("text"):
                    yielded.append(text)

    except Exception as exc:
        logger.error("AI service error: %s", exc, exc_info=True)
        yield _sse({"error": "AI service error, please try again."})
        yield _SSE_DONE
        return

    if assistant_reply := " ".join(yielded):
        messages.append(Message(role="assistant", content=assistant_reply))
        _trim(messages)

    yield _SSE_DONE

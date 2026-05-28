"""Fitness coach chat service — Anthropic streaming with live Supabase context."""

import json
import logging
import re
from datetime import date, timezone
from typing import AsyncIterator

import anthropic
from supabase import Client

from app.config import settings
from app.schemas.chat import Message

logger = logging.getLogger(__name__)

MODEL = "claude-sonnet-4-6"
MAX_HISTORY = 20
MAX_TOKENS = 512

_COACH_BASE = (
    "You are Whoomz, a friendly and motivating fitness coach AI. "
    "The user is tracking calories, workouts, and body weight. "
    "Give short, conversational responses — 1-3 sentences max unless the user asks for detail. "
    "No markdown, no bullet points. Speak like a coach, not a textbook. "
    "Use the live user context below (if present) to give personalised advice."
)

_SENTENCE_END = re.compile(r"(?<=[.!?])\s+|(?<=[.!?])$")

_anthropic = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

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
    """Raise ValueError if session_id exists and belongs to a different user."""
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
                f"{r['name']} ({r['calories']} kcal, {r['meal_type']})"
                for r in food_result.data
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
# Public service function
# ---------------------------------------------------------------------------


async def chat(
    user_id: str,
    session_id: str,
    message: str,
    supabase: Client,
) -> AsyncIterator[str]:
    """Stream SSE events for a chat turn with live user context.

    Yields:
        ``data: {"text": "<sentence>"}\\n\\n``  — one per sentence boundary
        ``data: {"done": true}\\n\\n``           — terminal event
    """
    messages = _get_or_create_session(session_id, user_id)
    messages.append(Message(role="user", content=message))
    _trim(messages)

    live_context = _fetch_user_context(user_id, supabase)
    system_prompt = f"{_COACH_BASE}\n\nLive user context:\n{live_context}"

    api_messages = [{"role": m.role, "content": m.content} for m in messages]

    sentence_buffer = ""
    yielded: list[str] = []

    try:
        async with _anthropic.messages.stream(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=system_prompt,
            messages=api_messages,
        ) as stream:
            async for token in stream.text_stream:
                sentence_buffer += token
                parts = _SENTENCE_END.split(sentence_buffer)
                while len(parts) > 1:
                    sentence = parts.pop(0).strip()
                    if sentence:
                        yield _sse({"text": sentence})
                        yielded.append(sentence)
                    sentence_buffer = parts[0] if parts else ""

    except anthropic.APIStatusError as exc:
        logger.error("Anthropic API error %s: %s", exc.status_code, exc.message)
        yield _sse({"error": "AI service error, please try again."})
        yield _SSE_DONE
        return
    except anthropic.APIConnectionError:
        logger.exception("Anthropic connection error")
        yield _sse({"error": "Could not reach AI service, please try again."})
        yield _SSE_DONE
        return

    if remainder := sentence_buffer.strip():
        yield _sse({"text": remainder})
        yielded.append(remainder)

    if assistant_reply := " ".join(yielded):
        messages.append(Message(role="assistant", content=assistant_reply))
        _trim(messages)

    yield _SSE_DONE

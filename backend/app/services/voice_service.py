"""Voice chat service — provider-agnostic fitness coach with SSE streaming."""

import json
import logging
from typing import AsyncIterator

from app.config import settings
from app.schemas.voice import Message
from app.services.ai.service import AIProviderType, AIService

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

MAX_HISTORY = 20

SYSTEM_PROMPT = (
    "You are Whoomz, a friendly fitness coach AI. "
    "The user is tracking calories, weight, and workouts. "
    "Give short, conversational responses — 1-3 sentences max. "
    "No markdown, no bullet points. Speak like a coach, not a textbook."
)

# ---------------------------------------------------------------------------
# SSE helpers
# ---------------------------------------------------------------------------


def _sse(data: dict) -> str:
    return f"data: {json.dumps(data)}\n\n"


_SSE_DONE = 'data: {"done": true}\n\n'

# ---------------------------------------------------------------------------
# In-memory history store: { session_id: (user_id, [Message]) }
# ---------------------------------------------------------------------------

_history: dict[str, tuple[str, list[Message]]] = {}


def validate_session(session_id: str, user_id: str) -> None:
    """Raise ValueError if *session_id* exists and belongs to a different user.

    Call this eagerly in the router (before creating the StreamingResponse) so
    the error surfaces as an HTTPException rather than an unhandled generator
    exception mid-stream.
    """
    if session_id in _history:
        owner_id, _ = _history[session_id]
        if owner_id != user_id:
            raise ValueError("Session does not belong to this user.")


def _get_or_create_session(session_id: str, user_id: str) -> list[Message]:
    """Return the message list for *session_id*, creating it if needed.

    Assumes ownership has already been validated via :func:`validate_session`.
    """
    if session_id not in _history:
        _history[session_id] = (user_id, [])
    _, messages = _history[session_id]
    return messages


def _build_api_messages(messages: list[Message]) -> list[dict]:
    return [{"role": m.role, "content": m.content} for m in messages]


# ---------------------------------------------------------------------------
# Public service function
# ---------------------------------------------------------------------------


async def chat(
    user_id: str,
    session_id: str,
    transcript: str,
) -> AsyncIterator[str]:
    """Stream SSE events for a voice chat turn.

    Yields:
        ``data: {"text": "<sentence>"}\\n\\n``  — one per sentence boundary
        ``data: {"done": true}\\n\\n``           — terminal event
    """
    messages = _get_or_create_session(session_id, user_id)
    messages.append(Message(role="user", content=transcript))
    if len(messages) > MAX_HISTORY:
        del messages[:-MAX_HISTORY]

    api_messages = _build_api_messages(messages)
    ai = AIService(provider=AIProviderType(settings.ai_provider))
    yielded: list[str] = []

    try:
        async for raw in ai.stream(api_messages, SYSTEM_PROMPT, tools=None):
            data = json.loads(raw[len("data: "):].strip())
            if text := data.get("text"):
                yield raw
                yielded.append(text)
    except Exception:
        logger.exception("AI service error in voice chat")
        yield _sse({"error": "AI service error, please try again."})
        yield _SSE_DONE
        return

    if assistant_reply := " ".join(yielded):
        messages.append(Message(role="assistant", content=assistant_reply))
        if len(messages) > MAX_HISTORY:
            del messages[:-MAX_HISTORY]

    yield _SSE_DONE

"""Voice chat service — Anthropic-powered fitness coach with SSE streaming."""

import json
import logging
import re
from typing import AsyncIterator

import anthropic

from app.config import settings
from app.schemas.voice import Message

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

MODEL = "claude-sonnet-4-6"
MAX_HISTORY = 20  # messages per session (hard cap to control token spend)
MAX_TOKENS = 256  # response tokens — short, coach-style replies

SYSTEM_PROMPT = (
    "You are Whoomz, a friendly fitness coach AI. "
    "The user is tracking calories, weight, and workouts. "
    "Give short, conversational responses — 1-3 sentences max. "
    "No markdown, no bullet points. Speak like a coach, not a textbook."
)

# Sentence-boundary detection: split after . ! ? followed by whitespace or EOS
_SENTENCE_END = re.compile(r"(?<=[.!?])\s+|(?<=[.!?])$")

# Shared client — one instance reuses the connection pool across all requests
_anthropic = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

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

    sentence_buffer = ""
    yielded: list[str] = []  # completed sentences, used to build the assistant history entry

    try:
        async with _anthropic.messages.stream(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=SYSTEM_PROMPT,
            messages=_build_api_messages(messages),
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
        if len(messages) > MAX_HISTORY:
            del messages[:-MAX_HISTORY]

    yield _SSE_DONE

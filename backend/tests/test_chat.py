"""Tests for POST /api/v1/chat/."""

import json
from collections.abc import AsyncIterator
from unittest.mock import MagicMock, patch

import anthropic
import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.dependencies import get_current_user, get_supabase
from app.main import app
from app.schemas.chat import Message
from app.services import chat_service

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

FAKE_USER = {"id": "user-123", "email": "test@whoomz.app"}
VALID_PAYLOAD = {"session_id": "sess-abc", "message": "How many calories today?"}


# ---------------------------------------------------------------------------
# Fake Anthropic stream helpers
# ---------------------------------------------------------------------------


class _FakeTextStream:
    def __init__(self, tokens: list[str]):
        self._tokens = tokens

    def __aiter__(self):
        return self._iter()

    async def _iter(self):
        for t in self._tokens:
            yield t


class _FakeStreamCtx:
    """Async context manager that yields tokens from text_stream."""

    def __init__(self, tokens: list[str]):
        self.text_stream = _FakeTextStream(tokens)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        pass


class _ErrorStreamCtx:
    """Async context manager that raises on __aenter__ to simulate Anthropic errors."""

    def __init__(self, exc: Exception):
        self._exc = exc

    async def __aenter__(self):
        raise self._exc

    async def __aexit__(self, *args):
        pass


# ---------------------------------------------------------------------------
# Router-level fake stream (patches chat_service.chat entirely)
# ---------------------------------------------------------------------------


async def _fake_chat_stream(*args, **kwargs) -> AsyncIterator[str]:
    yield 'data: {"text": "Great job!"}\n\n'
    yield 'data: {"text": "Keep it up."}\n\n'
    yield 'data: {"done": true}\n\n'


# ---------------------------------------------------------------------------
# Supabase mock builder
# ---------------------------------------------------------------------------


def _mock_supabase():
    sb = MagicMock()
    chain = MagicMock()
    for method in ("select", "insert", "update", "delete", "eq", "gte", "lte", "order", "is_", "limit", "maybe_single"):
        getattr(chain, method).return_value = chain
    sb.table.return_value = chain
    return sb, chain


def _default_context_responses(chain):
    """Two sequential execute() returns used by _fetch_user_context: food logs then workouts."""
    chain.execute.side_effect = [
        MagicMock(data=[]),  # food_logs: empty
        MagicMock(data=[]),  # workouts: no active session
    ]


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_chat_history():
    chat_service._history.clear()
    yield
    chat_service._history.clear()


@pytest.fixture
def auth_override():
    app.dependency_overrides[get_current_user] = lambda: FAKE_USER


@pytest.fixture
def full_override():
    """Auth + Supabase both overridden with default context responses."""
    sb, chain = _mock_supabase()
    _default_context_responses(chain)
    app.dependency_overrides[get_current_user] = lambda: FAKE_USER
    app.dependency_overrides[get_supabase] = lambda: sb
    return sb, chain


# ---------------------------------------------------------------------------
# Group 1: Router layer (service mocked)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_authenticated_chat_streams_sentences(auth_override):
    with patch.object(chat_service, "chat", side_effect=_fake_chat_stream):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/chat/", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_200_OK
    assert "text/event-stream" in response.headers["content-type"]

    events = [line for line in response.text.splitlines() if line.startswith("data:")]
    payloads = [json.loads(e.removeprefix("data: ")) for e in events]

    assert len(payloads) == 3
    assert payloads[0] == {"text": "Great job!"}
    assert payloads[1] == {"text": "Keep it up."}
    assert payloads[2] == {"done": True}


@pytest.mark.anyio
async def test_unauthenticated_request_returns_401():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_session_ownership_mismatch_returns_403():
    chat_service._history["shared-sess"] = ("user-A", [])
    app.dependency_overrides[get_current_user] = lambda: {"id": "user-B", "email": "b@test.com"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/chat/",
            json={"session_id": "shared-sess", "message": "sneaky"},
        )

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_new_session_by_second_user_is_allowed():
    chat_service._history["sess-A"] = ("user-A", [])
    app.dependency_overrides[get_current_user] = lambda: {"id": "user-B", "email": "b@test.com"}

    with patch.object(chat_service, "chat", side_effect=_fake_chat_stream):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/chat/",
                json={"session_id": "sess-B", "message": "hello"},
            )

    assert response.status_code == status.HTTP_200_OK


@pytest.mark.anyio
async def test_response_headers_include_no_cache(auth_override):
    with patch.object(chat_service, "chat", side_effect=_fake_chat_stream):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/chat/", json=VALID_PAYLOAD)

    assert response.headers.get("cache-control") == "no-cache"
    assert response.headers.get("x-accel-buffering") == "no"


# ---------------------------------------------------------------------------
# Group 2: Schema validation
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_empty_message_returns_422(auth_override):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json={"session_id": "s", "message": ""})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_empty_session_id_returns_422(auth_override):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json={"session_id": "", "message": "hello"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_missing_message_returns_422(auth_override):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json={"session_id": "s"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_missing_session_id_returns_422(auth_override):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json={"message": "hello"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_extra_fields_in_request_rejected(auth_override):
    payload = {**VALID_PAYLOAD, "evil": "injected"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_invalid_mode_returns_422(auth_override):
    payload = {**VALID_PAYLOAD, "mode": "fax"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/chat/", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_voice_mode_accepted(auth_override):
    payload = {**VALID_PAYLOAD, "mode": "voice"}
    with patch.object(chat_service, "chat", side_effect=_fake_chat_stream):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/chat/", json=payload)

    assert response.status_code == status.HTTP_200_OK


# ---------------------------------------------------------------------------
# Group 3: Service — session management (direct unit tests, no HTTP)
# ---------------------------------------------------------------------------


def test_validate_session_passes_for_new_session():
    chat_service.validate_session("brand-new-sess", "user-123")  # must not raise


def test_validate_session_passes_for_correct_owner():
    chat_service._history["my-sess"] = ("user-123", [])
    chat_service.validate_session("my-sess", "user-123")  # must not raise


def test_validate_session_raises_for_different_owner():
    chat_service._history["my-sess"] = ("user-A", [])
    with pytest.raises(ValueError, match="does not belong"):
        chat_service.validate_session("my-sess", "user-B")


# ---------------------------------------------------------------------------
# Group 4: Service — streaming & history (Anthropic mocked, service called directly)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_sentence_buffering_splits_on_punctuation():
    sb, chain = _mock_supabase()
    _default_context_responses(chain)

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Hello world!", " How are you?"])
        events = [chunk async for chunk in chat_service.chat("user-123", "s1", "hi", sb)]

    payloads = [json.loads(e.removeprefix("data: ").strip()) for e in events]
    text_events = [p for p in payloads if "text" in p]

    assert len(text_events) == 2
    assert text_events[0]["text"] == "Hello world!"
    assert text_events[1]["text"] == "How are you?"
    assert payloads[-1] == {"done": True}


@pytest.mark.anyio
async def test_remainder_without_trailing_punctuation_is_flushed():
    sb, chain = _mock_supabase()
    _default_context_responses(chain)

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["No punctuation here"])
        events = [chunk async for chunk in chat_service.chat("user-123", "s1", "hi", sb)]

    payloads = [json.loads(e.removeprefix("data: ").strip()) for e in events]
    text_events = [p for p in payloads if "text" in p]

    assert len(text_events) == 1
    assert text_events[0]["text"] == "No punctuation here"
    assert payloads[-1] == {"done": True}


@pytest.mark.anyio
async def test_history_saved_after_successful_turn():
    sb, chain = _mock_supabase()
    _default_context_responses(chain)

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Good work!"])
        async for _ in chat_service.chat("user-123", "sess-h", "Push harder!", sb):
            pass

    _, messages = chat_service._history["sess-h"]
    assert len(messages) == 2
    assert messages[0].role == "user"
    assert messages[0].content == "Push harder!"
    assert messages[1].role == "assistant"
    assert "Good work!" in messages[1].content


@pytest.mark.anyio
async def test_history_trimmed_when_over_max():
    sb, chain = _mock_supabase()
    _default_context_responses(chain)

    seed = [
        Message(role="user" if i % 2 == 0 else "assistant", content=f"msg-{i}")
        for i in range(chat_service.MAX_HISTORY)
    ]
    chat_service._history["sess-trim"] = ("user-123", seed)

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Nice!"])
        async for _ in chat_service.chat("user-123", "sess-trim", "One more", sb):
            pass

    _, messages = chat_service._history["sess-trim"]
    assert len(messages) <= chat_service.MAX_HISTORY


# ---------------------------------------------------------------------------
# Group 5: Service — Supabase context (Supabase + Anthropic mocked)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_food_logs_fetched_for_context():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=[{"name": "Oats", "calories": 350, "meal_type": "breakfast"}]),
        MagicMock(data=[]),  # no active workout
    ]

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Great!"])
        async for _ in chat_service.chat("user-123", "s1", "hi", sb):
            pass

    table_calls = [call.args[0] for call in sb.table.call_args_list]
    assert "food_logs" in table_calls


@pytest.mark.anyio
async def test_active_workout_fetched_for_context():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=[]),  # no food logs
        MagicMock(data=[{"id": "w1", "name": "Leg Day", "started_at": "2026-05-28T09:00:00+00:00"}]),
    ]

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Keep going!"])
        async for _ in chat_service.chat("user-123", "s1", "hi", sb):
            pass

    table_calls = [call.args[0] for call in sb.table.call_args_list]
    assert "workouts" in table_calls
    chain.is_.assert_called_with("finished_at", "null")


@pytest.mark.anyio
async def test_supabase_context_error_does_not_crash_stream():
    sb = MagicMock()
    sb.table.side_effect = Exception("DB unreachable")

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _FakeStreamCtx(["Still here!"])
        events = [chunk async for chunk in chat_service.chat("user-123", "s1", "hi", sb)]

    payloads = [json.loads(e.removeprefix("data: ").strip()) for e in events]
    assert payloads[-1] == {"done": True}


# ---------------------------------------------------------------------------
# Group 6: Anthropic error handling (via HTTP, full dependency override)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_anthropic_api_status_error_emits_sse_error(full_override):
    mock_response = MagicMock()
    mock_response.status_code = 500
    exc = anthropic.APIStatusError("Server error", response=mock_response, body=None)

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _ErrorStreamCtx(exc)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/chat/", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_200_OK
    events = [line for line in response.text.splitlines() if line.startswith("data:")]
    payloads = [json.loads(e.removeprefix("data: ")) for e in events]

    assert any("error" in p for p in payloads)
    assert payloads[-1] == {"done": True}


@pytest.mark.anyio
async def test_anthropic_connection_error_emits_sse_error(full_override):
    exc = anthropic.APIConnectionError(request=MagicMock())

    with patch.object(chat_service, "_anthropic") as mock_client:
        mock_client.messages.stream.return_value = _ErrorStreamCtx(exc)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/chat/", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_200_OK
    events = [line for line in response.text.splitlines() if line.startswith("data:")]
    payloads = [json.loads(e.removeprefix("data: ")) for e in events]

    assert any("error" in p for p in payloads)
    assert payloads[-1] == {"done": True}

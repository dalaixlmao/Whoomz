"""Tests for POST /api/v1/voice/chat."""

import json
from collections.abc import AsyncIterator
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.dependencies import get_current_user
from app.main import app
from app.services import voice_service

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FAKE_USER = {"id": "user-123", "email": "coach@whoomz.app"}

VALID_PAYLOAD = {"session_id": "sess-abc", "transcript": "How many calories should I eat today?"}


async def _fake_chat_stream(*args, **kwargs) -> AsyncIterator[str]:
    """Return two sentences as SSE events, then the done sentinel."""
    yield 'data: {"text": "Great question!"}\n\n'
    yield 'data: {"text": "Aim for around 2000 calories."}\n\n'
    yield 'data: {"done": true}\n\n'


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_overrides():
    """Always clear dependency overrides after each test."""
    yield
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_voice_history():
    """Clear in-memory session history between tests."""
    voice_service._history.clear()
    yield
    voice_service._history.clear()


@pytest.fixture
def auth_override():
    """Inject a fake authenticated user."""
    app.dependency_overrides[get_current_user] = lambda: FAKE_USER


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_authenticated_chat_streams_sentences(auth_override):
    """Authenticated request streams sentence events followed by done."""
    with patch.object(voice_service, "chat", side_effect=_fake_chat_stream):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/voice/chat", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_200_OK
    assert "text/event-stream" in response.headers["content-type"]

    raw = response.text
    events = [line for line in raw.splitlines() if line.startswith("data:")]
    payloads = [json.loads(e.removeprefix("data: ")) for e in events]

    # Two sentence events + one done event
    assert len(payloads) == 3
    assert payloads[0] == {"text": "Great question!"}
    assert payloads[1] == {"text": "Aim for around 2000 calories."}
    assert payloads[2] == {"done": True}


@pytest.mark.anyio
async def test_unauthenticated_request_returns_401():
    """Request with no auth header must be rejected with 401."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/voice/chat", json=VALID_PAYLOAD)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_empty_transcript_returns_422(auth_override):
    """Pydantic must reject an empty transcript string."""
    payload = {"session_id": "sess-abc", "transcript": ""}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/voice/chat", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_missing_session_id_returns_422(auth_override):
    """Missing session_id must return 422."""
    payload = {"transcript": "How are my calories?"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/voice/chat", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_session_ownership_mismatch_returns_403():
    """A session pre-seeded by one user cannot be accessed by another."""
    # Pre-seed history under user-A
    voice_service._history["shared-sess"] = (
        "user-A",
        [],
    )

    # Override auth to user-B
    app.dependency_overrides[get_current_user] = lambda: {"id": "user-B", "email": "b@test.com"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/api/v1/voice/chat",
            json={"session_id": "shared-sess", "transcript": "Am I allowed?"},
        )

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_extra_fields_in_request_are_rejected(auth_override):
    """Extra fields must be rejected (extra='forbid' on schema)."""
    payload = {**VALID_PAYLOAD, "evil_field": "injected"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/api/v1/voice/chat", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

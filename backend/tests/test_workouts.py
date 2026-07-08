"""Tests for /api/v1/workouts endpoints."""

from unittest.mock import MagicMock

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.dependencies import get_current_user, get_supabase, get_user_supabase
from app.main import app

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE = "/api/v1/workouts"

USER_ID = "00000000-0000-0000-0000-000000000001"
OTHER_USER_ID = "00000000-0000-0000-0000-000000000002"
WORKOUT_ID = "00000000-0000-0000-0000-000000000010"
EXERCISE_ID = "00000000-0000-0000-0000-000000000020"

FAKE_USER = {"id": USER_ID, "email": "user@whoomz.app"}

VALID_WORKOUT = {
    "name": "Morning Run",
    "started_at": "2024-03-15T07:00:00+00:00",
}

DB_WORKOUT = {
    "id": WORKOUT_ID,
    "user_id": USER_ID,
    "name": "Morning Run",
    "notes": None,
    "started_at": "2024-03-15T07:00:00+00:00",
    "finished_at": None,
}

VALID_EXERCISE = {
    "exercise_name": "Bench Press",
    "tracking_type": "sets_reps_weight",
    "metrics": {"sets": 3, "reps": 10, "weight_kg": 80},
    "order": 1,
}

DB_EXERCISE = {
    "id": EXERCISE_ID,
    "workout_id": WORKOUT_ID,
    "exercise_name": "Bench Press",
    "tracking_type": "sets_reps_weight",
    "metrics": {"sets": 3, "reps": 10, "weight_kg": 80},
    "order": 1,
    "notes": None,
}

OWNED_ROW = {"id": WORKOUT_ID, "user_id": USER_ID}
OTHER_ROW = {"id": WORKOUT_ID, "user_id": OTHER_USER_ID}


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def auth_override():
    """All workout tests run as an authenticated user by default."""
    app.dependency_overrides[get_current_user] = lambda: FAKE_USER
    app.dependency_overrides[get_user_supabase] = lambda: MagicMock()


def _mock_supabase():
    """Chainable Supabase mock.  Includes .update() for PATCH operations."""
    sb = MagicMock()
    chain = MagicMock()
    for method in ("select", "insert", "update", "delete", "eq",
                   "gte", "lte", "order", "maybe_single"):
        getattr(chain, method).return_value = chain
    sb.table.return_value = chain
    return sb, chain


# ---------------------------------------------------------------------------
# POST /workouts
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_create_workout_returns_201():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_WORKOUT])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_WORKOUT)

    assert response.status_code == status.HTTP_201_CREATED
    body = response.json()
    assert body["id"] == WORKOUT_ID
    assert body["name"] == "Morning Run"
    assert body["user_id"] == USER_ID
    assert body["finished_at"] is None


@pytest.mark.anyio
async def test_create_workout_injects_user_id():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_WORKOUT])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.post(f"{BASE}/", json=VALID_WORKOUT)

    inserted = chain.insert.call_args[0][0]
    assert inserted["user_id"] == USER_ID


@pytest.mark.anyio
async def test_create_workout_with_notes():
    row = {**DB_WORKOUT, "notes": "Felt strong today"}
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[row])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/", json={**VALID_WORKOUT, "notes": "Felt strong today"}
        )

    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["notes"] == "Felt strong today"


@pytest.mark.anyio
async def test_create_workout_missing_started_at_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json={"name": "Run"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_workout_missing_name_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/", json={"started_at": "2024-03-15T07:00:00+00:00"}
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_workout_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json={**VALID_WORKOUT, "evil": "x"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_workout_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_WORKOUT)

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_create_workout_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_WORKOUT)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# GET /workouts?date= (optional)
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_list_workouts_no_date_returns_all():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_WORKOUT])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/")

    assert response.status_code == status.HTTP_200_OK
    assert len(response.json()) == 1


@pytest.mark.anyio
async def test_list_workouts_with_date_calls_range_filters():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_WORKOUT])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "2024-03-15"})

    assert response.status_code == status.HTTP_200_OK
    assert chain.gte.called
    assert chain.lte.called


@pytest.mark.anyio
async def test_list_workouts_no_date_skips_range_filters():
    """Without a date param, gte/lte must NOT be called."""
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.get(f"{BASE}/")

    assert not chain.gte.called
    assert not chain.lte.called


@pytest.mark.anyio
async def test_list_workouts_invalid_date_format_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "15-03-2024"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_list_workouts_empty_returns_empty_list():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/")

    assert response.status_code == status.HTTP_200_OK
    assert response.json() == []


@pytest.mark.anyio
async def test_list_workouts_filters_by_user_id():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[])
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.get(f"{BASE}/")

    eq_calls = [call.args for call in chain.eq.call_args_list]
    assert ("user_id", USER_ID) in eq_calls


@pytest.mark.anyio
async def test_list_workouts_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/")

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_list_workouts_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# GET /workouts/{workout_id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_get_workout_detail_returns_200_with_exercises():
    sb, chain = _mock_supabase()
    # 3 sequential execute() calls: ownership check → full workout → exercises
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=DB_WORKOUT),
        MagicMock(data=[DB_EXERCISE]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["id"] == WORKOUT_ID
    assert len(body["exercises"]) == 1
    assert body["exercises"][0]["id"] == EXERCISE_ID


@pytest.mark.anyio
async def test_get_workout_detail_empty_exercises():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=DB_WORKOUT),
        MagicMock(data=[]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_200_OK
    assert response.json()["exercises"] == []


@pytest.mark.anyio
async def test_get_workout_detail_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_get_workout_detail_wrong_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_get_workout_detail_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_get_workout_detail_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# PATCH /workouts/{workout_id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_patch_workout_returns_200():
    updated_row = {**DB_WORKOUT, "name": "Evening Run"}
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[updated_row]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "Evening Run"})

    assert response.status_code == status.HTTP_200_OK
    assert response.json()["name"] == "Evening Run"


@pytest.mark.anyio
async def test_patch_workout_only_sends_provided_fields():
    """model_dump(exclude_unset=True) must not send unprovided fields to the DB."""
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[DB_WORKOUT]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "New Name"})

    update_payload = chain.update.call_args[0][0]
    assert "name" in update_payload
    assert "notes" not in update_payload
    assert "finished_at" not in update_payload


@pytest.mark.anyio
async def test_patch_workout_empty_body_returns_422():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [MagicMock(data=OWNED_ROW)]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_patch_workout_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "X"})

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_patch_workout_wrong_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "X"})

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_patch_workout_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"evil": "x"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_patch_workout_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "X"})

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_patch_workout_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(f"{BASE}/{WORKOUT_ID}", json={"name": "X"})

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# DELETE /workouts/{workout_id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_delete_workout_returns_204():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_204_NO_CONTENT


@pytest.mark.anyio
async def test_delete_workout_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_delete_workout_wrong_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_delete_workout_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_delete_workout_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# POST /workouts/{workout_id}/exercises
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_add_exercise_returns_201():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[DB_EXERCISE]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    assert response.status_code == status.HTTP_201_CREATED
    body = response.json()
    assert body["id"] == EXERCISE_ID
    assert body["workout_id"] == WORKOUT_ID
    assert body["exercise_name"] == "Bench Press"


@pytest.mark.anyio
async def test_add_exercise_injects_workout_id():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[DB_EXERCISE]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    inserted = chain.insert.call_args[0][0]
    assert inserted["workout_id"] == WORKOUT_ID


@pytest.mark.anyio
async def test_add_exercise_workout_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_add_exercise_wrong_workout_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_add_exercise_invalid_tracking_type_returns_422():
    bad = {**VALID_EXERCISE, "tracking_type": "invalid_type"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=bad)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_add_exercise_missing_order_returns_422():
    bad = {k: v for k, v in VALID_EXERCISE.items() if k != "order"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=bad)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_add_exercise_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/{WORKOUT_ID}/exercises", json={**VALID_EXERCISE, "evil": "x"}
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_add_exercise_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_add_exercise_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/{WORKOUT_ID}/exercises", json=VALID_EXERCISE)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# PATCH /workouts/{workout_id}/exercises/{exercise_id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_patch_exercise_returns_200():
    updated = {**DB_EXERCISE, "exercise_name": "Squat"}
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[updated]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}",
            json={"exercise_name": "Squat"},
        )

    assert response.status_code == status.HTTP_200_OK
    assert response.json()["exercise_name"] == "Squat"


@pytest.mark.anyio
async def test_patch_exercise_only_sends_provided_fields():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[DB_EXERCISE]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}",
            json={"order": 2},
        )

    update_payload = chain.update.call_args[0][0]
    assert "order" in update_payload
    assert "exercise_name" not in update_payload


@pytest.mark.anyio
async def test_patch_exercise_empty_body_returns_422():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [MagicMock(data=OWNED_ROW)]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={}
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_patch_exercise_workout_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"order": 2}
        )

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_patch_exercise_wrong_workout_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"order": 2}
        )

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_patch_exercise_exercise_not_found_returns_404():
    """update() returning empty data means the exercise doesn't exist in this workout."""
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=[]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"order": 2}
        )

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_patch_exercise_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"evil": "x"}
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_patch_exercise_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"order": 2}
        )

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_patch_exercise_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.patch(
            f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}", json={"order": 2}
        )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# DELETE /workouts/{workout_id}/exercises/{exercise_id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_delete_exercise_returns_204():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),                  # ownership check
        MagicMock(data={"id": EXERCISE_ID}),         # existence check
        MagicMock(data=[]),                          # delete
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_204_NO_CONTENT


@pytest.mark.anyio
async def test_delete_exercise_workout_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_delete_exercise_wrong_workout_owner_returns_403():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=OTHER_ROW)
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_delete_exercise_exercise_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = [
        MagicMock(data=OWNED_ROW),
        MagicMock(data=None),   # existence check → not found
    ]
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_delete_exercise_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb
    app.dependency_overrides[get_user_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_delete_exercise_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{WORKOUT_ID}/exercises/{EXERCISE_ID}")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED

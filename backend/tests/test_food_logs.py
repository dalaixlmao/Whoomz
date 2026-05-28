"""Tests for /api/v1/food-logs endpoints."""

from unittest.mock import MagicMock

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.dependencies import get_current_user, get_supabase
from app.main import app

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE = "/api/v1/food-logs"

USER_ID = "00000000-0000-0000-0000-000000000001"
LOG_ID = "00000000-0000-0000-0000-000000000099"
OTHER_USER_ID = "00000000-0000-0000-0000-000000000002"

FAKE_USER = {"id": USER_ID, "email": "user@whoomz.app"}

VALID_LOG = {
    "name": "Chicken Rice Bowl",
    "calories": 650,
    "protein_g": 45.0,
    "carbs_g": 70.0,
    "fat_g": 12.0,
    "meal_type": "lunch",
}

DB_ROW = {
    "id": LOG_ID,
    "user_id": USER_ID,
    "name": "Chicken Rice Bowl",
    "calories": 650,
    "protein_g": 45.0,
    "carbs_g": 70.0,
    "fat_g": 12.0,
    "meal_type": "lunch",
    "logged_at": "2024-03-15T12:30:00+00:00",
}

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_overrides():
    yield
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def auth_override():
    """All food-log tests run as an authenticated user by default."""
    app.dependency_overrides[get_current_user] = lambda: FAKE_USER


def _mock_supabase() -> MagicMock:
    """Return a chainable Supabase mock.

    Every builder method (table, select, insert, …) returns `self` so that
    arbitrary method chains resolve without AttributeError. The final
    `.execute()` is configured per-test.
    """
    sb = MagicMock()
    # Make every attribute access on sb.table(…) return the same mock so
    # chains like .select().eq().gte().lte().order().execute() all work.
    chain = MagicMock()
    chain.select.return_value = chain
    chain.insert.return_value = chain
    chain.delete.return_value = chain
    chain.eq.return_value = chain
    chain.gte.return_value = chain
    chain.lte.return_value = chain
    chain.order.return_value = chain
    chain.maybe_single.return_value = chain
    sb.table.return_value = chain
    return sb, chain


# ---------------------------------------------------------------------------
# POST /food-logs/
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_create_food_log_returns_201():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_ROW])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_LOG)

    assert response.status_code == status.HTTP_201_CREATED
    body = response.json()
    assert body["id"] == LOG_ID
    assert body["name"] == "Chicken Rice Bowl"
    assert body["calories"] == 650
    assert body["meal_type"] == "lunch"
    assert body["user_id"] == USER_ID


@pytest.mark.anyio
async def test_create_food_log_injects_user_id():
    """The service must inject the authenticated user's id, never trust the body."""
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_ROW])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.post(f"{BASE}/", json=VALID_LOG)

    inserted = sb.table.return_value.insert.call_args[0][0]
    assert inserted["user_id"] == FAKE_USER["id"]


@pytest.mark.anyio
async def test_create_food_log_optional_macros_omitted():
    """A log with no macro fields should still be accepted."""
    minimal = {"name": "Black Coffee", "calories": 5, "meal_type": "breakfast"}
    row = {**DB_ROW, "name": "Black Coffee", "calories": 5,
           "protein_g": None, "carbs_g": None, "fat_g": None, "meal_type": "breakfast"}

    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[row])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=minimal)

    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["name"] == "Black Coffee"


@pytest.mark.anyio
async def test_create_food_log_invalid_meal_type_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json={**VALID_LOG, "meal_type": "brunch"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_food_log_missing_calories_returns_422():
    payload = {k: v for k, v in VALID_LOG.items() if k != "calories"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=payload)

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_food_log_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json={**VALID_LOG, "evil": "x"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_create_food_log_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB error")
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_LOG)

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_create_food_log_unauthenticated_returns_401():
    app.dependency_overrides.clear()  # remove auth override

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/", json=VALID_LOG)

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# GET /food-logs?date=
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_list_food_logs_returns_rows_for_date():
    LOG_ID_2 = "00000000-0000-0000-0000-000000000088"
    row2 = {**DB_ROW, "id": LOG_ID_2, "name": "Salad", "calories": 300, "meal_type": "lunch"}
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[DB_ROW, row2])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "2024-03-15"})

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert len(body) == 2
    assert body[0]["id"] == LOG_ID
    assert body[1]["id"] == LOG_ID_2


@pytest.mark.anyio
async def test_list_food_logs_empty_date_returns_empty_list():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "2020-01-01"})

    assert response.status_code == status.HTTP_200_OK
    assert response.json() == []


@pytest.mark.anyio
async def test_list_food_logs_missing_date_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/")

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_list_food_logs_invalid_date_format_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "15-03-2024"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_list_food_logs_filters_by_user_id():
    """Query must include an eq filter on user_id."""
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=[])
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        await client.get(f"{BASE}/", params={"date": "2024-03-15"})

    eq_calls = [call.args for call in chain.eq.call_args_list]
    assert ("user_id", FAKE_USER["id"]) in eq_calls


@pytest.mark.anyio
async def test_list_food_logs_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"{BASE}/", params={"date": "2024-03-15"})

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ---------------------------------------------------------------------------
# DELETE /food-logs/{id}
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_delete_food_log_returns_204():
    sb, chain = _mock_supabase()
    # First execute: ownership check. Second: delete.
    chain.execute.side_effect = [
        MagicMock(data={"id": LOG_ID, "user_id": USER_ID}),
        MagicMock(data=[]),
    ]
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{LOG_ID}")

    assert response.status_code == status.HTTP_204_NO_CONTENT


@pytest.mark.anyio
async def test_delete_food_log_not_found_returns_404():
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(data=None)
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{LOG_ID}")

    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_delete_food_log_wrong_owner_returns_403():
    """A user must not be able to delete another user's log."""
    sb, chain = _mock_supabase()
    chain.execute.return_value = MagicMock(
        data={"id": LOG_ID, "user_id": OTHER_USER_ID}
    )
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{LOG_ID}")

    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.anyio
async def test_delete_food_log_supabase_error_returns_400():
    sb, chain = _mock_supabase()
    chain.execute.side_effect = Exception("DB connection lost")
    app.dependency_overrides[get_supabase] = lambda: sb

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{LOG_ID}")

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_delete_food_log_unauthenticated_returns_401():
    app.dependency_overrides.clear()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.delete(f"{BASE}/{LOG_ID}")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED

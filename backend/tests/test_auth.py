"""Tests for POST /api/v1/auth/{signup,login,logout,refresh}."""

from unittest.mock import MagicMock

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.dependencies import get_supabase
from app.main import app

# ---------------------------------------------------------------------------
# Helpers / builders
# ---------------------------------------------------------------------------

BASE = "/api/v1/auth"


def _make_user(id_="user-uuid-123", email="test@whoomz.app", name="Test User"):
    """Return a mock Supabase user object."""
    user = MagicMock()
    user.id = id_
    user.email = email
    user.user_metadata = {"name": name}
    return user


def _make_session(access="access-token-abc", refresh="refresh-token-xyz"):
    """Return a mock Supabase session object."""
    session = MagicMock()
    session.access_token = access
    session.refresh_token = refresh
    return session


def _make_supabase(*, sign_up_response=None, sign_in_response=None,
                   sign_out_side_effect=None, refresh_response=None):
    """Build a mock Supabase client pre-configured for each auth method."""
    client = MagicMock()
    if sign_up_response is not None:
        client.auth.sign_up.return_value = sign_up_response
    if sign_in_response is not None:
        client.auth.sign_in_with_password.return_value = sign_in_response
    if sign_out_side_effect is not None:
        client.auth.sign_out.side_effect = sign_out_side_effect
    else:
        client.auth.sign_out.return_value = None
    if refresh_response is not None:
        client.auth.refresh_session.return_value = refresh_response
    return client


def _auth_response_ok(user=None, session=None):
    """Supabase response with both user and session present."""
    resp = MagicMock()
    resp.user = user or _make_user()
    resp.session = session or _make_session()
    return resp


def _auth_response_no_session():
    """Supabase response where session is None (e.g. email confirmation required)."""
    resp = MagicMock()
    resp.user = _make_user()
    resp.session = None
    return resp


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_overrides():
    """Always clear dependency overrides after each test."""
    yield
    app.dependency_overrides.clear()


def _override_supabase(client):
    app.dependency_overrides[get_supabase] = lambda: client


# ---------------------------------------------------------------------------
# POST /auth/signup
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_signup_success_returns_201_with_tokens():
    mock_sb = _make_supabase(sign_up_response=_auth_response_ok())
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"name": "Test User", "email": "test@whoomz.app", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_201_CREATED
    body = response.json()
    assert body["access_token"] == "access-token-abc"
    assert body["refresh_token"] == "refresh-token-xyz"
    assert body["token_type"] == "bearer"
    assert body["user"]["email"] == "test@whoomz.app"
    assert body["user"]["name"] == "Test User"


@pytest.mark.anyio
async def test_signup_no_session_returns_400():
    """When Supabase requires email confirmation it returns no session."""
    mock_sb = _make_supabase(sign_up_response=_auth_response_no_session())
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"name": "User", "email": "confirm@whoomz.app", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_signup_supabase_error_returns_400():
    """Supabase raising (e.g. email already registered) maps to 400."""
    mock_sb = MagicMock()
    mock_sb.auth.sign_up.side_effect = Exception("User already registered")
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"name": "User", "email": "dupe@whoomz.app", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_signup_invalid_email_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"name": "User", "email": "not-an-email", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_signup_missing_name_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"email": "test@whoomz.app", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_signup_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/signup",
            json={"name": "User", "email": "test@whoomz.app", "password": "secret123", "evil": "x"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_login_success_returns_200_with_tokens():
    mock_sb = _make_supabase(sign_in_response=_auth_response_ok())
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/login",
            json={"email": "test@whoomz.app", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["access_token"] == "access-token-abc"
    assert body["refresh_token"] == "refresh-token-xyz"
    assert body["token_type"] == "bearer"
    assert body["user"]["id"] == "user-uuid-123"


@pytest.mark.anyio
async def test_login_wrong_password_returns_401():
    mock_sb = MagicMock()
    mock_sb.auth.sign_in_with_password.side_effect = Exception("Invalid login credentials")
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/login",
            json={"email": "test@whoomz.app", "password": "wrongpassword"},
        )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_login_missing_password_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/login",
            json={"email": "test@whoomz.app"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_login_invalid_email_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/login",
            json={"email": "not-valid", "password": "secret123"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_login_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/login",
            json={"email": "test@whoomz.app", "password": "secret123", "extra": "x"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


# ---------------------------------------------------------------------------
# POST /auth/logout
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_logout_success_returns_204():
    mock_sb = _make_supabase()
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/logout",
            headers={"Authorization": "Bearer valid-access-token"},
        )

    assert response.status_code == status.HTTP_204_NO_CONTENT
    mock_sb.auth.sign_out.assert_called_once_with("valid-access-token")


@pytest.mark.anyio
async def test_logout_no_auth_header_returns_401():
    """Missing Bearer token must be rejected before the service is called."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/logout")

    # HTTPBearer returns 401 when the header is absent (FastAPI ≥ 0.95)
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_logout_supabase_error_returns_400():
    mock_sb = _make_supabase(sign_out_side_effect=Exception("Token expired"))
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/logout",
            headers={"Authorization": "Bearer bad-token"},
        )

    assert response.status_code == status.HTTP_400_BAD_REQUEST


# ---------------------------------------------------------------------------
# POST /auth/refresh
# ---------------------------------------------------------------------------


@pytest.mark.anyio
async def test_refresh_success_returns_200_with_new_tokens():
    new_session = _make_session(access="new-access-token", refresh="new-refresh-token")
    mock_sb = _make_supabase(refresh_response=_auth_response_ok(session=new_session))
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/refresh",
            json={"refresh_token": "old-refresh-token"},
        )

    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["access_token"] == "new-access-token"
    assert body["refresh_token"] == "new-refresh-token"
    mock_sb.auth.refresh_session.assert_called_once_with("old-refresh-token")


@pytest.mark.anyio
async def test_refresh_expired_token_returns_401():
    mock_sb = MagicMock()
    mock_sb.auth.refresh_session.side_effect = Exception("Refresh token expired")
    _override_supabase(mock_sb)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/refresh",
            json={"refresh_token": "expired-token"},
        )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.anyio
async def test_refresh_missing_token_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(f"{BASE}/refresh", json={})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.anyio
async def test_refresh_extra_field_returns_422():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            f"{BASE}/refresh",
            json={"refresh_token": "tok", "extra": "x"},
        )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

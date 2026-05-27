from fastapi import HTTPException, status
from supabase import Client

from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, SignupRequest, UserInfo


def _build_auth_response(session, user) -> AuthResponse:
    """Build a normalised AuthResponse from a Supabase session + user."""
    name: str | None = None
    if user.user_metadata:
        name = user.user_metadata.get("name") or user.user_metadata.get("full_name")

    return AuthResponse(
        access_token=session.access_token,
        refresh_token=session.refresh_token,
        user=UserInfo(
            id=str(user.id),
            email=user.email or "",
            name=name,
        ),
    )


async def signup(data: SignupRequest, supabase: Client) -> AuthResponse:
    try:
        response = supabase.auth.sign_up(
            {
                "email": data.email,
                "password": data.password,
                "options": {"data": {"name": data.name}},
            }
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    if response.user is None or response.session is None:
        # Supabase returns a user but no session when email confirmation is required
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signup succeeded but no session was returned. "
            "Check if email confirmation is required.",
        )

    return _build_auth_response(response.session, response.user)


async def login(data: LoginRequest, supabase: Client) -> AuthResponse:
    try:
        response = supabase.auth.sign_in_with_password(
            {"email": data.email, "password": data.password}
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if response.session is None or response.user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return _build_auth_response(response.session, response.user)


async def logout(access_token: str, supabase: Client) -> None:
    try:
        supabase.auth.sign_out(access_token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Logout failed",
        ) from exc


async def refresh(data: RefreshRequest, supabase: Client) -> AuthResponse:
    try:
        response = supabase.auth.refresh_session(data.refresh_token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if response.session is None or response.user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return _build_auth_response(response.session, response.user)

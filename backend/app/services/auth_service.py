import logging

from fastapi import HTTPException, status
from supabase import Client

from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, SignupRequest, UserInfo

logger = logging.getLogger(__name__)


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
    logger.info("Signup service — email: %s", data.email)
    try:
        response = supabase.auth.sign_up(
            {
                "email": data.email,
                "password": data.password,
                "options": {"data": {"name": data.name}},
            }
        )
    except Exception as exc:
        logger.error("Signup service error — email: %s, error: %s", data.email, str(exc))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    if response.user is None or response.session is None:
        logger.warning("Signup service — email confirmation required: %s", data.email)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signup succeeded but no session was returned. "
            "Check if email confirmation is required.",
        )

    logger.info("Signup service success — user_id: %s", response.user.id)
    return _build_auth_response(response.session, response.user)


async def login(data: LoginRequest, supabase: Client) -> AuthResponse:
    logger.info("Login service — email: %s", data.email)
    try:
        response = supabase.auth.sign_in_with_password(
            {"email": data.email, "password": data.password}
        )
    except Exception as exc:
        logger.warning("Login service error — email: %s", data.email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if response.session is None or response.user is None:
        logger.warning("Login service — invalid credentials: %s", data.email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    logger.info("Login service success — user_id: %s", response.user.id)
    return _build_auth_response(response.session, response.user)


async def logout(access_token: str, supabase: Client) -> None:
    logger.info("Logout service")
    try:
        supabase.auth.sign_out(access_token)
        logger.info("Logout service success")
    except Exception as exc:
        logger.error("Logout service error: %s", str(exc))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Logout failed",
        ) from exc


async def refresh(data: RefreshRequest, supabase: Client) -> AuthResponse:
    logger.info("Refresh service")
    try:
        response = supabase.auth.refresh_session(data.refresh_token)
    except Exception as exc:
        logger.warning("Refresh service — invalid token")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if response.session is None or response.user is None:
        logger.warning("Refresh service — session or user is None")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    logger.info("Refresh service success")
    return _build_auth_response(response.session, response.user)

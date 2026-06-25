import logging
from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.dependencies import SupabaseClient
from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, SignupRequest
from app.services import auth_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])

_bearer = HTTPBearer()

BearerCredentials = Annotated[HTTPAuthorizationCredentials, Depends(_bearer)]


@router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(body: SignupRequest, supabase: SupabaseClient) -> AuthResponse:
    logger.info("Signup request — email: %s", body.email)
    result = await auth_service.signup(body, supabase)
    logger.info("Signup successful — user_id: %s", result.user.id)
    return result


@router.post("/login")
async def login(body: LoginRequest, supabase: SupabaseClient) -> AuthResponse:
    logger.info("Login request — email: %s", body.email)
    result = await auth_service.login(body, supabase)
    logger.info("Login successful — user_id: %s", result.user.id)
    return result


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(credentials: BearerCredentials, supabase: SupabaseClient) -> None:
    logger.info("Logout request")
    await auth_service.logout(credentials.credentials, supabase)
    logger.info("Logout successful")


@router.post("/refresh")
async def refresh(body: RefreshRequest, supabase: SupabaseClient) -> AuthResponse:
    logger.info("Token refresh request")
    result = await auth_service.refresh(body, supabase)
    logger.info("Token refresh successful")
    return result

from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.dependencies import SupabaseClient
from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, SignupRequest
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])

_bearer = HTTPBearer()

BearerCredentials = Annotated[HTTPAuthorizationCredentials, Depends(_bearer)]


@router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(body: SignupRequest, supabase: SupabaseClient) -> AuthResponse:
    return await auth_service.signup(body, supabase)


@router.post("/login")
async def login(body: LoginRequest, supabase: SupabaseClient) -> AuthResponse:
    return await auth_service.login(body, supabase)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(credentials: BearerCredentials, supabase: SupabaseClient) -> None:
    await auth_service.logout(credentials.credentials, supabase)


@router.post("/refresh")
async def refresh(body: RefreshRequest, supabase: SupabaseClient) -> AuthResponse:
    return await auth_service.refresh(body, supabase)

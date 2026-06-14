from typing import Annotated, TypedDict

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google import genai as google_genai
from openai import AsyncOpenAI
from supabase import Client, create_client

from app.config import settings

_bearer = HTTPBearer()


class AuthUser(TypedDict):
    id: str
    email: str
    token: str


def get_supabase() -> Client:
    return create_client(settings.supabase_url, settings.supabase_key)


def get_supabase_admin() -> Client:
    """Service role client — bypasses RLS. Use only for server-side jobs, never for user requests."""
    return create_client(settings.supabase_url, settings.supabase_service_key)


SupabaseClient = Annotated[Client, Depends(get_supabase)]


def get_user_supabase(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
) -> Client:
    client = create_client(settings.supabase_url, settings.supabase_key)
    client.postgrest.auth(credentials.credentials)
    return client


UserSupabaseClient = Annotated[Client, Depends(get_user_supabase)]


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
    supabase: SupabaseClient,
) -> AuthUser:
    token = credentials.credentials
    try:
        response = supabase.auth.get_user(token)
        return AuthUser(id=response.user.id, email=response.user.email or "", token=token)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


CurrentUser = Annotated[AuthUser, Depends(get_current_user)]


def get_openai_client() -> AsyncOpenAI:
    return AsyncOpenAI(api_key=settings.openai_api_key)


OpenAIClient = Annotated[AsyncOpenAI, Depends(get_openai_client)]


def get_gemini_client() -> google_genai.Client:
    return google_genai.Client(api_key=settings.gemini_api_key)


GeminiClient = Annotated[google_genai.Client, Depends(get_gemini_client)]

from fastapi import APIRouter

from app.schemas.health import HealthResponse

router = APIRouter(prefix="/health", tags=["health"])

APP_VERSION = "0.1.0"


@router.get("/", summary="Health check")
async def health_check() -> HealthResponse:
    return HealthResponse(status="ok", version=APP_VERSION)

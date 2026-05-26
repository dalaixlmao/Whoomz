import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.routers import health, voice

logger = logging.getLogger(__name__)

API_PREFIX = "/api/v1"


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Whoomz backend starting up...")
    yield
    logger.info("Whoomz backend shutting down.")


app = FastAPI(
    title="Whoomz API",
    description="Fitness tracking REST API — calories, weight, and daily goals.",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(health.router, prefix=API_PREFIX)
app.include_router(voice.router, prefix=API_PREFIX)

import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.dependencies import get_supabase_admin
from app.routers import auth, chat, daily_notes, food_logs, health, scheduler, voice, weight_logs, workouts
from app.services.scheduler_service import run_daily_notes_job

logger = logging.getLogger(__name__)

API_PREFIX = "/api/v1"


@asynccontextmanager
async def lifespan(app: FastAPI):
    _scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")
    _scheduler.add_job(
        run_daily_notes_job,
        CronTrigger.from_crontab(settings.daily_notes_cron, timezone="Asia/Kolkata"),
        args=[get_supabase_admin()],
    )
    _scheduler.start()
    logger.info("Scheduler started — daily notes cron: %s (Asia/Kolkata)", settings.daily_notes_cron)
    yield
    _scheduler.shutdown()
    logger.info("Whoomz backend shutting down.")


app = FastAPI(
    title="Whoomz API",
    description="Fitness tracking REST API — calories, weight, and daily goals.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix=API_PREFIX)
app.include_router(chat.router, prefix=API_PREFIX)
app.include_router(voice.router, prefix=API_PREFIX)
app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(food_logs.router, prefix=API_PREFIX)
app.include_router(workouts.router, prefix=API_PREFIX)
app.include_router(weight_logs.router, prefix=API_PREFIX)
app.include_router(daily_notes.router, prefix=API_PREFIX)
app.include_router(scheduler.router, prefix=API_PREFIX)

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    supabase_url: str
    supabase_key: str
    supabase_service_key: str
    anthropic_api_key: str
    openai_api_key: str
    gemini_api_key: str
    ai_provider: str

    # Daily notes cron expression (minute hour day month day_of_week), timezone = Asia/Kolkata
    daily_notes_cron: str = "5 0 * * *"  # 12:05 AM IST

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()  # type: ignore[call-arg]

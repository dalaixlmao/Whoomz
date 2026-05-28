from typing import Literal

from pydantic import BaseModel, Field


class Message(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    model_config = {"extra": "forbid"}

    session_id: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)
    mode: Literal["text", "voice"] = "text"

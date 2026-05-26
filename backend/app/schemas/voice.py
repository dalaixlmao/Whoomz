from typing import Literal

from pydantic import BaseModel, Field


class Message(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class VoiceChatRequest(BaseModel):
    model_config = {"extra": "forbid"}

    session_id: str = Field(..., min_length=1)
    transcript: str = Field(..., min_length=1)


class VoiceChatResponse(BaseModel):
    text: str
    session_id: str

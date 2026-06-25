"""Voice chat router — POST /api/v1/voice/chat."""

import logging

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import StreamingResponse

from app.dependencies import CurrentUser
from app.schemas.voice import VoiceChatRequest
from app.services import voice_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/voice", tags=["voice"])


@router.post(
    "/chat",
    summary="Send a voice transcript and receive a streamed fitness-coach reply",
    response_class=StreamingResponse,
)
async def voice_chat(
    body: VoiceChatRequest,
    user: CurrentUser,
) -> StreamingResponse:
    logger.info("Voice chat request — user_id: %s, session_id: %s", user["id"], body.session_id)
    try:
        voice_service.validate_session(session_id=body.session_id, user_id=user["id"])
    except ValueError as exc:
        logger.warning("Voice chat validation error — user_id: %s, error: %s", user["id"], str(exc))
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        )

    event_stream = voice_service.chat(
        user_id=user["id"],
        session_id=body.session_id,
        transcript=body.transcript,
    )

    return StreamingResponse(
        event_stream,
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )

"""Voice chat router — POST /api/v1/voice/chat."""

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import StreamingResponse

from app.dependencies import CurrentUser
from app.schemas.voice import VoiceChatRequest
from app.services import voice_service

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
    # Validate session ownership eagerly — before the StreamingResponse is
    # created — so the ValueError surfaces here (as an HTTPException) rather
    # than mid-stream where FastAPI can no longer convert it.
    try:
        voice_service.validate_session(session_id=body.session_id, user_id=user["id"])
    except ValueError as exc:
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
            "X-Accel-Buffering": "no",  # disable nginx buffering for SSE
        },
    )

"""Chat router — POST /api/v1/chat."""

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import StreamingResponse

from app.dependencies import CurrentUser, SupabaseClient
from app.schemas.chat import ChatRequest
from app.services import chat_service

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post(
    "/",
    summary="Send a message to the fitness coach and receive a streamed reply",
    response_class=StreamingResponse,
)
async def chat(
    body: ChatRequest,
    user: CurrentUser,
    supabase: SupabaseClient,
) -> StreamingResponse:
    try:
        chat_service.validate_session(session_id=body.session_id, user_id=user["id"])
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc))

    event_stream = chat_service.chat(
        user_id=user["id"],
        session_id=body.session_id,
        message=body.message,
        supabase=supabase,
    )

    return StreamingResponse(
        event_stream,
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )

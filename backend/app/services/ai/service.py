"""Centralized AI service — factory + context using the Strategy pattern."""

import re
from enum import StrEnum
from typing import AsyncIterator

from app.services.ai.base import AIProvider, StreamEvent, TextChunk, ToolCallRequest, ToolDefinition, ToolResult

_SENTENCE_END = re.compile(r"(?<=[.!?])\s+|(?<=[.!?])$")


class AIProviderType(StrEnum):
    GEMINI = "gemini"
    OPENAI = "openai"


def create_ai_provider(provider: AIProviderType) -> AIProvider:
    """Factory — returns the concrete strategy for the requested provider."""
    if provider == AIProviderType.GEMINI:
        from app.services.ai.gemini import GeminiProvider
        return GeminiProvider()
    if provider == AIProviderType.OPENAI:
        from app.services.ai.openai import OpenAIProvider
        return OpenAIProvider()
    raise ValueError(f"Unknown AI provider: {provider}")


class AIService:
    """Context class that delegates to the chosen AIProvider strategy.

    Handles sentence-level streaming and the tool-call → result → follow-up loop.
    Callers receive plain TextChunk / ToolCallRequest events and tool results,
    then drive tool execution themselves before calling stream_after_tools.
    """

    def __init__(self, provider: AIProviderType = AIProviderType.GEMINI) -> None:
        self._provider: AIProvider = create_ai_provider(provider)

    async def stream(
        self,
        messages: list[dict],
        system_prompt: str,
        tools: list[ToolDefinition] | None = None,
    ) -> AsyncIterator[str]:
        """Yield sentence-by-sentence text SSE strings and tool call events.

        Yields:
            ``data: {"text": "..."}`` for each completed sentence
            ``data: {"__tool_call__": true, "name": "...", "args": {...}}`` for tool calls
        """
        import json

        buffer = ""

        async for event in self._provider.stream(messages, system_prompt, tools):
            if isinstance(event, TextChunk):
                buffer += event.text
                parts = _SENTENCE_END.split(buffer)
                while len(parts) > 1:
                    sentence = parts.pop(0).strip()
                    if sentence:
                        yield f'data: {json.dumps({"text": sentence})}\n\n'
                    buffer = parts[0] if parts else ""
            elif isinstance(event, ToolCallRequest):
                yield f'data: {json.dumps({"__tool_call__": True, "name": event.name, "args": event.args})}\n\n'

        if remainder := buffer.strip():
            import json as _json
            yield f'data: {_json.dumps({"text": remainder})}\n\n'

    async def stream_after_tools(
        self,
        messages: list[dict],
        system_prompt: str,
        tool_calls: list[ToolCallRequest],
        tool_results: list[ToolResult],
    ) -> AsyncIterator[str]:
        """Yield sentence-by-sentence text SSE strings for the follow-up turn."""
        import json

        buffer = ""

        async for chunk in self._provider.stream_after_tools(messages, system_prompt, tool_calls, tool_results):
            buffer += chunk.text
            parts = _SENTENCE_END.split(buffer)
            while len(parts) > 1:
                sentence = parts.pop(0).strip()
                if sentence:
                    yield f'data: {json.dumps({"text": sentence})}\n\n'
                buffer = parts[0] if parts else ""

        if remainder := buffer.strip():
            yield f'data: {json.dumps({"text": remainder})}\n\n'

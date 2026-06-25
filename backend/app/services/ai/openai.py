"""OpenAI provider implementation."""

import json
import logging
from typing import AsyncIterator

from openai import AsyncOpenAI

from app.config import settings
from app.services.ai.base import AIProvider, StreamEvent, TextChunk, ToolCallRequest, ToolDefinition, ToolResult

logger = logging.getLogger(__name__)


def _build_openai_tools(tools: list[ToolDefinition]) -> list[dict]:
    return [
        {
            "type": "function",
            "function": {
                "name": tool.name,
                "description": tool.description,
                "parameters": {
                    "type": "object",
                    "properties": tool.parameters.get("properties", {}),
                    "required": tool.required,
                },
            },
        }
        for tool in tools
    ]


class OpenAIProvider(AIProvider):
    def __init__(self, model: str = "gpt-4o", max_tokens: int = 1024) -> None:
        self._client = AsyncOpenAI(api_key=settings.openai_api_key)
        self._model = model
        self._max_tokens = max_tokens

    async def stream(
        self,
        messages: list[dict],
        system_prompt: str,
        tools: list[ToolDefinition] | None = None,
    ) -> AsyncIterator[StreamEvent]:
        full_messages = [{"role": "system", "content": system_prompt}] + messages
        accumulated_tool_calls: dict[int, dict] = {}

        stream = await self._client.chat.completions.create(
            model=self._model,
            max_tokens=self._max_tokens,
            messages=full_messages,  # type: ignore[arg-type]
            tools=_build_openai_tools(tools) if tools else [],  # type: ignore[arg-type]
            stream=True,
        )

        async for chunk in stream:
            choice = chunk.choices[0] if chunk.choices else None
            if not choice:
                continue

            delta = choice.delta

            if delta.content:
                yield TextChunk(text=delta.content)

            if delta.tool_calls:
                for tc in delta.tool_calls:
                    idx = tc.index
                    if idx not in accumulated_tool_calls:
                        accumulated_tool_calls[idx] = {
                            "id": tc.id or "",
                            "name": tc.function.name if tc.function else "",
                            "arguments": "",
                        }
                    if tc.function and tc.function.arguments:
                        accumulated_tool_calls[idx]["arguments"] += tc.function.arguments
                    if tc.id and not accumulated_tool_calls[idx]["id"]:
                        accumulated_tool_calls[idx]["id"] = tc.id
                    if tc.function and tc.function.name and not accumulated_tool_calls[idx]["name"]:
                        accumulated_tool_calls[idx]["name"] = tc.function.name

        for tc in accumulated_tool_calls.values():
            try:
                args = json.loads(tc["arguments"]) if tc["arguments"] else {}
            except json.JSONDecodeError:
                args = {}
            yield ToolCallRequest(name=tc["name"], args=args)

    async def stream_after_tools(
        self,
        messages: list[dict],
        system_prompt: str,
        tool_calls: list[ToolCallRequest],
        tool_results: list[ToolResult],
    ) -> AsyncIterator[TextChunk]:
        assistant_tool_calls = [
            {
                "id": f"call_{i}",
                "type": "function",
                "function": {"name": tc.name, "arguments": json.dumps(tc.args)},
            }
            for i, tc in enumerate(tool_calls)
        ]
        tool_result_messages = [
            {"role": "tool", "tool_call_id": f"call_{i}", "content": tr.result}
            for i, tr in enumerate(tool_results)
        ]

        followup_messages = (
            [{"role": "system", "content": system_prompt}]
            + messages
            + [{"role": "assistant", "content": None, "tool_calls": assistant_tool_calls}]
            + tool_result_messages
        )

        stream = await self._client.chat.completions.create(
            model=self._model,
            max_tokens=self._max_tokens,
            messages=followup_messages,  # type: ignore[arg-type]
            stream=True,
        )

        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield TextChunk(text=chunk.choices[0].delta.content)

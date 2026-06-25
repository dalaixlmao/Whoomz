"""Anthropic provider implementation."""

import json
import logging
from typing import AsyncIterator

import anthropic

from app.config import settings
from app.services.ai.base import AIProvider, TextChunk, ToolCallRequest, ToolDefinition, ToolResult

logger = logging.getLogger(__name__)


def _build_anthropic_tools(tools: list[ToolDefinition]) -> list[dict]:
    return [
        {
            "name": tool.name,
            "description": tool.description,
            "input_schema": {
                "type": "object",
                "properties": tool.parameters.get("properties", {}),
                "required": tool.required,
            },
        }
        for tool in tools
    ]


class AnthropicProvider(AIProvider):
    def __init__(self, model: str = "claude-sonnet-4-6", max_tokens: int = 1024) -> None:
        self._client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        self._model = model
        self._max_tokens = max_tokens

    async def stream(
        self,
        messages: list[dict],
        system_prompt: str,
        tools: list[ToolDefinition] | None = None,
    ) -> AsyncIterator[StreamEvent]:
        kwargs: dict = dict(
            model=self._model,
            max_tokens=self._max_tokens,
            system=system_prompt,
            messages=messages,
        )
        if tools:
            kwargs["tools"] = _build_anthropic_tools(tools)

        pending_tool: dict | None = None

        async with self._client.messages.stream(**kwargs) as stream:
            async for event in stream:
                if event.type == "content_block_start":
                    if event.content_block.type == "tool_use":
                        pending_tool = {
                            "name": event.content_block.name,
                            "input_json": "",
                        }
                elif event.type == "content_block_delta":
                    delta = event.delta
                    if delta.type == "text_delta":
                        yield TextChunk(text=delta.text)
                    elif delta.type == "input_json_delta" and pending_tool is not None:
                        pending_tool["input_json"] += delta.partial_json
                elif event.type == "content_block_stop":
                    if pending_tool is not None:
                        try:
                            args = json.loads(pending_tool["input_json"]) if pending_tool["input_json"] else {}
                        except json.JSONDecodeError:
                            args = {}
                        yield ToolCallRequest(name=pending_tool["name"], args=args)
                        pending_tool = None

    async def stream_after_tools(
        self,
        messages: list[dict],
        system_prompt: str,
        tool_calls: list[ToolCallRequest],
        tool_results: list[ToolResult],
    ) -> AsyncIterator[TextChunk]:
        assistant_content = [
            {
                "type": "tool_use",
                "id": f"toolu_{i:02d}",
                "name": tc.name,
                "input": tc.args,
            }
            for i, tc in enumerate(tool_calls)
        ]
        tool_result_content = [
            {
                "type": "tool_result",
                "tool_use_id": f"toolu_{i:02d}",
                "content": tr.result,
            }
            for i, tr in enumerate(tool_results)
        ]

        followup_messages = (
            messages
            + [{"role": "assistant", "content": assistant_content}]
            + [{"role": "user", "content": tool_result_content}]
        )

        async with self._client.messages.stream(
            model=self._model,
            max_tokens=self._max_tokens,
            system=system_prompt,
            messages=followup_messages,
        ) as stream:
            async for event in stream:
                if event.type == "content_block_delta" and event.delta.type == "text_delta":
                    yield TextChunk(text=event.delta.text)

"""Gemini AI provider implementation."""

import logging
from typing import AsyncIterator

from google import genai as google_genai
from google.genai import types as genai_types

from app.config import settings
from app.services.ai.base import AIProvider, StreamEvent, TextChunk, ToolCallRequest, ToolDefinition, ToolResult

logger = logging.getLogger(__name__)

_TYPE_MAP = {
    "string": genai_types.Type.STRING,
    "integer": genai_types.Type.INTEGER,
    "number": genai_types.Type.NUMBER,
    "object": genai_types.Type.OBJECT,
    "array": genai_types.Type.ARRAY,
    "boolean": genai_types.Type.BOOLEAN,
}


def _to_gemini_schema(schema: dict) -> genai_types.Schema:
    kwargs: dict = {"type": _TYPE_MAP.get(schema.get("type", "string"), genai_types.Type.STRING)}
    if "description" in schema:
        kwargs["description"] = schema["description"]
    if "enum" in schema:
        kwargs["enum"] = schema["enum"]
    if "properties" in schema:
        kwargs["properties"] = {k: _to_gemini_schema(v) for k, v in schema["properties"].items()}
    if "required" in schema:
        kwargs["required"] = schema["required"]
    if "items" in schema:
        kwargs["items"] = _to_gemini_schema(schema["items"])
    return genai_types.Schema(**kwargs)


def _build_gemini_tools(tools: list[ToolDefinition]) -> genai_types.Tool:
    declarations = []
    for tool in tools:
        param_schema = {
            "type": "object",
            "properties": tool.parameters.get("properties", {}),
            "required": tool.required,
        }
        declarations.append(
            genai_types.FunctionDeclaration(
                name=tool.name,
                description=tool.description,
                parameters=_to_gemini_schema(param_schema),
            )
        )
    return genai_types.Tool(function_declarations=declarations)


class GeminiProvider(AIProvider):
    def __init__(self, model: str = "gemini-2.5-flash", max_tokens: int = 1024) -> None:
        self._client = google_genai.Client(api_key=settings.gemini_api_key)
        self._model = model
        self._max_tokens = max_tokens

    async def stream(
        self,
        messages: list[dict],
        system_prompt: str,
        tools: list[ToolDefinition] | None = None,
    ) -> AsyncIterator[StreamEvent]:
        contents = self._to_contents(messages)
        config = genai_types.GenerateContentConfig(
            system_instruction=system_prompt,
            tools=[_build_gemini_tools(tools)] if tools else [],
            max_output_tokens=self._max_tokens,
        )

        async for chunk in await self._client.aio.models.generate_content_stream(
            model=self._model, contents=contents, config=config
        ):
            if chunk.text:
                yield TextChunk(text=chunk.text)

            if chunk.candidates:
                for candidate in chunk.candidates:
                    if candidate.content and candidate.content.parts:
                        for part in candidate.content.parts:
                            if part.function_call:
                                yield ToolCallRequest(
                                    name=part.function_call.name,
                                    args=dict(part.function_call.args) if part.function_call.args else {},
                                )

    async def stream_after_tools(
        self,
        messages: list[dict],
        system_prompt: str,
        tool_calls: list[ToolCallRequest],
        tool_results: list[ToolResult],
    ) -> AsyncIterator[TextChunk]:
        fc_parts = [
            genai_types.Part(
                function_call=genai_types.FunctionCall(name=tc.name, args=tc.args)
            )
            for tc in tool_calls
        ]
        result_parts = [
            genai_types.Part(
                function_response=genai_types.FunctionResponse(
                    name=tr.name, response={"result": tr.result}
                )
            )
            for tr in tool_results
        ]

        followup_contents = self._to_contents(messages) + [
            genai_types.Content(role="model", parts=fc_parts),
            genai_types.Content(role="user", parts=result_parts),
        ]
        config = genai_types.GenerateContentConfig(
            system_instruction=system_prompt,
            max_output_tokens=self._max_tokens,
        )

        async for chunk in await self._client.aio.models.generate_content_stream(
            model=self._model, contents=followup_contents, config=config
        ):
            if chunk.text:
                yield TextChunk(text=chunk.text)

    @staticmethod
    def _to_contents(messages: list[dict]) -> list[genai_types.Content]:
        contents = []
        for m in messages:
            role = "model" if m["role"] == "assistant" else "user"
            contents.append(genai_types.Content(role=role, parts=[genai_types.Part(text=m["content"])]))
        return contents

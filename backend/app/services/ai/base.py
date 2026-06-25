"""Abstract AI provider interface and shared data types."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import AsyncIterator


@dataclass
class ToolDefinition:
    """Provider-agnostic tool definition using JSON Schema for parameters."""
    name: str
    description: str
    parameters: dict  # JSON Schema object with "properties" and optional "required"
    required: list[str] = field(default_factory=list)


@dataclass
class TextChunk:
    text: str


@dataclass
class ToolCallRequest:
    name: str
    args: dict


@dataclass
class ToolResult:
    name: str
    result: str


# Union of events yielded by AIProvider.stream()
StreamEvent = TextChunk | ToolCallRequest


class AIProvider(ABC):
    """Strategy interface — each AI backend implements this."""

    @abstractmethod
    async def stream(
        self,
        messages: list[dict],
        system_prompt: str,
        tools: list[ToolDefinition] | None = None,
    ) -> AsyncIterator[StreamEvent]:
        """First-pass stream: yields TextChunks and ToolCallRequests."""
        ...

    @abstractmethod
    async def stream_after_tools(
        self,
        messages: list[dict],
        system_prompt: str,
        tool_calls: list[ToolCallRequest],
        tool_results: list[ToolResult],
    ) -> AsyncIterator[TextChunk]:
        """Follow-up stream after tool execution, no further tool calls expected."""
        ...

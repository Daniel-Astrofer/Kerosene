from __future__ import annotations

from pathlib import Path
from typing import Any


def can_handle(name: str) -> bool:
    return False


def tool_schema() -> list[dict[str, Any]]:
    return []


def call_tool(root: Path, name: str, args: dict[str, Any]) -> dict[str, Any]:
    raise RuntimeError(name)

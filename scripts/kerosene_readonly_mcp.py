#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


SERVER_NAME = "kerosene-mcp"
SERVER_VERSION = "0.3.0"
DEFAULT_ROOT = Path(os.environ.get("KEROSENE_MCP_ROOT", "/home/omega/Kerosene"))
CODEX_FLEET_SCRIPT = Path(os.environ.get("KEROSENE_MCP_CODEX_FLEET_SCRIPT", "/home/omega/Kerosene/AGENTS/codex-fleet-mcp"))
AGY_FLEET_SCRIPT = Path(os.environ.get("KEROSENE_MCP_AGY_FLEET_SCRIPT", "/home/omega/Kerosene/AGENTS/agy-fleet-mcp"))

MAX_READ_BYTES = int(os.environ.get("KEROSENE_MCP_MAX_READ_BYTES", "100000000"))
DEFAULT_READ_BYTES = int(os.environ.get("KEROSENE_MCP_DEFAULT_READ_BYTES", "262144"))
MAX_READ_LINES = int(os.environ.get("KEROSENE_MCP_MAX_READ_LINES", "20000"))
DEFAULT_READ_LINES = int(os.environ.get("KEROSENE_MCP_DEFAULT_READ_LINES", "1000"))
MAX_READ_LINE_CHARS = int(os.environ.get("KEROSENE_MCP_MAX_READ_LINE_CHARS", "20000"))
MAX_READ_LINES_CHARS = int(os.environ.get("KEROSENE_MCP_MAX_READ_LINES_CHARS", "4000000"))
MAX_SEARCH_RESULTS = int(os.environ.get("KEROSENE_MCP_MAX_SEARCH_RESULTS", "5000"))
DEFAULT_SEARCH_RESULTS = int(os.environ.get("KEROSENE_MCP_DEFAULT_SEARCH_RESULTS", "250"))
MAX_SEARCH_FILES = int(os.environ.get("KEROSENE_MCP_MAX_SEARCH_FILES", "200000"))
DEFAULT_SEARCH_FILES = int(os.environ.get("KEROSENE_MCP_DEFAULT_SEARCH_FILES", "50000"))
MAX_SEARCH_FILE_BYTES = int(os.environ.get("KEROSENE_MCP_MAX_SEARCH_FILE_BYTES", "100000000"))
DEFAULT_SEARCH_TIMEOUT_SECONDS = float(os.environ.get("KEROSENE_MCP_DEFAULT_SEARCH_TIMEOUT_SECONDS", "480"))
MAX_SEARCH_TIMEOUT_SECONDS = float(os.environ.get("KEROSENE_MCP_MAX_SEARCH_TIMEOUT_SECONDS", "1500"))
DEFAULT_SEARCH_RESPONSE_CHARS = int(os.environ.get("KEROSENE_MCP_DEFAULT_SEARCH_RESPONSE_CHARS", "1000000"))
MAX_SEARCH_RESPONSE_CHARS = int(os.environ.get("KEROSENE_MCP_MAX_SEARCH_RESPONSE_CHARS", "4000000"))
MAX_TOOL_RESPONSE_CHARS = int(os.environ.get("KEROSENE_MCP_MAX_TOOL_RESPONSE_CHARS", "4000000"))
MAX_TREE_ENTRIES = int(os.environ.get("KEROSENE_MCP_MAX_TREE_ENTRIES", "50000"))
DEFAULT_TREE_ENTRIES = int(os.environ.get("KEROSENE_MCP_DEFAULT_TREE_ENTRIES", "5000"))
MAX_LIST_ENTRIES = int(os.environ.get("KEROSENE_MCP_MAX_LIST_ENTRIES", "50000"))
DEFAULT_LIST_ENTRIES = int(os.environ.get("KEROSENE_MCP_DEFAULT_LIST_ENTRIES", "2000"))
MAX_CONTEXT_LINES = int(os.environ.get("KEROSENE_MCP_MAX_CONTEXT_LINES", "25"))
DEFAULT_COMMAND_TIMEOUT_SECONDS = int(os.environ.get("KEROSENE_MCP_DEFAULT_COMMAND_TIMEOUT_SECONDS", "7200"))
MAX_COMMAND_TIMEOUT_SECONDS = int(os.environ.get("KEROSENE_MCP_MAX_COMMAND_TIMEOUT_SECONDS", "14400"))
MAX_MCP_PROXY_TIMEOUT_SECONDS = int(os.environ.get("KEROSENE_MCP_MAX_PROXY_TIMEOUT_SECONDS", "172800"))

EXCLUDED_DIR_NAMES = {
    ".dart_tool",
    ".git",
    ".gradle",
    ".idea",
    ".mypy_cache",
    ".pytest_cache",
    ".qodana",
    ".venv",
    ".vscode",
    "__pycache__",
    "build",
    "coverage",
    "node_modules",
    "target",
    "venv",
}

SENSITIVE_EXACT_NAMES = {
    ".env",
    ".env.local",
    ".env.production",
    ".env.prod",
    ".env.staging",
    ".netrc",
    "id_dsa",
    "id_ecdsa",
    "id_ed25519",
    "id_rsa",
    "wallet.dat",
}

SAFE_ENV_EXAMPLE_NAMES = {
    ".env.dist",
    ".env.example",
    ".env.sample",
    ".env.template",
}

SENSITIVE_DIR_NAMES = {
    ".git",
    ".gnupg",
    ".secrets",
    ".ssh",
    "secrets",
}

SENSITIVE_SUFFIXES = {
    ".db",
    ".jks",
    ".key",
    ".keystore",
    ".mv.db",
    ".p12",
    ".pem",
    ".pfx",
    ".sqlite",
    ".sqlite3",
}

SENSITIVE_ENV_MARKERS = {
    "ACCESS_TOKEN",
    "API_KEY",
    "AUTH_TOKEN",
    "CREDENTIAL",
    "PASSWORD",
    "PRIVATE_KEY",
    "SECRET",
    "TOKEN",
}

SCRUB_SHELL_ENV = os.environ.get("KEROSENE_MCP_SCRUB_SHELL_ENV", "0").strip().lower() in {
    "1",
    "true",
    "yes",
    "on",
}

BINARY_SUFFIXES = {
    ".7z",
    ".apk",
    ".bin",
    ".class",
    ".dll",
    ".dylib",
    ".gif",
    ".gz",
    ".hprof",
    ".ico",
    ".jar",
    ".jpeg",
    ".jpg",
    ".keystore",
    ".mp3",
    ".mp4",
    ".otf",
    ".png",
    ".so",
    ".tar",
    ".ttf",
    ".webp",
    ".zip",
}


class ReadOnlyMcpError(RuntimeError):
    pass


def utc_iso(timestamp: float) -> str:
    return dt.datetime.fromtimestamp(timestamp, dt.timezone.utc).isoformat(timespec="seconds")


def clamp_int(value: Any, default: int, minimum: int, maximum: int) -> int:
    if value is None:
        return default
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise ReadOnlyMcpError(f"Expected integer value, got {value!r}") from exc
    return max(minimum, min(maximum, parsed))


def clamp_float(value: Any, default: float, minimum: float, maximum: float) -> float:
    if value is None:
        return default
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise ReadOnlyMcpError(f"Expected numeric value, got {value!r}") from exc
    return max(minimum, min(maximum, parsed))


def as_bool(value: Any, default: bool = False) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "on"}
    return bool(value)


def is_relative_to(path: Path, root: Path) -> bool:
    return path == root or root in path.parents


def relative_path(root: Path, path: Path) -> str:
    if path == root:
        return "."
    return path.relative_to(root).as_posix()


def has_suffix(path: Path, suffixes: set[str]) -> bool:
    return any(suffix.lower() in suffixes for suffix in path.suffixes)


def is_sensitive_path(path: Path) -> bool:
    lower_parts = {part.lower() for part in path.parts}
    if lower_parts & SENSITIVE_DIR_NAMES:
        return True

    lower_name = path.name.lower()
    if lower_name in SAFE_ENV_EXAMPLE_NAMES:
        return False
    if lower_name in SENSITIVE_EXACT_NAMES:
        return True
    if lower_name.startswith(".env."):
        return True
    return has_suffix(path, SENSITIVE_SUFFIXES)


def shell_environment(root: Path) -> dict[str, str]:
    if not SCRUB_SHELL_ENV:
        env = os.environ.copy()
        env["KEROSENE_MCP_ROOT"] = str(root)
        return env

    env: dict[str, str] = {}
    for key, value in os.environ.items():
        upper_key = key.upper()
        if any(marker in upper_key for marker in SENSITIVE_ENV_MARKERS):
            continue
        env[key] = value
    env["KEROSENE_MCP_ROOT"] = str(root)
    return env


def is_excluded_dir(path: Path) -> bool:
    return path.name in EXCLUDED_DIR_NAMES or (path / "pyvenv.cfg").exists()


def is_hidden_name(name: str) -> bool:
    return name.startswith(".")


def is_binary_suffix(path: Path) -> bool:
    return has_suffix(path, BINARY_SUFFIXES)


def is_probably_binary(data: bytes) -> bool:
    if not data:
        return False
    sample = data[:4096]
    if b"\0" in sample:
        return True
    control = 0
    for byte in sample:
        if byte in (9, 10, 12, 13, 27):
            continue
        if byte < 32 or byte == 127:
            control += 1
    return control / len(sample) > 0.30


def decode_text(data: bytes) -> tuple[str, str]:
    try:
        return data.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return data.decode("utf-8", errors="replace"), "utf-8-replacement"


def truncate_text(value: str, max_chars: int = 500) -> str:
    if len(value) <= max_chars:
        return value
    return value[: max_chars - 15] + "...<truncated>"


def compact_tool_value(value: Any, *, max_chars: int = MAX_TOOL_RESPONSE_CHARS) -> str:
    text = json.dumps(value, indent=2, sort_keys=True)
    if len(text) <= max_chars:
        return text

    if not isinstance(value, dict):
        return json.dumps(
            {
                "response_truncated": True,
                "original_response_chars": len(text),
                "error": "Tool response exceeded connector-safe size.",
            },
            indent=2,
            sort_keys=True,
        )

    compacted = dict(value)
    compacted["response_truncated"] = True
    compacted["original_response_chars"] = len(text)
    compacted["response_truncation_reason"] = "connector_safe_response_budget"

    for key in ("content", "stdout", "stderr", "tree"):
        current = compacted.get(key)
        if isinstance(current, str):
            compacted[key] = truncate_text(current, max(1000, max_chars // 2))

    for key in ("results", "lines", "entries"):
        current = compacted.get(key)
        if isinstance(current, list):
            compacted[f"original_{key}_count"] = len(current)
            compacted[key] = current
            while compacted[key]:
                candidate = json.dumps(compacted, indent=2, sort_keys=True)
                if len(candidate) <= max_chars:
                    return candidate
                keep = max(0, len(compacted[key]) // 2)
                compacted[key] = compacted[key][:keep]

    text = json.dumps(compacted, indent=2, sort_keys=True)
    if len(text) <= max_chars:
        return text

    summary = {
        "response_truncated": True,
        "original_response_chars": compacted.get("original_response_chars"),
        "response_truncation_reason": "connector_safe_response_budget",
        "available_keys": sorted(str(key) for key in value.keys()),
        "error": "Tool response exceeded connector-safe size. Retry with a narrower path, lower max_results, lower max_bytes, or read_file_lines.",
    }
    return json.dumps(summary, indent=2, sort_keys=True)


def resolve_root(root: Path) -> Path:
    resolved = root.expanduser().resolve(strict=True)
    if not resolved.is_dir():
        raise ReadOnlyMcpError(f"Project root is not a directory: {resolved}")
    return resolved


def resolve_existing_path(root: Path, user_path: Any) -> Path:
    raw = "." if user_path in (None, "") else str(user_path)
    candidate = Path(raw).expanduser()
    if not candidate.is_absolute():
        candidate = root / candidate
    try:
        resolved = candidate.resolve(strict=True)
    except FileNotFoundError as exc:
        raise ReadOnlyMcpError(f"Path does not exist: {raw}") from exc
    except OSError as exc:
        raise ReadOnlyMcpError(f"Cannot resolve path {raw!r}: {exc}") from exc
    if not is_relative_to(resolved, root):
        raise ReadOnlyMcpError(f"Path is outside the Kerosene project root: {raw}")
    return resolved


def ensure_readable_file(root: Path, user_path: Any) -> Path:
    path = resolve_existing_path(root, user_path)
    if path.is_dir():
        raise ReadOnlyMcpError(f"Path is a directory, not a file: {relative_path(root, path)}")
    if is_sensitive_path(path):
        raise ReadOnlyMcpError(
            f"Refusing to read sensitive file: {relative_path(root, path)}. "
            "Use an explicit safer export if this content is required."
        )
    return path


def resolve_writable_path(root: Path, user_path: Any) -> Path:
    raw = "." if user_path in (None, "") else str(user_path)
    candidate = Path(raw).expanduser()
    if candidate.is_absolute():
        raise ReadOnlyMcpError("Path must be relative to the project root")
    resolved_root = root.resolve(strict=True)
    path = (resolved_root / candidate).resolve(strict=False)
    if not is_relative_to(path, resolved_root):
        raise ReadOnlyMcpError(f"Path is outside the Kerosene project root: {raw}")
    if is_sensitive_path(path):
        raise ReadOnlyMcpError(
            f"Refusing to modify sensitive file: {relative_path(root, path)}. "
            "Use an explicit safer export if this content is required."
        )
    return path


def write_file(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    path = resolve_writable_path(root, args.get("path"))
    content = args.get("content")
    if not isinstance(content, str):
        raise ReadOnlyMcpError("Field 'content' must be a string")
    create_parents = as_bool(args.get("create_parents"), True)
    existed_before = path.exists()
    if path.exists() and path.is_dir():
        raise ReadOnlyMcpError(f"Path is a directory, not a file: {relative_path(root, path)}")
    if create_parents:
        path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return {
        "path": relative_path(root, path),
        "bytes_written": len(content.encode("utf-8")),
        "created": not existed_before,
    }


def replace_text_in_file(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    path = ensure_readable_file(root, args.get("path"))
    old_text = args.get("old_text")
    new_text = args.get("new_text")
    if not isinstance(old_text, str) or not old_text:
        raise ReadOnlyMcpError("Field 'old_text' must be a non-empty string")
    if not isinstance(new_text, str):
        raise ReadOnlyMcpError("Field 'new_text' must be a string")

    replace_all = as_bool(args.get("replace_all"), True)
    case_sensitive = as_bool(args.get("case_sensitive"), True)
    original = path.read_text(encoding="utf-8")

    if case_sensitive:
        occurrences = original.count(old_text)
        if occurrences == 0:
            raise ReadOnlyMcpError("No occurrences found")
        updated = original.replace(old_text, new_text, -1 if replace_all else 1)
        replaced = occurrences if replace_all else 1
    else:
        pattern = re.compile(re.escape(old_text), re.IGNORECASE)
        matches = list(pattern.finditer(original))
        if not matches:
            raise ReadOnlyMcpError("No occurrences found")
        if replace_all:
            updated, replaced = pattern.subn(new_text, original)
        else:
            updated = pattern.sub(new_text, original, count=1)
            replaced = 1

    path.write_text(updated, encoding="utf-8")
    return {
        "path": relative_path(root, path),
        "replacements": replaced,
        "bytes_written": len(updated.encode("utf-8")),
    }


def shell_command(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    command = args.get("command")
    if not isinstance(command, str) or not command.strip():
        raise ReadOnlyMcpError("Field 'command' must be a non-empty string")

    cwd_arg = args.get("cwd")
    cwd = resolve_existing_path(root, cwd_arg) if cwd_arg not in (None, "") else root
    if cwd.is_file():
        cwd = cwd.parent
    if not cwd.is_dir():
        raise ReadOnlyMcpError(f"Path is not a directory: {relative_path(root, cwd)}")

    timeout_seconds = clamp_int(
        args.get("timeout_seconds"),
        DEFAULT_COMMAND_TIMEOUT_SECONDS,
        1,
        MAX_COMMAND_TIMEOUT_SECONDS,
    )
    env = shell_environment(root)

    try:
        completed = subprocess.run(
            command,
            shell=True,
            cwd=str(cwd),
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            check=False,
        )
        return {
            "command": command,
            "cwd": relative_path(root, cwd),
            "timeout_seconds": timeout_seconds,
            "returncode": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
            "timed_out": False,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "command": command,
            "cwd": relative_path(root, cwd),
            "timeout_seconds": timeout_seconds,
            "returncode": None,
            "stdout": exc.stdout or "",
            "stderr": exc.stderr or "",
            "timed_out": True,
            "error": f"Command timed out after {timeout_seconds} seconds",
        }


def call_mcp_proxy(script: Path, tool_name: str, arguments: dict[str, Any], timeout_seconds: int = 1200) -> Any:
    if not script.exists():
        raise ReadOnlyMcpError(f"Proxy MCP script not found: {script}")
    payload = "\n".join(
        [
            json.dumps({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05"}}),
            json.dumps({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": tool_name, "arguments": arguments}}),
        ]
    ) + "\n"
    try:
        completed = subprocess.run(
            [str(script)],
            input=payload,
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
            check=False,
            env=os.environ.copy(),
        )
    except subprocess.TimeoutExpired as exc:
        raise ReadOnlyMcpError(f"Proxy MCP call timed out after {timeout_seconds} seconds") from exc
    if completed.returncode != 0 and not completed.stdout.strip():
        raise ReadOnlyMcpError(completed.stderr.strip() or f"Proxy MCP exited with {completed.returncode}")
    last_result: Any = None
    for line in completed.stdout.splitlines():
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        if message.get("id") == 2:
            if "error" in message:
                error = message["error"]
                raise ReadOnlyMcpError(error.get("message") or "Proxy MCP tool call failed")
            result = message.get("result")
            content = result.get("content") if isinstance(result, dict) else None
            if (
                isinstance(content, list)
                and content
                and isinstance(content[0], dict)
                and isinstance(content[0].get("text"), str)
            ):
                try:
                    last_result = json.loads(content[0]["text"])
                except json.JSONDecodeError:
                    last_result = content[0]["text"]
            else:
                last_result = result
    if last_result is None:
        raise ReadOnlyMcpError("Proxy MCP did not return a tool result")
    return last_result


def proxy_timeout_seconds(tool_name: str, arguments: dict[str, Any]) -> int:
    timeout = 1200
    raw_timeout = arguments.get("timeout_seconds")
    try:
        requested = int(float(raw_timeout)) if raw_timeout is not None else None
    except (TypeError, ValueError):
        requested = None
    if requested:
        timeout = max(timeout, requested + 120)
        if tool_name.endswith("_quota_probe_all"):
            timeout = max(timeout, requested * 8 + 240)
    return min(timeout, MAX_MCP_PROXY_TIMEOUT_SECONDS)


def path_type(path: Path) -> str:
    if path.is_symlink():
        return "symlink"
    if path.is_dir():
        return "directory"
    if path.is_file():
        return "file"
    return "other"


def entry_info(root: Path, path: Path) -> dict[str, Any]:
    try:
        stat = path.lstat()
    except OSError as exc:
        return {
            "name": path.name,
            "path": relative_path(root, path) if is_relative_to(path, root) else str(path),
            "type": "unknown",
            "readable": False,
            "blocked_reason": str(exc),
        }

    info: dict[str, Any] = {
        "name": path.name,
        "path": relative_path(root, path) if is_relative_to(path, root) else path.name,
        "type": path_type(path),
        "size": stat.st_size,
        "modified": utc_iso(stat.st_mtime),
    }

    try:
        resolved = path.resolve(strict=True)
    except OSError:
        info["readable"] = False
        info["blocked_reason"] = "unresolvable_symlink_or_path"
        return info

    if not is_relative_to(resolved, root):
        info["readable"] = False
        info["blocked_reason"] = "outside_project_root"
    elif path.is_dir() and is_excluded_dir(path):
        info["readable"] = False
        info["blocked_reason"] = "excluded_directory"
    elif path.is_file() and is_sensitive_path(path):
        info["readable"] = False
        info["blocked_reason"] = "sensitive_path"
    elif path.is_file() and is_binary_suffix(path):
        info["readable"] = False
        info["blocked_reason"] = "binary_file"
    else:
        info["readable"] = True
    return info


def sorted_children(path: Path) -> list[Path]:
    return sorted(path.iterdir(), key=lambda child: (not child.is_dir(), child.name.lower()))


def list_directory(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    path = resolve_existing_path(root, args.get("path"))
    if not path.is_dir():
        raise ReadOnlyMcpError(f"Path is not a directory: {relative_path(root, path)}")

    include_hidden = as_bool(args.get("include_hidden"), False)
    max_entries = clamp_int(args.get("max_entries"), DEFAULT_LIST_ENTRIES, 1, MAX_LIST_ENTRIES)
    entries: list[dict[str, Any]] = []
    skipped = {"hidden": 0, "excluded_directory": 0}
    truncated = False

    for child in sorted_children(path):
        if not include_hidden and is_hidden_name(child.name):
            skipped["hidden"] += 1
            continue
        if child.is_dir() and is_excluded_dir(child):
            skipped["excluded_directory"] += 1
            continue
        if len(entries) >= max_entries:
            truncated = True
            break
        entries.append(entry_info(root, child))

    return {
        "root": str(root),
        "path": relative_path(root, path),
        "entries": entries,
        "entry_count": len(entries),
        "truncated": truncated,
        "skipped": skipped,
    }


def read_file(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    if "path" not in args:
        raise ReadOnlyMcpError("read_file requires a path")
    path = ensure_readable_file(root, args["path"])
    size = path.stat().st_size
    offset = clamp_int(args.get("offset"), 0, 0, max(size, 0))
    max_bytes = clamp_int(args.get("max_bytes"), DEFAULT_READ_BYTES, 1, MAX_READ_BYTES)

    with path.open("rb") as handle:
        sample = handle.read(4096)
        if is_probably_binary(sample):
            raise ReadOnlyMcpError(f"Refusing to read binary file: {relative_path(root, path)}")
        handle.seek(offset)
        data = handle.read(max_bytes)

    text, encoding = decode_text(data)
    return {
        "path": relative_path(root, path),
        "size": size,
        "offset": offset,
        "bytes_read": len(data),
        "max_bytes": max_bytes,
        "truncated": offset + len(data) < size,
        "encoding": encoding,
        "content": text,
    }


def read_file_lines(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    if "path" not in args:
        raise ReadOnlyMcpError("read_file_lines requires a path")
    path = ensure_readable_file(root, args["path"])
    size = path.stat().st_size
    start_line = clamp_int(args.get("start_line"), 1, 1, 2_000_000_000)
    max_lines = clamp_int(args.get("max_lines"), DEFAULT_READ_LINES, 1, MAX_READ_LINES)
    max_chars = clamp_int(args.get("max_chars"), 1_000_000, 1_000, MAX_READ_LINES_CHARS)
    max_line_chars = clamp_int(args.get("max_line_chars"), MAX_READ_LINE_CHARS, 100, MAX_READ_LINE_CHARS)

    lines: list[dict[str, Any]] = []
    emitted_chars = 0
    last_line = start_line - 1
    truncated = False
    encoding = "utf-8"

    with path.open("rb") as handle:
        sample = handle.read(4096)
        if is_probably_binary(sample):
            raise ReadOnlyMcpError(f"Refusing to read binary file: {relative_path(root, path)}")
        handle.seek(0)
        for line_number, raw_line in enumerate(handle, start=1):
            if line_number < start_line:
                continue
            if len(lines) >= max_lines or emitted_chars >= max_chars:
                truncated = True
                break

            line_text, line_encoding = decode_text(raw_line)
            if line_encoding != "utf-8":
                encoding = line_encoding
            line_text = line_text.rstrip("\r\n")
            if len(line_text) > max_line_chars:
                line_text = truncate_text(line_text, max_line_chars)
            emitted_chars += len(line_text)
            lines.append({"line": line_number, "text": line_text})
            last_line = line_number

    return {
        "path": relative_path(root, path),
        "size": size,
        "start_line": start_line,
        "line_count": len(lines),
        "last_line": last_line if lines else None,
        "next_start_line": last_line + 1 if truncated else None,
        "max_lines": max_lines,
        "max_chars": max_chars,
        "truncated": truncated,
        "encoding": encoding,
        "lines": lines,
    }


def prune_dirnames(parent: Path, dirnames: list[str], include_hidden: bool, stats: Counter[str]) -> None:
    kept: list[str] = []
    for name in sorted(dirnames, key=str.lower):
        if is_excluded_dir(parent / name):
            stats["excluded_directories"] += 1
            continue
        if not include_hidden and is_hidden_name(name):
            stats["hidden_directories"] += 1
            continue
        kept.append(name)
    dirnames[:] = kept


def iter_text_files(
    root: Path,
    start: Path,
    *,
    include_hidden: bool,
    max_files: int,
    max_file_bytes: int,
    stats: Counter[str],
) -> Iterable[Path]:
    yielded = 0
    for dirpath, dirnames, filenames in os.walk(start):
        prune_dirnames(Path(dirpath), dirnames, include_hidden, stats)
        for filename in sorted(filenames, key=str.lower):
            if yielded >= max_files:
                stats["max_files_reached"] += 1
                return
            if not include_hidden and is_hidden_name(filename):
                stats["hidden_files"] += 1
                continue
            path = Path(dirpath) / filename
            try:
                resolved = path.resolve(strict=True)
            except OSError:
                stats["unresolvable_files"] += 1
                continue
            if not is_relative_to(resolved, root):
                stats["outside_root_files"] += 1
                continue
            if is_sensitive_path(path):
                stats["sensitive_files"] += 1
                continue
            if is_binary_suffix(path):
                stats["binary_suffix_files"] += 1
                continue
            try:
                if not path.is_file():
                    continue
                size = path.stat().st_size
            except OSError:
                stats["stat_errors"] += 1
                continue
            if size > max_file_bytes:
                stats["large_files"] += 1
                continue
            yielded += 1
            yield path


def search_text(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    query = str(args.get("query") or "")
    if not query:
        raise ReadOnlyMcpError("search_text requires a non-empty query")

    started_at = time.monotonic()
    start = resolve_existing_path(root, args.get("path"))
    if start.is_file():
        start = start.parent
    include_hidden = as_bool(args.get("include_hidden"), False)
    case_sensitive = as_bool(args.get("case_sensitive"), False)
    max_results = clamp_int(args.get("max_results"), DEFAULT_SEARCH_RESULTS, 1, MAX_SEARCH_RESULTS)
    max_files = clamp_int(args.get("max_files"), DEFAULT_SEARCH_FILES, 1, MAX_SEARCH_FILES)
    context_lines = clamp_int(args.get("context_lines"), 0, 0, MAX_CONTEXT_LINES)
    max_file_bytes = clamp_int(args.get("max_file_bytes"), MAX_SEARCH_FILE_BYTES, 1_000, MAX_SEARCH_FILE_BYTES)
    timeout_seconds = clamp_float(
        args.get("timeout_seconds"),
        DEFAULT_SEARCH_TIMEOUT_SECONDS,
        1.0,
        MAX_SEARCH_TIMEOUT_SECONDS,
    )
    max_response_chars = clamp_int(
        args.get("max_response_chars"),
        DEFAULT_SEARCH_RESPONSE_CHARS,
        10_000,
        MAX_SEARCH_RESPONSE_CHARS,
    )
    deadline = started_at + timeout_seconds

    needle = query if case_sensitive else query.lower()
    stats: Counter[str] = Counter()
    results: list[dict[str, Any]] = []
    emitted_result_chars = 0

    def response(*, truncated: bool, timed_out: bool = False, truncation_reason: str | None = None) -> dict[str, Any]:
        elapsed = time.monotonic() - started_at
        payload: dict[str, Any] = {
            "query": query,
            "path": relative_path(root, start),
            "case_sensitive": case_sensitive,
            "results": results,
            "result_count": len(results),
            "truncated": truncated,
            "timed_out": timed_out,
            "timeout_seconds": timeout_seconds,
            "elapsed_seconds": round(elapsed, 3),
            "max_response_chars": max_response_chars,
            "stats": dict(stats),
        }
        if truncation_reason:
            payload["truncation_reason"] = truncation_reason
        return payload

    for path in iter_text_files(
        root,
        start,
        include_hidden=include_hidden,
        max_files=max_files,
        max_file_bytes=max_file_bytes,
        stats=stats,
    ):
        if time.monotonic() >= deadline:
            stats["search_timeout_reached"] += 1
            return response(truncated=True, timed_out=True, truncation_reason="timeout")

        stats["scanned_files"] += 1
        try:
            data = path.read_bytes()
        except OSError:
            stats["read_errors"] += 1
            continue
        if time.monotonic() >= deadline:
            stats["search_timeout_reached"] += 1
            return response(truncated=True, timed_out=True, truncation_reason="timeout")
        if is_probably_binary(data):
            stats["binary_content_files"] += 1
            continue
        text, _encoding = decode_text(data)
        lines = text.splitlines()
        for line_number, line in enumerate(lines, start=1):
            if line_number % 256 == 0 and time.monotonic() >= deadline:
                stats["search_timeout_reached"] += 1
                return response(truncated=True, timed_out=True, truncation_reason="timeout")
            haystack = line if case_sensitive else line.lower()
            column = haystack.find(needle)
            if column < 0:
                continue
            item: dict[str, Any] = {
                "path": relative_path(root, path),
                "line": line_number,
                "column": column + 1,
                "text": truncate_text(line),
            }
            if context_lines:
                before_start = max(0, line_number - 1 - context_lines)
                after_end = min(len(lines), line_number + context_lines)
                item["before"] = [
                    {"line": index + 1, "text": truncate_text(lines[index])}
                    for index in range(before_start, line_number - 1)
                ]
                item["after"] = [
                    {"line": index + 1, "text": truncate_text(lines[index])}
                    for index in range(line_number, after_end)
                ]
            item_chars = len(json.dumps(item, ensure_ascii=False, sort_keys=True))
            if emitted_result_chars + item_chars > max_response_chars:
                stats["response_char_budget_reached"] += 1
                return response(truncated=True, truncation_reason="response_char_budget")
            results.append(item)
            emitted_result_chars += item_chars
            if len(results) >= max_results:
                return response(truncated=True, truncation_reason="max_results")

    return response(truncated=False)


def visible_tree_children(root: Path, path: Path, include_hidden: bool, stats: Counter[str]) -> list[Path]:
    children: list[Path] = []
    for child in sorted_children(path):
        if not include_hidden and is_hidden_name(child.name):
            stats["hidden_entries"] += 1
            continue
        try:
            resolved = child.resolve(strict=True)
        except OSError:
            stats["unresolvable_entries"] += 1
            continue
        if not is_relative_to(resolved, root):
            stats["outside_root_entries"] += 1
            continue
        if child.is_dir() and is_excluded_dir(child):
            stats["excluded_directories"] += 1
            continue
        children.append(child)
    return children


def get_project_tree(root: Path, args: dict[str, Any]) -> dict[str, Any]:
    start = resolve_existing_path(root, args.get("path"))
    if not start.is_dir():
        raise ReadOnlyMcpError(f"Path is not a directory: {relative_path(root, start)}")

    include_hidden = as_bool(args.get("include_hidden"), False)
    include_files = as_bool(args.get("include_files"), True)
    max_depth = clamp_int(args.get("max_depth"), 4, 1, 16)
    max_entries = clamp_int(args.get("max_entries"), DEFAULT_TREE_ENTRIES, 1, MAX_TREE_ENTRIES)
    stats: Counter[str] = Counter()
    lines = [f"{relative_path(root, start)}/"]
    emitted = 0
    truncated = False

    def walk(path: Path, prefix: str, depth: int) -> None:
        nonlocal emitted, truncated
        if truncated or depth >= max_depth:
            return
        children = visible_tree_children(root, path, include_hidden, stats)
        if not include_files:
            children = [child for child in children if child.is_dir() and not child.is_symlink()]
        for index, child in enumerate(children):
            if emitted >= max_entries:
                lines.append(prefix + "`-- ...")
                truncated = True
                return
            is_last = index == len(children) - 1
            marker = "`-- " if is_last else "|-- "
            child_is_dir = child.is_dir() and not child.is_symlink()
            child_label = child.name + ("/" if child_is_dir else "")
            if child.is_file() and is_sensitive_path(child):
                child_label += " [blocked:sensitive]"
            elif child.is_file() and is_binary_suffix(child):
                child_label += " [binary]"
            elif child.is_symlink():
                child_label += " [symlink]"
            lines.append(prefix + marker + child_label)
            emitted += 1
            if child_is_dir:
                next_prefix = prefix + ("    " if is_last else "|   ")
                walk(child, next_prefix, depth + 1)

    walk(start, "", 0)
    return {
        "root": str(root),
        "path": relative_path(root, start),
        "tree": "\n".join(lines),
        "entry_count": emitted,
        "max_depth": max_depth,
        "truncated": truncated,
        "stats": dict(stats),
    }


def project_summary(root: Path, _args: dict[str, Any]) -> dict[str, Any]:
    stats: Counter[str] = Counter()
    extension_counts: Counter[str] = Counter()
    top_level_counts: Counter[str] = Counter()
    max_files = DEFAULT_SEARCH_FILES
    scanned = 0

    for path in iter_text_files(
        root,
        root,
        include_hidden=False,
        max_files=max_files,
        max_file_bytes=MAX_SEARCH_FILE_BYTES,
        stats=stats,
    ):
        scanned += 1
        rel = path.relative_to(root)
        top_level_counts[rel.parts[0] if rel.parts else "."] += 1
        extension_counts[path.suffix.lower() or "<none>"] += 1

    important_files = [
        "README.md",
        "docs/backend/PROJECT_CONSOLIDATED_SUMMARY.md",
        "docs/backend/API_REFERENCE.md",
        "docs/backend/api/WALLET.md",
        "backend/kerosene/build.gradle.kts",
        "frontend/pubspec.yaml",
        "backend/mpc-sidecar/go.mod",
    ]

    components: list[dict[str, str]] = []
    if (root / "backend/kerosene/build.gradle.kts").exists():
        components.append({"name": "backend/kerosene", "stack": "Java/Kotlin Gradle backend"})
    if (root / "frontend/pubspec.yaml").exists():
        components.append({"name": "frontend", "stack": "Flutter/Dart app"})
    if (root / "backend/mpc-sidecar/go.mod").exists():
        components.append({"name": "backend/mpc-sidecar", "stack": "Go MPC sidecar"})
    if (root / "backend/kerosene-infrastructure").exists():
        components.append({"name": "backend/kerosene-infrastructure", "stack": "Docker/local infrastructure"})
    if (root / "docs").exists():
        components.append({"name": "docs", "stack": "Project documentation"})

    return {
        "root": str(root),
        "server": SERVER_NAME,
        "workspace_guards": [
            "all paths are resolved under the configured project root",
            "all non-sensitive project files are writable, including backend, frontend, docs, scripts, and infrastructure files",
            "sensitive files such as .env files, private keys, .git internals, local databases, and secrets directories are refused",
            "shell commands run from inside the project root and inherit the full server environment by default",
            "set KEROSENE_MCP_SCRUB_SHELL_ENV=1 to strip secret-like environment variables before shell execution",
            "binary and oversized files are skipped for search",
        ],
        "components": components,
        "important_files": [path for path in important_files if (root / path).exists()],
        "top_level_text_file_counts": dict(top_level_counts.most_common(20)),
        "extension_counts": dict(extension_counts.most_common(25)),
        "scanned_text_files": scanned,
        "skipped": dict(stats),
    }


def tool_schema() -> list[dict[str, Any]]:
    return [
        {
            "name": "list_directory",
            "description": "List entries inside the project root.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "default": ".", "description": "Path relative to the project root."},
                    "include_hidden": {"type": "boolean", "default": False},
                    "max_entries": {"type": "integer", "minimum": 1, "maximum": MAX_LIST_ENTRIES, "default": DEFAULT_LIST_ENTRIES},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "read_file",
            "description": "Read a text file from the project with byte limits. Refuses sensitive and binary files.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path relative to the project root."},
                    "offset": {"type": "integer", "minimum": 0, "default": 0},
                    "max_bytes": {"type": "integer", "minimum": 1, "maximum": MAX_READ_BYTES, "default": DEFAULT_READ_BYTES},
                },
                "required": ["path"],
                "additionalProperties": False,
            },
        },
        {
            "name": "read_file_lines",
            "description": "Read a text file by line range with bounded output. Prefer this for large source files and logs.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path relative to the project root."},
                    "start_line": {"type": "integer", "minimum": 1, "default": 1},
                    "max_lines": {"type": "integer", "minimum": 1, "maximum": MAX_READ_LINES, "default": DEFAULT_READ_LINES},
                    "max_chars": {"type": "integer", "minimum": 1000, "maximum": MAX_READ_LINES_CHARS, "default": 1000000},
                    "max_line_chars": {"type": "integer", "minimum": 100, "maximum": MAX_READ_LINE_CHARS, "default": MAX_READ_LINE_CHARS},
                },
                "required": ["path"],
                "additionalProperties": False,
            },
        },
        {
            "name": "search_text",
            "description": "Search literal text in project files. Skips excluded, sensitive, binary, and oversized files.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
                    "path": {"type": "string", "default": "."},
                    "case_sensitive": {"type": "boolean", "default": False},
                    "include_hidden": {"type": "boolean", "default": False},
                    "context_lines": {"type": "integer", "minimum": 0, "maximum": MAX_CONTEXT_LINES, "default": 0},
                    "max_results": {"type": "integer", "minimum": 1, "maximum": MAX_SEARCH_RESULTS, "default": DEFAULT_SEARCH_RESULTS},
                    "max_files": {"type": "integer", "minimum": 1, "maximum": MAX_SEARCH_FILES, "default": DEFAULT_SEARCH_FILES},
                    "max_file_bytes": {"type": "integer", "minimum": 1000, "maximum": MAX_SEARCH_FILE_BYTES, "default": MAX_SEARCH_FILE_BYTES},
                    "timeout_seconds": {"type": "number", "minimum": 1, "maximum": MAX_SEARCH_TIMEOUT_SECONDS, "default": DEFAULT_SEARCH_TIMEOUT_SECONDS},
                    "max_response_chars": {"type": "integer", "minimum": 10000, "maximum": MAX_SEARCH_RESPONSE_CHARS, "default": DEFAULT_SEARCH_RESPONSE_CHARS},
                },
                "required": ["query"],
                "additionalProperties": False,
            },
        },
        {
            "name": "write_file",
            "description": "Write large UTF-8 text to any non-sensitive file inside the project root. Creates parent directories as needed.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path relative to the project root."},
                    "content": {"type": "string"},
                    "create_parents": {"type": "boolean", "default": True},
                },
                "required": ["path", "content"],
                "additionalProperties": False,
            },
        },
        {
            "name": "replace_text_in_file",
            "description": "Replace text in any existing non-sensitive project file.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path relative to the project root."},
                    "old_text": {"type": "string"},
                    "new_text": {"type": "string"},
                    "replace_all": {"type": "boolean", "default": True},
                    "case_sensitive": {"type": "boolean", "default": True},
                },
                "required": ["path", "old_text", "new_text"],
                "additionalProperties": False,
            },
        },
        {
            "name": "search_code",
            "description": "Alias for search_text, kept for the MCP structure originally requested.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
                    "path": {"type": "string", "default": "."},
                    "case_sensitive": {"type": "boolean", "default": False},
                    "include_hidden": {"type": "boolean", "default": False},
                    "context_lines": {"type": "integer", "minimum": 0, "maximum": MAX_CONTEXT_LINES, "default": 0},
                    "max_results": {"type": "integer", "minimum": 1, "maximum": MAX_SEARCH_RESULTS, "default": DEFAULT_SEARCH_RESULTS},
                    "max_files": {"type": "integer", "minimum": 1, "maximum": MAX_SEARCH_FILES, "default": DEFAULT_SEARCH_FILES},
                    "max_file_bytes": {"type": "integer", "minimum": 1000, "maximum": MAX_SEARCH_FILE_BYTES, "default": MAX_SEARCH_FILE_BYTES},
                    "timeout_seconds": {"type": "number", "minimum": 1, "maximum": MAX_SEARCH_TIMEOUT_SECONDS, "default": DEFAULT_SEARCH_TIMEOUT_SECONDS},
                    "max_response_chars": {"type": "integer", "minimum": 10000, "maximum": MAX_SEARCH_RESPONSE_CHARS, "default": DEFAULT_SEARCH_RESPONSE_CHARS},
                },
                "required": ["query"],
                "additionalProperties": False,
            },
        },
        {
            "name": "get_project_tree",
            "description": "Return an ASCII tree for the project or a subdirectory.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "default": "."},
                    "include_hidden": {"type": "boolean", "default": False},
                    "include_files": {"type": "boolean", "default": True},
                    "max_depth": {"type": "integer", "minimum": 1, "maximum": 16, "default": 4},
                    "max_entries": {"type": "integer", "minimum": 1, "maximum": MAX_TREE_ENTRIES, "default": DEFAULT_TREE_ENTRIES},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "project_summary",
            "description": "Summarize detected project components and file distribution without reading secrets.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "shell_command",
            "description": "Run a shell command inside the project root and capture stdout/stderr. Supports large local validation/build commands such as Java/Gradle, Flutter, Dart, Go, git, rg, sed, and find.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "Shell command to execute."},
                    "cwd": {"type": "string", "default": ".", "description": "Working directory relative to the project root."},
                    "timeout_seconds": {"type": "integer", "minimum": 1, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": DEFAULT_COMMAND_TIMEOUT_SECONDS},
                },
                "required": ["command"],
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_start_worker",
            "description": "Start a managed Codex worker. This is the Kerosene-native entrypoint for the Codex fleet.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "task": {"type": "string"},
                    "agent_id": {"type": "string"},
                    "model": {"type": "string"},
                    "cwd": {"type": "string"},
                    "sandbox": {"type": "string"},
                    "approval_policy": {"type": "string"},
                    "reasoning_effort": {"type": "string"},
                    "codex_home": {"type": "string"},
                    "run_as_user": {"type": "string"},
                    "create_worktree": {"type": "boolean"},
                },
                "required": ["task"],
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_resume_worker",
            "description": "Resume a managed Codex worker thread.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "agent_id": {"type": "string"},
                    "prompt": {"type": "string"},
                    "model": {"type": "string"},
                    "sandbox": {"type": "string"},
                    "approval_policy": {"type": "string"},
                    "reasoning_effort": {"type": "string"},
                },
                "required": ["agent_id", "prompt"],
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_status",
            "description": "Show status for managed Codex workers.",
            "inputSchema": {"type": "object", "properties": {"agent_id": {"type": "string"}}, "additionalProperties": False},
        },
        {
            "name": "fleet_stop_worker",
            "description": "Stop a managed Codex worker by process group.",
            "inputSchema": {
                "type": "object",
                "properties": {"agent_id": {"type": "string"}, "force": {"type": "boolean", "default": False}},
                "required": ["agent_id"],
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_tail",
            "description": "Read recent JSONL event lines or stderr lines for a managed worker.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "agent_id": {"type": "string"},
                    "stream": {"type": "string", "enum": ["events", "stderr"]},
                    "lines": {"type": "integer", "minimum": 1, "maximum": 500},
                },
                "required": ["agent_id"],
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_usage_report",
            "description": "Aggregate token usage emitted by completed codex exec turns.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "fleet_agent_users",
            "description": "Show the Codex worker slot to session map.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "fleet_preflight",
            "description": "Check session availability and Codex login health before dispatching workers.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "check_login": {"type": "boolean", "default": True},
                    "timeout_seconds": {"type": "number", "minimum": 2, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 8},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_quota_probe",
            "description": "Open a temporary Codex TUI through a PTY, send /status, capture account and quota text, then terminate it.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "cwd": {"type": "string"},
                    "model": {"type": "string"},
                    "codex_home": {"type": "string"},
                    "agent_id": {"type": "string"},
                    "run_as_user": {"type": "string"},
                    "timeout_seconds": {"type": "number", "minimum": 3, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 12},
                    "include_raw_output": {"type": "boolean", "default": True},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "fleet_quota_probe_all",
            "description": "Probe Codex quota for all default Codex sessions.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "cwd": {"type": "string"},
                    "model": {"type": "string"},
                    "timeout_seconds": {"type": "number", "minimum": 3, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 12},
                    "include_raw_output": {"type": "boolean", "default": False},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_start_worker",
            "description": "Start a managed Antigravity worker. This is the Kerosene-native entrypoint for the agy fleet.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "task": {"type": "string"},
                    "agent_id": {"type": "string"},
                    "model": {"type": "string"},
                    "cwd": {"type": "string"},
                    "run_as_user": {"type": "string"},
                    "print_timeout": {"type": "string"},
                    "sandbox": {"type": "boolean"},
                    "dangerously_skip_permissions": {"type": "boolean"},
                    "add_dirs": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["task"],
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_resume_worker",
            "description": "Resume a managed agy worker.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "agent_id": {"type": "string"},
                    "prompt": {"type": "string"},
                    "model": {"type": "string"},
                    "conversation_id": {"type": "string"},
                    "continue_recent": {"type": "boolean"},
                    "print_timeout": {"type": "string"},
                    "sandbox": {"type": "boolean"},
                    "dangerously_skip_permissions": {"type": "boolean"},
                },
                "required": ["agent_id", "prompt"],
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_status",
            "description": "Show status for managed agy workers.",
            "inputSchema": {"type": "object", "properties": {"agent_id": {"type": "string"}}, "additionalProperties": False},
        },
        {
            "name": "agy_stop_worker",
            "description": "Stop a managed agy worker by process group.",
            "inputSchema": {
                "type": "object",
                "properties": {"agent_id": {"type": "string"}, "force": {"type": "boolean", "default": False}},
                "required": ["agent_id"],
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_tail",
            "description": "Read recent stdout or stderr lines for a managed agy worker.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "agent_id": {"type": "string"},
                    "stream": {"type": "string", "enum": ["stdout", "stderr"]},
                    "lines": {"type": "integer", "minimum": 1, "maximum": 500},
                },
                "required": ["agent_id"],
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_usage_report",
            "description": "Report captured output sizes for managed agy runs.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "agy_agent_users",
            "description": "Show agy worker slots and the codex session map.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "agy_preflight",
            "description": "Check session availability and agy CLI health before dispatching workers.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "check_login": {"type": "boolean", "default": True},
                    "timeout_seconds": {"type": "number", "minimum": 2, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 12},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_quota_probe",
            "description": "Open a temporary agy TUI through a PTY, send /status, capture account/quota text, then terminate it.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "cwd": {"type": "string"},
                    "model": {"type": "string"},
                    "agent_id": {"type": "string"},
                    "run_as_user": {"type": "string"},
                    "timeout_seconds": {"type": "number", "minimum": 3, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 15},
                    "include_raw_output": {"type": "boolean", "default": True},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "agy_quota_probe_all",
            "description": "Probe agy status/quota for all default slots.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "cwd": {"type": "string"},
                    "model": {"type": "string"},
                    "timeout_seconds": {"type": "number", "minimum": 3, "maximum": MAX_COMMAND_TIMEOUT_SECONDS, "default": 15},
                    "include_raw_output": {"type": "boolean", "default": False},
                },
                "additionalProperties": False,
            },
        },
    ]


def call_tool(root: Path, name: str, args: dict[str, Any]) -> Any:
    if name == "list_directory":
        return list_directory(root, args)
    if name == "read_file":
        return read_file(root, args)
    if name == "read_file_lines":
        return read_file_lines(root, args)
    if name in {"search_text", "search_code"}:
        return search_text(root, args)
    if name == "write_file":
        return write_file(root, args)
    if name == "replace_text_in_file":
        return replace_text_in_file(root, args)
    if name == "shell_command":
        return shell_command(root, args)
    if name == "get_project_tree":
        return get_project_tree(root, args)
    if name == "project_summary":
        return project_summary(root, args)
    if name.startswith("fleet_"):
        return call_mcp_proxy(CODEX_FLEET_SCRIPT, name, args, timeout_seconds=proxy_timeout_seconds(name, args))
    if name.startswith("agy_"):
        return call_mcp_proxy(AGY_FLEET_SCRIPT, name, args, timeout_seconds=proxy_timeout_seconds(name, args))
    raise ReadOnlyMcpError(f"Unknown tool: {name}")


class McpServer:
    def __init__(self, root: Path) -> None:
        self.root = root

    def send(self, payload: dict[str, Any]) -> None:
        sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
        sys.stdout.flush()

    def result(self, request_id: Any, result: Any) -> None:
        self.send({"jsonrpc": "2.0", "id": request_id, "result": result})

    def error(self, request_id: Any, code: int, message: str) -> None:
        self.send({"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}})

    def handle(self, message: dict[str, Any]) -> None:
        method = message.get("method")
        request_id = message.get("id")
        if request_id is None:
            return
        try:
            if method == "initialize":
                params = message.get("params") or {}
                self.result(
                    request_id,
                    {
                        "protocolVersion": params.get("protocolVersion") or "2024-11-05",
                        "capabilities": {"tools": {"listChanged": False}},
                        "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                    },
                )
            elif method == "tools/list":
                self.result(request_id, {"tools": tool_schema()})
            elif method == "tools/call":
                params = message.get("params") or {}
                name = str(params.get("name") or "")
                args = params.get("arguments") or {}
                if not isinstance(args, dict):
                    raise ReadOnlyMcpError("Tool arguments must be a JSON object")
                value = call_tool(self.root, name, args)
                self.result(
                    request_id,
                    {
                        "content": [
                            {
                                "type": "text",
                                "text": compact_tool_value(value),
                            }
                        ]
                    },
                )
            elif method in {"resources/list", "prompts/list"}:
                key = "resources" if method.startswith("resources/") else "prompts"
                self.result(request_id, {key: []})
            elif method == "ping":
                self.result(request_id, {})
            else:
                self.error(request_id, -32601, f"Method not found: {method}")
        except ReadOnlyMcpError as exc:
            self.result(
                request_id,
                {
                    "isError": True,
                    "content": [{"type": "text", "text": str(exc)}],
                },
            )
        except Exception as exc:  # Keep the MCP process alive after unexpected tool failures.
            print(f"{SERVER_NAME}: unexpected error: {exc}", file=sys.stderr)
            self.result(
                request_id,
                {
                    "isError": True,
                    "content": [{"type": "text", "text": f"Unexpected error: {exc}"}],
                },
            )

    def serve(self) -> None:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                message = json.loads(line)
            except json.JSONDecodeError as exc:
                print(f"{SERVER_NAME}: invalid JSON-RPC message: {exc}", file=sys.stderr)
                continue
            if isinstance(message, dict):
                self.handle(message)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MCP server for the Kerosene project.")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="Project root exposed through MCP.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = resolve_root(Path(args.root))
    McpServer(root).serve()


if __name__ == "__main__":
    main()

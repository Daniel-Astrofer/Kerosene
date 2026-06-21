# Kerosene MCP

`scripts/kerosene-mcp` exposes the Kerosene repository through a local MCP server with read, write, replace, and shell tools. `scripts/kerosene-readonly-mcp` is kept as a compatibility wrapper for existing local client configs.

## Tools

- `list_directory`: lists a directory inside the configured project root.
- `read_file`: reads bounded text from a file.
- `read_file_lines`: reads bounded line ranges from large text files without returning one oversized payload.
- `search_text`: searches literal text across source, docs, config, and logs.
- `get_project_tree`: returns an ASCII project tree.
- `search_code`: alias for `search_text`.
- `project_summary`: summarizes detected project components and file distribution.
- `write_file`: writes text to a project file and creates parent directories as needed.
- `replace_text_in_file`: replaces text inside an existing project file.
- `shell_command`: runs a shell command inside the project root and captures stdout/stderr.

## Safety Boundary

- The server resolves every requested path under `KEROSENE_MCP_ROOT`, defaulting to `/home/omega/Kerosene`.
- It allows file reads, large file writes, replace operations, and shell commands only inside the project root and still refuses sensitive files.
- It implements no delete or process-control tools.
- It refuses sensitive files such as `.env`, private keys, keystores, local databases, wallet files, `.git/**`, and `secrets/**`.
- Search skips excluded build/cache folders, binary files, sensitive files, and oversized files.
- Shell commands inherit the full server environment by default so local tooling can work normally. Set `KEROSENE_MCP_SCRUB_SHELL_ENV=1` to strip secret-like variables before execution.

## Agent Commit Rule

- After any agent-authored code, config, test, or documentation change, the agent must create a local git commit on the current branch before reporting completion.
- Stage only files changed for the current task. Do not stage unrelated worktree changes, generated secrets, local databases, wallet material, or environment files.
- Do not push commits unless the user explicitly asks for a push.

## Project Refactor Mode

The MCP is intended for project-wide refactors across frontend, backend, docs, scripts, tests, assets, and infrastructure files inside the repository root.

Every non-sensitive text file under `/home/omega/Kerosene` is writable. Do not maintain a small allowlist of source directories; agents must be able to edit the project broadly when the requested task requires it.

Files like `docs/backend/api/WALLET.md` and `docs/backend/api/SOVEREIGNTY.md` are normal documentation targets and must not be blocked just because they contain technical terms or legacy references.

Sensitive content must still be blocked by context, not by generic words. Keep refusing:

- `.env`
- `.env.*`
- `*.pem`
- `*.key`
- `*.crt`
- `.git/**`
- `secrets/**`
- binary files
- local databases and wallet material

Do not refuse legitimate refactors because a file path or file content mentions words such as `wallet`, `payment`, `error`, `secret`, `token`, `auth`, `vault`, or `card`. Refuse only when the path matches real sensitive material.

The server allows large edits throughout the repository, and the shell tool is available for local validation and build commands such as `./gradlew build`, `./gradlew test`, `java -version`, `flutter analyze`, `flutter test`, `dart format`, `go test`, `git diff`, `git status`, `grep`, `rg`, `sed`, and `find`.

For large files, agents should call `read_file_lines` with `start_line` and `max_lines` instead of asking `read_file` for a very large byte payload. This keeps the MCP bridge responsive while still allowing full source inspection in chunks.

Search tools have a connector-safe time and response budget. `search_text` and `search_code` accept `timeout_seconds` and `max_response_chars`; when the budget is reached they return partial results with `truncated: true` instead of letting the tunnel turn the call into a 502.

This policy is enforced by `scripts/kerosene_readonly_mcp.py`.

## Local MCP Config

Use this entry in an MCP-capable local client:

```json
{
  "mcpServers": {
    "kerosene-mcp": {
      "command": "/home/omega/Kerosene/scripts/kerosene-mcp",
      "args": [],
      "env": {
        "KEROSENE_MCP_ROOT": "/home/omega/Kerosene"
      }
    }
  }
}
```

For Codex CLI, the equivalent registration is:

```bash
codex mcp add kerosene-mcp -- /home/omega/Kerosene/scripts/kerosene-mcp
```

## ChatGPT Web

ChatGPT Web cannot launch a local `stdio` command directly. OpenAI's MCP documentation describes two supported paths for private/local MCP servers:

- expose a remote MCP server over Streamable HTTP or HTTP/SSE;
- use Secure MCP Tunnel so ChatGPT reaches a private local or on-prem MCP server without opening inbound firewall ports.

For the tunnel path, configure `tunnel-client` with this MCP command:

```bash
tunnel-client init \
  --sample sample_mcp_stdio_local \
  --profile kerosene-mcp \
  --tunnel-id tunnel_... \
  --mcp-command "/home/omega/Kerosene/scripts/kerosene-mcp"
```

Then keep `tunnel-client run --profile kerosene-mcp --mcp.connection-max-ttl 30m --mcp.max-concurrent-requests 4` running and create a custom ChatGPT connector using the tunnel.

Official references:

- https://developers.openai.com/api/docs/guides/tools-connectors-mcp
- https://developers.openai.com/api/docs/guides/secure-mcp-tunnels

## Manual Verification

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"."}}}' \
  '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"read_file_lines","arguments":{"path":"scripts/kerosene_readonly_mcp.py","start_line":1,"max_lines":20}}}' \
  | /home/omega/Kerosene/scripts/kerosene-mcp
```


## Tunnel Startup

Keep secrets in `scripts/.env.tunnel` or the shell environment. Do not write runtime API keys into this repository.

```bash
cd /home/omega/Kerosene
export CONTROL_PLANE_API_KEY="<runtime-api-key>"

./scripts/start-kerosene-tunnel.sh
```

The startup script recreates the `kerosene-readonly` profile, validates it with `doctor`, and runs the tunnel with `MCP_CONNECTION_MAX_TTL=30m` and `MCP_MAX_CONCURRENT_REQUESTS=4` by default. Override with `KEROSENE_TUNNEL_MCP_CONNECTION_MAX_TTL` and `KEROSENE_TUNNEL_MCP_MAX_CONCURRENT_REQUESTS` only when needed.

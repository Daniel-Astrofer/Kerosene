# Kerosene MCP

`scripts/kerosene-readonly-mcp` exposes the Kerosene repository through a local MCP server with read, write, replace, and shell tools.

## Tools

- `list_directory`: lists a directory inside the configured project root.
- `read_file`: reads bounded text from a file.
- `search_text`: searches literal text across source, docs, config, and logs.
- `get_project_tree`: returns an ASCII project tree.
- `search_code`: alias for `search_text`.
- `project_summary`: summarizes detected project components and file distribution.
- `write_file`: writes text to a project file and creates parent directories as needed.
- `replace_text_in_file`: replaces text inside an existing project file.
- `shell_command`: runs a shell command inside the project root and captures stdout/stderr.

## Safety Boundary

- The server resolves every requested path under `KEROSENE_MCP_ROOT`, defaulting to `/home/omega/Kerosene`.
- It allows file writes and shell commands only inside the project root and still refuses sensitive files.
- It implements no delete or process-control tools.
- It refuses sensitive files such as `.env`, private keys, keystores, local databases, and wallet files.
- Search skips excluded build/cache folders, binary files, sensitive files, and oversized files.

## Agent Commit Rule

- After any agent-authored code, config, test, or documentation change, the agent must create a local git commit on the current branch before reporting completion.
- Stage only files changed for the current task. Do not stage unrelated worktree changes, generated secrets, local databases, wallet material, or environment files.
- Do not push commits unless the user explicitly asks for a push.

## Project Refactor Mode

The MCP is intended for project-wide refactors across frontend, backend, docs, and infrastructure files inside the repository root.

Explicitly writable areas include:

- `frontend/lib/**`
- `frontend/assets/**`
- `frontend/tool/**`
- `frontend/pubspec.yaml`
- `backend/**`
- `docs/backend/api/**`
- `docs/AGENTS/**`

Files like `docs/backend/api/WALLET.md` and `docs/backend/api/SOVEREIGNTY.md` are normal documentation targets and must not be blocked just because they contain technical terms or legacy references.

Sensitive content must still be blocked by context, not by generic words. Keep refusing:

- `.env`
- `.env.*`
- `*.pem`
- `*.key`
- `*.crt`
- `secrets/**`
- `vault/**`
- `docker-compose*.yml`
- `application*.properties`
- `application*.yml`
- binary files
- local databases and wallet material

Do not refuse legitimate refactors because a file mentions words such as `wallet`, `payment`, `error`, `secret`, `token`, `auth`, or `card`. Refuse only when the path or content matches real sensitive material.

The server now allows large edits in backend and frontend source files, and the shell tool is available for local validation commands such as `flutter analyze`, `dart format`, `git diff`, `git status`, `grep`, `rg`, `sed`, and `find`.

This policy is enforced by `scripts/kerosene_readonly_mcp.py`.

## Local MCP Config

Use this entry in an MCP-capable local client:

```json
{
  "mcpServers": {
    "kerosene-mcp": {
      "command": "/home/omega/Kerosene/scripts/kerosene-readonly-mcp",
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
codex mcp add kerosene-mcp -- /home/omega/Kerosene/scripts/kerosene-readonly-mcp
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
  --mcp-command "/home/omega/Kerosene/scripts/kerosene-readonly-mcp"
```

Then keep `tunnel-client run --profile kerosene-mcp` running and create a custom ChatGPT connector using the tunnel.

Official references:

- https://developers.openai.com/api/docs/guides/tools-connectors-mcp
- https://developers.openai.com/api/docs/guides/secure-mcp-tunnels

## Manual Verification

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"."}}}' \
  | /home/omega/Kerosene/scripts/kerosene-readonly-mcp
```


# Comando de Iniciualização 

```cd /home/omega/Kerosene

export CONTROL_PLANE_API_KEY="<CONTROL_PLANE_API_KEY>"

./tunnel-client init \
--sample sample_mcp_stdio_local \
--profile kerosene-readonly \
--tunnel-id tunnel_... \
--mcp-command "/home/omega/Kerosene/scripts/kerosene-readonly-mcp"

./tunnel-client doctor --profile kerosene-readonly --explain
./tunnel-client run --profile kerosene-readonly 
```

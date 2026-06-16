# Codex Fleet MCP

`scripts/codex-fleet-mcp` exposes a local MCP server for Antigravity 2.0 CLI (`agy`) to manage Codex workers without tmux.

Tools exposed:

- `fleet_start_worker`: starts `codex exec --json` in the background.
- `fleet_resume_worker`: resumes a recorded Codex thread.
- `fleet_status`: shows managed worker state, PID, thread id, logs, and latest usage.
- `fleet_stop_worker`: stops a worker process group.
- `fleet_tail`: reads recent JSONL events or stderr.
- `fleet_usage_report`: aggregates token usage emitted by `codex exec --json`.
- `fleet_agent_users`: shows the worker slot to Unix user mapping.
- `fleet_preflight`: checks user switching and Codex login health before dispatching.
- `fleet_quota_probe`: opens a temporary Codex PTY, sends `/status`, parses quota text, then exits.
- `fleet_quota_probe_all`: probes quota for `codex1`, `codex2`, `codex3`, and `codex4`.

State is stored under `~/.codex-fleet` for the user that launches the MCP server.

## Codex User Slots

The orchestrator is `agy`, but Codex workers run as the four already-authenticated Unix users:

| agent_id | Unix user |
| --- | --- |
| `codex1` | `codex1` |
| `codex2` | `codex2` |
| `codex3` | `codex3` |
| `codex4` | `codex4` |

Aliases are also mapped:

| alias | Unix user |
| --- | --- |
| `security` | `codex1` |
| `performance` | `codex2` |
| `quality` | `codex3` |
| `tests` | `codex4` |

If `fleet_start_worker` is called without `agent_id`, it picks the next free slot from `codex1` to `codex4`.

When `agy` runs as `omega`, switching to the Codex users requires passwordless user switching from `omega` to `codex1..codex4` (`sudo -n -H -u <user> -- ...`). If that is not configured, the MCP call fails before consuming quota.

Do not create ad-hoc users such as `jka` for this fleet. `fleet_start_worker` uses `agent_id`, not `worker_id`, and `task` is required.

Install the sudoers rule once as root:

```bash
sudo /home/omega/Kerosene/scripts/install-codex-fleet-sudoers.sh
```

## Install In agy

Run this from the `omega` account, because the active `agy` profile is owned by `omega`:

```bash
/home/omega/Kerosene/scripts/install-codex-fleet-agy.sh
```

The installer writes the `codex-fleet` entry into the CLI MCP config files:

- `/home/omega/.gemini/config/mcp_config.json`
- `/home/omega/.gemini/antigravity-cli/mcp_config.json`

It also adds a managed memory block to `/home/omega/.gemini/GEMINI.md` telling `agy` to use `codex-fleet` autonomously instead of the old tmux workflow.

Equivalent MCP config entry:

```json
{
  "mcpServers": {
    "codex-fleet": {
      "command": "/home/omega/Kerosene/scripts/codex-fleet-mcp",
      "args": [],
      "env": {
        "CODEX_FLEET_CODEX_BIN": "/path/to/codex"
      }
    }
  }
}
```

This intentionally does not call the Visual Studio-style `antigravity --add-mcp` launcher. If `agy` does not hot-reload MCP servers, restart the current `agy` session or open a new `agy` chat after registration.

The compatibility script still exists:

```bash
/home/omega/Kerosene/scripts/install-codex-fleet-mcp.sh
```

It now forwards to the `agy` installer.

## Authentication And Verification

`agy` authentication and `codex` authentication are separate:

- `agy` must be signed in so Antigravity CLI can run and call MCP tools.
- `codex` must be signed in for the Unix user that launches the MCP server, because `fleet_quota_probe` and workers run the `codex` CLI underneath.

The active `agy` logs on this machine use `/home/omega/.gemini/antigravity-cli` and `/home/omega/.gemini/config`; do not assume credentials are stored under `~/.antigravity/credentials.json`.

After installing and restarting `agy`, verify the MCP server:

```bash
agy mcp-call codex-fleet fleet_agent_users '{}'
agy mcp-call codex-fleet fleet_preflight '{}'
agy mcp-call codex-fleet fleet_status '{}'
agy mcp-call codex-fleet fleet_quota_probe_all '{}'
```

These `agy mcp-call` commands are manual verification commands only. In a normal conversation, the `agy` agent should call the MCP tools itself.

Start four workers explicitly:

```bash
agy mcp-call codex-fleet fleet_start_worker '{"agent_id":"codex1","model":"gpt-5.5","task":"Audit security issues, dependency risks, and dead code. Report findings with file paths.","create_worktree":true}'
agy mcp-call codex-fleet fleet_start_worker '{"agent_id":"codex2","model":"gpt-5.5","task":"Audit backend and frontend performance bottlenecks. Report concrete fixes with file paths.","create_worktree":true}'
agy mcp-call codex-fleet fleet_start_worker '{"agent_id":"codex3","model":"gpt-5.5","task":"Audit code quality, naming, typing, and UI consistency. Report concrete fixes with file paths.","create_worktree":true}'
agy mcp-call codex-fleet fleet_start_worker '{"agent_id":"codex4","model":"gpt-5.5","task":"Audit missing unit, integration, and flaky tests. Report concrete test additions with file paths.","create_worktree":true}'
```

Then inspect process state and token usage:

```bash
agy mcp-call codex-fleet fleet_status '{}'
agy mcp-call codex-fleet fleet_usage_report '{}'
```

## Notes

`fleet_quota_probe` reads the quota for the account visible to the user running the MCP server. To probe a different Unix user, pass `run_as_user`, but that requires passwordless `sudo -n -iu <user>`.

With the default slot map, prefer:

```bash
agy mcp-call codex-fleet fleet_quota_probe '{"agent_id":"codex1"}'
agy mcp-call codex-fleet fleet_quota_probe_all '{}'
```

`fleet_usage_report` reports tokens used by managed `codex exec --json` runs. It is not the same as quota remaining, and a prompt like `{"task":"status"}` does not query Codex quota.

If quota probing returns `token_revoked`, `401`, or OAuth/auth errors, interpret that as Codex CLI authentication for the specific `run_as_user`; it is not an MCP registration error and not an `agy` login error. Diagnose manually with `sudo -n -H -u codex1 -- /usr/local/bin/codex login status` and renew with `sudo -H -u codex1 -- /usr/local/bin/codex login --device-auth`, replacing `codex1` as needed.

For write-heavy tasks, prefer `create_worktree=true` to isolate worker changes. For tasks that must see the current dirty working tree, keep `create_worktree=false` and use only one writer at a time.

To change a worker model, stop or wait for the current process and call `fleet_resume_worker` with the same `agent_id` and a new `model`. A running `codex exec` process cannot switch model in place.

# Agy Fleet MCP

`scripts/agy-fleet-mcp` exposes a local MCP server for Codex to manage Antigravity CLI (`agy`) workers.

The managed Antigravity slots are named `agy1`, `agy2`, `agy3`, and `agy4`, but they run under the existing Unix users:

| agent_id | Unix user |
| --- | --- |
| `agy1` | `codex1` |
| `agy2` | `codex2` |
| `agy3` | `codex3` |
| `agy4` | `codex4` |

Aliases `codex1`, `codex2`, `codex3`, and `codex4` are accepted and canonicalized to the matching `agyN` slot.

## Tools

- `agy_start_worker`: starts `agy --print` in the background.
- `agy_resume_worker`: resumes with `agy --print --continue` or `--conversation`.
- `agy_status`: shows managed worker state, PID, logs, and latest captured output.
- `agy_stop_worker`: stops a worker process group.
- `agy_tail`: reads recent stdout or stderr.
- `agy_usage_report`: reports captured output sizes. `agy --print` does not emit Codex token JSON.
- `agy_agent_users`: shows the `agyN` slot to `codexN` user mapping.
- `agy_preflight`: checks user switching, agy binary health, and optionally model/login health.
- `agy_quota_probe`: opens a temporary agy TUI, sends `/status`, and captures output.
- `agy_quota_probe_all`: probes all default slots.

State is stored under `~/.agy-fleet` for the Codex user that launches the MCP server.

## Install In Codex

Run as the Codex user that should orchestrate agy workers:

```bash
/path/to/scripts/install-agy-fleet-codex.sh
```

Then restart Codex so it reloads MCP servers.

Equivalent manual registration:

```bash
codex mcp add agy-fleet -- /path/to/scripts/agy-fleet-mcp
```

## Install In agy

Run this from the `omega` account, because the active `agy` profile belongs to `omega`:

```bash
/home/omega/Kerosene/scripts/install-agy-fleet-agy.sh
```

The installer writes the `agy-fleet` entry into the CLI MCP config files:

- `/home/omega/.gemini/config/mcp_config.json`
- `/home/omega/.gemini/antigravity-cli/mcp_config.json`

It also adds a managed memory block to `/home/omega/.gemini/GEMINI.md` telling `agy` to use `agy-fleet` autonomously.

## User Switching

If a Codex session running as `codex2` should launch workers as `codex1`, `codex3`, or `codex4`, passwordless user switching must be configured.

Install the sudoers rule once as root:

```bash
sudo /path/to/scripts/install-agy-fleet-sudoers.sh
```

Then verify through the MCP tool:

```text
agy_preflight {}
```

In this runtime, a `sudo_no_new_privileges` diagnostic means the container/session is preventing sudo from elevating. That is a runtime restriction, not an agy login problem.

## Example Dispatch

```text
agy_start_worker {"agent_id":"agy1","task":"Audit security issues and report concrete findings with file paths.","cwd":"/home/omega/Kerosene"}
agy_start_worker {"agent_id":"agy2","task":"Audit performance bottlenecks and report concrete fixes with file paths.","cwd":"/home/omega/Kerosene"}
agy_start_worker {"agent_id":"agy3","task":"Audit code quality, naming, typing, and UI consistency.","cwd":"/home/omega/Kerosene"}
agy_start_worker {"agent_id":"agy4","task":"Audit missing tests and flaky test risks.","cwd":"/home/omega/Kerosene"}
```

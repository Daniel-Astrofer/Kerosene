# Nightly Agent Orchestration State

Status: active
Current window: now until 12:00 America/Sao_Paulo
Cadence: hourly
Start-local policy: ignored; do not run `scripts/start-local.sh`.
Implementation concurrency: 1 agent maximum.
Read-only concurrency: 2 agents maximum only for non-overlapping audit scopes.

## Current task

ID: none currently running
Agent: none
Status: ready for next cycle

## Last completed work

- `b4d17435 fase-4/docs: align api docs to kfe only`
- `f029287b fase-4/kfe-cleanup: remove legacy financial naming`
- `e698edd8 fase-4/kfe-cleanup: remove legacy financial route policies`

## Next task

`fase-6/architecture: add backend cleanup audit`

## Blockers

- `scripts/start-local.sh` intentionally disabled by user instruction.
- Some agent sandboxes cannot create `.git/index.lock`; orchestrator may need to commit after validation.
- Some agent sandboxes cannot run Gradle due socket/network/cache restrictions; orchestrator should rerun validations from main shell when possible.

## Orchestrator cycle checklist

1. Check `git status --short`.
2. Check active agents.
3. If an agent is active, inspect status and do not start another implementation task.
4. If working tree is dirty, validate/commit/revert/register blocker before continuing.
5. Pick the next queue item only when safe.
6. Dispatch at most one implementation agent.
7. Require scoped files, `git diff --check`, focused validation, and isolated commit.
8. Update this file at the end of the cycle.

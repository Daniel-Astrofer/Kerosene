# Nightly Agent Orchestration State

Status: active
Current window: now until 12:00 America/Sao_Paulo
Cadence: hourly
Start-local policy: ignored; do not run `scripts/start-local.sh`.
Implementation concurrency: 1 agent maximum.
Read-only concurrency: 2 agents maximum only for non-overlapping audit scopes.

## Current task

ID: fase-6/kfe: add financial invariant tests
Agent: codex8
Status: running KFE invariant test agent in isolated worktree

## Last completed work

- `78f4dc30 fase-6/startup: add fast backend diagnostics`
- `a695ce67 fase-6/audit: add structured domain audit event foundation`
- `2619fc4b fase-6/logging: add structured runtime logging foundation`
- `4ece67c fase-6/orchestration: complete docs standard task`
- `a99d50b fase-6/docs: define backend code documentation standard`
- `e3135c0 fase-6/architecture: add backend cleanup audit`
- `659efd10 fase-6/mcp: stabilize tunnel script paths`
- `b4d17435 fase-4/docs: align api docs to kfe only`
- `f029287b fase-4/kfe-cleanup: remove legacy financial naming`
- `e698edd8 fase-4/kfe-cleanup: remove legacy financial route policies`

## Next task

`fase-6/kfe: add financial invariant tests`

## Blockers

- `scripts/start-local.sh` intentionally disabled by user instruction.
- Some agent sandboxes cannot create `.git/index.lock`; orchestrator may need to commit after validation.
- Some agent sandboxes cannot run Gradle due socket/network/cache restrictions; orchestrator should rerun validations from main shell when possible.

## Orchestrator cycle checklist

1. Check `git status --short`.
2. Check active agents.
3. If an agent is active, inspect status and do not start another implementation task.
4. If working tree is dirty, clean it before continuing: inspect the diff, preserve unknown/user changes, commit validated task-owned changes when safe, revert only disposable/generated changes, stash only with a state-file note, then continue to the next pending task whenever a safe path exists.
5. Pick the next queue item only when safe.
6. Dispatch at most one implementation agent.
7. Require scoped files, `git diff --check`, focused validation, and isolated commit.
8. Update this file at the end of the cycle.

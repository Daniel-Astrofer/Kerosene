---
name: kerosene-context
description: Project-wide Kerosene orientation for agents working in this repository. Use when you need to understand the repo structure, agent workflow, key entry points, or the rules that govern backend, frontend, orchestration, and local tooling before making changes.
---

# Kerosene Context

Use this skill to orient on the Kerosene repository before editing code, planning work, or choosing the right subsystem.

## What to load first

Read [references/repo-map.md](../../frontend/agents/kerosene-context/references/repo-map.md) first when you need a fast mental model of the project.

Then inspect the relevant area:

- `frontend/agents/` for agent orchestration notes and operator rules
- `backend/kerosene/` for the main application
- `infra/` for deployment, runtime, Docker, Kubernetes and environment support
- `backend/mpc-sidecar/` and `backend/vault/` for integration and secret-handling code
- `frontend/` for UI-facing code

## Working rules

- Prefer the repository's existing conventions over inventing new structure.
- Treat the agent manuals in `frontend/agents/` as operational constraints, not suggestions.
- Use the smallest relevant surface area: read the subsystem you are changing, then move outward only if needed.
- When work touches agents or orchestration, verify prompt/terminal protocol and execution flow before editing.
- When work touches infrastructure or secrets, check the environment path and runtime assumptions before changing code.
- After any agent-authored code, config, test, or documentation change, create a local git commit on the current branch before reporting completion. Stage only files changed for the task, never stage unrelated user changes, never commit secrets, and do not push unless the user explicitly asks.

## Use cases

Use this skill when the request is about:

- understanding the whole Kerosene codebase
- deciding where a change belongs
- mapping frontend, backend, infrastructure, or agent responsibilities
- onboarding a new agent to the project
- avoiding false assumptions about local workflow or runtime layout

## Output discipline

When answering from this skill, summarize the project in terms of:

- primary entry points
- subsystem boundaries
- agent/orchestration constraints
- likely file locations for the requested change

# Nightly Agent Orchestration Queue

Status: active
Window: now until 12:00 America/Sao_Paulo
Cadence: hourly automation
Runtime constraint: do not run `scripts/start-local.sh` until Nycollas explicitly re-enables it.

## Global rules

- The orchestrator must not write production code directly.
- Agents implement; the orchestrator validates, commits, records state, and chooses the next task.
- Use at most 1 implementation agent at a time.
- Use at most 2 simultaneous agents only for read-only audits with non-overlapping scopes.
- Check `git status --short` before every task.
- If the working tree is dirty, clean it before starting or continuing the next pending task: inspect the diff, preserve user-authored or unknown changes, commit validated task-owned changes when safe, revert only clearly disposable/generated changes, stash only with an explicit state-file note, then continue to the next queue item.
- Do not use `git add .`.
- Each implementation must run `git diff --check` and focused validation.
- Each completed task must create one isolated commit with format `<fase>/<area>: <summary>`.
- Backend work must follow `docs/backend/KEROSENE_BACKEND_ENGINEERING_DESIGN_SYSTEM.md`.
- Financial code and docs are KFE-only: active financial APIs must use `/kfe/**` or `/api/admin/kfe/**`.
- Keep the timer enabled and keep focus on pending queue tasks. On Docker, Gradle, network, permission, tool-filter, unsafe/unknown dirty-worktree changes, or scope risk, record the risk in state, preserve work safely, and continue with any safe validation, cleanup, read-only audit, or next pending task that does not depend on the failing surface.

## Code documentation rule

Document intent, invariants, risks, side effects, and security decisions.

Document:

- public controllers, use cases, ports, and application services;
- methods with business rules, security rules, audit events, external calls, idempotency, or fail-closed behavior;
- non-obvious private methods.

Avoid:

- comments that merely repeat method names;
- Javadoc on trivial getters/setters/mappers;
- broad rewrites outside task scope.

## Queue

### 1. `fase-6/architecture: add backend cleanup audit`

Mode: read-only preferred.

Goal:

- map Clean Architecture and SOLID violations;
- identify controllers with business logic;
- identify broad services and naming inconsistencies;
- identify unsafe error handling and missing useful documentation;
- identify logging and audit gaps.

Allowed output:

- `docs/backend/ARCHITECTURE_CLEANUP_AUDIT.md`

Validation:

- `git diff --check`

### 2. `fase-6/docs: define backend code documentation standard`

Goal:

- add a code documentation standard to the backend design system;
- include examples for KFE, security, idempotency, audit logging, and fail-closed decisions.

Allowed files:

- `docs/backend/KEROSENE_BACKEND_ENGINEERING_DESIGN_SYSTEM.md`

Validation:

- `git diff --check`

### 3. `fase-6/logging: add structured runtime logging foundation`

Goal:

- add/refine structured logging for runtime diagnostics;
- include traceId/correlationId, event, domain, operation, safe message, exception type, and sanitized metadata;
- define separate categories for runtime, startup, security, auth, KFE, audit, integration, Vault, MPC, and frontend API communication;
- never log secrets or raw credentials.

Validation:

- `git diff --check`
- focused logging/exception tests

### 4. `fase-6/audit: add structured domain audit events`

Goal:

- separate audit events from development/runtime logs;
- define stable audit event taxonomy;
- add events to critical Auth, Admin Access, KFE, Vault, and MPC flows;
- sanitize all audit payloads.

Minimum taxonomy:

- `AUTH_LOGIN_SUCCEEDED`
- `AUTH_LOGIN_FAILED`
- `AUTH_LOGOUT`
- `JWT_SESSION_REVOKED`
- `ADMIN_ACCESS_REQUESTED`
- `ADMIN_ACCESS_APPROVED`
- `ADMIN_ACCESS_REJECTED`
- `ADMIN_ACCESS_REDEEMED`
- `BACKUP_CODES_REGENERATED`
- `KFE_WALLET_CREATED`
- `KFE_TRANSACTION_SUBMITTED`
- `KFE_IDEMPOTENCY_CONFLICT`
- `KFE_OUTBOX_DISPATCHED`
- `KFE_OUTBOX_RETRY`
- `KFE_SETTLEMENT_COMPLETED`
- `KFE_SETTLEMENT_FAILED`
- `KFE_INBOUND_CREDITED`
- `KFE_INBOUND_DUPLICATE_REJECTED`
- `VAULT_ATTESTATION_SUCCEEDED`
- `VAULT_ATTESTATION_FAILED`
- `MPC_SIGN_REJECTED`
- `MPC_UNSUPPORTED_MODE_REJECTED`

Validation:

- `git diff --check`
- focused audit event/sanitization tests

### 5. `fase-6/startup: add fast backend diagnostics`

Goal:

- add a fast diagnostic path for startup/config failures;
- check profiles, required env vars, Flyway safety, datasource, Redis, Vault, MPC, LND, and KFE-only assumptions;
- output clear OK/WARN/FAIL results.

Do not run:

- `scripts/start-local.sh`

Validation:

- `git diff --check`
- run the diagnostic only

### 6. `fase-6/kfe: add financial invariant tests`

Goal:

- add KFE invariant tests around idempotency, outbox, inbound settlement, terminal states, PSBT, payment requests, and archived wallets.

Required invariants:

- idempotency is reserved before external provider calls;
- payload mismatch does not execute a provider;
- duplicate settlement does not alter balance twice;
- duplicate failure does not release reserve twice;
- duplicate inbound proof does not credit twice;
- outbox retry does not call provider if transaction is terminal;
- terminal states do not regress;
- expired payment requests cannot be paid;
- archived wallets reject sensitive operations.

Validation:

- `git diff --check`
- focused KFE tests

### 7. `fase-6/kfe-transaction: clean submit transaction use case`

Goal:

- refactor only the KFE transaction submission path;
- keep controller thin;
- keep business rules in use case/application layer;
- document public/complex methods;
- preserve KFE-only behavior and invariants.

Validation:

- `git diff --check`
- focused transaction tests

### 8. `fase-6/frontend: align financial api client to kfe only`

Goal:

- ensure frontend financial calls use `/kfe/**` or `/api/admin/kfe/**`;
- remove legacy ledger/wallet/transaction aliases where unused;
- align frontend DTOs/payloads with backend KFE DTOs;
- improve user-facing error handling and trace/correlation display.

Validation:

- `flutter analyze`
- focused Flutter tests

### 9. `fase-6/observability: propagate trace ids between app and backend`

Goal:

- backend accepts/generates correlation IDs and returns traceId on errors;
- frontend sends correlationId per request and surfaces backend traceId in dev/admin error views;
- logs and audit events include traceId.

Validation:

- `git diff --check`
- focused backend tests
- focused frontend tests where applicable

### 10. `fase-6/docs: update developer troubleshooting guide`

Goal:

- document how to use logs, audit events, traceId, startup diagnostics, and KFE-only verification;
- include a fast debugging flow for container crashes without running all containers blindly.

Allowed output:

- `docs/backend/TROUBLESHOOTING.md`

Validation:

- `git diff --check`

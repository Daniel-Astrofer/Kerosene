# Kerosene - Limitations

## Purpose

This file lists the material limitations, incomplete areas and code/documentation mismatches that still exist after reconciliation.

These points are not editorial caveats. They are engineering constraints that should influence implementation, review, testing and audit conclusions.

## 1. Onboarding and Activation Mismatch

Current backend truth:

- signup finalization creates an active user immediately

Current frontend legacy behavior:

- still models activation deposit requirement
- still polls activation status
- still attempts activation payment confirmation

Impact:

- onboarding documentation that describes activation-by-deposit as mandatory is now wrong
- frontend UX may still surface obsolete states

## 2. Voucher Flow Is Not Operational

Present in code:

- voucher entity
- voucher-related services and adapters

Not present in active API:

- public `/voucher/**` controller surface

Additional evidence:

- code logs explicitly state that voucher flow is disabled

Impact:

- voucher onboarding must be treated as legacy/dead code until reintroduced through controllers and tests

## 3. Advanced Security Modes Are Inconsistent

Present in model:

- `SHAMIR`
- `MULTISIG_2FA`

Runtime constraint:

- `account.security.advanced-modes-enabled=false` blocks advanced profile updates by default

Impact:

- the repository models stronger custody modes than the currently enabled user-facing configuration path

## 4. MPC Threshold Crypto Is Not Wired

Observed in code:

- sidecar `Keygen` returns not-wired error
- sidecar `Sign` returns not-wired error
- Java client rejects placeholder results

Impact:

- threshold signing/keygen cannot be presented as operational
- any documentation implying live MPC custody would be inaccurate

## 5. Vault Attestation Is Simulated

Observed in code:

- `TpmAttestationService` accepts any quote that does not contain `tampered`

Impact:

- remote attestation is architectural intent, not production-grade assurance

## 6. `/audit/trigger` Is Effectively Unreachable

Observed in code:

- endpoint requires `hasRole('ADMIN')`
- JWT HTTP auth currently grants only `USER`

Impact:

- manual merkle trigger path cannot be relied on operationally without additional auth plumbing

## 7. Frontend Still Calls Removed or Legacy Endpoints

Observed in frontend:

- `transaction_remote_datasource.dart` still calls:
  - `/transactions/confirm-deposit`
  - `/transactions/deposits`
  - `/transactions/deposit-balance`
  - `/transactions/deposit/{txid}`
- `admin_data_service.dart` still calls `/transactions/deposits`

Impact:

- parts of frontend data access are stale
- these routes must not be treated as canonical backend contract

## 8. Protected Sovereignty Calls Are Missing Required Header in Frontend

Observed in frontend:

- `security_remote_datasource.dart` calls `POST /sovereignty/reattest`
- `security_remote_datasource.dart` calls `POST /sovereignty/telemetry`
- no `X-Admin-Token` is attached

Observed in backend:

- telemetry is exposed as `GET /sovereignty/telemetry`

Impact:

- these features will fail against correctly secured environments because of both missing admin header and HTTP method mismatch

## 9. Web Admin Does Not Bootstrap Realtime

Observed in frontend:

- mobile app mounts realtime bootstrap
- web admin does not

Impact:

- notifications and balance deltas are not live by default in web operations

## 10. API Envelope Is Mixed

Observed in backend:

- some endpoints return `ApiResponse<T>`
- others return raw DTOs, lists, maps or HTML

Observed in frontend:

- only `/audit` is globally declared as raw in response interceptor
- additional raw endpoints are handled ad hoc

Impact:

- client implementations must not assume a uniform envelope

## 11. Security Status Simplifies Protection Level Incorrectly

Observed in code:

- `AccountSecurityStatusService` sets `unprotected = !totpEnabled`

Impact:

- passkey-only accounts may be labeled in an oversimplified way
- this field should not be treated as a complete risk classification

## 12. Android Release Packaging Is Not Production-Grade

Observed in Android config:

- release build signs with debug signing config
- manifest enables `usesCleartextTraffic=true`

Impact:

- current APK configuration is not suitable to describe as hardened production mobile packaging

## 13. Lightning and BTCPay Are Disabled By Default

Observed in config:

- `lightning.lnd.enabled=false`
- `btcpay.enabled=false`

Impact:

- API routes exist, but operational availability is configuration dependent

## 14. Admin Surface Is Partially Placeholder

Observed in frontend:

- admin settings screen is marked as placeholder

Impact:

- the web console is not uniformly mature across all modules

## 15. Legacy Config Values Still Exist Beside New Behavior

Examples:

- static `bitcoin.deposit-address` remains in config
- stale frontend endpoint constants remain in `AppConfig`
- signup state still carries old payment-related fields

Impact:

- static config presence does not automatically imply active runtime behavior

## 16. Local Compose Is Canonical For Dev, Not Proof Of Production

Observed in infrastructure:

- three shards are simulated on one machine
- local compose disables solvency enforcement
- Vault and MPC limitations still apply

Impact:

- successful local startup is not equivalent to validated production readiness

## 17. Realtime Notification Model Has Legacy Compatibility Paths

Observed in backend:

- `NotificationService` still supports `legacy(title, body)` creation

Observed in frontend:

- modern code expects structured kind/severity/entity metadata

Impact:

- the structured notification payload is canonical, but legacy creation still exists and can reintroduce weaker semantics

## 18. Validation Scope Of This Documentation Pass

Validated:

- source code
- controller surfaces
- filters
- configs
- compose/runtime scripts
- backend compilation
- APK artifact metadata

Not fully validated end-to-end in this pass:

- complete multi-shard distributed behavior
- live reserve correctness against real Bitcoin/Lightning infrastructure
- real Vault attestation with hardware TPM
- real threshold signing through MPC sidecars
- full frontend functional regression test matrix

## Bottom Line

The repository already contains a serious distributed-financial design, but it is not a uniformly production-complete system across every subsystem.

The most reliable, current, code-backed surfaces are:

- core auth
- passkeys
- wallet and ledger flows
- payment links
- reserve overview
- mobile realtime notifications

The least reliable or most legacy-loaded surfaces are:

- activation deposit onboarding
- voucher onboarding
- MPC-backed advanced custody
- production-grade attestation claims
- stale frontend deposit endpoints

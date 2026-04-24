# Kerosene - Overview

## Status

This documentation is the canonical, code-first description of the current Kerosene repository state as validated on 2026-04-23.

Primary verification sources:

- `docs/API_REFERENCE.md`
- `docs/ARCHITECTURE.md`
- `docs/INFRASTRUCTURE.md`
- `docs/FEATURES_AND_STATES.md`
- `docs/FRONTEND_NOTIFICATION_SYSTEM.md`
- `docs/KEROSENE_MASTER_REFERENCE.md`
- `docs/README.md`
- `docs/APK.md`
- `backend/kerosene/src/main/java/**`
- `backend/kerosene/src/main/resources/**`
- `backend/kerosene-infrastructure/**`
- `backend/vault/**`
- `backend/mpc-sidecar/**`
- `frontend/**`

Where documentation and code diverged, code was treated as the source of truth.

## System Definition

Kerosene is a distributed Bitcoin-centric financial platform with:

- Spring Boot backend shards
- Flutter mobile client
- Flutter web admin console
- Tor hidden-service exposure
- a dedicated Vault service for AES master-key provisioning
- a Go MPC sidecar intended for threshold cryptography
- Postgres and Redis per shard
- internal ledger, wallet, payment-link, mining, treasury and audit subsystems
- optional external integrations for BTCPay and Lightning

At runtime, the system exposes two financial planes:

- internal money movement inside the platform ledger
- external Bitcoin and Lightning transfers tracked as network transfers

## Canonical Runtime Topology

The current canonical local topology is `backend/kerosene-infrastructure/docker-compose.local.yml`.

It simulates:

- `kerosene-vault`
- three regional application shards: `IS`, `CH`, `SG`
- one Postgres and one Redis instance per region
- one Tor daemon and one Vanguards sidecar per region
- one MPC sidecar per region
- shard identity volumes and Vault onion publication

Host ports exposed by the local cluster:

- `8080 -> kerosene-app-is`
- `8081 -> kerosene-app-ch`
- `8082 -> kerosene-app-sg`

The architecture documentation in older files still describes a production-style distributed deployment. That is directionally useful, but the compose file above is the practical reference for the repository as it stands.

## What The System Actually Does Today

### Confirmed backend domains

- authentication and onboarding
- TOTP, backup codes, passkeys and emergency recovery
- device-scoped app PIN
- wallet creation and wallet card lifecycle
- internal ledger transfers and internal payment requests
- on-chain address issuance, payment links and external transfer tracking
- Lightning invoice/payment APIs
- treasury reserve overview and solvency/audit surfaces
- realtime balance and notification delivery over STOMP/WebSocket
- mining rig rental and allocation lifecycle

### Confirmed platform properties

- Java 21 backend
- Spring Boot 3.3.2
- JWT-based stateless auth for HTTP
- STOMP native-header auth for WebSocket `CONNECT`
- default Bitcoin network: `testnet`
- default minimum confirmations: `3`
- payment-link expiry default: `60` minutes
- explicit CORS allowlist only; wildcard CORS is rejected

## Canonical Corrections Versus Legacy Documentation

The following points are resolved here in favor of code:

1. Signup finalization creates an active user immediately.
   `FinalizeSignupAccount` sets `isActive=true` and `activatedAt=now`.

2. Activation-by-deposit is legacy, not canonical.
   `AccountActivationService.confirm(...)` now throws and does not drive the real onboarding path.

3. Voucher onboarding is effectively disabled.
   Voucher entities and helper services still exist, but there is no active public `/voucher/**` controller.

4. The deposit address endpoint is no longer just a static config echo.
   `GET /transactions/deposit-address` now issues a dedicated on-chain allocation for the primary wallet.

5. Advanced account-security modes are modeled but disabled by default.
   `account.security.advanced-modes-enabled=false` blocks runtime profile updates for `SHAMIR` and `MULTISIG_2FA`.

6. MPC/TSS is not operational end-to-end.
   The sidecar returns explicit "not wired" errors for threshold keygen and signing.

7. Web realtime is not bootstrapped by default.
   The mobile app mounts realtime bootstrap; the web admin app currently does not.

## Repository Map

| Path | Responsibility |
| --- | --- |
| `backend/kerosene` | Main Spring Boot application |
| `backend/kerosene-infrastructure` | Docker images, compose files, init scripts |
| `backend/vault` | Vault service for arming, attestation and key provisioning |
| `backend/mpc-sidecar` | Go gRPC sidecar for future threshold crypto |
| `frontend` | Flutter mobile app and Flutter web admin |
| `docs` | Legacy and partially outdated documentation set |
| `docs-final` | This reconciled documentation set |

## Validation Performed

The following validations were completed in this workspace:

- backend `compileJava`: success
- backend `compileTestJava`: success
- static inspection of controllers, services, DTOs, filters, configs and compose/runtime scripts
- APK artifact validation at `frontend/build/app/outputs/flutter-apk/app-release.apk`

Current APK facts from the built artifact:

- application id: `com.teste.kersosene`
- version: `1.0.0 (1)`
- SHA-256: `6934f0e6a1f7298a4910f4d8cdf2a399b06b18b7e5c71a436f57a823ca499d74`

## Document Map

- `01-overview.md`: scope, methodology, canonical corrections
- `02-architecture.md`: topology, trust boundaries, startup and data flows
- `03-backend.md`: backend modules, services and operational defaults
- `04-api.md`: HTTP and WebSocket contract inventory
- `05-frontend.md`: mobile/web structure, runtime behavior and gaps
- `06-security.md`: auth, hardening controls and security limitations
- `07-infrastructure.md`: compose topology, networks, volumes and scripts
- `08-payments.md`: internal transfers, external transfers, payment links and fees
- `09-realtime-notifications.md`: STOMP channels, payloads and frontend consumers
- `10-state-machine.md`: canonical system states and transitions
- `11-treasury.md`: reserves, solvency, liquidity and audit chain
- `12-limitations.md`: non-operational, inconsistent or incomplete areas

## Intended Readers

This set is written to be directly usable by:

- backend engineers
- frontend engineers
- infrastructure engineers
- auditors
- security reviewers
- AI agents operating over the repository

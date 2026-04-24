# Kerosene - Architecture

## Architectural Summary

Kerosene is architected as a multi-node financial platform that tries to separate:

- user-facing application logic
- secrecy of long-lived key material
- onion-routed network exposure
- treasury and solvency verification
- optional threshold-signing infrastructure

The codebase models a stronger production design than the currently operational implementation. This document distinguishes between architectural intent and what is actually wired.

## Logical Topology

```text
Flutter Mobile
  -> local Tor bootstrap + local relay
  -> shard onion endpoint

Flutter Web Admin
  -> direct resolved origin / onion gateway / same-origin
  -> shard HTTP + STOMP endpoint

Regional Shard (IS / CH / SG)
  -> Spring Boot app
  -> Postgres (regional)
  -> Redis (regional)
  -> Tor hidden service
  -> Vanguards hardening sidecar
  -> MPC sidecar (planned threshold crypto)
  -> Vault provisioning client
  -> Bitcoin / Lightning / BTCPay integrations

Vault
  -> armed by 2-of-3 director approvals
  -> attests shard hardware
  -> provisions AES master key
```

## Runtime Units

### 1. Regional application shard

Each regional shard is the same Spring Boot application with region-specific environment:

- `REGION=IS|CH|SG`
- regional Postgres DSN
- regional Redis host
- regional Tor sockets and control data
- regional shard identity path
- region-local MPC sidecar host

The shard owns business APIs:

- auth
- wallets
- ledger
- transactions
- treasury
- notifications
- mining
- sovereignty status

### 2. Vault

The Vault service is a separate Java service with three critical endpoints:

- `POST /v1/vault/arm`
- `POST /v1/vault/attest`
- `GET /v1/vault/provision`

It is responsible for:

- receiving the AES master key only after quorum arming
- storing that key in off-heap locked memory
- issuing ephemeral provisioning tokens after attestation
- handing the master key to attested nodes

### 3. Tor and onion exposure

Each shard exposes its application through a Tor hidden service. In the local topology:

- the shard app runs on `10.241.0.10:8080`, `10.241.0.11:8080`, `10.241.0.12:8080`
- the Tor daemon maps hidden-service port `80` to the local shard address
- the app container consumes Tor socks/control artifacts through mounted volumes

`vanguards` is also present per region and attached to the Tor control socket/state volumes.

### 4. MPC sidecar

The repository includes one sidecar per region. It is supposed to back threshold cryptography, but at present:

- `Keygen` returns `threshold keygen is not wired to a round-based TSS coordinator yet`
- `Sign` returns `threshold signing is not wired to a round-based TSS coordinator yet`

The sidecar should therefore be treated as an architectural stub, not as an operational security control.

## Trust Boundaries

### Boundary A: client to shard

Controls in this boundary:

- JWT bearer auth for HTTP
- STOMP `Authorization` native header for WebSocket
- CORS explicit origin allowlist
- `ParanoidSecurityFilter`
- `RateLimitFilter`

### Boundary B: shard to Vault

Controls in this boundary:

- Vault bootstrap/provisioning flow
- attestation token exchange
- Vault master key not persisted in the shard config when `vault.enabled=true`

### Boundary C: shard to regional storage

Controls in this boundary:

- per-region Postgres
- per-region Redis
- encrypted string persistence through `StringCryptoConverter` in multiple entities

### Boundary D: shard to Bitcoin / Lightning / BTCPay

Controls and caveats:

- network payment abstractions exist
- BTCPay is optional and off by default
- Lightning is optional and off by default
- some external provider operations are partial or configuration-gated

## Startup and Provisioning Sequence

The local startup path is:

1. `scripts/start-local.sh`
2. infrastructure init via `backend/kerosene-infrastructure/scripts/init-local.sh`
3. certificate generation and Tor config rewrite if needed
4. Docker compose up for Vault, Tor, app shards, DBs, Redis and sidecars
5. DB migration script
6. Vault arming via `scripts/arm-vault.sh`
7. shard startup waits for Vault provisioning
8. script prints cluster readiness and onion endpoints

Required `.env` material validated by init scripts:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `PASSWORD_PEPPER`
- `FOUNDER_TOTP_SECRET`
- `AES_SECRET`

## Architectural Data Flows

## Signup and account creation

Current canonical flow:

1. client gets PoW challenge
2. client calls signup
3. optional TOTP setup and verification
4. passkey onboarding start
5. passkey onboarding finish
6. backend finalizes user, creates wallet/ledger if missing, and returns authenticated token material

Important consequence:

- account activation happens during signup finalization, not through a later deposit-link confirmation flow

## HTTP authentication

1. client sends `Authorization: Bearer <jwt>`
2. `JwtAuthenticationFilter` extracts user id
3. security context receives principal with role `USER`
4. if token is near expiry, response includes `X-New-Token`

## WebSocket authentication

1. HTTP upgrade is allowed on `/ws/**`
2. STOMP `CONNECT` must carry native header `Authorization`
3. JWT is validated in `ConnectAuthenticationStompMessageHandler`
4. user is bound to `/user/queue/*` destinations

## External on-chain receive

1. user asks for deposit address
2. backend allocates an address through `ExternalPaymentsService`
3. a transfer/watch record is created
4. monitors detect mempool/confirmed activity
5. settlement and notification update platform state

## Internal ledger transfer

1. user calls `POST /ledger/transaction`
2. ownership and transactional factors are validated
3. ledger services persist the debit/credit
4. balance update and notification are emitted

## Treasury overview

1. `ReserveBalanceService.captureSnapshot()` gathers reserves
2. Lightning balances are queried
3. reserved outbound transfers are deducted
4. liquidity state is derived
5. `GET /treasury/overview` returns the synthesized view

## Realtime notification dispatch

1. domain code persists `NotificationEntity`
2. `NotificationPersistenceService` publishes `NotificationPersistedEvent`
3. `NotificationDispatchAfterCommitListener` sends payload to `/user/queue/notifications`

## Architecture Reality Checks

### What is operational

- shard apps
- Vault arming/provision request flow
- Tor hidden-service exposure
- Postgres and Redis regional split
- wallet, ledger, transfer, treasury and notification domains
- mobile Tor bootstrap

### What is modeled but incomplete

- TPM attestation is simulated
- MPC threshold operations are not wired
- some cross-shard/quorum services exist in code but were not validated as a full distributed consensus implementation in this review

## Security-Sensitive Architectural Facts

- `VaultMemoryLocker` uses off-heap direct memory plus `mlock`
- Vault arming requires any 2 of 3 valid directors: `director-1`, `director-2`, `director-3`
- shard boot can fallback to configured AES only when `vault.enabled=false`
- local compose runs with `VAULT_ENABLED=true`
- local compose sets `AUDIT_SOLVENCY_ENFORCED=false`

## Architectural Gaps

1. Remote attestation is not production-grade.
   `TpmAttestationService` accepts anything unless the quote contains the word `tampered`.

2. Threshold custody is not live.
   The Go sidecar and Java client both refuse to return fake signatures, so advanced threshold flows cannot complete end-to-end.

3. Old documentation overstates activation-via-deposit.
   Current onboarding does not rely on it.

4. Web and mobile do not share the same network entry model.
   Mobile is Tor-native; web is origin/gateway-native.

5. The older `backend/kerosene/docker-compose.yml` should not be treated as the canonical local runtime.

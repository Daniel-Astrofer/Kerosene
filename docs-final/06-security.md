# Kerosene - Security

## Security Posture Summary

Kerosene combines several defensive layers:

- stateless JWT auth
- passkeys, TOTP, backup codes and emergency recovery
- device-scoped app PIN
- request hardening and header sanitization
- Tor hidden-service exposure
- Vault-backed key provisioning
- encrypted persistence for selected fields
- treasury reserve checks and audit surfaces

The repository also contains several incomplete or simulated controls. Those are listed explicitly below and again in `12-limitations.md`.

## Authentication Layers

## HTTP JWT

Current properties:

- only `Authorization: Bearer <jwt>` is accepted
- query-param JWT support was intentionally removed
- JWT renewal uses `X-New-Token`

The HTTP security context currently grants a single authority:

- `USER`

This matters because endpoints annotated for `ADMIN` are not reachable through ordinary JWT auth unless another auth mechanism injects that role.

## STOMP/WebSocket auth

`/ws/**` is permitted at HTTP filter level so the upgrade can happen, but actual auth occurs during STOMP `CONNECT`.

Required STOMP native header:

- `Authorization: Bearer <jwt>`

If missing or invalid, `CONNECT` is rejected.

## Multi-factor model

### Available factors

- passphrase
- TOTP
- passkey
- backup codes
- device-scoped app PIN

### Transactional factor matrix

| Account security mode | Required factors for transaction authorization |
| --- | --- |
| `STANDARD` | Passkey |
| `PASSKEY` | Passkey |
| `SHAMIR` | Passphrase + TOTP, plus platform co-signing when scope requires |
| `MULTISIG_2FA` | Passphrase + TOTP, plus passkey when threshold `>= 3` |

If passkey is required but not presented, the backend emits a structured `PRECONDITION_REQUIRED` error with a fresh passkey challenge.

## Passkeys

Passkey-specific controls include:

- relying-party and origin matching
- compatibility checks for current login host
- signature-counter replay detection
- structured remediation payloads when assertion fails

`PasskeyInventoryDTO` currently exposes:

- whether a passkey is registered
- whether current login is compatible
- presence of legacy credentials
- current relying-party id
- current host
- registered device inventory

## TOTP and recovery

TOTP is used for:

- optional signup hardening
- login continuation when required
- advanced transaction authorization
- app PIN reset flows
- emergency recovery
- owner-level audit siphon flow

Backup codes are first-class and can be regenerated.

Emergency recovery has public endpoints but still requires controlled proof material and rate-limited flow execution.

## App PIN

App PIN is a frontend-facing local access gate backed by the server.

Current backend facts:

- device-scoped semantics
- optional `X-Device-Hash`
- min length `4`
- max length `8`
- max attempts `5`
- lockout `5` minutes

`AppPinStatusDTO` exposes:

- enabled/configured/locked
- failed attempts and remaining attempts
- min/max pin length
- whether TOTP can reset it
- device-scoped flag
- lock timestamps

## Request Hardening

## Rate limiting

`RateLimitFilter` buckets requests using:

- `Authorization`
- `X-Idempotency-Key`
- `Digest`
- selected JSON body identity fields
- network fallback

Current limits:

- general `100/min`
- `/auth/**` `20/min`
- financial user-level limit `3/min` for selected ledger writes

## ParanoidSecurityFilter

This filter enforces:

- only `application/json` or `application/x-protobuf` for requests with body
- max request body `2048` bytes
- stripping of `X-Forwarded-For`, `Via`, `User-Agent`
- `X-Content-Type-Options: nosniff`
- HSTS
- suppression of `Server`, `X-Powered-By`, `Date`
- random `X-Pad-Noise` response header

Optional constant-time padding:

- disabled by default in docker profile
- only applies to `/auth/` and `/ledger/` paths when enabled

## Digest handling

If a client sends:

- `Digest: SHA-256=<base64>`

then the backend recomputes the body hash after the request chain.

Important consequence:

- digest mismatch does not simply return a validation error
- it calls `SuicideService.triggerInstantSuicide(...)`

This is a high-consequence path and must be treated as such by any client generating `Digest`.

## Data Protection

## Vault-backed key material

When `vault.enabled=true`, startup requires Vault provisioning.

Vault properties:

- arming requires 2 of 3 valid directors
- key is stored in locked off-heap memory by `VaultMemoryLocker`
- provisioning is one-time token based

## Persistence encryption

Selected entity fields use `StringCryptoConverter`, including multiple sensitive values such as:

- wallet XPUBs
- wallet deposit secrets
- external destinations
- invoice payloads

## Tor exposure

The intended public exposure plane is onion-based.

In local compose:

- application shards sit behind regional Tor daemons
- only Tor daemons attach to the `tor_egress` network
- mobile app is Tor-native

## Sovereignty and attestation

The codebase contains:

- sovereignty status endpoint
- manual re-attestation endpoint
- telemetry endpoint
- shard heartbeat path in Vault
- TPM attestation service

Security caveat:

- Vault TPM attestation is simulated, not production-grade

`TpmAttestationService` currently returns success for any quote that does not contain the word `tampered`.

## Security Inconsistencies and Risks

1. `AccountSecurityStatusService` marks `unprotected = !totpEnabled`.
   This under-describes passkey-only protection and is not a reliable whole-account risk signal.

2. Advanced security modes are represented in model and signup state, but blocked by default in runtime profile updates.

3. `/audit/trigger` requires `ROLE_ADMIN`, but current JWT auth only grants `USER`.

4. The web frontend does not add `X-Admin-Token` for protected sovereignty endpoints.

5. The frontend telemetry call is method-mismatched.
   The client posts to telemetry while the backend exposes `GET /sovereignty/telemetry`.

6. Android release builds currently use debug signing config.

7. Android manifest enables cleartext traffic.

8. Web admin currently lacks live WebSocket bootstrap, reducing security-relevant situational awareness for operations.

## Security Controls That Are Present But Not Sufficient Alone

The following should not be overstated in audits:

- TPM attestation
- MPC threshold custody
- admin-only merkle trigger route
- frontend activation-deposit gating

They exist in some form, but they do not currently amount to complete production-grade control planes.

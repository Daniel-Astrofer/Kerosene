# Kerosene - Backend

## Stack

- Java 21
- Spring Boot 3.3.2
- Spring Security
- Spring WebSocket/STOMP
- JPA/Hibernate
- PostgreSQL
- Redis
- Gradle

Validation completed on this repository state:

- `./gradlew compileJava --no-daemon`: success
- `./gradlew compileTestJava --no-daemon`: success

## Module Layout

| Package area | Responsibility |
| --- | --- |
| `source.auth` | signup, login, TOTP, passkeys, recovery, account security, app PIN |
| `source.wallet` | wallet model, wallet creation/update, wallet card profile/lifecycle |
| `source.ledger` | internal balances, internal transfers, payment requests, history, audits |
| `source.transactions` | on-chain, Lightning, payment links, external transfers, deposits, BTCPay |
| `source.treasury` | reserve capture, solvency, revenue collection, treasury overview |
| `source.notification` | persistence and realtime notification dispatch |
| `source.mining` | rig catalog and allocation lifecycle |
| `source.security` | sovereignty, suicide, attestation clients, shard identity, telemetry |
| `source.common` | root status and shared utilities |
| `source.config` | HTTP security, WebSocket config, transport setup |

## Backend Contract Model

The backend is not uniform in response shape.

### Endpoints that usually return `ApiResponse<T>`

- most auth endpoints
- wallet endpoints
- ledger business endpoints
- transaction business endpoints

### Endpoints that return raw maps, DTOs or primitives

- `/`
- `/healthz`
- `/notifications`
- `/treasury/overview`
- `/v1/audit/**`
- `/audit/**`
- `/sovereignty/**`
- some economy/onramp endpoints

Frontend code already contains special handling for this mixed envelope model.

## Core Business Domains

## Authentication and identity

Main controllers:

- `UserController`
- `PasskeyController`
- `MeController`
- `TotpController`
- `BackupCodesController`
- `EmergencyRecoveryController`
- `AccountSecurityController`
- `AccountSecurityStatusController`
- `AppPinController`
- `AccountActivationController`

Key facts:

- PoW is required for signup
- login can return direct JWT or a pre-auth token for TOTP continuation
- passkey login and passkey onboarding are active
- emergency recovery is public but rate-limited and challenge-driven
- app PIN is device-scoped and keyed by optional `X-Device-Hash`

## Signup reality

Canonical signup finalization occurs in `FinalizeSignupAccount`.

Effects of finalization:

- creates or resolves the user
- persists passkey credential if needed
- sets `isActive=true`
- sets `activatedAt=now`
- applies `accountSecurity`
- generates platform cosigner secret for advanced modes when applicable
- creates primary wallet if missing
- heals missing ledger if wallet already exists
- sends `account_created` notification after commit

This is the most important backend truth for onboarding documentation.

## Account security modes

Mode model:

- `STANDARD`
- `PASSKEY`
- `SHAMIR`
- `MULTISIG_2FA`

Current reality:

- `STANDARD` and `PASSKEY` both require passkey for transactional authorization
- `SHAMIR` requires passphrase plus TOTP, and platform co-signing when scope requires
- `MULTISIG_2FA` requires passphrase plus TOTP, and passkey when threshold `>= 3`

Runtime caveat:

- advanced profile updates are blocked by default because `account.security.advanced-modes-enabled=false`

## Wallet subsystem

Wallet facts:

- wallet modes: `KEROSENE`, `SELF_CUSTODY`
- self-custody wallets require XPUB validation
- XPUB is only allowed in `SELF_CUSTODY`
- wallet names are uppercased by the entity setter

Wallet response model includes:

- wallet identity and timestamps
- `walletMode`
- `xpubConfigured`
- wallet-card type and rotation status
- card number suffixes and expiry fields
- profile-based fee rates

Security fact:

- the response DTO still has a `passphraseHash` field, but the assembler forces it to `null`

## Wallet card lifecycle

Wallet cards are synthesized from:

- `WalletCardLifecycleService`
- `WalletCardProfileService`

Current card rotation statuses:

- `ACTIVE`
- `ROTATING`
- `EXPIRING`

Current profile types:

- `BRONZE`
- `WHITE`
- `BLACK`

Default profile thresholds:

- minimum account age for card profile logic: 6 months
- `WHITE` monthly movement over `1500`
- `BLACK` monthly movement over `3000`

Default card-linked fee rates:

- bronze: `0.009`
- white: `0.008`
- black: `0.007`

## Ledger subsystem

Main responsibilities:

- internal wallet balances
- internal transfer history
- internal payment requests
- ledger integrity helpers
- merkle/audit surfaces

Important runtime facts:

- `GET /ledger/history` caps `size` at `100`
- per-user financial rate limiting in `LedgerController` is `3` requests per minute, even though an inline comment still says `10`
- internal payment request statuses are currently `PENDING`, `PAID`, `EXPIRED`

## Transactions subsystem

The transactions domain handles:

- deposit-address issuance
- unsigned tx generation
- broadcast
- payment links
- external on-chain transfers
- Lightning invoices and pays
- transfer cancellation
- onramp URL discovery

Important runtime facts:

- `GET /transactions/deposit-address` now issues a dedicated address allocation for the primary wallet
- `bitcoin.deposit-address` remains in config but is no longer the canonical deposit-address API behavior
- default `bitcoin.min-confirmations=3`
- default payment-link expiration is `60` minutes

## Treasury and audit subsystem

Main responsibilities:

- reserve snapshot capture
- liquidity state evaluation
- financial audit chain
- revenue collection chain
- merkle transparency surfaces

Current treasury overview output:

- total on-chain reserve
- Lightning node reserve
- inbound/outbound liquidity
- reserved and available balances
- `lightningSendsAllowed`
- liquidity state

Self-custody note:

- self-custody XPUB balances are monitored but intentionally excluded from platform treasury totals

## Notification subsystem

Notifications are persisted in `public.notifications` and then fanned out over WebSocket after DB commit.

Persisted fields include:

- `userId`
- `kind`
- `severity`
- `title`
- `body`
- optional `deeplink`
- optional `entityType`
- optional `entityId`
- `read`
- `createdAt`

## Mining subsystem

Mining covers:

- rig listing
- allocation creation
- allocation lookup
- allocation cancelation

Current allocation statuses:

- `ACTIVE`
- `COMPLETED`
- `CANCELLED`

## Operational Defaults

From `application.properties` and `application-docker.properties`, notable defaults are:

- `spring.jpa.hibernate.ddl-auto=validate`
- local Postgres at `localhost:5432`
- local Redis at `127.0.0.1:6379`
- `bitcoin.network=testnet`
- `vault.enabled=false` in base config, but enabled in docker/local cluster
- `mpc.sidecar.tls.enabled=true` in base config
- `btcpay.enabled=false`
- `lightning.lnd.enabled=false`
- app PIN min length `4`, max `8`
- app PIN max attempts `5`
- app PIN lockout `5` minutes
- wallet card validity `24` months
- card expiring-soon window `14` days
- `transactions.external.fee-rate=0.009` in docker profile

## Backend Realities That Must Not Be Misdocumented

1. Activation deposit flow is not the canonical account-creation flow anymore.

2. `/voucher/**` is not an active public API surface.

3. Advanced security modes exist in the model but are not broadly enabled in runtime profile management.

4. Treasury and audit outputs are not hardcoded examples; they are generated from live service calls.

5. WebSocket auth is not inherited from the HTTP upgrade request alone; STOMP `CONNECT` auth matters.

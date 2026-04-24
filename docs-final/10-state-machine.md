# Kerosene - State Machine

## Scope

This document records the operational states that are actually present in the codebase. It intentionally distinguishes between:

- canonical active states
- legacy states still present in code
- unreachable or partially wired transitions

## 1. Signup and Authentication

## Backend signup session (`SignupState`)

Temporary signup state contains:

- `sessionId`
- `username`
- hashed `passphrase`
- `totpSecret`
- flags `isTotpVerified`, `isPasskeyRegistered`, `isPaymentConfirmed`
- optional `btcDepositAddress`
- passkey material
- backup codes
- chosen `accountSecurity`
- optional advanced-mode parameters

Canonical transition path today:

1. signup created
2. optional TOTP verified or skipped
3. passkey registered
4. `FinalizeSignupAccount.execute(sessionId)`
5. user persisted with `isActive=true`
6. signup state deleted after commit

Legacy artifacts still present in state:

- `isPaymentConfirmed`
- `btcDepositAddress`

These fields reflect older onboarding ideas and are not the canonical activation path anymore.

## Frontend auth states

| State | Meaning |
| --- | --- |
| `AuthInitial` | Startup / unknown session |
| `AuthLoading` | Network or auth transition in progress |
| `AuthAuthenticated` | Logged-in user loaded |
| `AuthUnauthenticated` | No valid session |
| `AuthError` | Auth failure |
| `AuthRequiresTotpSetup` | Signup waiting for TOTP verification/skip |
| `AuthTotpVerified` | Signup TOTP stage completed |
| `AuthRequiresLoginTotp` | Login waiting for TOTP completion |
| `AuthPaymentRequired` | Legacy activation-deposit UI state |
| `AuthServerUnavailable` | Stored session exists but backend unavailable |

Canonical frontend path should now be:

1. signup
2. optional TOTP setup
3. passkey onboarding
4. authenticated session

But current frontend still supports:

- activation deposit polling
- activation deposit confirmation attempts

## 2. Account Security Modes

Canonical account security modes:

- `STANDARD`
- `SHAMIR`
- `MULTISIG_2FA`
- `PASSKEY`

Transaction-authorization transitions:

- `STANDARD -> passkey challenge required`
- `PASSKEY -> passkey challenge required`
- `SHAMIR -> passphrase + TOTP required`
- `MULTISIG_2FA -> passphrase + TOTP required`, plus passkey when threshold `>= 3`

Runtime caveat:

- profile updates for advanced modes are blocked by default, even though signup state can still carry those choices

## 3. Account Activation

Canonical user activation states in backend:

- inactive user
- active user

Current canonical transition:

- signup finalization sets the user active immediately

Legacy activation DTO still exposes:

- `activated`
- `canReceiveInbound`
- `requiresActivationDeposit`
- `paymentLinkId`
- `depositAddress`
- `paymentStatus`

But `AccountActivationService.confirm(...)` now throws instead of completing the legacy flow.

## 4. Passkeys

Passkey operational states:

- no passkey registered
- passkey registered but incompatible with current host/rp id
- passkey registered and compatible
- assertion rejected
- replay detected
- challenge required/refreshed
- assertion accepted

Replay protection trigger:

- signature counter must advance; otherwise the credential is rejected

## 5. App PIN

Current server-visible app PIN states:

- enabled/disabled
- configured/unconfigured
- locked/unlocked
- device-scoped
- resettable with TOTP or not

Derived lock progression:

1. failed attempts increment
2. remaining attempts decrease
3. account enters locked state after maximum attempts
4. lock expires after configured lockout window or recovery flow

## 6. Wallet and Card Lifecycle

## Wallet mode

- `KEROSENE`
- `SELF_CUSTODY`

## Wallet card profile type

- `BRONZE`
- `WHITE`
- `BLACK`

## Wallet card rotation status

- `ACTIVE`
- `ROTATING`
- `EXPIRING`

Card lifecycle transition model:

1. wallet missing card metadata -> initialize card snapshot
2. active card approaches expiry window -> `EXPIRING`
3. expired card is rotated -> `ROTATING`
4. new card becomes `ACTIVE`

## 7. Internal Ledger States

## Internal payment request

Observed statuses:

- `PENDING`
- `PAID`
- `EXPIRED`

Transition model:

`PENDING -> PAID`

`PENDING -> EXPIRED`

## Ledger transaction history

Observed statuses in history entities:

- `PENDING`
- `CONCLUDED`
- `CANCELED`

## Ledger-entry fee state

Observed fee-collection statuses:

- `PENDING`
- `COLLECTED`

## 8. Payment Links

Canonical statuses:

- `pending`
- `paid`
- `expired`
- `completed`
- `cancelled`
- `verifying_onboarding`
- `verifying_activation`

Canonical transitions:

- `pending -> paid`
- `pending -> expired`
- `pending -> cancelled`
- `paid -> completed`

Legacy or special transitions still present:

- `paid -> verifying_onboarding -> pending/completed`
- `paid -> verifying_activation -> completed`

These special states remain in the code because onboarding/activation helper paths still exist.

## 9. External Transfer and Monitoring States

## External transfer

Observed normalized statuses:

- `PENDING`
- `DETECTED`
- `MEMPOOL`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`
- `EXPIRED`
- `FAILED`
- `SETTLED`

Typical inbound on-chain transition:

`PENDING -> DETECTED -> CONFIRMED -> COMPLETED`

Typical Lightning/provider-normalized transition:

`PENDING -> SETTLED/PAID -> COMPLETED`

Exceptional transitions:

- `PENDING -> CANCELLED`
- `PENDING -> EXPIRED`
- `PENDING -> FAILED`

## Blockchain address watch

Observed watch statuses:

- `WATCHING`
- `DETECTED`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`

## Legacy deposit entity

Legacy `DepositEntity` still models:

- `pending`
- `confirmed`
- `credited`

This entity should not be confused with the more current network-transfer/watch pipeline.

## Pending broadcast transaction

Observed pending-transaction statuses:

- `PENDING`
- `CONFIRMED`
- `FAILED`

## 10. Mining

Mining allocation statuses:

- `ACTIVE`
- `COMPLETED`
- `CANCELLED`

Canonical transition model:

`ACTIVE -> COMPLETED`

`ACTIVE -> CANCELLED`

## 11. Notifications

Notification delivery lifecycle:

1. domain event generated
2. notification persisted with `read=false`
3. after-commit WebSocket dispatch
4. frontend stores session/local feed
5. optional mark-as-read sync to backend

Notification severities:

- `info`
- `success`
- `warning`
- `error`

## 12. Treasury and Owner Collection

## Liquidity state

Current `TreasuryOverviewDTO.liquidityState` values:

- `BLOCKED_ONCHAIN_RESERVE`
- `REBALANCE_REQUIRED`
- `HEALTHY`

## Siphon request entity

Observed statuses:

- `PENDING`
- `EXECUTED`
- `CANCELLED`

Note:

- current exposed controller path for siphon uses direct validation and fee collection; this entity exists but is not the primary exposed workflow described by the current controller

## 13. Voucher Legacy State

Voucher entity statuses:

- `PENDING`
- `PAID`
- `USED`

Current operational note:

- voucher state exists in persistence model, but public voucher flow is disabled

## Canonical State Guidance

For new engineering work, the most trustworthy state machines are:

- passkey-based signup finalization
- wallet card lifecycle
- internal payment request lifecycle
- external transfer lifecycle
- treasury liquidity state

The least trustworthy, most legacy-loaded state machines are:

- activation-deposit onboarding
- voucher onboarding
- any flow that assumes `/transactions/deposits` style endpoints are authoritative

# KFE System Treasury Wallet Design

## Context

KFE already supports `INTERNAL` wallets and resolves their label to `carteira global`, but the current behavior creates that wallet through user provisioning. That is not enough for the platform treasury requirement because the wallet is not a canonical system asset, is not bootstrapped when Kerosene starts, and is only indirectly included in reserve overview by aggregating all balances.

The approved requirement is:

- Kerosene must ensure, on startup, that exactly one global internal treasury wallet exists.
- The wallet is controlled only by Kerosene servers.
- No human user, admin session, or operator receives direct access to signing secrets.
- Spending from this wallet must go through the existing quorum/signing path.
- Treasury/reserve reporting must account for this wallet explicitly.

## Recommended Approach

Use a non-login technical principal plus an explicit treasury marker.

The wallet will keep a `user_id` because the current schema and transaction model require one, but that user will be a locked platform principal, not a normal account. The wallet itself will also be marked as a system treasury wallet, so code does not rely on a label such as `carteira global` to identify it.

Rejected alternatives:

- A wallet without `user_id` would be conceptually clean, but it would force broader schema and service changes because KFE currently binds wallets, transactions, dashboards, and idempotency to users.
- Reusing a human admin account would be unsafe because it mixes human identity with server-owned funds and makes access boundaries ambiguous.

## Data Model

Add a stable way to identify the treasury wallet:

- A locked technical principal with username `KFE_TREASURY_SYSTEM`.
- A nullable wallet column `system_role`, where normal user wallets have `NULL` and the global treasury wallet has `TREASURY`.
- A uniqueness guarantee that allows only one active treasury wallet.

The wallet should remain:

- `kind = INTERNAL`
- `asset = BTC`
- `status = ACTIVE`
- `spendable = true`
- label displayed to internal/admin tooling as `carteira global`

The marker must be the source of truth. Labels are presentation only.

## Startup Bootstrap

Add a KFE startup component that runs after the application context is ready:

1. Ensure the locked technical principal exists and cannot authenticate through normal login.
2. Look up the active system treasury wallet by marker, not by label.
3. If it exists, verify it has a BTC balance row and return.
4. If it does not exist, create one internal wallet for the technical principal.
5. Create the initial BTC balance row if missing.
6. Record audit event `KFE_SYSTEM_TREASURY_WALLET_BOOTSTRAPPED`.

The bootstrap must be idempotent. Restarting Kerosene must not create another treasury wallet.

## Quorum And Secrets

The treasury wallet signs only through server-side quorum flow:

- API callers submit an authorized treasury intent.
- KFE validates policy and locks funds.
- KFE requests quorum approval using the existing quorum gateway.
- Only server-side signer/MPC/Vault/sidecar components access signing material.
- Secrets never appear in API payloads, DTOs, logs, database rows, frontend state, or admin responses.

If quorum is unavailable, the transaction must fail closed or remain in a pending/reconciliation state. It must not fall back to a local plaintext key or human-supplied secret.

## Treasury Accounting

Reserve overview must include the system treasury wallet explicitly.

The current reserve overview can sum all balances, but the implementation should make the treasury inclusion intentional by querying or classifying the treasury wallet separately. Admin responses should be able to prove:

- total on-chain BTC
- available treasury BTC
- reserved/locked treasury BTC
- whether the treasury wallet exists and is active
- liquidity state derived from treasury balances

User dashboards and normal wallet lists must not show the system treasury wallet.

## Error Handling

Startup behavior should be fail closed:

- Missing technical principal creation should fail startup.
- Duplicate active treasury wallets should fail startup until repaired.
- Missing balance row should be repaired automatically if the wallet is otherwise valid.
- Quorum/signing provider unavailability should prevent spending, not bypass security.

## Testing

Required tests:

- Bootstrap creates the technical principal, treasury wallet, BTC balance, and audit event.
- Bootstrap is idempotent across repeated runs.
- Duplicate active treasury wallet records are detected.
- User wallet listing and dashboard exclude the treasury wallet.
- Reserve overview includes treasury balances explicitly.
- Treasury spending requires quorum and does not expose signing secrets.

## Scope Boundaries

This design covers KFE's system treasury wallet, bootstrap, quorum boundary, and reserve accounting. It does not make Lightning production-ready, replace the existing signer/MPC implementation, or expose new user-facing wallet screens.

# Kerosene - Treasury

## Treasury Objective

The treasury subsystem answers one question continuously:

- do platform-controlled assets safely back user liabilities and operational payout needs?

It does this through reserve capture, liquidity evaluation, transparency endpoints and revenue-collection logic.

## Reserve Model

The canonical reserve snapshot type is `ReserveSnapshot`, containing:

- `hotWalletBtc`
- `walletMonitoredOnchainBtc`
- `treasuryXpubOnchainBtc`
- `lightningBtc`
- `totalOnchainBtc`
- `totalAssetsBtc`

## Reserve Capture Logic

`CaptureReserveSnapshotInteractor` aggregates:

1. hot-wallet on-chain balance
2. Lightning node balance
3. monitored wallet XPUB/address balances
4. treasury audit XPUB balance

Important accounting rule:

- self-custody wallet XPUB balances are monitored but must not inflate platform treasury reserve

This is explicitly enforced in code.

## Reserve Scan Parameters

Current configuration defaults:

- `financial.audit.wallet-xpub-gap-limit=20`
- `financial.audit.treasury-xpub-scan-range=128`

These values determine how far XPUB scanning can extend during reserve capture.

## Treasury Overview API

`GET /treasury/overview` returns `TreasuryOverviewDTO`:

- `totalOnchainBtc`
- `lightningNodeBtc`
- `inboundLiquidityBtc`
- `outboundLiquidityBtc`
- `reservedOnchainBtc`
- `reservedLightningBtc`
- `availableOnchainBtc`
- `availableLightningBtc`
- `lightningSendsAllowed`
- `liquidityState`

## Liquidity Computation

`TreasuryService.overview()` currently:

1. captures reserve snapshot
2. reads Lightning local and remote balances
3. sums reserved outbound amounts for transfer statuses:
   - `PENDING`
   - `MEMPOOL`
   - `CONFIRMED`
4. subtracts reserved balances from available balances
5. decides whether Lightning outbound is currently allowed

## Liquidity State Values

- `BLOCKED_ONCHAIN_RESERVE`
- `REBALANCE_REQUIRED`
- `HEALTHY`

Interpretation:

- `BLOCKED_ONCHAIN_RESERVE`: on-chain reserve does not back Lightning outbound posture
- `REBALANCE_REQUIRED`: inbound liquidity ratio is too low
- `HEALTHY`: reserve and liquidity posture are acceptable

## Rebalance Policy

`LiquidityRebalancePolicy` requires at least:

- `20%` inbound liquidity

Below that threshold, the system considers loop-out/rebalance necessary.

## Lightning Send Gating

Lightning outbound is only allowed when both conditions are true:

- on-chain reserve adequately backs outbound Lightning liquidity
- available Lightning balance remains positive after reservation

This is enforced through `TreasuryService.assertLightningOutboundAvailable(...)`.

## Financial Transparency and Audit

## Public audit stats

`GET /v1/audit/stats` exposes:

- `liability_to_users`
- `platform_profit_pending`
- `actual_onchain_balance`
- `actual_lightning_balance`
- `actual_wallet_xpub_balance`
- `actual_treasury_xpub_balance`
- `actual_total_assets`
- `is_solvent`

Important correction versus older docs:

- these values are not fixed examples
- `actual_onchain_balance` now comes from live `ReserveBalanceService.captureSnapshot()`

## Audit config

Protected endpoints:

- `GET /v1/audit/config`
- `PUT /v1/audit/config`

They require `X-Admin-Token` and currently expose/update:

- `maxWithdrawLimit`
- `auditXpubConfigured`
- `auditXpubPreview`
- `updatedAt`

## Merkle transparency

Merkle transparency endpoints:

- `GET /audit/latest-root`
- `GET /audit/history`
- `POST /audit/trigger`

Behavior:

- authenticated users can read latest root and history
- manual trigger is annotated with `hasRole('ADMIN')`

Practical caveat:

- current JWT path only grants `USER`, so manual trigger is effectively unreachable without another role-injection path

## Financial Audit Chain

`PerformFinancialAuditInteractor` assembles this chain:

1. validate audit prerequisites
2. load liabilities
3. capture reserve snapshot
4. evaluate solvency
5. trigger circuit breaker behavior

Relevant config:

- `audit.solvency.enforced`
- `audit.solvency.drift-tolerance-btc`

In local compose:

- `AUDIT_SOLVENCY_ENFORCED=false`

This means local execution is not the same as a strictly enforced production solvency posture.

## Revenue Collection

`CollectRevenueInteractor` assembles this chain:

1. validate profitability
2. persist revenue
3. append Merkle entry
4. assign audit address
5. log collection

Related fee economics:

- `FeeMarkupPolicy` adds `10%` plus `500` sats over estimated network fee

## Siphon Flow

Protected endpoint:

- `POST /v1/audit/siphon`

Required controls:

- `X-Owner-TOTP`
- `X-Hardware-Signature`

Current implementation details:

- founder TOTP secret is read from config/env
- hardware signature is compared against configured expected marker
- pending platform profit is calculated from ledger entries
- fees are marked as collected after success
- destination is hardcoded to `bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh`

This hardcoded destination is a deliberate safety property in the current code.

## Treasury Caveats

1. A placeholder address `1A1z7agoat7F9gq5TFGakzrx6R5vbR2rAP` still appears in config and legacy constants, but it is not the canonical deposit-address API behavior.

2. Treasury correctness depends on external reserve adapters, Lightning client behavior and monitoring accuracy; this review validated code paths, not a full live reserve proof.

3. Audit trigger role requirements are stricter than the currently granted HTTP authority model.

4. Local compose disables solvency enforcement, so local green status is not proof of production safety.

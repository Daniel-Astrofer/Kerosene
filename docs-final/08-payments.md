# Kerosene - Payments

## Payment Domains

Kerosene currently operates across four payment domains:

- internal ledger transfers
- internal payment requests
- external on-chain transfers
- external Lightning transfers

Around those, the system also provides:

- payment links
- deposit address allocation
- onramp URL discovery
- BTCPay webhook ingestion

## Internal Money Movement

## Ledger transfer

Primary route:

- `POST /ledger/transaction`

Characteristics:

- authenticated
- rate-limited at `3/min` per user in controller logic
- goes through transactional authentication
- writes internal ledger history
- triggers wallet and notification refresh behavior in frontend

Typical request concerns:

- receiver
- amount
- context
- optional passkey assertion
- optional passphrase confirmation
- optional TOTP code
- optional idempotency key

## Internal payment requests

Routes:

- `POST /ledger/payment-request`
- `GET /ledger/payment-request/{linkId}`
- `POST /ledger/payment-request/{linkId}/pay`

Current status lifecycle:

- `PENDING`
- `PAID`
- `EXPIRED`

DTO fields include:

- id
- requester user id
- receiver wallet id and wallet name
- destination hash
- amount
- status
- `expiresAt`
- `createdAt`
- `paidAt`

## External On-Chain Receive

## Deposit address issuance

Canonical endpoints:

- `GET /transactions/deposit-address`
- `POST /transactions/network/onchain/address`

Current reality:

- the backend issues a dedicated on-chain allocation
- this is no longer just a read of static `bitcoin.deposit-address`

`OnchainAddressAllocationDTO` fields:

- `walletName`
- `onchainAddress`
- `network`
- `provider`
- `externalWalletReference`
- `walletMode`
- `transferId`
- `transferStatus`
- `confirmations`
- `requiredConfirmations`
- `blockchainTxid`

Minimum confirmation threshold:

- default `3`

## External transfer tracking

`ExternalTransferResponseDTO` fields:

- transfer id
- network
- transfer type
- status
- provider
- wallet name
- destination
- invoice id
- blockchain txid
- payment hash
- invoice data
- amount BTC
- network fee BTC
- platform fee BTC
- total debited BTC
- external reference
- confirmations
- expiry/detection/settlement timestamps
- creation/update timestamps
- context

Observed normalized transfer statuses in code:

- `PENDING`
- `DETECTED`
- `MEMPOOL`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`
- `EXPIRED`
- `FAILED`
- `SETTLED`

Provider statuses such as `PAID` and `PROCESSING` are normalized into this lifecycle by adapters and lifecycle services.

Associated blockchain address-watch states:

- `WATCHING`
- `DETECTED`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`

## External On-Chain Send

Primary routes:

- `POST /transactions/network/onchain/send`
- `POST /transactions/withdraw`

Both flows depend on:

- wallet ownership checks
- transactional factor verification
- treasury/liquidity constraints where relevant

## Lightning

Primary routes:

- `POST /transactions/network/lightning/invoice`
- `POST /transactions/network/lightning/pay`

Lightning wallet-profile route:

- `GET /transactions/network/wallet-profile`

`WalletNetworkAddressDTO` includes:

- wallet name
- on-chain address
- Lightning address
- network/provider/reference
- wallet mode
- `lightningEnabled`
- `lightningUnavailableReason`

Operational caveat:

- `lightning.lnd.enabled=false` by default

This means the API surface exists, but operational behavior is configuration dependent.

## Payment Links

Primary routes:

- `POST /transactions/create-payment-link`
- `GET /transactions/payment-link/{linkId}`
- `POST /transactions/payment-link/{linkId}/confirm`
- `POST /transactions/payment-link/{linkId}/complete`
- `POST /transactions/payment-link/{linkId}/cancel`
- `GET /transactions/payment-links`

`PaymentLinkDTO` fields:

- `id`
- `userId`
- `sessionId`
- `amountBtc`
- `grossAmountBtc`
- `depositFeeBtc`
- `netAmountBtc`
- `description`
- `depositAddress`
- `visibility`
- `confirmationMode`
- `amountLocked`
- `referenceLabel`
- `metadata`
- `status`
- `txid`
- `expiresAt`
- `createdAt`
- `paidAt`
- `completedAt`
- `cancelledAt`
- `cancelReason`

Canonical payment-link statuses:

- `pending`
- `paid`
- `expired`
- `completed`
- `cancelled`
- `verifying_onboarding`
- `verifying_activation`

Visibility values:

- `PRIVATE`
- `PUBLIC`

Confirmation-mode values:

- `MANUAL_REVIEW`
- `AUTO_COMPLETE`

## Payment-Link Reality

Payment links are the current active public-facing receive primitive.

However, there is legacy coupling in code to historical onboarding and activation concepts:

- `verifying_onboarding`
- `verifying_activation`
- account-activation monitor/finalizer services

Those states still exist in code, but they do not change the fact that normal signup now produces an already active user.

## Fees

Three fee layers matter today.

### 1. Wallet-card profile fee rates

Wallet responses expose:

- `withdrawalFeeRate`
- `depositFeeRate`

Default card-profile rates:

- bronze `0.009`
- white `0.008`
- black `0.007`

### 2. External fee rate default in docker profile

- `transactions.external.fee-rate=0.009`

### 3. Fee markup policy

`FeeMarkupPolicy` applies:

- `10%` markup over estimated network fee
- plus fixed `500` sats

This is used to preserve margin against mempool fluctuation.

## BTCPay

Webhook route:

- `POST /integrations/btcpay/webhook/{storeId}`

Operational gate:

- only useful when `btcpay.enabled=true`

Normalization logic maps BTCPay states like:

- `SETTLED -> SETTLED`
- `EXPIRED -> EXPIRED`
- `INVALID -> FAILED`
- `PROCESSING -> PENDING`

## Activation and Voucher Legacy Payment Paths

These are not canonical current payment flows.

### Activation deposit flow

- frontend still models it
- activation status endpoints still exist
- backend `confirm()` explicitly throws that initial deposit must now happen inside the platform, not by activation link

### Voucher flow

- voucher entity and some services remain
- public controller surface is absent
- adapter code explicitly logs that voucher flow is disabled

## Practical Guidance

For engineering and AI agents, the canonical payment primitives are:

- internal transfers via `/ledger/transaction`
- internal payment requests via `/ledger/payment-request`
- external on-chain/Lightning transfers via `/transactions/network/**`
- payment links via `/transactions/payment-link/**`
- treasury availability checks via `/treasury/overview`

Legacy deposit-confirmation and voucher assumptions should not be used for new work.

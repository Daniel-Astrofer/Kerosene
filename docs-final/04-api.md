# Kerosene - API

## Contract Conventions

## Authentication

HTTP authentication uses:

- `Authorization: Bearer <jwt>`

JWT in query parameters was intentionally removed and must not be relied on.

When a valid JWT is near expiry, the backend may issue:

- `X-New-Token: <jwt>`

WebSocket/STOMP authentication uses:

- native STOMP header `Authorization: Bearer <jwt>`

## Important headers

| Header | Meaning |
| --- | --- |
| `Authorization` | Required for authenticated HTTP and STOMP flows |
| `X-New-Token` | Response header with renewed JWT |
| `X-Device-Hash` | Optional device identity used by app PIN and security-profile endpoints |
| `Digest` | Optional `SHA-256=<base64>` request digest; mismatch triggers suicide path |
| `X-Idempotency-Key` | Used by some write flows and by rate-limit bucketing |
| `X-Admin-Token` | Required by protected sovereignty and audit-config endpoints |
| `X-Owner-TOTP` | Required by audit siphon |
| `X-Hardware-Signature` | Required by audit siphon |

## CORS

Current backend behavior:

- explicit allowlist only via `app.cors.allowed-origins`
- wildcard `*` is rejected at startup
- allowed methods: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`
- allowed headers: `Authorization`, `Content-Type`, `Digest`, `X-Requested-With`, `X-Idempotency-Key`
- exposed headers: `X-New-Token`

## Content types and body limits

`ParanoidSecurityFilter` accepts request bodies only for:

- `application/json`
- `application/x-protobuf`

Body limit:

- `2048` bytes

## Rate limits

Global filter:

- general: `100` requests/minute
- `/auth/**`: `20` requests/minute

Additional financial limit in `LedgerController`:

- `POST /ledger/transaction`: `3` per minute per user
- `POST /ledger/payment-request/{linkId}/pay`: `3` per minute per user

## Response envelope model

Use the `Response` column below:

- `ApiResponse<T>`: wrapped business response
- `Raw`: raw map/DTO/list/string/HTML

## Public Routes

The following routes are currently `permitAll` in `Security.java`:

- `/`
- `/healthz`
- `/auth/signup`
- `/auth/signup/totp/verify`
- `/auth/login`
- `/auth/login/totp/verify`
- `/auth/passkey/challenge`
- `/auth/passkey/verify`
- `/auth/passkey/onboarding/start`
- `/auth/passkey/onboarding/finish`
- `/auth/recovery/emergency/start`
- `/auth/recovery/emergency/finish`
- `/auth/pow/challenge`
- `/integrations/btcpay/webhook/**`
- `/actuator/health`
- `/actuator/health/**`
- `/sovereignty/ping`
- `/sovereignty/status`
- swagger/openapi resources
- `/error`
- `/ws/**`

## Endpoint Inventory

## System and health

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/` | Public | Raw | Root status map |
| `GET` | `/healthz` | Public | Raw | Health summary map |
| `GET` | `/actuator/health` | Public | Raw | Spring health |
| `GET` | `/actuator/health/**` | Public | Raw | Spring health detail paths |

## Authentication and onboarding

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/pow/challenge` | Public | `ApiResponse<String>` | Signup PoW challenge |
| `POST` | `/auth/signup` | Public | `ApiResponse<SignupResponseDTO>` | Starts signup, includes TOTP bootstrap data |
| `POST` | `/auth/signup/totp/verify` | Public | `ApiResponse<String>` | Verifies or skips signup TOTP, returns session id |
| `POST` | `/auth/login` | Public | `ApiResponse<String>` | Returns either `userId jwt` or pre-auth token |
| `POST` | `/auth/login/totp/verify` | Public | `ApiResponse<String>` | Completes TOTP login |
| `GET` | `/auth/passkey/challenge` | Public | `ApiResponse<String>` | Login challenge; query param `username` |
| `POST` | `/auth/passkey/verify` | Public | `ApiResponse<?>` | Completes passkey login |
| `POST` | `/auth/passkey/onboarding/start` | Public | `ApiResponse<String>` | Query param `sessionId`; creates signup passkey challenge |
| `POST` | `/auth/passkey/onboarding/finish` | Public | `ApiResponse<String>` | Finalizes signup and returns authenticated token material |
| `POST` | `/auth/recovery/emergency/start` | Public | `ApiResponse<?>` | Starts emergency recovery |
| `POST` | `/auth/recovery/emergency/finish` | Public | `ApiResponse<?>` | Finishes emergency recovery |

## Authenticated user and security profile

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/me` | JWT | `ApiResponse<Map>` | Accepts optional `X-Device-Hash` |
| `GET` | `/auth/security-status` | JWT | `ApiResponse<AccountSecurityStatusDTO>` | Includes passkey inventory |
| `GET` | `/auth/security/profile` | JWT | `ApiResponse<AccountSecurityProfileDTO>` | Accepts optional `X-Device-Hash` |
| `PUT` | `/auth/security/profile` | JWT | `ApiResponse<AccountSecurityProfileDTO>` | Accepts optional `X-Device-Hash`; advanced modes gated |
| `GET` | `/auth/security/app-pin` | JWT | `ApiResponse<AppPinStatusDTO>` | Device-scoped semantics |
| `PUT` | `/auth/security/app-pin` | JWT | `ApiResponse<AppPinStatusDTO>` | Accepts optional `X-Device-Hash` |
| `POST` | `/auth/security/app-pin/verify` | JWT | `ApiResponse<AppPinStatusDTO>` | Accepts optional `X-Device-Hash` |
| `POST` | `/auth/totp/setup` | JWT | `ApiResponse<TotpSetupResponseDTO>` | TOTP bootstrap for existing account |
| `POST` | `/auth/totp/verify` | JWT | `ApiResponse<BackupCodesStatusDTO>` | Enables TOTP |
| `DELETE` | `/auth/totp` | JWT | `ApiResponse<Void>` | Disables TOTP |
| `GET` | `/auth/backup-codes` | JWT | `ApiResponse<BackupCodesStatusDTO>` | Current backup-code status |
| `POST` | `/auth/backup-codes/regenerate` | JWT | `ApiResponse<BackupCodesStatusDTO>` | Regenerates codes |
| `GET` | `/auth/passkey/devices` | JWT | `ApiResponse<PasskeyInventoryDTO>` | Registered passkey inventory |
| `POST` | `/auth/passkey/register` | JWT | `ApiResponse<?>` | Adds passkey to logged-in account |

## Legacy activation endpoints still present

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/activation-status` | JWT | `ApiResponse<AccountActivationStatusDTO>` | Reflects user active state; not canonical onboarding driver |
| `POST` | `/auth/activation-status/deposit-link` | JWT | `ApiResponse<AccountActivationStatusDTO>` | Returns status-like DTO, not a real activation workflow |
| `POST` | `/auth/activation-status/{linkId}/confirm` | JWT | `ApiResponse<AccountActivationStatusDTO>` or error | `confirm()` currently throws validation error |

## Wallets

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `POST` | `/wallet/create` | JWT | `ApiResponse<WalletResponseDTO>` | Creates wallet |
| `GET` | `/wallet/all` | JWT | `ApiResponse<List<WalletResponseDTO>>` | Lists user wallets |
| `GET` | `/wallet/find` | JWT | `ApiResponse<WalletResponseDTO>` | Query param `name` |
| `PUT` | `/wallet/update` | JWT | `ApiResponse<WalletResponseDTO>` | Updates wallet metadata |
| `DELETE` | `/wallet/delete` | JWT | `ApiResponse<Void>` | Deletes wallet by payload |

## Internal ledger

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `POST` | `/ledger/transaction` | JWT | `ApiResponse<TransactionDTO>` | Additional per-user limit `3/min` |
| `GET` | `/ledger/history` | JWT | `ApiResponse<List<TransactionDTO>>` | Query params `page`, `size`; `size <= 100` |
| `GET` | `/ledger/all` | JWT | `ApiResponse<List<LedgerDTO>>` | All ledgers for user |
| `GET` | `/ledger/find` | JWT | `ApiResponse<LedgerDTO>` | Query param `walletName` |
| `GET` | `/ledger/balance` | JWT | `ApiResponse<BigDecimal>` | Query param `walletName` |
| `POST` | `/ledger/payment-request` | JWT | `ApiResponse<InternalPaymentRequestDTO>` | Creates internal request |
| `GET` | `/ledger/payment-request/{linkId}` | JWT | `ApiResponse<InternalPaymentRequestDTO>` | Reads request |
| `POST` | `/ledger/payment-request/{linkId}/pay` | JWT | `ApiResponse<TransactionDTO>` | Additional per-user limit `3/min` |

## External transactions and payment links

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/transactions/deposit-address` | JWT | `ApiResponse<OnchainAddressAllocationDTO>` | Issues dedicated on-chain allocation |
| `GET` | `/transactions/estimate-fee` | JWT | `ApiResponse<EstimatedFeeDTO>` | Query param `amount` |
| `POST` | `/transactions/create-unsigned` | JWT | `ApiResponse<UnsignedTransactionDTO>` | Unsigned tx generation |
| `GET` | `/transactions/status` | JWT | `ApiResponse<TransactionResponseDTO>` | Query param `txid` |
| `POST` | `/transactions/broadcast` | JWT | `ApiResponse<BroadcastTransactionDTO>` | Broadcast signed transaction |
| `POST` | `/transactions/create-payment-link` | JWT | `ApiResponse<PaymentLinkDTO>` | Creates external receive link |
| `GET` | `/transactions/payment-link/{linkId}` | JWT | `ApiResponse<PaymentLinkDTO>` | Reads payment link |
| `POST` | `/transactions/payment-link/{linkId}/confirm` | JWT | `ApiResponse<PaymentLinkDTO>` | Manual confirmation path |
| `POST` | `/transactions/payment-link/{linkId}/complete` | JWT | `ApiResponse<PaymentLinkDTO>` | Final completion path |
| `POST` | `/transactions/payment-link/{linkId}/cancel` | JWT | `ApiResponse<PaymentLinkDTO>` | Cancels link |
| `GET` | `/transactions/payment-links` | JWT | `ApiResponse<List<PaymentLinkDTO>>` | Lists user links |
| `POST` | `/transactions/withdraw` | JWT | `ApiResponse<?>` | External withdrawal path |

## Network payments

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `POST` | `/transactions/network/onchain/address` | JWT | `ApiResponse<OnchainAddressAllocationDTO>` | Explicit on-chain address issuance |
| `GET` | `/transactions/network/wallet-profile` | JWT | `ApiResponse<WalletNetworkAddressDTO>` | Query param `walletName` |
| `POST` | `/transactions/network/onchain/send` | JWT | `ApiResponse<ExternalTransferResponseDTO>` | On-chain payout |
| `POST` | `/transactions/network/lightning/invoice` | JWT | `ApiResponse<LightningInvoiceResponseDTO>` | Creates invoice |
| `POST` | `/transactions/network/lightning/pay` | JWT | `ApiResponse<ExternalTransferResponseDTO>` | Pays invoice |
| `POST` | `/transactions/network/transfers/{transferId}/cancel` | JWT | `ApiResponse<ExternalTransferResponseDTO>` | Cancels transfer if possible |
| `GET` | `/transactions/network/transfers` | JWT | `ApiResponse<List<ExternalTransferResponseDTO>>` | Lists transfers |
| `GET` | `/transactions/network/transfers/{transferId}` | JWT | `ApiResponse<ExternalTransferResponseDTO>` | Reads transfer |
| `POST` | `/deposit/{transferId}/cancel` | JWT | `ApiResponse<ExternalTransferResponseDTO>` | Dedicated deposit cancel route |

## Economy and onramp

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/api/economy/status` | JWT | Raw | Economy status map |
| `GET` | `/api/economy/btc-price` | JWT | Raw | BTC price map |
| `GET` | `/api/onramp/urls` | JWT | Raw | Onramp URL map |

## Notifications

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/notifications` | JWT | Raw | Returns list of notification records |
| `PUT` | `/notifications/{id}/read` | JWT | Raw | Marks notification as read |

## Mining

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/mining/rigs` | JWT | `ApiResponse<List<MiningRigOfferDTO>>` | Available rigs |
| `POST` | `/mining/allocations` | JWT | `ApiResponse<MiningAllocationResponseDTO>` | Creates allocation |
| `GET` | `/mining/allocations` | JWT | `ApiResponse<List<MiningAllocationResponseDTO>>` | Lists allocations |
| `GET` | `/mining/allocations/{allocationId}` | JWT | `ApiResponse<MiningAllocationResponseDTO>` | Reads allocation |
| `POST` | `/mining/allocations/{allocationId}/cancel` | JWT | `ApiResponse<MiningAllocationResponseDTO>` | Cancels allocation |

## Treasury, audit and sovereignty

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `GET` | `/treasury/overview` | JWT | Raw | Returns `TreasuryOverviewDTO` |
| `GET` | `/v1/audit/stats` | JWT | Raw | Transparency stats |
| `GET` | `/v1/audit/config` | JWT + `X-Admin-Token` | Raw | Admin token also required |
| `PUT` | `/v1/audit/config` | JWT + `X-Admin-Token` | Raw | Admin token also required |
| `POST` | `/v1/audit/siphon` | JWT + `X-Owner-TOTP` + `X-Hardware-Signature` | Raw | Revenue siphon flow |
| `GET` | `/audit/latest-root` | JWT | Raw | Latest merkle root |
| `GET` | `/audit/history` | JWT | Raw | Historical merkle roots |
| `POST` | `/audit/trigger` | JWT + `ROLE_ADMIN` | Raw | Currently likely unreachable because JWT filter grants only `USER` |
| `GET` | `/sovereignty/status` | Public | Raw | Sovereignty status map |
| `POST` | `/sovereignty/reattest` | JWT + `X-Admin-Token` | Raw | Manual re-attestation |
| `GET` | `/sovereignty/telemetry` | JWT + `X-Admin-Token` | Raw | Protected telemetry |
| `GET` | `/sovereignty/ping` | Public | Raw HTML | Human-readable ping page |

## External integration webhook

| Method | Route | Auth | Response | Notes |
| --- | --- | --- | --- | --- |
| `POST` | `/integrations/btcpay/webhook/{storeId}` | Public | Raw | Active only when `btcpay.enabled=true` |

## WebSocket/STOMP Surface

Registered STOMP endpoints:

- `/ws/balance` with SockJS
- `/ws/raw-balance` without SockJS
- `/ws/payment-request` with SockJS
- `/ws/raw-payment-request` without SockJS

Broker configuration:

- broker prefixes: `/topic`, `/queue`
- app destination prefix: `/app`

User destinations actively used by backend/frontend:

- `/user/queue/balance`
- `/user/queue/notifications`

## Canonical API Caveats

1. There is no active public `/voucher/**` controller.

2. Some frontend constants still point to removed routes such as:
   - `/transactions/confirm-deposit`
   - `/transactions/deposits`
   - `/transactions/deposit-balance`
   - `/notifications/send`
   - `/notifications/register-token`

3. `Digest` should be used carefully.
   A mismatch does not produce a normal validation error; it triggers `SuicideService`.

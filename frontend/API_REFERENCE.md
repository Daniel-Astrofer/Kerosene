# Kerosene API Reference

This document outlines the REST API endpoints available in the Kerosene backend and Vault systems. All responses generally follow a standard `ApiResponse<T>` wrapper (except for Vault specific endpoints).

---

## 🔐 1. Authentication & Users (`UsuarioController`, `WebAuthnController`)

**Base URL:** `/auth`

### 1.1 Basic Operations
- `GET /auth/pow/challenge`
  - **Description:** Generates a Proof-of-Work challenge to prevent spam/DDoS.
  - **Returns:** `{ challenge: string }`
- `POST /auth/signup`
  - **Description:** Registers a new user. Returns a TOTP setup key and backup codes.
  - **Body:** `UserDTO`
- `POST /auth/signup/totp/verify`
  - **Description:** Completes registration by verifying the first TOTP code. Returns JWT.
  - **Body:** `UserDTO`
- `POST /auth/login`
  - **Description:** First step of login. Verifies credentials.
  - **Body:** `UserDTO`
- `POST /auth/login/totp/verify`
  - **Description:** Second step of login. Verifies TOTP and returns JWT.
  - **Body:** `UserDTO`

### 1.2 WebAuthn / Passkeys (`/auth/passkey`)
*Note: Some endpoints require JWT Authentication.*
- `POST /register/start`: Starts Passkey registration for an authenticated user.
- `POST /register/finish`: Completes Passkey registration.
- `POST /login/start`: Starts Passkey login (bypasses TOTP if successful).
- `POST /login/finish`: Completes Passkey login and returns JWT.
- `POST /register/onboarding/start`: Starts Passkey registration during the signup flow (pre-database insertion).
- `POST /register/onboarding/finish`: Completes onboarding Passkey registration.

---

## 💼 2. Wallets (`WalletController`)

**Base URL:** `/wallet`
*Note: All endpoints require JWT Authentication.*

- `POST /create`
  - **Description:** Creates a new wallet for the user.
  - **Body:** `WalletRequestDTO`
- `GET /all`
  - **Description:** Lists all wallets belonging to the authenticated user.
- `GET /find?name={walletName}`
  - **Description:** Retrieves details of a specific wallet.
- `PUT /update`
  - **Description:** Updates wallet details.
  - **Body:** `WalletUpdateDTO`
- `DELETE /delete`
  - **Description:** Permanently deletes a wallet.
  - **Body:** `WalletRequestDTO`

---

## 📒 3. Ledger & Internal Finances (`LedgerController`)

**Base URL:** `/ledger`
*Note: All endpoints require JWT Authentication.*

- `GET /all`: Retrieves all ledger accounts associated with the user's wallets.
- `GET /find?walletName={name}`: Retrieves a specific ledger account.
- `GET /balance?walletName={name}`: Gets the current balance of a wallet.
- `GET /history?page={0}&size={50}`: Retrieves paginated transaction history.
- `POST /transaction`: Processes an internal funds transfer between users.
  - **Body:** `TransactionDTO`

### 3.1 Payment Requests (Links)
- `POST /payment-request`: Creates an internal payment request link.
  - **Body:** `{ amount: decimal, receiverWalletName: string }`
- `GET /payment-request/{linkId}`: Gets public details of a payment request. *(Public)*
- `POST /payment-request/{linkId}/pay`: Pays an internal payment request.
  - **Body:** `{ payerWalletName: string }`

---

## 💱 4. Bitcoin Transactions (`TransactionController`)

**Base URL:** `/transactions`
*Note: Most endpoints require JWT Authentication.*

- `GET /deposit-address`: Gets the master Bitcoin deposit address for the system.
- `GET /estimate-fee?amount={btc}`: Estimates network fees for a desired amount.
- `POST /create-unsigned`: Creates an unsigned Bitcoin transaction (raw hex) to be signed by the user's secure wallet.
  - **Body:** `TransactionRequestDTO`
- `POST /broadcast`: Broadcasts a signed raw transaction to the Bitcoin network.
  - **Body:** `BroadcastTransactionDTO`
- `GET /status?txid={hash}`: Checks the blockchain status of a transaction.
- `POST /withdraw`: Executes a withdrawal from the platform ledger to an external BTC address.
  - **Body:** `WithdrawRequestDTO`

### 4.1 Payment Links (External)
- `POST /create-payment-link`: Creates a payment link to receive BTC from external sources.
- `GET /payment-link/{linkId}`: Gets payment link details. *(Public)*
- `POST /payment-link/{linkId}/confirm`: Confirms an inward payment with a TXID.
- `POST /payment-link/{linkId}/complete`: Marks a paid link as completed.
- `GET /payment-links`: Lists all external payment links for the user.

---

## 🎟️ 5. Vouchers (`VoucherController`)

**Base URL:** `/voucher`

- `POST /request`: Requests a new voucher. Returns deposit address and satoshi amount.
- `POST /confirm?pendingVoucherId={id}&txid={hash}`: Confirms on-chain payment for a voucher.
- `POST /onboarding-link?sessionId={id}`: Generates a mandatory fixed BTC onboarding payment link for account activation.
- `POST /onboarding-mock-confirm?sessionId={id}`: **(DEV ONLY)** Mocks the onboarding payment and finalizes registration immediately.

---

## 🔔 6. Notifications (`NotificationController`)

**Base URL:** `/notifications`

- `POST /send`
  - **Description:** Dispatches a push notification to a user.
  - **Body:** `{ userId, title, body }`

---

## 🛡️ 7. Sovereignty & Audit (`SovereigntyStatusController`, `LedgerAuditController`, `MerkleAuditController`)

### 7.1 Node & Sovereignty Status (Public)
**Base URL:** `/sovereignty`
- `GET /status`: Returns the system sovereignty report (TPM, Quorum, Merkle, Memory protection).
- `GET /ping`: Basic HTML status page.
- `GET /telemetry`: Internal RAM metrics. *(Requires Admin Token)*
- `POST /reattest`: Resets TPM PCR baseline after OS updates. *(Requires Admin Token)*

### 7.2 Proof of Reserves & Audit
**Base URL:** `/v1/audit`
- `GET /stats`: Public Proof of Reserves, showing liabilities vs pending profit vs on-chain balance.
- `POST /siphon`: Admin endpoint to extract platform fees to a cold wallet. *(Requires TOTP & Hardware Signature)*

**Base URL:** `/audit` (Merkle Checks)
- `GET /latest-root`: Gets the most recent Merkle root checkpoint. *(Requires Auth)*
- `GET /history`: Gets recent Merkle checkpoints. *(Requires Auth)*
- `POST /trigger`: Manually triggers a Merkle root computation. *(Requires Admin)*

---

## 🔒 8. Vault System (`VaultController`)

**Base URL:** `/v1/vault`
*Note: Internal infrastructure API running on a segregated Tor network.*

- `POST /arm`
  - **Description:** Arms the vault using a M-of-N Quorum of Directors. Locks the Master Key in RAM.
  - **Headers:** `X-Director-Id`, `X-Director-Signature`
  - **Body:** `{ master_key: "base64" }`
- `POST /attest`
  - **Description:** Shards send their TPM PCR Quote. If valid, returns a session token.
  - **Body:** `{ tpm_quote, node_id }`
- `GET /provision`
  - **Description:** Delivers the Master Key to an attested Shard.
  - **Headers:** `Authorization: Bearer <token>`, `X-Node-Id`

---

## 🛠️ 9. Development & Testing Utilities

To facilitate development and automated testing without requiring real hardware or Bitcoin transactions, several "Mocking" features are available when using specific literal values.

### 9.1 WebAuthn Mocking
- **Trigger**: Send `"id": "mock_cred"` in the `credentialResponseJson` of registration or onboarding.
- **Effect**: Bypasses Yubico's formal verification and cryptographic signature checks. Returns a simulated credential state.

### 9.2 Bitcoin/Voucher Mocking
- **Trigger**: Use a `txid` starting with `mock_tx_` (e.g., `mock_tx_12345`).
- **Effect**: 
    - Bypasses blockchain network checks.
    - Bypasses database uniqueness constraints for transaction IDs.
    - Marks payments as "PAID" instantly.

### 9.3 Onboarding Shortcut
- **Endpoint**: `POST /voucher/onboarding-mock-confirm?sessionId={id}`
- **Effect**: Forces the completion of the onboarding flow for a given session. It creates the user in the database, links a mock voucher, and sets `isActive = true` immediately.

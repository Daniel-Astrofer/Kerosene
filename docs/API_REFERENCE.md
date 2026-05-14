# Referencia Real da API Kerosene

Documento derivado dos controllers Spring Boot reais em 2026-04-07.

## Convencoes

Base da API principal:

```text
http://<host>:8080
```

Via Tor, os `torrc-*` expoem `HiddenServicePort 80` apontando para `kerosene-app-*:8080`.

Formato padrao de resposta para a maior parte da API:

```json
{
  "success": true,
  "message": "Mensagem",
  "data": {},
  "errorCode": null,
  "timestamp": "2026-04-07T00:00:00"
}
```

Headers relevantes:

| Header | Uso |
| --- | --- |
| `Authorization: Bearer <jwt>` | Autenticacao REST. |
| `X-New-Token` | Resposta do backend quando o JWT foi renovado. |
| `X-Admin-Token` | `/sovereignty/reattest` e `/sovereignty/telemetry`. |
| `X-Owner-TOTP` | `/v1/audit/siphon`. |
| `X-Hardware-Signature` | `/v1/audit/siphon`. |
| `Digest: SHA-256=<base64>` | Opcional; se presente, o filtro compara com o body. |

Regras globais reais:

- Requests com body precisam usar `Content-Type: application/json` ou `application/x-protobuf`.
- Body acima de 2 KB e rejeitado pelo `ParanoidSecurityFilter`.
- REST JWT usa somente header `Authorization`; token em query param foi removido para REST.
- Rate limit geral: 100 req/min por IP.
- Rate limit para `/auth/*`: 20 req/min por IP.
- Rate limit financeiro em ledger: 10 operacoes/min por usuario.

## Matriz de Autenticacao Real

Pela `SecurityFilterChain`, estao `permitAll`:

```text
/auth/signup
/auth/signup/totp/verify
/auth/login
/auth/login/totp/verify
/auth/passkey/login/start
/auth/passkey/login/finish
/auth/passkey/register/onboarding/start
/auth/passkey/register/onboarding/finish
/auth/hardware/register/onboarding/start
/auth/hardware/register/onboarding/finish
/auth/pow/challenge
/voucher/**
/sovereignty/**
/v3/api-docs/**
/swagger-ui/**
/error
/ws/**
/actuator/**
```

Observacao importante: os endpoints implementados em `PasskeyController` sao `/auth/passkey/challenge`, `/auth/passkey/register`, `/auth/passkey/verify`, `/auth/passkey/onboarding/start` e `/auth/passkey/onboarding/finish`. Esses paths nao batem com os matchers antigos liberados acima e, no estado atual, caem em `anyRequest().authenticated()`.

## Auth

Controller: `source.auth.controller.UsuarioController`

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/pow/challenge` | Publico | - | `ApiResponse<Map<String,String>>` com `challenge`. |
| `POST` | `/auth/login` | Publico | `UserDTO` | `202 ApiResponse<String>` com id/pre-auth step. |
| `POST` | `/auth/signup` | Publico | `UserDTO` | `ApiResponse<SignupResponseDTO>` com `otpUri` e `backupCodes`. |
| `POST` | `/auth/signup/totp/verify` | Publico | `UserDTO` | `202 ApiResponse<String>` com JWT. |
| `POST` | `/auth/login/totp/verify` | Publico | `UserDTO` | `202 ApiResponse<String>` com JWT. |

`UserDTO` aceita:

```json
{
  "username": "alice",
  "passphrase": ["c", "h", "a", "r", "s"],
  "totpSecret": "base32",
  "totpCode": "123456",
  "voucherCode": "code",
  "challenge": "pow-challenge",
  "nonce": "nonce",
  "preAuthToken": "token",
  "accountSecurity": "STANDARD",
  "backupCodes": ["code1", "code2"]
}
```

`SignupResponseDTO`:

```json
{
  "otpUri": "otpauth://...",
  "backupCodes": ["..."]
}
```

## Passkeys

Controller: `source.auth.controller.PasskeyController`

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/passkey/challenge?username={username}` | JWT no estado atual | Query `username` | `ApiResponse<String>` challenge. |
| `POST` | `/auth/passkey/register` | JWT | `PasskeyRegistrationRequest` | `ApiResponse<String>` `OK`. |
| `POST` | `/auth/passkey/verify` | JWT no estado atual | `PasskeyVerifyRequest` | `ApiResponse<String>` JWT se assinatura valida. |
| `POST` | `/auth/passkey/onboarding/start?sessionId={id}` | JWT no estado atual | Query `sessionId` | `ApiResponse<String>` challenge. |
| `POST` | `/auth/passkey/onboarding/finish?sessionId={id}` | JWT no estado atual | Query `sessionId`, body `PasskeyRegistrationRequest` | `ApiResponse<String>` `OK`. |

`PasskeyRegistrationRequest`:

```json
{
  "publicKey": "base64-or-base64url",
  "publicKeyCose": "base64-or-base64url",
  "deviceName": "Pixel 8",
  "signature": "base64",
  "authData": "base64",
  "clientDataJSON": "base64",
  "credentialId": "base64url",
  "userHandle": "base64url"
}
```

`PasskeyVerifyRequest`:

```json
{
  "username": "alice",
  "credentialId": "base64url",
  "signature": "base64",
  "authData": "base64",
  "clientDataJSON": "base64"
}
```

## Wallet

Controller: `source.wallet.controller.WalletController`

Base path: `/wallet`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/wallet/create` | JWT | `WalletRequestDTO` | `201 ApiResponse<WalletResponseDTO>`. |
| `GET` | `/wallet/all` | JWT | - | `ApiResponse<List<WalletResponseDTO>>`. |
| `GET` | `/wallet/find?name={name}` | JWT | Query `name` | `ApiResponse<WalletResponseDTO>`. |
| `PUT` | `/wallet/update` | JWT | `WalletUpdateDTO` | `ApiResponse<String>`. |
| `DELETE` | `/wallet/delete` | JWT | `WalletRequestDTO` | `ApiResponse<String>`. |

`WalletRequestDTO`:

```json
{
  "passphrase": "secret",
  "name": "Main wallet"
}
```

`WalletUpdateDTO`:

```json
{
  "passphrase": "secret",
  "name": "Main wallet",
  "newName": "Cold wallet"
}
```

`WalletResponseDTO`:

```json
{
  "id": 1,
  "name": "Main wallet",
  "passphraseHash": "...",
  "createdAt": "2026-04-07T00:00:00",
  "updatedAt": "2026-04-07T00:00:00",
  "isActive": true,
  "totpUri": "otpauth://..."
}
```

## Ledger

Controller: `source.ledger.controller.LedgerController`

Base path: `/ledger`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/ledger/transaction` | JWT | `TransactionDTO` | `ApiResponse<Void>`. |
| `GET` | `/ledger/history?page=0&size=50` | JWT | Query `page`, `size` max 100 | `ApiResponse<List<LedgerTransactionHistory>>`. |
| `GET` | `/ledger/all` | JWT | - | `ApiResponse<List<LedgerDTO>>`. |
| `GET` | `/ledger/find?walletName={name}` | JWT | Query `walletName` | `ApiResponse<LedgerDTO>`. |
| `GET` | `/ledger/balance?walletName={name}` | JWT | Query `walletName` | `ApiResponse<BigDecimal>`. |
| `POST` | `/ledger/payment-request` | JWT | `{ "amount": 1.23, "receiverWalletName": "Main" }` | `ApiResponse<InternalPaymentRequestDTO>`. |
| `GET` | `/ledger/payment-request/{linkId}` | JWT pela security atual | Path `linkId` | `ApiResponse<PaymentRequestPublicDTO>`. |
| `POST` | `/ledger/payment-request/{linkId}/pay` | JWT | `{ "payerWalletName": "Main" }` | `ApiResponse<InternalPaymentRequestDTO>`. |

`TransactionDTO`:

```json
{
  "sender": "Main",
  "receiver": "receiverUserOrWalletOrAddress",
  "amount": 0.0001,
  "context": "payment",
  "idempotencyKey": "uuid",
  "requestTimestamp": 1775500000000,
  "passkeyAssertionJson": "{}",
  "confirmationPassphrase": "secret",
  "totpCode": "123456"
}
```

`LedgerDTO`:

```json
{
  "id": 1,
  "walletId": 1,
  "walletName": "Main",
  "balance": 0.01,
  "nonce": 1,
  "lastHash": "...",
  "context": "...",
  "amount": 0.01
}
```

`PaymentRequestPublicDTO`:

```json
{
  "amount": 0.0001,
  "status": "PENDING",
  "expiresAt": "2026-04-07T00:00:00"
}
```

## Bitcoin Transactions e Payment Links

Controller: `source.transactions.controller.TransactionController`

Base path: `/transactions`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/transactions/deposit-address` | JWT | - | `ApiResponse<String>` endereco configurado. |
| `GET` | `/transactions/estimate-fee?amount={btc}` | JWT | Query `amount` | `ApiResponse<EstimatedFeeDTO>`. |
| `POST` | `/transactions/create-unsigned` | JWT | `TransactionRequestDTO` | `ApiResponse<UnsignedTransactionDTO>`. |
| `GET` | `/transactions/status?txid={hash}` | JWT | Query `txid` | `ApiResponse<TransactionResponseDTO>`. |
| `POST` | `/transactions/broadcast` | JWT | `BroadcastTransactionDTO` | `ApiResponse<TransactionResponseDTO>`. |
| `POST` | `/transactions/create-payment-link` | JWT | `CreatePaymentLinkRequest` | `201 ApiResponse<PaymentLinkDTO>`. |
| `GET` | `/transactions/payment-link/{linkId}` | JWT pela security atual | Path `linkId` | `ApiResponse<PaymentLinkDTO>`. |
| `POST` | `/transactions/payment-link/{linkId}/confirm` | JWT pela security atual | `ConfirmPaymentRequest` | `ApiResponse<PaymentLinkDTO>`. |
| `POST` | `/transactions/payment-link/{linkId}/complete` | JWT | Path `linkId` | `ApiResponse<PaymentLinkDTO>`. |
| `GET` | `/transactions/payment-links` | JWT | - | `ApiResponse<List<PaymentLinkDTO>>`. |
| `POST` | `/transactions/withdraw` | JWT | `WithdrawRequestDTO` | `ApiResponse<TransactionResponseDTO>`. |

`TransactionRequestDTO`:

```json
{
  "fromAddress": "bc1...",
  "toAddress": "bc1...",
  "amount": 0.0001,
  "feeSatoshis": 1200
}
```

`BroadcastTransactionDTO`:

```json
{
  "rawTxHex": "020000...",
  "toAddress": "bc1...",
  "amount": 0.0001,
  "message": "optional"
}
```

`WithdrawRequestDTO`:

```json
{
  "fromWalletName": "Main",
  "toAddress": "bc1...",
  "amount": 0.0001,
  "description": "withdraw",
  "totpCode": "123456",
  "passkeyAssertionResponseJSON": "{}",
  "passkeyAssertionRequestJSON": "{}",
  "confirmationPassphrase": "secret"
}
```

`PaymentLinkDTO`:

```json
{
  "id": "link",
  "userId": 1,
  "sessionId": null,
  "amountBtc": 0.00022,
  "description": "ONBOARDING_VOUCHER",
  "depositAddress": "bc1...",
  "status": "pending",
  "txid": null,
  "expiresAt": "2026-04-07T00:00:00",
  "createdAt": "2026-04-07T00:00:00",
  "paidAt": null,
  "completedAt": null
}
```

## Vouchers e Onboarding

Controller: `source.voucher.controller.VoucherController`

Base path: `/voucher`

Todos os endpoints em `/voucher/**` estao `permitAll` na security atual.

| Metodo | Path | Body/Query | Resposta |
| --- | --- | --- | --- |
| `POST` | `/voucher/request` | Sem body | `depositAddress`, `amountSats`, `pendingVoucherId`. |
| `POST` | `/voucher/confirm?pendingVoucherId={id}&txid={txid}` | Query | `ApiResponse<String>` com voucher code. |
| `POST` | `/voucher/onboarding-link?sessionId={id}` | Query `sessionId` | `ApiResponse<PaymentLinkDTO>`. |
| `POST` | `/voucher/onboarding-mock-confirm?sessionId={id}` | Query `sessionId` | `ApiResponse<String>` `OK`. |

Regra real em `/voucher/onboarding-link`: exige que `SignupState` exista em Redis e que passkey esteja registrada. O valor de onboarding no codigo e `0.00022000` BTC.

## Economy e Onramp

Controllers:

- `source.transactions.controller.EconomyController`
- `source.transactions.controller.OnrampController`

| Metodo | Path | Auth | Resposta |
| --- | --- | --- | --- |
| `GET` | `/api/economy/status` | JWT | `withdrawalFeeSats`, `withdrawalStatus`. |
| `GET` | `/api/onramp/urls` | JWT | Mapa de provider para URL. |

## Notifications

Controller: `source.notification.controller.NotificationController`

| Metodo | Path | Auth | Body | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/notifications/send` | JWT | `{ "userId": "1", "title": "Titulo", "body": "Texto" }` | `ApiResponse<String>`. |

## Auditoria e Proof of Reserves

Controllers:

- `source.ledger.controller.LedgerAuditController`
- `source.ledger.audit.MerkleAuditController`

| Metodo | Path | Auth | Body/Headers | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/v1/audit/stats` | JWT pela security atual | - | Mapa com `liability_to_users`, `platform_profit_pending`, `actual_onchain_balance`, `is_solvent`. |
| `POST` | `/v1/audit/siphon` | JWT + headers | `X-Owner-TOTP`, `X-Hardware-Signature`, body mapa | Mapa com `message`, `amount_withdrawn`, `destination`. |
| `GET` | `/audit/latest-root` | JWT + `isAuthenticated()` | - | Ultimo checkpoint Merkle ou `NO_CHECKPOINT_YET`. |
| `GET` | `/audit/history?limit=10` | JWT + `isAuthenticated()` | Query `limit`, max 50 | Lista de checkpoints. |
| `POST` | `/audit/trigger` | JWT + `hasRole('ADMIN')` | - | Novo checkpoint Merkle. |

Observacao real: `JwtAuthenticationFilter` cria autoridade `USER`. Se nao houver outro mecanismo de role, `hasRole('ADMIN')` pode ficar inacessivel para tokens normais.

## Soberania e Status

Controller: `source.security.SovereigntyStatusController`

Base path: `/sovereignty`

`/sovereignty/**` esta `permitAll` na security atual, mas alguns endpoints validam `X-Admin-Token` internamente.

| Metodo | Path | Auth interna | Resposta |
| --- | --- | --- | --- |
| `GET` | `/sovereignty/status` | Publico | Mapa com hardware attestation, quorum, Merkle, memory protection e uptime. |
| `POST` | `/sovereignty/reattest` | `X-Admin-Token` | Mapa `message` ou erro. |
| `GET` | `/sovereignty/telemetry` | `X-Admin-Token` | Snapshot de telemetria em RAM. |
| `GET` | `/sovereignty/ping` | Publico | HTML simples de status. |

## WebSocket/STOMP

Configuracao: `source.config.WebSocketConfig`

Endpoints:

| Endpoint | SockJS | Uso |
| --- | --- | --- |
| `/ws/balance` | Sim | Conexao STOMP de saldo. |
| `/ws/raw-balance` | Nao | Fallback raw WebSocket. |
| `/ws/payment-request` | Sim | Eventos de payment request. |
| `/ws/raw-payment-request` | Nao | Fallback raw WebSocket. |

Autenticacao de CONNECT:

```text
Authorization: Bearer <jwt>
```

ou query param no handshake:

```text
/ws/balance?token=<jwt>
```

Topicos:

| Topico | Payload |
| --- | --- |
| `/topic/balance/{userId}` | `BalanceUpdateEvent`. |
| `/topic/payment-request/{linkId}` | `InternalPaymentRequestDTO`. |
| `/user/{userId}/queue/notifications` | Mapa com `title`, `body`, `timestamp`. |

## Vault Interno

Servico separado: `backend/vault`

Base:

```text
http://<vault-host>:8090/v1/vault
```

No compose, o Vault nao expoe porta para host; e acessado via rede interna/Tor.

| Metodo | Path | Headers | Body | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/v1/vault/arm` | `X-Director-Id`, `X-Director-Signature` | `{ "master_key": "base64" }` | String com status de quorum/armed. |
| `POST` | `/v1/vault/attest` | - | `{ "tpm_quote": "...", "node_id": "...", "public_key": "..." }` | Token de provisionamento em texto puro. |
| `GET` | `/v1/vault/provision` | `Authorization: Bearer <token>`, `X-Node-Id` | - | `{ "aes_key": "base64" }`. |
| `POST` | `/v1/vault/heartbeat` | `X-Node-Id`, `X-Shard-Timestamp`, `X-Shard-Signature` | - | `ACK`. |

Regras reais:

- `/arm` exige diretor em `director-1`, `director-2`, `director-3`.
- `/arm` exige assinatura com tamanho minimo de 12 chars.
- Quorum de armamento: 2 aprovacoes com a mesma `master_key`.
- `/attest` rejeita se o Vault nao estiver armado ou estiver em lockdown.
- `/provision` consome token uma unica vez.
- `/heartbeat` rejeita skew maior que 30 segundos e assinatura invalida.

# Referencia Real da API Kerosene

Documento derivado dos controllers Spring Boot reais em 2026-04-22.

Referencia canônica detalhada, incluindo todos os DTOs publicos e controllers novos: [`backend/kerosene/docs/API_REFERENCE_CONTROLLERS.md`](../backend/kerosene/docs/API_REFERENCE_CONTROLLERS.md).

## Cobertura Verificada

Checagem mecanica realizada contra todos os `@RestController` em `backend/kerosene/src/main/java/source/**`.

Controllers atualmente cobertos nesta referencia:

- `source.auth.controller.UserController`
- `source.auth.controller.AccountActivationController`
- `source.auth.controller.AccountSecurityController`
- `source.auth.controller.AccountSecurityStatusController`
- `source.auth.controller.BackupCodesController`
- `source.auth.controller.PasskeyController`
- `source.auth.controller.EmergencyRecoveryController`
- `source.auth.controller.MeController`
- `source.auth.controller.TotpController`
- `source.wallet.controller.WalletController`
- `source.ledger.controller.LedgerController`
- `source.ledger.controller.LedgerAuditController`
- `source.ledger.audit.MerkleAuditController`
- `source.transactions.controller.TransactionController`
- `source.transactions.controller.NetworkPaymentsController`
- `source.transactions.controller.EconomyController`
- `source.transactions.controller.OnrampController`
- `source.mining.controller.MiningController`
- `source.notification.controller.NotificationController`
- `source.security.SovereigntyStatusController`

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
  "timestamp": "2026-04-09T00:00:00"
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
- Rate limit financeiro em ledger: 10 operacoes/min por usuario apenas para `POST /ledger/transaction` e `POST /ledger/payment-request/{linkId}/pay`.
- Erros de fator transacional, como TOTP invalido ou `PASSKEY_CHALLENGE_REQUIRED`, nao indicam JWT invalido. O cliente deve manter a sessao e apenas pedir novo fator/retry.

## API Operacional de Onion Routing

Nao existe endpoint REST publico para controlar `Tor` ou `Vanguards`. O backend passou a publicar esse estado no componente Spring Actuator `health`, que agora reporta o socket Unix do Tor e o arquivo `vanguards.state` montado pelo sidecar.

Componente de health:

```json
{
  "components": {
    "tor": {
      "status": "UP",
      "details": {
        "torSocksPath": "/var/run/tor/socks/tor.sock",
        "torSocksReady": true,
        "vanguardsStateFile": "/var/run/tor/vanguards/vanguards.state",
        "vanguardsStateReady": true,
        "vanguardsStateSizeBytes": 1234,
        "vanguardsStateLastModified": "2026-04-16T13:00:00Z"
      }
    }
  }
}
```

Semantica:

- `torSocksReady=false`: o backend perdeu o Unix socket do Tor local.
- `vanguardsStateReady=false`: Tor pode estar de pe, mas o addon `vanguards` ainda nao inicializou ou perdeu o volume de estado.
- `reason`: presente quando o componente `tor` esta `DOWN`.

Observacao real: na `SecurityFilterChain` atual, `/actuator/**` ainda nao esta `permitAll`. Portanto, esse contrato e operacional/interno; ele nao deve ser tratado como endpoint publico ate a policy de seguranca ser alterada de forma explicita.

## Matriz de Autenticacao Real

Pela `SecurityFilterChain`, estao `permitAll`:

```text
/auth/signup
/auth/signup/totp/verify
/auth/login
/auth/login/totp/verify
/auth/passkey/challenge
/auth/passkey/verify
/auth/passkey/onboarding/start
/auth/passkey/onboarding/finish
/auth/recovery/emergency/start
/auth/recovery/emergency/finish
/auth/pow/challenge
/voucher/**
/v3/api-docs/**
/swagger-ui/**
/error
/ws/**
```

Observacao importante: os endpoints implementados em `PasskeyController` sao `/auth/passkey/challenge`, `/auth/passkey/register`, `/auth/passkey/verify`, `/auth/passkey/onboarding/start` e `/auth/passkey/onboarding/finish`. Na configuracao atual, `challenge`, `verify`, `onboarding/start` e `onboarding/finish` estao `permitAll`, enquanto `register` permanece JWT-only por design.

Observacao de cobertura: `/voucher/**` continua `permitAll` na security, mas nao ha `VoucherController` ativo em `backend/kerosene/src/main/java/source/**` nesta revisao.

## Auth

Controller: `source.auth.controller.UserController`

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/pow/challenge` | Publico | - | `ApiResponse<Map<String,String>>` com `challenge`. |
| `POST` | `/auth/login` | Publico | `UserDTO` | `202 ApiResponse<String>` com `preAuthToken`. |
| `POST` | `/auth/signup` | Publico | `UserDTO` | `ApiResponse<SignupResponseDTO>` com `sessionId`, `otpUri`, `backupCodes` e `totpOptional`. Exige PoW valido. |
| `POST` | `/auth/signup/totp/verify` | Publico | `UserDTO` | `202 ApiResponse<String>` com `sessionId` de onboarding salvo em Redis. |
| `POST` | `/auth/login/totp/verify` | Publico | `UserDTO` | `202 ApiResponse<String>` com payload textual no formato `"<userId> <jwt>"`. |

Observacao real: existe tambem um fluxo publico e separado para recuperacao extrema da conta, descrito na secao `Emergency Recovery`. Ele NAO emite JWT e sempre rotaciona passphrase, TOTP, passkey e recovery codes.

Fluxo real de auth:

- `POST /auth/signup` valida username/passphrase, exige `challenge` + `nonce`, cria um `SignupState` em Redis, gera TOTP e retorna os backup codes em claro apenas nessa resposta.
- `POST /auth/signup/totp/verify` recebe `sessionId` e `totpCode` opcional; ainda NAO cria o usuario no Postgres e devolve o mesmo `sessionId` para onboarding.
- `POST /auth/login` nao devolve JWT; devolve um `preAuthToken` com TTL de 5 minutos.
- `POST /auth/login/totp/verify` aceita TOTP normal ou backup code de 8 digitos; no caso de backup code, o codigo usado e consumido.

`UserDTO` aceita:

```json
{
  "username": "alice",
  "password": "frase bip39",
  "totpSecret": "base32",
  "totpCode": "123456",
  "challenge": "pow-challenge",
  "nonce": "nonce",
  "preAuthToken": "pre-auth-uuid",
  "sessionId": "signup-session-id",
  "accountSecurity": "STANDARD",
  "shamirTotalShares": 5,
  "shamirThreshold": 3,
  "multisigThreshold": 2,
  "backupCodes": ["code1", "code2"]
}
```

`SignupResponseDTO`:

```json
{
  "sessionId": "signup-session-id",
  "otpUri": "otpauth://...",
  "backupCodes": ["..."],
  "totpOptional": true
}
```

## Account Activation

Controller: `source.auth.controller.AccountActivationController`

Base path: `/auth/activation-status`

Esses endpoints exigem JWT e controlam a ativacao da conta apos o onboarding. A conta pode existir e autenticar, mas o recebimento inbound permanece bloqueado enquanto `activated=false`.

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/activation-status` | JWT | - | `ApiResponse<AccountActivationStatusDTO>`. |
| `POST` | `/auth/activation-status/deposit-link` | JWT | body vazio | `ApiResponse<AccountActivationStatusDTO>` com link criado ou reutilizado. |
| `POST` | `/auth/activation-status/{linkId}/confirm` | JWT | `ConfirmPaymentRequest` | `ApiResponse<AccountActivationStatusDTO>` apos submeter o `txid`. |

Regras reais:

- `POST /deposit-link` cria um payment link `ACCOUNT_ACTIVATION` atrelado ao `userId` autenticado.
- O link de ativacao usa o endereco estatico/fallback de deposito do backend e nao exige wallet primaria do usuario; isso e intencional porque a ativacao acontece antes de liberar recebimentos inbound.
- Se ja existir link de ativacao nao expirado, o endpoint reutiliza esse link.
- `POST /{linkId}/confirm` valida propriedade do link, `description == "ACCOUNT_ACTIVATION"` e muda o payment link para `verifying_activation`.
- A ativacao definitiva ocorre quando `AccountActivationMonitorService` detecta confirmacoes on-chain suficientes, ou imediatamente em ambiente com `voucher.mock.accept-any-txid=true`.

`AccountActivationStatusDTO`:

```json
{
  "activated": false,
  "canReceiveInbound": false,
  "requiresActivationDeposit": true,
  "requiredAmountBtc": 0.00005,
  "paymentLinkId": "pay_ab12cd34ef56",
  "depositAddress": "bc1...",
  "paymentStatus": "pending",
  "warningMessage": "Conta pendente de ativacao por deposito obrigatorio. O recebimento permanece bloqueado.",
  "activatedAt": null
}
```

## Passkeys

Controller: `source.auth.controller.PasskeyController`

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/passkey/challenge?username={username}` | Publico | Query `username` | `ApiResponse<String>` challenge. |
| `POST` | `/auth/passkey/register` | JWT | `PasskeyRegistrationRequest` | `ApiResponse<String>` `OK`. |
| `POST` | `/auth/passkey/verify` | Publico | `PasskeyVerifyRequest` | `ApiResponse<String>` JWT se assinatura valida. |
| `POST` | `/auth/passkey/onboarding/start?sessionId={id}` | Publico | Query `sessionId` | `ApiResponse<String>` challenge. |
| `POST` | `/auth/passkey/onboarding/finish?sessionId={id}` | Publico | Query `sessionId`, body `PasskeyRegistrationRequest` | `ApiResponse<String>` `OK`. |

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

Observacao real: em `POST /auth/passkey/register`, o controller decodifica `publicKeyCose` diretamente. O fallback para `publicKey` existe no onboarding e no fluxo de emergency recovery, mas nao no registro autenticado comum.

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

## Emergency Recovery

Controller: `source.auth.controller.EmergencyRecoveryController`

Base path: `/auth/recovery/emergency`

Fluxo real:

1. Cliente chama `GET /auth/pow/challenge`.
2. Cliente chama `POST /auth/recovery/emergency/start` com username, nova passphrase BIP39, nonce PoW e pelo menos 3 recovery codes distintos.
3. Backend responde com `recoverySessionId`, `otpUri` do NOVO TOTP e `passkeyChallenge`.
4. Cliente registra um NOVO autenticador TOTP e uma NOVA passkey.
5. Cliente chama `POST /auth/recovery/emergency/finish`.
6. Backend valida TOTP novo + prova criptografica da passkey nova e so entao rotaciona as credenciais antigas para o mesmo username.

Garantias reais do fluxo:

- Endpoint publico, sem JWT.
- Usa PoW obrigatorio.
- Exige multiplos recovery codes distintos.
- Nao divulga se o username existe ou se os recovery codes estavam corretos.
- A sessao de recuperacao expira em 10 minutos por padrao.
- `finish` consome a sessao com `GETDEL`; se falhar, o cliente precisa reiniciar o fluxo.
- O sucesso retorna um NOVO conjunto de recovery codes; os antigos deixam de valer.

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/auth/recovery/emergency/start` | Publico | `EmergencyRecoveryStartRequest` | `202 ApiResponse<EmergencyRecoveryStartResponse>`. |
| `POST` | `/auth/recovery/emergency/finish` | Publico | `EmergencyRecoveryFinishRequest` | `200 ApiResponse<EmergencyRecoveryFinishResponse>`. |

`EmergencyRecoveryStartRequest`:

```json
{
  "username": "alice",
  "newPassphrase": ["l", "e", "g", "a", "l", " ", "..."],
  "recoveryCodes": ["12345678", "23456789", "34567890"],
  "challenge": "pow-challenge",
  "nonce": "pow-nonce"
}
```

`EmergencyRecoveryStartResponse`:

```json
{
  "recoverySessionId": "d0f0b5641d9f4f36a797e6998551d4c1",
  "otpUri": "otpauth://totp/Kerosene:alice?secret=BASE32...",
  "passkeyChallenge": "7f8d0b8a4d0f...",
  "expiresInSeconds": 600,
  "requiredRecoveryCodes": 3
}
```

`EmergencyRecoveryFinishRequest`:

```json
{
  "recoverySessionId": "d0f0b5641d9f4f36a797e6998551d4c1",
  "totpCode": "123456",
  "publicKey": "base64-or-base64url",
  "publicKeyCose": "base64-or-base64url",
  "deviceName": "Pixel 8",
  "signature": "base64url",
  "authData": "base64url",
  "clientDataJSON": "base64url",
  "credentialId": "base64url",
  "userHandle": "base64url"
}
```

`EmergencyRecoveryFinishResponse`:

```json
{
  "username": "alice",
  "newBackupCodes": ["11111111", "22222222", "33333333"]
}
```

Erros esperados:

- `400 RECOVERY_BAD_REQUEST`: body invalido, passphrase nova invalida, menos de 3 codes, falta PoW, falta prova TOTP/passkey nova.
- `401 RECOVERY_REJECTED`: username/codes invalidos, TOTP novo invalido, prova da passkey nova invalida, ou recovery codes ja rotacionados.
- `410 RECOVERY_SESSION_EXPIRED`: `recoverySessionId` expirado ou ja consumido.
- `429 RECOVERY_RATE_LIMITED`: tentativa bloqueada temporariamente por abuso.

## Account Security

Controller: `source.auth.controller.AccountSecurityController`

Base path: `/auth/security`

Esses endpoints sao autenticados via JWT e refletem o modo de protecao ja persistido no usuario.

| Metodo | Path | Auth real | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/security/profile` | JWT | - | `ApiResponse<AccountSecurityProfileDTO>`. |
| `PUT` | `/auth/security/profile` | JWT | `AccountSecurityUpdateRequestDTO` | `ApiResponse<AccountSecurityProfileDTO>`. |

`AccountSecurityUpdateRequestDTO`:

```json
{
  "accountSecurity": "MULTISIG_2FA",
  "shamirTotalShares": 5,
  "shamirThreshold": 3,
  "multisigThreshold": 2
}
```

`AccountSecurityProfileDTO`:

```json
{
  "accountSecurity": "STANDARD",
  "shamirTotalShares": null,
  "shamirThreshold": null,
  "multisigThreshold": 2,
  "passkeyAvailable": true,
  "passkeyEnabledForTransactions": false,
  "requiredFactors": ["PASSKEY"]
}
```

Regras reais do `PUT /auth/security/profile`:

- `STANDARD`: limpa configuracoes de `SHAMIR`, volta `multisigThreshold` para `2` e usa passkey como fator obrigatorio de transacao. Nao pede TOTP em transacoes.
- `SHAMIR`: exige `shamirTotalShares` e `shamirThreshold`; total entre `2` e `8`; threshold entre `2` e `totalShares`.
- `MULTISIG_2FA`: aceita `multisigThreshold` `2` ou `3`; se for `3`, uma passkey ja registrada e obrigatoria.
- `PASSKEY`: exige ao menos uma passkey registrada antes da troca.
- `requiredFactors` e calculado no backend a partir do modo salvo e do threshold atual.

Matriz real de fatores para transacoes (`/ledger/*`, `/transactions/network/onchain/send`, `/transactions/network/lightning/pay` e fluxos que usam `WalletAuthorizationService`):

| Modo | `requiredFactors` | `totpCode` | Passkey |
| --- | --- | --- | --- |
| `STANDARD` | `["PASSKEY"]` | Nao enviar. | Obrigatoria sob challenge do servidor. |
| `PASSKEY` | `["PASSKEY"]` | Nao enviar. | Obrigatoria sob challenge do servidor. |
| `SHAMIR` | `["SLIP39_SHARES", "TOTP"]` | Obrigatorio. | Nao obrigatoria por padrao. |
| `MULTISIG_2FA`, threshold `2` | `["PASSPHRASE", "TOTP"]` | Obrigatorio. | Nao obrigatoria. |
| `MULTISIG_2FA`, threshold `3` | `["PASSPHRASE", "TOTP", "PASSKEY"]` | Obrigatorio. | Obrigatoria sob challenge do servidor. |

Quando a passkey for exigida e a primeira chamada nao trouxer assinatura, o backend responde erro de validacao com mensagem no formato `PASSKEY_CHALLENGE_REQUIRED:<challenge>`. O cliente deve assinar esse challenge e reenviar a mesma operacao com o campo de assertion adequado. Esse erro nao deve encerrar a sessao local.

## Account Utilities

Controllers:

- `source.auth.controller.MeController`
- `source.auth.controller.AccountSecurityStatusController`
- `source.auth.controller.TotpController`
- `source.auth.controller.BackupCodesController`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/auth/me` | JWT | - | `ApiResponse<Map>` com `id`, `userId`, `username`, `testBalanceClaimed`, `passkeyEnabledForTransactions` e `createdAt` quando disponivel. |
| `GET` | `/auth/security-status` | JWT | - | `ApiResponse<AccountSecurityStatusDTO>`. |
| `POST` | `/auth/totp/setup` | JWT | - | `ApiResponse<TotpSetupResponseDTO>` com `otpUri` e `secret`. |
| `POST` | `/auth/totp/verify` | JWT | `{ "totpCode": "123456" }` | `ApiResponse<BackupCodesStatusDTO>`. |
| `DELETE` | `/auth/totp` | JWT | - | `ApiResponse<String>` com `OK`. |
| `GET` | `/auth/backup-codes` | JWT | - | `ApiResponse<BackupCodesStatusDTO>`. |
| `POST` | `/auth/backup-codes/regenerate` | JWT | - | `ApiResponse<BackupCodesStatusDTO>` com novos codigos em `newlyGeneratedCodes`. |

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
  "passphraseHash": null,
  "createdAt": "2026-04-07T00:00:00",
  "updatedAt": "2026-04-07T00:00:00",
  "isActive": true,
  "totpUri": "otpauth://...",
  "depositAddress": "bc1q...",
  "lightningAddress": "main@kerosene.mock",
  "xpubConfigured": true,
  "cardType": "WHITE",
  "withdrawalFeeRate": 0.0080,
  "depositFeeRate": 0.0080
}
```

Regras reais de cartao/taxa na camada de wallet:

- `BRONZE`: cartao inicial. Taxa de saque `0.0090` e deposito `0.0090`.
- `WHITE`: conta com pelo menos 6 meses e movimentacao elegivel acima de `1500` nos ultimos 30 dias. Taxa de saque `0.0080` e deposito `0.0080`.
- `BLACK`: conta com pelo menos 6 meses e movimentacao elegivel acima de `3000` nos ultimos 30 dias. Taxa de saque `0.0070` e deposito `0.0070`.
- A movimentacao mensal usada nessa classificacao considera a janela movel dos ultimos 30 dias sobre o historico financeiro persistido.
- `totpUri` so e retornado na criacao da wallet. Nos endpoints de consulta ele volta `null`.
- `passphraseHash` permanece write-only do ponto de vista da API e nao deve ser usado pelo cliente.

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
| `POST` | `/ledger/payment-request/{linkId}/pay` | JWT | `{ "payerWalletName": "Main", "totpCode": null, "passkeyAssertionJson": "{}", "confirmationPassphrase": null }` | `ApiResponse<InternalPaymentRequestDTO>`. |

`TransactionDTO`:

```json
{
  "sender": "Main",
  "receiver": "receiverUsernameOrWalletIdOrBlockchainAddressOrDestinationHash",
  "amount": 0.0001,
  "context": "payment",
  "idempotencyKey": "uuid",
  "requestTimestamp": 1775500000000,
  "passkeyAssertionJson": "{}",
  "confirmationPassphrase": null,
  "totpCode": null
}
```

`receiver` aceito em `POST /ledger/transaction`:

- `username` do recebedor.
- `walletId` numerico.
- endereco blockchain da wallet (`depositAddress` ou endereco estatico derivado da wallet quando aplicavel).
- `destinationHash` publico de payment request (SHA-256 hexadecimal de 64 chars).

Campos de autorizacao em `TransactionDTO`:

- `passkeyAssertionJson`: obrigatorio para `STANDARD`, `PASSKEY` e `MULTISIG_2FA` com threshold `3`, mas normalmente so e preenchido no retry apos `PASSKEY_CHALLENGE_REQUIRED:<challenge>`.
- `totpCode`: enviar somente quando `requiredFactors` contem `TOTP`, ou seja, `SHAMIR` e `MULTISIG_2FA`.
- `confirmationPassphrase`: obrigatorio para `MULTISIG_2FA`; em `SHAMIR`, o cliente envia a passphrase reconstruida a partir das shares SLIP-39.
- Erro de TOTP/passkey em transacao deve ser tratado como falha de autorizacao da operacao, nao como logout.

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

`InternalPaymentRequestDTO` retornado em criacao/pagamento:

```json
{
  "id": "uuid",
  "requesterUserId": 1,
  "receiverWalletName": "Main",
  "amount": 0.0001,
  "status": "PENDING",
  "expiresAt": "2026-04-09T00:30:00",
  "createdAt": "2026-04-09T00:00:00",
  "paidAt": null
}
```

Regras reais de payment request interno:

- TTL de 30 minutos.
- `GET /ledger/payment-request/{linkId}` passa pelo DTO publico, mas continua protegido por JWT pela `SecurityFilterChain`.
- Status efetivamente usados no service: `PENDING`, `PAID` e `EXPIRED`.
- `POST /ledger/payment-request/{linkId}/pay` reaproveita o orquestrador de transacao interna e aceita fatores extras de seguranca conforme a politica da conta pagadora.

## Bitcoin Transactions e Payment Links

Controller: `source.transactions.controller.TransactionController`

Base path: `/transactions`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/transactions/deposit-address` | JWT | - | `ApiResponse<String>` endereco custodial dedicado para a wallet principal do usuario. Em dev, pode creditar saldo mock automaticamente com taxa de deposito conforme o cartao atual da wallet do usuario. |
| `GET` | `/transactions/estimate-fee?amount={btc}` | JWT | Query `amount` | `ApiResponse<EstimatedFeeDTO>`. |
| `POST` | `/transactions/create-unsigned` | JWT | `TransactionRequestDTO` | `ApiResponse<UnsignedTransactionDTO>`. |
| `GET` | `/transactions/status?txid={hash}` | JWT | Query `txid` | `ApiResponse<TransactionResponseDTO>`. |
| `POST` | `/transactions/broadcast` | JWT | `BroadcastTransactionDTO` | `ApiResponse<TransactionResponseDTO>`. |
| `POST` | `/transactions/create-payment-link` | JWT | `CreatePaymentLinkRequest` | `201 ApiResponse<PaymentLinkDTO>`. |
| `GET` | `/transactions/payment-link/{linkId}` | JWT pela security atual | Path `linkId` | `ApiResponse<PaymentLinkDTO>`. Endpoint autenticado para fluxos ja logados. |
| `POST` | `/transactions/payment-link/{linkId}/confirm` | JWT pela security atual | `ConfirmPaymentRequest` | `ApiResponse<PaymentLinkDTO>`. Endpoint autenticado para fluxos ja logados. |
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

`EstimatedFeeDTO`:

```json
{
  "fastSatoshisPerByte": 18,
  "standardSatoshisPerByte": 10,
  "slowSatoshisPerByte": 4,
  "estimatedFastBtc": 0.00001234,
  "estimatedStandardBtc": 0.00000987,
  "estimatedSlowBtc": 0.00000456,
  "amountReceived": 0.0001,
  "totalToSend": 0.00011234
}
```

`UnsignedTransactionDTO`:

```json
{
  "rawTxHex": "020000...",
  "txId": "temporary-txid",
  "inputs": [
    {
      "txid": "prev-txid",
      "vout": 0,
      "value": 0.0002,
      "scriptPubKey": "0014..."
    }
  ],
  "outputs": [
    {
      "address": "bc1...",
      "value": 0.0001
    }
  ],
  "totalAmount": 0.0001,
  "fee": 1200,
  "fromAddress": "bc1...",
  "toAddress": "bc1..."
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

`TransactionResponseDTO`:

```json
{
  "txid": "real-or-mock-txid",
  "status": "PENDING",
  "feeSatoshis": 1200,
  "amountReceived": 0.0001
}
```

`CreatePaymentLinkRequest`:

```json
{
  "amount": 0.00022,
  "description": "Invoice ABC"
}
```

`ConfirmPaymentRequest`:

```json
{
  "txid": "blockchain-txid",
  "fromAddress": "bc1..."
}
```

`WithdrawRequestDTO`:

```json
{
  "fromWalletName": "Main",
  "toAddress": "bc1...",
  "amount": 0.0001,
  "description": "withdraw",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "passkeyAssertionRequestJSON": null,
  "confirmationPassphrase": null
}
```

`totpCode` em `WithdrawRequestDTO` segue a mesma matriz de fatores da conta: contas `STANDARD`/`PASSKEY` nao enviam TOTP; contas `SHAMIR`/`MULTISIG_2FA` enviam TOTP. `POST /transactions/withdraw` e retrocompatibilidade para a trilha on-chain nova.

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
  "expiresAt": "2026-04-09T01:00:00",
  "createdAt": "2026-04-09T00:00:00",
  "paidAt": null,
  "completedAt": null
}
```

Regras reais de payment links:

- Sao armazenados apenas em Redis.
- `status` pode assumir `pending`, `paid`, `expired`, `completed`, `verifying_onboarding` e `verifying_activation`.
- `POST /transactions/payment-link/{linkId}/confirm` marca links normais como `paid`.
- Para onboarding (`description == "ONBOARDING_VOUCHER"` e `sessionId != null`), a confirmacao publica muda o status para `verifying_onboarding` enquanto o backend aguarda confirmacoes on-chain antes de finalizar o usuario.
- Para ativacao de conta (`description == "ACCOUNT_ACTIVATION"` e `userId != null`), a confirmacao muda o status para `verifying_activation`; esse fluxo nao credita wallet do usuario.

`PaymentLinkDTO` real:

```json
{
  "id": "pay_ab12cd34ef56",
  "userId": 123,
  "sessionId": null,
  "amountBtc": 1.00000000,
  "grossAmountBtc": 1.00000000,
  "depositFeeBtc": 0.00900000,
  "netAmountBtc": 0.99100000,
  "description": "Credit Test",
  "depositAddress": "1A1z7agoat7F9gq5TFGakzrx6R5vbR2rAP",
  "status": "paid",
  "txid": "tx_mock_123",
  "expiresAt": "2026-04-14T18:30:00",
  "createdAt": "2026-04-14T17:30:00",
  "paidAt": "2026-04-14T17:35:00",
  "completedAt": null
}
```

Semantica dos campos de `PaymentLinkDTO`:

- `amountBtc`: valor original solicitado no link; mantido por compatibilidade.
- `grossAmountBtc`: valor bruto considerado para o credito do link.
- `depositFeeBtc`: taxa de deposito aplicada no momento da confirmacao, usando o cartao atual da wallet do usuario.
- `netAmountBtc`: valor liquido efetivamente creditado no ledger do usuario.
- Na criacao do link, `grossAmountBtc` ja vem preenchido com o valor solicitado, enquanto `depositFeeBtc` e `netAmountBtc` permanecem `null` ate a confirmacao.
- Em onboarding, o link pode ficar em `verifying_onboarding` sem preencher `depositFeeBtc`/`netAmountBtc`, porque esse fluxo nao credita wallet do usuario.
- Em ativacao de conta, o link pode ficar em `verifying_activation` sem preencher `depositFeeBtc`/`netAmountBtc`, porque esse fluxo libera a conta apos confirmacao on-chain e nao credita saldo na wallet.

## External Network Payments

Controller: `source.transactions.controller.NetworkPaymentsController`

Base path: `/transactions/network`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `POST` | `/transactions/network/onchain/address` | JWT | `OnchainAddressRequestDTO` | `201 ApiResponse<WalletNetworkAddressDTO>`. |
| `GET` | `/transactions/network/wallet-profile?walletName={name}` | JWT | Query `walletName` | `ApiResponse<WalletNetworkAddressDTO>`. |
| `POST` | `/transactions/network/onchain/send` | JWT | `OnchainSendRequestDTO` | `ApiResponse<ExternalTransferResponseDTO>`. |
| `POST` | `/transactions/network/lightning/invoice` | JWT | `LightningInvoiceRequestDTO` | `201 ApiResponse<LightningInvoiceResponseDTO>`. |
| `POST` | `/transactions/network/lightning/pay` | JWT | `LightningPaymentRequestDTO` | `ApiResponse<ExternalTransferResponseDTO>`. |
| `GET` | `/transactions/network/transfers` | JWT | - | `ApiResponse<List<ExternalTransferResponseDTO>>`. |
| `GET` | `/transactions/network/transfers/{transferId}` | JWT | Path `transferId` | `ApiResponse<ExternalTransferResponseDTO>`. |

Regras reais:

- Movimentacoes externas on-chain e Lightning aplicam taxa dinamica conforme o cartao da wallet do usuario:
  - `BRONZE`: `0.9%`
  - `WHITE`: `0.8%`
  - `BLACK`: `0.7%`
- Autorizacao de saida externa usa a matriz de fatores de `/auth/security/profile`: `STANDARD`/`PASSKEY` exigem passkey e nao TOTP; `SHAMIR` e `MULTISIG_2FA` exigem TOTP; `MULTISIG_2FA` threshold `3` tambem exige passkey.
- Falha de TOTP em on-chain/Lightning retorna erro da operacao, mas nao invalida o JWT.
- `POST /transactions/withdraw` permanece por retrocompatibilidade, mas agora cai na mesma trilha on-chain nova.
- Endereco on-chain por carteira tenta usar o provider de custodia configurado em `custody.*` com nome default `BCX`, e faz fallback para derivacao local/xpub quando nao ha provider live.
- Lightning invoice e pagamento usam o mesmo adapter de custodia; em `mock-mode` a resposta e deterministica para desenvolvimento.
- Depositos externos confirmados que entram no ecossistema Kerosene (por exemplo, creditos on-chain detectados localmente e mock deposit local) passam a creditar o valor liquido apos aplicar a taxa de deposito do cartao vigente; esse breakdown hoje fica registrado no historico interno, nao em um DTO publico dedicado.

`OnchainAddressRequestDTO`:

```json
{
  "walletName": "Main",
  "regenerate": false
}
```

`OnchainSendRequestDTO`:

```json
{
  "fromWalletName": "Main",
  "toAddress": "bc1q...",
  "amount": 0.015,
  "description": "saque externo",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "confirmationPassphrase": null
}
```

Para `SHAMIR` e `MULTISIG_2FA`, envie `totpCode`. Para `MULTISIG_2FA` threshold `2`, envie tambem `confirmationPassphrase`; para `SHAMIR`, envie a passphrase reconstruida das shares. Para `STANDARD` e `PASSKEY`, omita `totpCode` e responda ao challenge de passkey quando o backend solicitar.

`LightningInvoiceRequestDTO`:

```json
{
  "walletName": "Main",
  "amount": 0.0015,
  "memo": "deposito lightning",
  "expiresInSeconds": 900
}
```

`LightningPaymentRequestDTO`:

```json
{
  "fromWalletName": "Main",
  "paymentRequest": "lnbc...",
  "amount": 0.0005,
  "maxRoutingFeeBtc": 0.00000100,
  "description": "pagamento lightning",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "confirmationPassphrase": null
}
```

Os campos de autorizacao de `LightningPaymentRequestDTO` seguem exatamente a mesma regra de `OnchainSendRequestDTO`.

`WalletNetworkAddressDTO`:

```json
{
  "walletName": "Main",
  "onchainAddress": "bc1q...",
  "lightningAddress": "main@kerosene.mock",
  "provider": "BCX",
  "externalWalletReference": "wallet-ref-123"
}
```

`LightningInvoiceResponseDTO`:

```json
{
  "transferId": "2d9f0eec-d738-4ad4-8f69-2f6e2f6af3a1",
  "walletName": "Main",
  "paymentRequest": "lnbc...",
  "paymentHash": "8c1f...",
  "lightningAddress": "main@kerosene.mock",
  "amountBtc": 0.0015,
  "provider": "BCX",
  "expiresAt": "2026-04-10T12:15:00",
  "status": "PENDING"
}
```

`ExternalTransferResponseDTO`:

```json
{
  "id": "f1c7e0e7-5fe3-4e16-a97b-7dd6af0d286d",
  "network": "ONCHAIN",
  "transferType": "OUTBOUND_PAYMENT",
  "status": "PENDING",
  "provider": "BCX",
  "walletName": "Main",
  "destination": "bc1q...",
  "amountBtc": 0.015,
  "networkFeeBtc": 0.00004500,
  "platformFeeBtc": 0.00012000,
  "totalDebitedBtc": 0.01516500,
  "externalReference": "txid-or-payment-hash",
  "createdAt": "2026-04-10T12:00:00",
  "updatedAt": "2026-04-10T12:00:00",
  "context": "saque externo"
}
```

Observacao: `platformFeeBtc` e `totalDebitedBtc` variam conforme `cardType` da wallet que originou a saida. O exemplo acima assume uma wallet `WHITE` com taxa de `0.8%`.

Estados e tipos efetivos observados no backend:

- `network`: `ONCHAIN`, `LIGHTNING`.
- `transferType`: `ADDRESS_ISSUE`, `INBOUND_INVOICE`, `OUTBOUND_PAYMENT`.
- `status`: `PENDING`, `SETTLED`, `COMPLETED`, `CANCELLED`.

## Mining Marketplace

Controller: `source.mining.controller.MiningController`

Base path: `/mining`

| Metodo | Path | Auth | Body/Query | Resposta |
| --- | --- | --- | --- | --- |
| `GET` | `/mining/rigs` | JWT | - | `ApiResponse<List<MiningRigOfferDTO>>`. |
| `POST` | `/mining/allocations` | JWT | `MiningAllocationRequestDTO` | `201 ApiResponse<MiningAllocationResponseDTO>`. |
| `GET` | `/mining/allocations` | JWT | - | `ApiResponse<List<MiningAllocationResponseDTO>>`. |
| `GET` | `/mining/allocations/{allocationId}` | JWT | Path `allocationId` | `ApiResponse<MiningAllocationResponseDTO>`. |
| `POST` | `/mining/allocations/{allocationId}/cancel` | JWT | - | `ApiResponse<MiningAllocationResponseDTO>`. |

Regras reais:

- O modelo segue o fluxo de hashpower rental da MRR: catalogo por algoritmo/unidade de hash, preco por unidade-dia, duracao minima/maxima e cancelamento pro-rata.
- O usuario pode enviar `requestedHashrate` diretamente ou apenas `budgetBtc`, e o backend deriva o hashrate contratado.
- Alocacoes ativas liquidam o rendimento projetado ao final do periodo; cancelamentos creditam rendimento proporcional do tempo usado + refund do tempo restante.
- A autorizacao da alocacao usa `WalletAuthorizationService` e segue a mesma matriz de fatores: `STANDARD`/`PASSKEY` usam passkey sem TOTP; `SHAMIR`/`MULTISIG_2FA` exigem TOTP.

`MiningAllocationRequestDTO`:

```json
{
  "walletName": "Treasury",
  "rigId": 1,
  "requestedHashrate": null,
  "budgetBtc": 0.01,
  "durationHours": 24,
  "payoutAddress": "bc1q...",
  "poolUrl": "stratum+tcp://pool.example:3333",
  "workerName": "worker.01",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "confirmationPassphrase": null
}
```

`MiningRigOfferDTO`:

```json
{
  "id": 1,
  "rigCode": "sha256-hydro-240",
  "displayName": "Hydro SHA256 240TH",
  "algorithm": "SHA256",
  "hashUnit": "TH",
  "availableHashrate": 1200.0,
  "pricePerUnitDayBtc": 0.00000850,
  "projectedBtcYieldPerUnitDay": 0.00000720,
  "minRentalHours": 1,
  "maxRentalHours": 168,
  "provider": "KEROSENE_INTERNAL"
}
```

`MiningAllocationResponseDTO`:

```json
{
  "id": "4af1495d-2877-4692-8a75-4f2cc5442a94",
  "rigId": 1,
  "rigName": "Hydro SHA256 240TH",
  "walletName": "Treasury",
  "algorithm": "SHA256",
  "allocatedHashrate": 1000.0,
  "hashUnit": "TH",
  "durationHours": 24,
  "rentalCostBtc": 0.00850000,
  "projectedGrossYieldBtc": 0.00720000,
  "projectedNetYieldBtc": 0.00709200,
  "refundedAmountBtc": null,
  "status": "ACTIVE",
  "providerRentalReference": "rent_sha256-hydro-240_ab12cd34",
  "payoutAddress": "bc1q...",
  "poolUrl": "stratum+tcp://pool.example:3333",
  "workerName": "worker.01",
  "startsAt": "2026-04-10T12:00:00",
  "endsAt": "2026-04-11T12:00:00",
  "settledAt": null
}
```

Estados efetivos de alocacao:

- `ACTIVE`: aluguel em curso.
- `COMPLETED`: periodo encerrado e rendimento projetado creditado.
- `CANCELLED`: aluguel encerrado antes do prazo com refund/pro-rata aplicado.

## Vouchers e Onboarding

`/voucher/**` ainda esta `permitAll` em `Security.java`, mas nao existe `source.voucher.controller.VoucherController` ativo em `backend/kerosene/src/main/java/source/**` nesta revisao. Portanto nao ha contrato REST implementado para vouchers neste snapshot do backend.

## Economy e Onramp

Controllers:

- `source.transactions.controller.EconomyController`
- `source.transactions.controller.OnrampController`

| Metodo | Path | Auth | Resposta |
| --- | --- | --- | --- |
| `GET` | `/api/economy/status` | JWT | `withdrawalFeeSats`, `withdrawalStatus`. |
| `GET` | `/api/economy/btc-price` | JWT | `btcUsd`, `btcBrl`, `usdBrl`. |
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

`/sovereignty/**` cai no `anyRequest().authenticated()` da security atual. Alguns endpoints ainda validam `X-Admin-Token` internamente.

| Metodo | Path | Auth interna | Resposta |
| --- | --- | --- | --- |
| `GET` | `/sovereignty/status` | JWT | Mapa com hardware attestation, quorum, Merkle, memory protection e uptime. |
| `POST` | `/sovereignty/reattest` | JWT + `X-Admin-Token` | Mapa `message` ou erro. |
| `GET` | `/sovereignty/telemetry` | JWT + `X-Admin-Token` | Snapshot de telemetria em RAM. |
| `GET` | `/sovereignty/ping` | JWT | HTML simples de status. |

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

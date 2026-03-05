# Kerosene Backend API — Documentação Completa para o Frontend

> **Última atualização**: 2026-03-03
>
> Todas as respostas seguem o formato padrão `ApiResponse<T>`:
> ```json
> { "success": true|false, "message": "...", "data": T, "errorCode": "..." (somente em erro), "timestamp": "..." }
> ```
>
> ⚠️ **ATENÇÃO: POLÍTICA MONETÁRIA**
> A plataforma opera **exclusivamente com valores fixos em Bitcoin (BTC)**. O backend **não** integra APIs de cotação de terceiros (como Binance), **não** possui gráficos de variação de preços e **não** exibe equivalências em moedas fiduciárias (BRL/USD/EUR). Todo o sistema (Saldos, Taxas de Rede, Onboarding e Saques) reflete a política cypherpunk de "1 BTC = 1 BTC".

---

## 🔐 Autenticação & Headers

### JWT Token
Todos os endpoints protegidos exigem o header:
```
Authorization: Bearer <jwt_token>
```

O JWT contém **apenas** o `userId` (claim `jti`) como subject. **Não há** `deviceHash`, fingerprint, IP ou qualquer informação de dispositivo no token.

### Renovação Automática de Token
Se o token estiver próximo de expirar (< 1 hora restante), o servidor retorna um header de resposta:
```
X-New-Token: <novo_jwt_token>
```
O frontend **deve** verificar a existência desse header em **toda resposta** e, se presente, substituir o token armazenado pelo novo.

### ⛔ Header `x-device-hash` — REMOVIDO
O header `x-device-hash` foi **completamente removido** do backend. O frontend **NÃO DEVE** enviá-lo em nenhuma requisição. Se enviado, será ignorado pelo servidor, mas polui os logs.

### Endpoints Públicos (sem JWT)
| Endpoint | Método |
|---|---|
| `/auth/login` | POST |
| `/auth/login/totp/verify` | POST |
| `/auth/signup` | POST |
| `/auth/signup/totp/verify` | POST |
| `/auth/pow/challenge` | GET |
| `/auth/passkey/login/start` | POST |
| `/auth/passkey/login/finish` | POST |
| `/voucher/**` | ALL |
| `/ws/**` | ALL |

Todos os outros endpoints exigem `Authorization: Bearer <token>`.

---

## 📋 Catálogo de Error Codes

Toda resposta de erro tem o campo `errorCode`. O frontend pode usar estes códigos para exibir mensagens localizadas.

### Auth Errors
| errorCode | HTTP | Descrição |
|---|---|---|
| `ERR_AUTH_USER_ALREADY_EXISTS` | 409 | Username já cadaistrado |
| `ERR_AUTH_USERNAME_MISSING` | 400 | Campo `username` é null ou vazio |
| `ERR_AUTH_PASSPHRASE_MISSING` | 400 | Campo `passphrase` é null |
| `ERR_AUTH_INVALID_USERNAME_FORMAT` | 400 | Username contém caracteres inválidos |
| `ERR_AUTH_CHARACTER_LIMIT_EXCEEDED` | 400 | Username ou passphrase excede limite de caracteres |
| `ERR_AUTH_USER_NOT_FOUND` | 404 | Nenhuma conta encontrada com esse username |
| `ERR_AUTH_INVALID_PASSPHRASE_FORMAT` | 400 | Passphrase não é um mnemônico BIP39 válido |
| `ERR_AUTH_INCORRECT_TOTP` | 401 | Código TOTP incorreto ou expirado |
| `ERR_AUTH_INVALID_CREDENTIALS` | 401 | Username ou passphrase incorretos |
| `ERR_AUTH_UNRECOGNIZED_DEVICE` | 403 | Sessão inválida (legado, não mais usado) |
| `ERR_AUTH_TOTP_TIMEOUT` | 408 | Tempo para verificação TOTP expirou |
| `ERR_AUTH_GENERIC` | 400 | Erro genérico de autenticação |

### Wallet Errors
| errorCode | HTTP | Descrição |
|---|---|---|
| `ERR_WALLET_ALREADY_EXISTS` | 409 | Já existe uma carteira com esse nome |
| `ERR_WALLET_NOT_FOUND` | 404 | Carteira não encontrada |
| `ERR_WALLET_GENERIC` | 400 | Erro genérico na operação de carteira |

### Ledger Errors
| errorCode | HTTP | Descrição |
|---|---|---|
| `ERR_LEDGER_NOT_FOUND` | 404 | Ledger não encontrado para esta carteira |
| `ERR_LEDGER_RECEIVER_NOT_FOUND` | 404 | Destinatário da transação não encontrado |
| `ERR_LEDGER_ALREADY_EXISTS` | 409 | Ledger já existe para esta carteira |
| `ERR_LEDGER_INSUFFICIENT_BALANCE` | 402 | Saldo insuficiente |
| `ERR_LEDGER_INVALID_OPERATION` | 400 | Operação inválida (valor negativo etc.) |
| `ERR_LEDGER_GENERIC` | 400 | Erro genérico de ledger |
| `ERR_LEDGER_PAYMENT_REQUEST_NOT_FOUND` | 404 | Link de pagamento não encontrado ou expirado |
| `ERR_LEDGER_PAYMENT_REQUEST_EXPIRED` | 410 | Link de pagamento expirou |
| `ERR_LEDGER_PAYMENT_REQUEST_ALREADY_PAID` | 409 | Link de pagamento já foi pago |
| `ERR_LEDGER_PAYMENT_REQUEST_SELF_PAY` | 403 | Não pode pagar seu próprio link |

### General
| errorCode | HTTP | Descrição |
|---|---|---|
| `ERR_INTERNAL_SERVER` | 500 | Erro inesperado no servidor |

---

## 0. Account Security Modes

O campo `accountSecurity` é escolhido **uma única vez** no cadastro (`POST /auth/signup`) e define como a plataforma co-assina operações. **Não pode ser alterado depois.**

| Valor | Descrição |
|---|---|
| `STANDARD` | Senha + TOTP (padrão) |
| `SHAMIR` | Shamir's Secret Sharing — plataforma guarda 1 share criptografado (AES-256-GCM) |
| `MULTISIG_2FA` | Plataforma guarda chave de co-assinatura criptografada (AES-256-GCM) |

> **Segurança**: o campo `platform_cosigner_secret` é armazenado como ciphertext AES-256-GCM Base64. **NUNCA é retornado em respostas de API.**

---

## 1. Authentication & Users (`/auth`)

### 1.1 Proof of Work (PoW) Challenge
- **URL**: `GET /auth/pow/challenge`
- **Auth**: Nenhuma
- **Descrição**: Retorna um desafio único. O client resolve: `SHA-256(challenge + nonce)` deve iniciar/terminar com zeros.
- **Response** (200):
```json
{
  "success": true,
  "message": "PoW Challenge generated",
  "data": { "challenge": "ab82c9f1a23b..." }
}
```

### 1.2 Signup
- **URL**: `POST /auth/signup`
- **Auth**: Nenhuma
- **Request Body**:
```json
{
  "username": "meuuser",
  "passphrase": "abandon ability able about above absent...",
  "challenge": "ab82c9f1a23b...",
  "nonce": "123456",
  "accountSecurity": "STANDARD"
}
```

| Campo | Tipo | Obrigatório | Regras |
|---|---|---|---|
| `username` | string | ✅ | Alfanumérico, max 30 chars |
| `passphrase` | string | ✅ | BIP39 mnemônico válido (EN ou PT-BR), 12/15/18/21/24 palavras |
| `challenge` | string | ✅ | Obtido via `GET /auth/pow/challenge` |
| `nonce` | string | ✅ | Solução do PoW |
| `accountSecurity` | string | ❌ | Default: `STANDARD`. Valores: `STANDARD`, `SHAMIR`, `MULTISIG_2FA` |

- **Response** (200):
```json
{
  "success": true,
  "message": "Account credentials validated. Please configure your authenticator app using the provided setup key.",
  "data": "otpauth://totp/Kerosene:meuuser?secret=JBSWY3DPEHPK3PXP&issuer=Kerosene"
}
```

> O `data` é a URI OTPAuth completa para gerar o QR Code no app.

- **Error Codes possíveis**: `ERR_AUTH_USER_ALREADY_EXISTS`, `ERR_AUTH_USERNAME_MISSING`, `ERR_AUTH_PASSPHRASE_MISSING`, `ERR_AUTH_INVALID_USERNAME_FORMAT`, `ERR_AUTH_CHARACTER_LIMIT_EXCEEDED`, `ERR_AUTH_INVALID_PASSPHRASE_FORMAT`

### 1.3 Signup — TOTP Verify
- **URL**: `POST /auth/signup/totp/verify`
- **Auth**: Nenhuma
- **Request Body**:
```json
{
  "username": "meuuser",
  "totpCode": "123456"
}
```

| Campo | Tipo | Obrigatório |
|---|---|---|
| `username` | string | ✅ |
| `totpCode` | string | ✅ (6 dígitos do app autenticador) |

- **Response** (202 Accepted):
```json
{
  "success": true,
  "message": "Device verified and account successfully created. You are now fully authenticated.",
  "data": "95d1a211fe39454c9a500a969cfda8d8"
}
```

> O `data` é o **sessionId** temporário (armazenado no Redis). Usado nos passos seguintes: Registro de Passkey Onboarding e Geração do Voucher. Expira em 24h. **NÃO é um JWT.**

### 1.4 Login
- **URL**: `POST /auth/login`
- **Auth**: Nenhuma
- **Request Body**:
```json
{
  "username": "meuuser",
  "passphrase": "abandon ability able about above absent..."
}
```

| Campo | Tipo | Obrigatório |
|---|---|---|
| `username` | string | ✅ |
| `passphrase` | string | ✅ (BIP39 mnemônico) |

- **Response** (202 Accepted):
```json
{
  "success": true,
  "message": "Login request received. Please proceed with TOTP verification.",
  "data": "42 eyJhbGciOiJIUzUxMiJ9..."
}
```

> O `data` retorna `"<userId> <jwt_token>"` separados por espaço. Se o usuário já tinha um JWT válido no header, o token é renovado automaticamente. O frontend deve fazer o parse: split por espaço, `data.split(" ")[0]` = userId, `data.split(" ")[1]` = token.

> **Rate Limiting**: Após 5 tentativas falhas consecutivas, a conta é bloqueada por 15 minutos. O erro retornado será `ERR_AUTH_INVALID_CREDENTIALS`.

### 1.5 Login — TOTP Verify
- **URL**: `POST /auth/login/totp/verify`
- **Auth**: Nenhuma
- **Request Body**:
```json
{
  "username": "meuuser",
  "totpCode": "123456"
}
```

| Campo | Tipo | Obrigatório | Notas |
|---|---|---|---|
| `username` | string | ✅ | Mesmo username do login |
| `totpCode` | string | ✅ | 6 dígitos do app autenticador |

> ⚠️ **NÃO envie `passphrase` neste endpoint**. A passphrase já foi validada no step `/auth/login`. Este endpoint faz lookup apenas pelo `username`.

- **Response** (202 Accepted):
```json
{
  "success": true,
  "message": "TOTP verification successful. You have logged in.",
  "data": "42 eyJhbGciOiJIUzUxMiJ9..."
}
```

> O formato do `data` é o mesmo do login: `"<userId> <jwt_token>"`.

### 1.6 Passkey — Register Start (Pós-login)
- **URL**: `POST /auth/passkey/register/start`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Registration options generated",
  "data": "{ PublicKeyCredentialCreationOptions JSON string }"
}
```

### 1.7 Passkey — Register Finish (Pós-login)
- **URL**: `POST /auth/passkey/register/finish`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Request Body**: Raw JSON string do Authenticator response.
- **Response** (200):
```json
{
  "success": true,
  "message": "Passkey registered successfully",
  "data": "OK"
}
```

### 1.8 Passkey — Login Start
- **URL**: `POST /auth/passkey/login/start?username={username}`
- **Auth**: Nenhuma
- **Response** (200):
```json
{
  "success": true,
  "message": "Login options generated",
  "data": "{ AssertionRequest JSON string }"
}
```

### 1.9 Passkey — Login Finish
- **URL**: `POST /auth/passkey/login/finish?username={username}`
- **Auth**: Nenhuma
- **Request Body**: Raw JSON string do Authenticator assertion response.
- **Descrição**: Autentica via Passkey e **bypassa a etapa TOTP inteiramente**.
- **Response** (200):
```json
{
  "success": true,
  "message": "Passkey login successful",
  "data": "eyJhbGciOiJIUzUxMiJ9..."
}
```

> O `data` é diretamente o JWT token (sem userId prefixado — diferente do login TOTP).

### 1.10 Passkey — Onboarding Register Start
- **URL**: `POST /auth/passkey/register/onboarding/start?sessionId={sessionId}`
- **Auth**: Nenhuma (usa `sessionId` do Redis)
- **Pré-condição**: `sessionId` obtido via `/auth/signup/totp/verify`. TOTP deve ter sido verificado.
- **Response** (200):
```json
{
  "success": true,
  "message": "Onboarding passkey options generated",
  "data": "{ PublicKeyCredentialCreationOptions JSON string }"
}
```

### 1.11 Passkey — Onboarding Register Finish
- **URL**: `POST /auth/passkey/register/onboarding/finish?sessionId={sessionId}`
- **Auth**: Nenhuma (usa `sessionId` do Redis)
- **Request Body**: Raw JSON string do Authenticator response.
- **Descrição**: Salva a Passkey temporariamente no Redis. A inserção no DB ocorrerá apenas após 3 confirmações do pagamento de Onboarding.
- **Response** (200):
```json
{
  "success": true,
  "message": "Passkey attached to Onboarding Session",
  "data": "OK"
}
```

### 1.12 Recuperação de Passkey (Dispositivo perdido)
Se o usuário perder a Passkey (ex.: YubiKey perdido, celular roubado):

1. Frontend tenta biometria/passkey → falha no client-side (credential not found).
2. Fallback: `POST /auth/login` com `username` + `passphrase`.
3. Em seguida: `POST /auth/login/totp/verify` com `username` + `totpCode`.
4. Com o JWT recebido, registrar nova Passkey via `/auth/passkey/register/start` → `/auth/passkey/register/finish`.

---

## 2. Wallet Management (`/wallet`)

> Todas as operações de wallet exigem `Authorization: Bearer <token>`.
> O nome da carteira é **always stored in UPPERCASE**. Enviar `"minhacarteira"` resulta em armazenamento como `"MINHACARTEIRA"`.

### 2.1 Create Wallet
- **URL**: `POST /wallet/create`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Request Body**:
```json
{
  "name": "minhacarteira",
  "passphrase": "abandon ability able about above absent absorb abstract absurd abuse access accident..."
}
```

| Campo | Tipo | Obrigatório | Regras |
|---|---|---|---|
| `name` | string | ✅ | 3–50 caracteres. Será convertido para UPPERCASE. Único por usuário. |
| `passphrase` | string | ✅ | **Deve ser um mnemônico BIP39 válido** (EN ou PT-BR, 12/15/18/21/24 palavras). Esta é a passphrase da **carteira** (chave de criptografia), NÃO a passphrase de login. |

> ⚠️ **IMPORTANTE**: A passphrase da wallet passa pela mesma validação BIP39 do signup. Se a passphrase não for um mnemônico válido, o endpoint retorna erro `ERR_AUTH_INVALID_PASSPHRASE_FORMAT`.

- **Response** (201 Created):
```json
{
  "success": true,
  "message": "Awesome! Your wallet was successfully created and is ready to store funds.",
  "data": "Awesome! Your wallet was successfully created and is ready to store funds."
}
```

### 2.2 Get All Wallets
- **URL**: `GET /wallet/all`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Successfully retrieved all your wallets.",
  "data": [
    {
      "id": 1,
      "name": "MINHACARTEIRA",
      "passphraseHash": "sha256hash...",
      "createdAt": "2026-03-01T12:00:00",
      "updatedAt": "2026-03-01T12:00:00",
      "isActive": true
    }
  ]
}
```

### 2.3 Find Wallet by Name
- **URL**: `GET /wallet/find?name=minhacarteira`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Query Param**: `name` (string, obrigatório)
- **Response** (200):
```json
{
  "success": true,
  "message": "Wallet successfully located.",
  "data": {
    "id": 1,
    "name": "MINHACARTEIRA",
    "passphraseHash": "sha256hash...",
    "createdAt": "2026-03-01T12:00:00",
    "updatedAt": null,
    "isActive": true
  }
}
```

### 2.4 Update Wallet Name
- **URL**: `PUT /wallet/update`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Request Body**:
```json
{
  "name": "MINHACARTEIRA",
  "newName": "INVESTIMENTOS",
  "passphrase": "abandon ability able..."
}
```

| Campo | Tipo | Obrigatório | Regras |
|---|---|---|---|
| `name` | string | ✅ | Nome atual da carteira |
| `newName` | string | ✅ | Novo nome, 3–50 chars |
| `passphrase` | string | ✅ | Passphrase BIP39 para autorizar a alteração |

- **Response** (200):
```json
{
  "success": true,
  "message": "Your wallet details have been successfully updated.",
  "data": "Your wallet details have been successfully updated."
}
```

### 2.5 Delete Wallet
- **URL**: `DELETE /wallet/delete`
- **Auth**: `Authorization: Bearer <token>` ✅
- **Request Body**:
```json
{
  "name": "INVESTIMENTOS",
  "passphrase": "abandon ability able..."
}
```

| Campo | Tipo | Obrigatório |
|---|---|---|
| `name` | string | ✅ |
| `passphrase` | string | ✅ (deve corresponder ao hash armazenado na criação) |

- **Response** (200):
```json
{
  "success": true,
  "message": "Wallet successfully permanently deleted.",
  "data": "Wallet successfully permanently deleted."
}
```

---

## 3. Ledger & Financials (`/ledger`)

> Todos os endpoints exigem `Authorization: Bearer <token>`.

### 3.1 Process Internal Transaction
- **URL**: `POST /ledger/transaction`
- **Auth**: ✅
- **Request Body**:
```json
{
  "sender": "MINHA_CARTEIRA",
  "receiver": "username_amigo",
  "amount": 0.05123,
  "context": "Pagamento do jantar"
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Transaction successfully processed and ledger has been updated.",
  "data": {
    "sender": "MINHA_CARTEIRA",
    "receiver": "username_amigo",
    "amount": 0.05123,
    "context": "Pagamento do jantar"
  }
}
```

### 3.2 Get Transaction History
- **URL**: `GET /ledger/history`
- **Auth**: ✅
- **Descrição**: Retorna as últimas 100 transações do usuário autenticado.
- **Response** (200):
```json
{
  "success": true,
  "message": "Transaction history (last 100 entries) retrieved successfully.",
  "data": [
    {
      "id": "uuid-da-transacao",
      "senderIdentifier": "MINHA_CARTEIRA",
      "senderUserId": 1,
      "receiverIdentifier": "amigo_username",
      "receiverUserId": 2,
      "transactionType": "INTERNAL",
      "amount": 0.05000000,
      "status": "CONCLUDED",
      "networkFee": null,
      "blockchainTxid": null,
      "context": "Pagamento do jantar",
      "createdAt": "2026-03-01T15:00:00"
    }
  ]
}
```

### 3.3 Get All Ledgers
- **URL**: `GET /ledger/all`
- **Auth**: ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Successfully retrieved all ledgers associated with your account.",
  "data": [
    {
      "id": 1,
      "walletId": 1,
      "walletName": "MINHACARTEIRA",
      "balance": 1.25000000,
      "nonce": 3,
      "lastHash": "a3f5d2...",
      "context": "Pagamento recebido"
    }
  ]
}
```

### 3.4 Find Ledger by Wallet Name
- **URL**: `GET /ledger/find?walletName=MINHACARTEIRA`
- **Auth**: ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Ledger details successfully retrieved.",
  "data": {
    "id": 1,
    "walletId": 1,
    "walletName": "MINHACARTEIRA",
    "balance": 1.25000000,
    "nonce": 3,
    "lastHash": "a3f5d2...",
    "context": "Último contexto"
  }
}
```

### 3.5 Get Balance
- **URL**: `GET /ledger/balance?walletName=MINHACARTEIRA`
- **Auth**: ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Current balance successfully retrieved.",
  "data": 1.25000000
}
```

### 3.6 Delete Ledger
- **URL**: `DELETE /ledger/delete?walletName=MINHACARTEIRA`
- **Auth**: ✅
- **Response** (200):
```json
{
  "success": true,
  "message": "Ledger successfully completely removed from the system."
}
```

### 3.7 Create Internal Payment Request (Link de Pagamento)
- **URL**: `POST /ledger/payment-request`
- **Auth**: ✅
- **Request Body**:
```json
{
  "amount": 0.0125,
  "receiverWalletName": "MINHA_CARTEIRA"
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Payment request link created successfully.",
  "data": {
    "id": "link-uuid-1234",
    "requesterUserId": 1,
    "receiverWalletName": "MINHA_CARTEIRA",
    "amount": 0.0125,
    "status": "PENDING",
    "expiresAt": "2026-03-01T18:00:00",
    "createdAt": "2026-03-01T17:00:00",
    "paidAt": null
  }
}
```

> **WebSocket**: Após criar, o frontend deve assinar `/topic/payment-request/{id}` via STOMP para receber a notificação de pagamento em tempo real.

### 3.8 Retrieve Payment Request
- **URL**: `GET /ledger/payment-request/{linkId}`
- **Auth**: ✅
- **Response** (200): Mesmo formato do 3.7

### 3.9 Pay Payment Request
- **URL**: `POST /ledger/payment-request/{linkId}/pay`
- **Auth**: ✅
- **Request Body**:
```json
{
  "payerWalletName": "CARTEIRA_PAGADORA"
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Payment successful.",
  "data": {
    "id": "link-uuid-1234",
    "requesterUserId": 1,
    "receiverWalletName": "MINHA_CARTEIRA",
    "amount": 0.0125,
    "status": "PAID",
    "expiresAt": "2026-03-01T18:00:00",
    "createdAt": "2026-03-01T17:00:00",
    "paidAt": "2026-03-01T17:30:00"
  }
}
```

> **Efeito colateral**: Dispara push WebSocket em `/topic/payment-request/{linkId}` com status `PAID`.

---

## 4. On-Chain Bitcoin Transactions (`/transactions`)

> Todos os endpoints exigem `Authorization: Bearer <token>`.

### 4.1 Get Deposit Address
- **URL**: `GET /transactions/deposit-address`
- **Response** (200):
```json
{
  "success": true,
  "message": "Success",
  "data": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
}
```

### 4.2 Estimate Network Fee
- **URL**: `GET /transactions/estimate-fee?amount=1.5`
- **Response** (200):
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "fastSatoshisPerByte": 30,
    "standardSatoshisPerByte": 15,
    "slowSatoshisPerByte": 5,
    "estimatedFastBtc": 0.00008500,
    "estimatedStandardBtc": 0.00004250,
    "estimatedSlowBtc": 0.00001400,
    "amountReceived": 1.5,
    "totalToSend": 1.50004250
  }
}
```

### 4.3 Create Unsigned Transaction
- **URL**: `POST /transactions/create-unsigned`
- **Request Body**:
```json
{
  "toAddress": "bc1...",
  "amount": 0.5,
  "feeLevel": "fast"
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Unsigned transaction created",
  "data": {
    "rawTxHex": "0100000001...",
    "txId": "sha256-hash",
    "inputs": [],
    "outputs": [],
    "totalAmount": 0.5,
    "fee": 5000,
    "fromAddress": "bc1...",
    "toAddress": "bc1..."
  }
}
```

### 4.4 Broadcast Signed Transaction
- **URL**: `POST /transactions/broadcast`
- **Request Body**:
```json
{
  "signedTxHex": "0100000001tx1234..."
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Transaction broadcasted to mempool",
  "data": {
    "txid": "hash-da-transacao",
    "status": "broadcasted",
    "feeSatoshis": 5000,
    "amountReceived": 0.5
  }
}
```

### 4.5 On-Chain Withdrawal
- **URL**: `POST /transactions/withdraw`
- **Request Body**:
```json
{
  "fromWalletName": "MINHACARTEIRA",
  "toAddress": "bc1_destino...",
  "amount": 0.1,
  "description": "Retirada externa"
}
```

- **Response** (200):
```json
{
  "success": true,
  "message": "Withdrawal sent to blockchain",
  "data": {
    "txid": "hash-on-chain",
    "status": "broadcasted",
    "feeSatoshis": 3000,
    "amountReceived": 0.10000000
  }
}
```

---

## 5. WebSockets (`/ws`)

### Conexão
| Tipo | URL |
|---|---|
| SockJS | `ws://host/ws/balance` |
| Raw WebSocket | `ws://host/ws/raw-balance` |
| Payment Request SockJS | `ws://host/ws/payment-request` |
| Payment Request Raw | `ws://host/ws/raw-payment-request` |

### Autenticação
- **Query param**: `?token=<jwt_token>`
- **OU** header STOMP: `Authorization: Bearer <token>` no frame CONNECT

### 5.1 Real-time Balance Updates
- **Subscribe**: `/user/queue/balance`
- **Payload**:
```json
{
  "walletId": 1,
  "walletName": "MINHA_CARTEIRA",
  "userId": 42,
  "newBalance": 1.55000000,
  "amount": 0.05000000,
  "context": "Pagamento do jantar"
}
```

### 5.2 Payment Request Notifications
- **Subscribe**: `/topic/payment-request/{linkId}`
- **Payload** (quando pago):
```json
{
  "id": "link-uuid-1234",
  "requesterUserId": 1,
  "receiverWalletName": "MINHA_CARTEIRA",
  "amount": 0.0125,
  "status": "PAID",
  "paidAt": "2026-03-01T17:30:00"
}
```

**Exemplo Flutter/Dart:**
```dart
stompClient.subscribe(
  destination: '/topic/payment-request/$linkId',
  callback: (frame) {
    final req = jsonDecode(frame.body!);
    if (req['status'] == 'PAID') {
      // Exibir confirmação de pagamento
    }
  },
);
```

---

## 6. Merkle Audit (`/audit`)

> Todos os endpoints exigem `Authorization: Bearer <token>`.

### 6.1 Get Latest Merkle Root
- **URL**: `GET /audit/latest-root`
- **Response** (200):
```json
{
  "id": "uuid-do-checkpoint",
  "merkleRoot": "a3f5d2e1b4c8...",
  "ledgerCount": 42,
  "createdAt": "2026-02-25T16:00:00",
  "anchorTxid": ""
}
```

### 6.2 Get Audit History
- **URL**: `GET /audit/history?limit=10`
- **Query Params**: `limit` (opcional, default 10, máximo 50)
- **Response** (200): Array de checkpoint objects.

### 6.3 Trigger Manual Audit
- **URL**: `POST /audit/trigger`
- **Auth**: ✅ (role `ADMIN` obrigatória)
- **Response** (200): Checkpoint object.

---

## 7. Voucher & Onboarding (`/voucher`)

> Todos os endpoints de voucher são **públicos** (sem JWT).

### 7.1 Generate Onboarding Payment Link
- **URL**: `POST /voucher/onboarding-link?sessionId={sessionId}`
- **Auth**: Nenhuma (usa `sessionId` do Redis)
- **Descrição**: Gera link de pagamento cobrando uma taxa fixa de entrada (ex: 0.0003 BTC). Retorna o valor exato a ser pago em satoshis.
- **Response** (200):
```json
{
  "success": true,
  "message": "Onboarding Payment Link generated successfully.",
  "data": {
    "id": "pay_3b2f91e98d8c",
    "userId": 12,
    "amountBtc": 0.00030250,
    "description": "ONBOARDING_VOUCHER",
    "depositAddress": "1A1z7agoat7F...",
    "status": "pending",
    "createdAt": "2026-02-28T14:32:00Z",
    "expiresAt": "2026-02-28T15:32:00Z",
    "paidAt": null,
    "completedAt": null,
    "txid": null
  }
}
```

> **Fluxo**: O usuário paga o valor exato no endereço. O backend monitora a blockchain aguardando **3 confirmações**. Após confirmação, o utarget é salvo no PostgreSQL (`isActive=true`) e uma notificação WebSocket é pelas.

### 7.2 Request Voucher
- **URL**: `POST /voucher/request`
- **Descrição**: Solicita dados de pagamento para Voucher de pré-depósito.
- **Response** (200):
```json
{
  "success": true,
  "message": "Voucher requested. Please send the exact amount of satoshis...",
  "data": {
    "depositAddress": "bc1qxy2kgdygjrsqtzq2n0yrf249x3p...",
    "amountSats": 100000,
    "pendingVoucherId": "pend_vch_192e21b8..."
  }
}
```

### 7.3 Confirm Voucher Payment
- **URL**: `POST /voucher/confirm?pendingVoucherId={..}&txid={..}`
- **Response** (200):
```json
{
  "success": true,
  "message": "Voucher paid and confirmed successfully.",
  "data": "VCH-A8B9C1-D2E3F4"
}
```

### 7.4 Verify Voucher
- **URL**: `GET /voucher/verify?code={codigo}`
- **Response** (200):
```json
{
  "success": true,
  "message": "Voucher is valid.",
  "data": {
    "code": "VCH-A8B9C1-D2E3F4",
    "valueBtc": 0.015,
    "status": "UNUSED",
    "expiresAt": "2026-03-01T23:59:59"
  }
}
```

---

## 8. Notifications (`/notifications`)

### 8.1 Send Push Notification (Internal/Admin)
- **URL**: `POST /notifications/send`
- **Auth**: ✅
- **Request Body**:
```json
{
  "userId": "42",
  "title": "Título da Notificação",
  "body": "Corpo da mensagem"
}
```

| Campo | Tipo | Obrigatório |
|---|---|---|
| `userId` | string | ✅ (ID numérico como string) |
| `title` | string | ✅ |
| `body` | string | ✅ |

- **Response** (200):
```json
{
  "success": true,
  "message": "Push notification has been successfully dispatched to the target user."
}
```

---

## 📐 Fluxo Completo de Onboarding (Novo Usuário)

```
1. GET  /auth/pow/challenge                          → challenge
2. POST /auth/signup   { username, passphrase, challenge, nonce }  → otpauth URI
3. POST /auth/signup/totp/verify  { username, totpCode } → sessionId
4. POST /auth/passkey/register/onboarding/start?sessionId=...     → WebAuthn options
5. POST /auth/passkey/register/onboarding/finish?sessionId=...    → OK
6. POST /voucher/onboarding-link?sessionId=...       → payment link
7. Usuário paga on-chain → 3 confirmações → conta ativada (isActive=true)
```

## 📐 Fluxo de Login Padrão (TOTP)

```
1. POST /auth/login  { username, passphrase }        → "userId token"
2. POST /auth/login/totp/verify  { username, totpCode }  → "userId token"
3. Usar token JWT em todos os endpoints protegidos
```

## 📐 Fluxo de Login via Passkey (Bypass TOTP)

```
1. POST /auth/passkey/login/start?username=...       → assertion options
2. POST /auth/passkey/login/finish?username=... { response JSON }  → JWT token
3. Usar token JWT em todos os endpoints protegidos
```

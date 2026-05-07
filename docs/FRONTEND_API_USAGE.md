# Uso da API pelo Frontend

Este guia define quais endpoints a UI deve consumir, com os parametros minimos esperados em cada fluxo. A referencia completa de controllers, DTOs e erros fica em [API_REFERENCE.md](API_REFERENCE.md).

## Contrato Base

- Use `AppConfig.apiUrl` como base da API. Web admin deve apontar para a origem HTTP real; mobile/desktop podem usar relay local Tor conforme `TokenInterceptor`.
- Todas as chamadas REST devem passar por `ApiClient`, com `Content-Type: application/json` e `Accept: application/json`.
- O backend normalmente responde `ApiResponse<T>`. `ApiResponseInterceptor` remove o envelope e entrega somente `data`; nao duplique parsing de `success/message` na UI, exceto rotas raw de `/audit`.
- JWT vai em `Authorization: Bearer <jwt>`. O cliente deve persistir `X-New-Token` quando vier na resposta.
- Nao envie JWT, passphrase, TOTP, backup code, seed, macaroon, token admin ou material de assinatura em query string ou logs.
- O body maximo aceito pelo filtro de seguranca e 2 KB. Campos grandes, arquivos e dumps devem ser rejeitados na UI antes do envio.
- Operacoes financeiras mutaveis precisam de `idempotencyKey` unico gerado no cliente. Use UUID v4 e envie no body quando o DTO pedir; somente `POST /transactions/payment-link/{linkId}/complete` usa header `Idempotency-Key`.
- Codigos esperados: `401/403` sessao/permissao, `400` validacao, `402` saldo insuficiente, `409` conflito/idempotencia, `410` expirado, `422` replay/rate limit/fator, `503` provider indisponivel.

## Mapa por UI

| UI/Fluxo | Endpoints que deve usar | Observacoes |
| --- | --- | --- |
| Landing publica `/` | `GET /api/public/mobile-download`, `GET /system/release`, `GET /health/ready` | Somente status publico e metadados sem segredo. |
| Download `/download` | `GET /api/public/mobile-download` | Renderizar links Android/iOS, versao, changelog, hash e assinatura. |
| Status publico `/status` | `GET /health/ready`, `GET /system/release` | Mostrar degradacao sem expor stack trace ou config. |
| Login/signup | `/auth/pow/challenge`, `/auth/signup`, `/auth/signup/totp/verify`, `/auth/login`, `/auth/login/totp/verify`, `/auth/passkey/*` | Rotas publicas; nao anexar JWT. |
| Home/wallet | `GET /auth/me`, `GET /wallet/all`, `GET /ledger/history`, `GET /transactions/network/transfers` | Atualizar saldos e eventos efemeros; historico legivel duravel fica no storage local criptografado. |
| Receber BTC | `GET /transactions/network/wallet-profile`, `POST /transactions/network/onchain/address`, `POST /transactions/network/lightning/invoice`, `POST /transactions/create-payment-link` | Preferir as rotas `network/*`; nao usar API publica de blockchain no app. |
| Enviar BTC | `POST /ledger/transaction`, `POST /transactions/network/onchain/send`, `POST /transactions/network/lightning/pay` | Enviar fatores conforme `/auth/security/profile`. |
| Payment requests | `POST /ledger/payment-request`, `GET /ledger/payment-request/{linkId}`, `POST /ledger/payment-request/{linkId}/pay` | Link interno protegido por JWT na security atual. |
| Mining | `GET /mining/rigs`, `POST /mining/allocations`, `GET /mining/allocations`, `POST /mining/allocations/{id}/cancel` | Mesma matriz de fatores transacionais. |
| Painel admin | `GET /api/admin/operations/*`, `GET /system/release`, `GET /v1/audit/stats`, `GET /audit/history` | Exige JWT/admin; logs devem permanecer saneados. |

## Autenticacao e Conta

### Signup

1. `GET /auth/pow/challenge`
2. `POST /auth/signup`

```json
{
  "username": "alice",
  "password": "frase bip39",
  "challenge": "challenge",
  "nonce": "nonce",
  "accountSecurity": "STANDARD"
}
```

3. `POST /auth/signup/totp/verify`

```json
{
  "sessionId": "signup-session-id",
  "totpCode": "123456"
}
```

4. Para passkey de onboarding, use `POST /auth/passkey/onboarding/start` e `POST /auth/passkey/onboarding/finish`.

### Login

1. `POST /auth/login`

```json
{
  "username": "alice",
  "password": "frase bip39"
}
```

2. `POST /auth/login/totp/verify`

```json
{
  "preAuthToken": "uuid",
  "totpCode": "123456"
}
```

3. Depois do JWT, carregar `GET /auth/me`, `GET /auth/security/profile`, `GET /auth/security-status` e `GET /auth/activation-status`.

Para ativacao de conta, a UI deve usar `POST /auth/activation-status/deposit-link` para gerar o link e `POST /auth/activation-status/{linkId}/confirm` com `txid`, `fromAddress` e `idempotencyKey`.

## Wallet e Ledger

| Acao | Endpoint | Parametros |
| --- | --- | --- |
| Criar wallet | `POST /wallet/create` | `{ "name": "Main", "passphrase": "..." }` |
| Listar wallets | `GET /wallet/all` | Sem body |
| Buscar wallet | `GET /wallet/find?name=Main` | Query `name` |
| Renomear wallet | `PUT /wallet/update` | `{ "name": "Main", "newName": "Treasury", "passphrase": "..." }` |
| Excluir wallet | `DELETE /wallet/delete` | `{ "name": "Treasury", "passphrase": "..." }` |
| Saldo | `GET /ledger/balance?walletName=Main` | Query `walletName` |
| Sincronizacao efemera | `GET /ledger/history?page=0&size=50` | `size` maximo 100; resposta saneada sem contraparte, contexto livre ou txid completo |

Transacao interna:

```json
{
  "sender": "Main",
  "receiver": "bob",
  "amount": 0.0001,
  "context": "payment",
  "idempotencyKey": "uuid-v4",
  "requestTimestamp": 1775500000000,
  "totpCode": null,
  "passkeyAssertionJson": "{}",
  "confirmationPassphrase": null
}
```

`receiver` pode ser username, `walletId`, endereco de wallet ou `destinationHash` de payment request.

## Recebimento On-Chain e Lightning

Perfil da carteira:

```http
GET /transactions/network/wallet-profile?walletName=Main
```

Gerar endereco on-chain dedicado:

```http
POST /transactions/network/onchain/address
```

```json
{
  "walletName": "Main",
  "expectedAmountBtc": 0.0015
}
```

Cada chamada cria um endereco novo e rastreado para aquele deposito. A UI nao deve oferecer opcao de regenerar/reutilizar: se o usuario iniciar outro deposito, chame o endpoint novamente. O backend grava `expectedAmountBtc`, observa quanto realmente entrou no endereco e credita o saldo liquido pelo valor observado on-chain.

Se o valor observado divergir de `expectedAmountBtc`, a operacao continua sendo liquidada pelo valor real recebido, mas o painel deve exibir a divergencia e o backend registra evento operacional `INBOUND_AMOUNT_MISMATCH`.

Criar invoice Lightning:

```http
POST /transactions/network/lightning/invoice
```

```json
{
  "walletName": "Main",
  "amount": 0.0015,
  "memo": "deposito lightning",
  "expiresInSeconds": 900
}
```

Mostrar historico de entradas e saidas externas com:

```http
GET /transactions/network/transfers
GET /transactions/network/transfers/{transferId}
POST /transactions/network/transfers/{transferId}/cancel
```

Onramp deve usar `GET /api/onramp/urls?walletName=Main&amountBtc=0.01` quando a UI precisar abrir providers externos.

## Envio On-Chain e Lightning

Antes de enviar, carregar `GET /auth/security/profile` e solicitar apenas os fatores necessarios. Em geral, `STANDARD` e `PASSKEY` usam passkey; `SHAMIR` e `MULTISIG_2FA` exigem TOTP; `MULTISIG_2FA` pode exigir tambem passkey ou passphrase de confirmacao.

Envio on-chain:

```http
POST /transactions/network/onchain/send
```

```json
{
  "idempotencyKey": "uuid-v4",
  "fromWalletName": "Main",
  "toAddress": "bc1q...",
  "amount": 0.015,
  "description": "saque externo",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "confirmationPassphrase": null
}
```

Pagamento Lightning:

```http
POST /transactions/network/lightning/pay
```

```json
{
  "idempotencyKey": "uuid-v4",
  "fromWalletName": "Main",
  "paymentRequest": "lnbc...",
  "amount": 0.0005,
  "maxRoutingFeeBtc": 0.000001,
  "description": "pagamento lightning",
  "totpCode": null,
  "passkeyAssertionResponseJSON": "{}",
  "confirmationPassphrase": null
}
```

`POST /transactions/withdraw` existe por retrocompatibilidade; novas telas devem preferir `/transactions/network/onchain/send`.

## Payment Links

Criar link Bitcoin externo:

```http
POST /transactions/create-payment-link
```

```json
{
  "amount": 0.00022,
  "description": "Invoice ABC"
}
```

Confirmar pagamento on-chain autenticado:

```http
POST /transactions/payment-link/{linkId}/confirm
```

```json
{
  "txid": "bitcoin-txid",
  "idempotencyKey": "uuid-v4",
  "fromAddress": "bc1q..."
}
```

Concluir link ja pago:

```http
POST /transactions/payment-link/{linkId}/complete
Idempotency-Key: uuid-v4
```

Listagem: `GET /transactions/payment-links`.

Payment request interno:

```http
POST /ledger/payment-request
GET /ledger/payment-request/{linkId}
POST /ledger/payment-request/{linkId}/pay
```

Body de pagamento:

```json
{
  "payerWalletName": "Main",
  "idempotencyKey": "uuid-v4",
  "totpCode": null,
  "passkeyAssertionJson": "{}",
  "confirmationPassphrase": null
}
```

## Painel Admin e Monitoramento

O painel empresarial deve consumir apenas endpoints administrativos autenticados:

| Secao | Endpoint | Campos de UI |
| --- | --- | --- |
| Overview | `GET /api/admin/operations/overview` | readiness geral, dependencias, metricas, resumo blockchain, Lightning, Vault e release |
| Health | `GET /api/admin/operations/health` | banco, Redis, Vault, Bitcoin Core, LND, attestation |
| Blockchain | `GET /api/admin/operations/blockchain` | rede, altura, hash do bloco, dificuldade, mempool, fees, sync, txs relevantes |
| Lightning | `GET /api/admin/operations/lightning` | sync LND, altura, peers, canais, balances e ultimo erro |
| Vault Raft | `GET /api/admin/operations/vault-raft` | quorum, leader, followers, seal/unseal e health |
| Release | `GET /api/admin/operations/release` | versao, commit, build time, image digest, manifesto autorizado |
| Mobile | `GET /api/admin/operations/mobile` | versao Android/iOS, changelog, hashes, assinatura |
| Logs | `GET /api/admin/operations/logs?limit=50` | eventos saneados; limite default 50 |

Nunca chamar APIs publicas de blockchain como fonte primaria da UI. O monitoramento deve vir do backend, que consulta Bitcoin Core mainnet pruned por RPC/ZMQ e LND por gRPC.

## Mining

Listar ofertas:

```http
GET /mining/rigs
```

Criar alocacao:

```http
POST /mining/allocations
```

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

Consultar e cancelar:

```http
GET /mining/allocations
GET /mining/allocations/{allocationId}
POST /mining/allocations/{allocationId}/cancel
```

## Auditoria, Soberania e Notificacoes

- Proof of reserves: `GET /v1/audit/stats`, `GET /audit/latest-root`, `GET /audit/history?limit=10`. `POST /audit/trigger` exige `ROLE_ADMIN`.
- Soberania comum: `GET /sovereignty/status` e `GET /sovereignty/ping` estao `permitAll` na security atual; app logado pode enviar JWT normalmente, mas a UI publica nao deve exibir dados internos.
- Soberania operacional: `GET /sovereignty/telemetry` e `POST /sovereignty/reattest` exigem JWT e `X-Admin-Token`; nao usar em UI comum.
- Notificacoes persistidas ainda tem controller REST apenas para `POST /notifications/send`. Para inbox, usar WebSocket `/user/{userId}/queue/notifications` ou storage local ate existir controller de list/read.

## Endpoints que a UI deve evitar

- `/transactions/deposit-address`: legado; preferir `/transactions/network/onchain/address`.
- `/transactions/withdraw`: legado; preferir `/transactions/network/onchain/send`.
- `/transactions/create-unsigned`, `/transactions/broadcast`, `/transactions/status`: telas novas nao devem montar/broadcastar transacao manual sem fluxo especifico de assinatura.
- `/voucher/**`: permitido na security, mas sem controller ativo neste snapshot.
- `/notifications` e `/notifications/{id}/read`: constantes existem no frontend, mas o backend atual documentado so implementa `POST /notifications/send`.
- `/sovereignty/telemetry` e `/sovereignty/reattest`: somente admin/operator com `X-Admin-Token`; nao expor em app de usuario.

## Gaps atuais do frontend

- `LedgerRemoteDataSource.sendInternalTransaction` envia `X-Idempotency-Key`, mas `POST /ledger/transaction` exige `idempotencyKey` no body.
- `TransactionRemoteDataSource.withdraw` chama envios on-chain/Lightning sem garantir `idempotencyKey`; os DTOs `OnchainSendRequestDTO` e `LightningPaymentRequestDTO` exigem esse campo.
- `TransactionRemoteDataSource.cancelInboundTransfer` usa `/deposit/{transferId}/cancel`; a rota preferencial nova e `POST /transactions/network/transfers/{transferId}/cancel`.
- `SecurityRemoteDataSource` chama `/sovereignty/telemetry` e `/sovereignty/reattest` sem `X-Admin-Token`; a UI admin deve fornecer o header ou ocultar essas acoes.
- A inbox de notificacoes chama `GET /notifications` e `PUT /notifications/{id}/read`, mas esses endpoints nao estao implementados no controller atual.

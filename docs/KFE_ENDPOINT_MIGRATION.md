# KFE Endpoint Migration

Este documento define a substituicao dos endpoints financeiros legados pelo
Kerosene Financial Engine (KFE).

Por padrao, os controllers financeiros antigos nao sao registrados no Spring.
Eles so voltam em rollback/debug se a aplicacao iniciar com:

```properties
kfe.legacy-financial.enabled=true
```

O novo contrato publico deve usar apenas `/kfe/...`.

## Modelo Atual

O KFE substitui os dominios publicos de `wallet`, `bitcoinaccounts`, `ledger`,
`payments`, `transactions` e partes financeiras de `treasury`.

Regras aplicadas:

- Postgres e a fonte soberana de estado financeiro.
- Toda transacao passa por idempotencia, validacao, quorum, lock, execucao e settlement.
- Quorum exige 100% dos servidores saudaveis e atestados, com minimo de 2.
- Menos de 2 servidores saudaveis bloqueia writes financeiros.
- `INTERNAL` nao cobra taxa.
- On-chain inbound e outbound cobram taxa fixa de 0.9%.
- `WATCH_ONLY` aparece como observado, separado do saldo gastavel.
- Extrato legivel no backend expira em 24 horas.
- Auditoria permanente guarda hashes, estados e metadados minimos, sem valores sensiveis em claro.
- Execucao externa on-chain/LN sai exclusivamente por `financial_execution_outbox`.

## Endpoints Substituidos

| Legado | Status | Novo endpoint |
|---|---:|---|
| `POST /wallet/create` | Desativado | `POST /kfe/wallets` |
| `GET /wallet/all` | Desativado | `GET /kfe/wallets` ou `GET /kfe/dashboard` |
| `GET /wallet/find` | Desativado | `GET /kfe/wallets` |
| `PUT /wallet/update` | Desativado | Futuro endpoint KFE de metadata/status |
| `DELETE /wallet/delete` | Desativado | Futuro arquivamento KFE |
| `GET /ledger/balance` | Desativado | `GET /kfe/dashboard` |
| `GET /ledger/history` | Desativado | `GET /kfe/dashboard` com `recentStatement` |
| `POST /ledger/transaction` | Desativado | `POST /kfe/transactions` com `rail=INTERNAL` |
| `POST /payments/quote` | Desativado | `POST /kfe/transactions` calcula pricing no engine |
| `POST /payments/{id}/confirm` | Desativado | `POST /kfe/transactions` idempotente |
| `GET /payments/{id}` | Desativado | `GET /kfe/transactions/{transactionId}` |
| `POST /transactions/network/onchain/address` | Desativado | `POST /kfe/wallets/{walletId}/addresses/rotate` |
| `POST /transactions/network/onchain/send` | Desativado | `POST /kfe/transactions` com `rail=ONCHAIN`, `direction=OUTBOUND` |
| `POST /transactions/network/lightning/pay` | Desativado | `POST /kfe/transactions` com `rail=LIGHTNING`, `direction=OUTBOUND` |
| `POST /transactions/network/lightning/invoice` | Desativado | Futuro adapter KFE sobre `financial_execution_outbox` |
| `GET /transactions/network/transfers` | Desativado | `GET /kfe/dashboard` e `GET /kfe/transactions/{id}` |
| `POST /bitcoin/accounts/internal-card` | Desativado | `POST /kfe/wallets` com `kind=INTERNAL` |
| `POST /bitcoin/accounts/cold-wallet` | Desativado | `POST /kfe/wallets` com `kind=WATCH_ONLY` |
| `POST /bitcoin/accounts/{id}/internal-card/permanent-address` | Desativado | `POST /kfe/wallets/{walletId}/addresses/rotate` ou `initialAddress` |
| `GET /audit/latest-root`, `GET /audit/history` | Desativado | `GET /api/admin/kfe/audit/latest` |
| `GET /v1/audit/*` | Desativado | `GET /api/admin/kfe/audit/events` e `POST /api/admin/kfe/audit/root` |
| `GET /treasury/overview` | Desativado | Futuro dashboard operacional KFE/admin |

## Criar Wallet

Endpoint:

```http
POST /kfe/wallets
Authorization: Bearer <jwt>
Content-Type: application/json
```

### INTERNAL

Use para saldo L2 interno. Sem taxa.

```json
{
  "kind": "INTERNAL",
  "label": "Main",
  "initialAddress": "bc1q...",
  "issueInitialAddress": false
}
```

Campos:

- `kind`: `INTERNAL`.
- `label`: nome visivel.
- `initialAddress`: opcional; fixa um endereco inicial ja conhecido.
- `xpub`: opcional; necessario para rotacao automatica de enderecos.
- `issueInitialAddress`: se `true`, o KFE tenta derivar um endereco a partir do `xpub`.

Observacao: rotacao dinamica exige `xpub`. Sem `xpub`, a wallet pode existir
como L2 pura e receber endereco depois por `initialAddress` em nova criacao ou
por endpoint futuro de importacao de endereco.

### CUSTODIAL_ONCHAIN

Use para wallet on-chain com chave sob MPC/Vault.

```json
{
  "kind": "CUSTODIAL_ONCHAIN",
  "label": "Vault BTC",
  "xpub": "xpub...",
  "issueInitialAddress": true
}
```

Comportamento:

- KFE cria a wallet em `CREATING`.
- KFE exige quorum saudavel e unanime.
- KFE solicita keygen ao MPC sidecar.
- KFE grava `mpcPublicKey` e ativa a wallet.
- Se `issueInitialAddress=true`, deriva o primeiro endereco pelo `xpub`.

Limite atual: o sidecar MPC existente retorna chave publica, mas ainda nao
retorna XPUB nativo. Por isso o request exige `xpub` ate o sidecar expor
geracao HD completa.

### WATCH_ONLY

Use para monitorar XPUB/descriptor externo. Nao e gastavel.

```json
{
  "kind": "WATCH_ONLY",
  "label": "Cold Storage",
  "xpub": "xpub...",
  "fingerprint": "abcd1234",
  "derivationPath": "m/84'/0'/0'"
}
```

Regras:

- `xpub` ou `descriptor` e obrigatorio.
- `spendable=false`.
- Saldo entra em `observedSats`, separado do total gastavel.

## Listar Wallets

```http
GET /kfe/wallets
Authorization: Bearer <jwt>
```

Resposta:

```json
{
  "success": true,
  "message": "KFE wallets retrieved.",
  "data": [
    {
      "id": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
      "kind": "INTERNAL",
      "status": "ACTIVE",
      "label": "Main",
      "asset": "BTC",
      "spendable": true,
      "xpubConfigured": false,
      "mpcKeyConfigured": false,
      "activeAddress": "bc1q...",
      "createdAt": "2026-06-11T15:00:00",
      "updatedAt": "2026-06-11T15:00:00"
    }
  ]
}
```

## Rotacionar Endereco

```http
POST /kfe/wallets/{walletId}/addresses/rotate
Authorization: Bearer <jwt>
```

Comportamento:

- Exige wallet `ACTIVE`.
- Bloqueia `WATCH_ONLY`.
- Envia proposta ao quorum.
- Marca enderecos ativos anteriores como `RETIRED`.
- Deriva novo endereco pelo `xpub`.

Resposta:

```json
{
  "success": true,
  "message": "KFE wallet address rotated.",
  "data": {
    "id": "8f5b41b2-c808-4703-a158-698a07b37b21",
    "walletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
    "address": "bc1q...",
    "role": "RECEIVE",
    "status": "ACTIVE",
    "derivationPath": "m/84'/0'/0'/0/1",
    "derivationIndex": 1,
    "providerReference": "KFE_XPUB_DERIVATION"
  }
}
```

## Dashboard Unificado

```http
GET /kfe/dashboard
Authorization: Bearer <jwt>
```

Retorna uma unica visao para todas as wallets:

```json
{
  "success": true,
  "message": "KFE dashboard retrieved.",
  "data": {
    "wallets": [
      {
        "walletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
        "kind": "INTERNAL",
        "status": "ACTIVE",
        "label": "Main",
        "asset": "BTC",
        "spendable": true,
        "availableSats": 100000,
        "pendingSats": 0,
        "lockedSats": 0,
        "autoHoldSats": 0,
        "observedSats": 0,
        "activeAddress": "bc1q..."
      }
    ],
    "recentStatement": [],
    "totalSpendableSats": 100000,
    "totalObservedSats": 5000000,
    "totalVisibleSats": 5100000
  }
}
```

WebSocket:

- Endpoint STOMP existente: `/ws/balance`.
- Fila KFE: `/user/queue/kfe-dashboard`.
- O payload e o mesmo modelo de `GET /kfe/dashboard`.

## Enviar Transacao Interna

```http
POST /kfe/transactions
Authorization: Bearer <jwt>
Content-Type: application/json
```

```json
{
  "idempotencyKey": "8f71c29c-1814-48c6-9d57-e0f7456f0441",
  "rail": "INTERNAL",
  "direction": "INTERNAL",
  "sourceWalletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
  "destinationWalletId": "392b04a5-f704-45d8-8f64-17fca74f019e",
  "amountSats": 25000,
  "networkFeeSats": 0,
  "memo": "transfer"
}
```

Resultado:

- Taxa Kerosene: `0`.
- Network fee: `0`.
- Reserva `available -> locked`.
- Settlement imediato: debita origem e credita destino.
- Status final: `SETTLED`.

## Saida On-chain

```json
{
  "idempotencyKey": "9b3e51fb-13fb-4834-b631-a188f1b1b934",
  "rail": "ONCHAIN",
  "direction": "OUTBOUND",
  "sourceWalletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
  "amountSats": 100000,
  "networkFeeSats": 1500,
  "externalReference": "bc1qdestination...",
  "memo": "withdraw"
}
```

Calculo:

- `keroseneFeeSats = ceil(amountSats * 0.009)`.
- `totalDebitSats = amountSats + networkFeeSats + keroseneFeeSats`.
- Status atual apos aceite: `EXECUTING`.
- O worker KFE consome `financial_execution_outbox`.
- Em sucesso do provider, o lock e liquidado e a transacao vai para `SETTLED`.
- Em falha final, o lock e liberado e a transacao vai para `FAILED`.
- Resultado ambiguo do provider vai para `REQUIRES_RECONCILIATION` sem liberar o lock.

## Entrada On-chain

```json
{
  "idempotencyKey": "txid:vout",
  "rail": "ONCHAIN",
  "direction": "INBOUND",
  "destinationWalletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
  "amountSats": 100000,
  "networkFeeSats": 0,
  "externalReference": "blockchain-txid"
}
```

Calculo:

- `keroseneFeeSats = ceil(amountSats * 0.009)`.
- `receiverAmountSats = amountSats - keroseneFeeSats`.
- `totalDebitSats = 0`.
- O settlement de entrada deve ser feito por monitor/adaptador KFE confiavel.
- Submissao inbound publica nao credita saldo automaticamente; ela entra em reconciliacao.

## Saida Lightning

```json
{
  "idempotencyKey": "6db73cb4-5f98-4fd7-aa1e-d3f04e4107aa",
  "rail": "LIGHTNING",
  "direction": "OUTBOUND",
  "sourceWalletId": "5da5b7b1-7dd9-4e01-9b72-d90e019fa6ac",
  "amountSats": 25000,
  "networkFeeSats": 100,
  "externalReference": "lnbc...",
  "memo": "ln pay"
}
```

Calculo:

- `keroseneFeeSats = 0`.
- `totalDebitSats = amountSats + networkFeeSats`.
- O worker KFE envia pelo gateway Lightning e liquida o lock em sucesso.

## Consultar Transacao

```http
GET /kfe/transactions/{transactionId}
Authorization: Bearer <jwt>
```

Resposta contem status, taxas, hashes de quorum, referencias de provider e
codigos de falha.

## Auditoria Admin

Endpoints protegidos por `ROLE_ADMIN`:

```http
GET  /api/admin/kfe/audit/latest
GET  /api/admin/kfe/audit/events?limit=50
GET  /api/admin/kfe/audit/transactions/{transactionId}
POST /api/admin/kfe/audit/root
```

Comportamento:

- Retorna apenas hashes, estados e referencias UUID.
- `POST /root` calcula o Merkle Root a partir de `financial_audit_log.event_hash`.
- O payload sensivel nao e exposto; o log guarda `payload_hash`.

## Worker de Execucao Externa

Controle por property:

```properties
kfe.execution.enabled=true
kfe.execution.outbox.fixed-delay-ms=5000
kfe.execution.outbox.initial-delay-ms=10000
```

Estados do outbox:

- `PENDING`: aguardando worker.
- `PROCESSING`: item reivindicado por um worker.
- `DISPATCHED`: provider aceitou/executou.
- `FAILED_RETRYABLE`: falha temporaria, com backoff.
- `FAILED_FINAL`: falha final, com transacao `FAILED`.
- `UNKNOWN`: resultado ambiguo, com transacao `REQUIRES_RECONCILIATION`.

## Estados

Estados persistidos em `transactions_master.status`:

- `INTENT`: request criado.
- `VALIDATING`: saldo, permissoes e pricing.
- `QUORUM_SYNC`: proposta enviada ao quorum.
- `LOCKED`: saldo reservado.
- `EXECUTING`: adapter/outbox em processamento.
- `SETTLED`: finalizado.
- `FAILED`: falha final.
- `REQUIRES_RECONCILIATION`: resultado externo ambiguo.

## Servicos Legados

Os controllers e workers/schedulers financeiros legados foram retirados do
registro padrao. As classes antigas permanecem temporariamente no codigo por
tres motivos tecnicos:

1. Monitores confiaveis de entrada on-chain/LN ainda precisam liquidar inbound no KFE.
2. Alguns testes legados ainda compilam contra esses tipos.
3. Infra compartilhada de quorum/MPC/derivacao ainda esta em pacotes antigos.

Regra para novas features: nao chamar services de `payments`, `ledger`,
`bitcoinaccounts`, `transactions` ou `treasury` para estado financeiro. Use
`source.kfe`.

Legado desligado por `kfe.legacy-financial.enabled=false` ou ausencia da
property:

- Controllers: `WalletController`, `PaymentsController`, `LedgerController`,
  `LedgerAuditController`, `MerkleAuditController`, `BitcoinAccountsController`,
  `TransactionController`, `NetworkPaymentsController`, `DepositController`,
  `OnrampController`, `EconomyController`, `TreasuryController`.
- Workers/schedulers: `PaymentExternalExecutionWorker`,
  `PaymentExternalReconciliationService`, `ExternalProviderOutboxWorker`,
  `InboundTransferMonitorService`, `PendingTransactionMonitoringScheduler`,
  `FinancialReconciliationService`, `LiquidityMonitorService`,
  `AccountActivationMonitorService`, `BitcoinReceivingMonitorService`,
  `ColdWalletMonitorService`, `BitcoinAccountsRetentionService`,
  `TreasuryPayoutWorker`, `FinancialIntegrityService`,
  `LedgerHistoryCleanupService`, `ShadowBalanceAuditService`,
  `ReconciliationAuditService`, `MerkleAuditScheduler`.

## Proximos Cortes

1. Conectar monitores KFE confiaveis para settlement inbound on-chain/LN.
2. Migrar os ultimos consumers internos de adapters externos para portas neutras KFE.
3. Apagar services/repos/entities legados restantes quando nenhum bean/produto depender deles.

# Runbook de Reconciliacao Manual

Este runbook cobre incidentes financeiros que chegam a `AUTO_RESOLUTION_PENDING`, `PENDING_MANUAL` ou issues abertas em `financial.financial_reconciliation_issues`. O objetivo e resolver sem ler codigo e sem expor segredos, preservando idempotencia e trilha auditavel.

## Regras Inviolaveis

- Nao edite `financial.ledger`, saldos de wallet, `processed_transactions`, outbox ou historico de transacao diretamente por SQL.
- Nao cole seed, macaroon, token, cookie, invoice BOLT11 completo, PSBT completo, private key, xpub de cliente ou payload de assinatura em ticket.
- Nao reenvie pagamento externo se houver `external_reference`, `blockchain_txid` ou `payment_hash` sem reconciliar no provider.
- Qualquer ajuste financeiro manual exige dois operadores: um executor e um aprovador.
- Toda decisao deve deixar `resolution_note` com evidencias, horario, operador e aprovador.

## Fontes Permitidas

Use apenas estas fontes durante a triagem:

- `GET /api/admin/operations/overview`
- `GET /api/admin/operations/blockchain`
- `GET /api/admin/operations/lightning`
- `GET /api/admin/operations/logs?limit=100`
- `POST /v1/audit/reserves/operational-proof`
- Tabelas somente leitura:
  - `financial.financial_reconciliation_runs`
  - `financial.financial_reconciliation_issues`
  - `financial.external_transfers`
  - `financial.external_provider_outbox`
  - `financial.network_transfer_events`
  - `financial.payment_links`

Se precisar consultar Bitcoin Core ou LND diretamente, rode o comando no host operacional autorizado e registre apenas hashes/fingerprints, altura, confirmacoes, status e horarios.

## Identificar o Caso

1. Abra o ultimo run:

```sql
SELECT id, started_at, finished_at, status, checked_transfers, issue_count, summary
FROM financial.financial_reconciliation_runs
ORDER BY started_at DESC
LIMIT 10;
```

2. Liste issues abertas:

```sql
SELECT id, run_id, transfer_id, issue_type, severity, status, reference,
       resolution_status, created_at, details
FROM financial.financial_reconciliation_issues
WHERE status = 'OPEN'
ORDER BY created_at DESC
LIMIT 50;
```

3. Para uma issue especifica, carregue a transferencia e o outbox:

```sql
SELECT id, user_id, wallet_id, wallet_name_snapshot, network, transfer_type,
       status, amount_btc, network_fee_btc, platform_fee_btc, total_debited_btc,
       external_reference, blockchain_txid, payment_hash, confirmations,
       detected_at, settled_at, updated_at
FROM financial.external_transfers
WHERE id = '<transfer_id>';

SELECT id, transfer_id, operation_type, status, attempts, provider_reference,
       last_error, next_attempt_at, claimed_by, claimed_at, dispatched_at,
       created_at, updated_at
FROM financial.external_provider_outbox
WHERE transfer_id = '<transfer_id>'
ORDER BY created_at DESC;
```

4. Consulte eventos saneados:

```sql
SELECT created_at, event_type, severity, reference, payload
FROM financial.network_transfer_events
WHERE transfer_id = '<transfer_id>'
ORDER BY created_at DESC
LIMIT 50;
```

## Classificar

Use `issue_type` como decisao primaria:

- `PROVIDER_SAGA_RETRY_SCHEDULED`: nao fazer ajuste manual. Confirmar que `external_provider_outbox` esta `PENDING`, `FAILED_RETRYABLE` ou `PROCESSING` com `next_attempt_at` vencido. Aguardar worker ou reiniciar worker.
- `PROVIDER_SAGA_INCOMPLETE`: provider saga ambigua. Verificar se existe `provider_reference`, `blockchain_txid` ou `payment_hash`.
- `PROVIDER_FAILURE_AMBIGUOUS`: falha com referencia externa. Nunca refund automatico sem checar provider.
- `PROVIDER_FAILURE_REFUND_BLOCKED`: faltam campos contabeis para refund seguro. Escalar para engenharia com evidencias.
- `CONFIRMATION_REGRESSION`: possivel reorg ou regressao de confirmacoes. Verificar altura atual e confirmacoes reais.
- `CONFIRMATION_REGRESSION_AUTO_REVERSED` ou `PROVIDER_FAILURE_AUTO_REFUNDED`: revisar e marcar issue como resolvida se a reversao/refund foi aplicada exatamente uma vez.

## Coletar Evidencia

Registre no ticket:

- `issue_id`, `run_id`, `transfer_id`, `operation_type`, `issue_type`, `severity`.
- Status antes/depois de `external_transfers` e `external_provider_outbox`.
- `blockchain_txid` ou `payment_hash` apenas como fingerprint quando o ticket sair do ambiente restrito.
- Altura Bitcoin, confirmacoes observadas, hash do bloco como fingerprint.
- Status LND/Bitcoin de `/api/admin/operations/*`.
- Resultado de `POST /v1/audit/reserves/operational-proof`: `status`, `snapshotHash`, `merkleRoot`, `totalAssetsBtc`, `internalLedgerBtc`.
- Decisao proposta: aguardar retry, cancelar tentativa, confirmar settlement, refund, escalar engenharia.

Nao registre invoice completo, endereco completo de usuario, payload do provider, PSBT, assinatura, token, segredo ou corpo de request bruto.

## Decisao por Fluxo

### Outbox Ainda Retryable

Condicoes:

- `issue_type = PROVIDER_SAGA_RETRY_SCHEDULED`
- outbox em `PENDING`, `FAILED_RETRYABLE` ou `PROCESSING`
- `next_attempt_at <= now()` ou claim antigo
- sem `external_reference`, `blockchain_txid` ou `payment_hash` novo

Acao:

1. Nao mexer em saldo.
2. Confirmar worker ativo.
3. Se claim estiver preso por mais de 10 minutos, aguardar reclaim automatico.
4. Reexecutar reconciliacao depois do worker.

### Falha Sem Referencia Externa

Condicoes:

- `PROVIDER_FAILED` ou issue de provider failure
- sem `external_reference`, `blockchain_txid`, `payment_hash` e sem `provider_reference`
- `total_debited_btc` e `wallet_id` presentes

Acao:

1. Confirmar que o servico automatico nao aplicou refund (`FAILED_SAFE` ou evento `RECONCILIATION_PROVIDER_AUTO_REFUNDED`).
2. Se ainda nao refundado, nao aplicar SQL no ledger. Escalar para endpoint/rotina de refund idempotente.
3. Depois do refund idempotente, issue pode ser encerrada com `resolution_status = MANUAL_CONFIRMED_AUTO_REFUND`.

### Falha Com Referencia Externa

Condicoes:

- existe `external_reference`, `blockchain_txid`, `payment_hash` ou `provider_reference`
- provider/outbox marcou falha ou transferencia ficou `AUTO_RESOLUTION_PENDING`

Acao:

1. On-chain: verificar tx por Bitcoin Core. Se confirmada ou em mempool com txid valido, tratar como enviada, nao refundar.
2. Lightning: verificar payment hash no LND. Se settled, tratar como enviada, nao refundar.
3. Se provider confirma inexistencia definitiva do pagamento, preparar refund idempotente via aplicacao.
4. Se provider esta indisponivel, manter `AUTO_RESOLUTION_PENDING` e repetir checagem.

### Regressao de Confirmacoes

Condicoes:

- `issue_type = CONFIRMATION_REGRESSION`
- confirmacoes armazenadas maiores que confirmacoes observadas

Acao:

1. Confirmar altura atual e melhor bloco.
2. Se transferencia inbound ja foi creditada e a reversao automatica ocorreu, validar evento e marcar issue resolvida.
3. Se nao ha reversao automatica segura, nao ajustar saldo por SQL. Escalar para rotina idempotente de reversao.
4. Manter comunicacao ao usuario como "confirmacao em revisao" ate confirmacao final.

## Encerrar Issue

Use este update somente para encerrar a issue de reconciliacao. Ele nao ajusta saldo e nao substitui refund, settlement ou reversao.

```sql
BEGIN;

UPDATE financial.financial_reconciliation_issues
   SET status = 'RESOLVED',
       resolution_status = 'MANUAL_RESOLVED',
       resolved_at = CURRENT_TIMESTAMP,
       resolved_by = '<operador>@<aprovador>',
       resolution_note = '<resumo curto: evidencia, decisao, snapshotHash, merkleRoot, comandos/endpoints consultados>'
 WHERE id = '<issue_id>'
   AND status = 'OPEN';

COMMIT;
```

Se a decisao for "sem acao", use `resolution_status = 'NO_ACTION_REQUIRED'`. Se precisar de engenharia, use `resolution_status = 'ESCALATED_ENGINEERING'` e mantenha `status = 'OPEN'`.

## Rollback

- Issue encerrada por engano: reabra com `status = 'OPEN'`, `resolution_status = 'PENDING'`, `resolved_at = NULL`, `resolved_by = NULL`, e explique o motivo em `resolution_note`.
- Refund/settlement/reversao aplicado por rotina idempotente: nao tente desfazer por SQL. Abra incidente de correcao financeira e gere novo `operational-proof`.
- Provider muda status depois da resolucao: abrir nova issue manual referenciando a issue anterior.

## Checklist de Dois Operadores

Antes de qualquer acao sensivel:

- [ ] Operador A coletou `issue_id`, `transfer_id`, estado da transferencia e outbox.
- [ ] Operador A gerou `POST /v1/audit/reserves/operational-proof`.
- [ ] Operador A verificou provider on-chain/LND sem copiar segredo.
- [ ] Operador B revisou evidencias e concordou com a classificacao.
- [ ] Operador B confirmou que nao ha tentativa duplicada ou refund ja aplicado.
- [ ] Operador A executou apenas endpoint/rotina idempotente ou update de encerramento da issue.
- [ ] Operador B validou logs/eventos e novo estado.
- [ ] Ticket contem `snapshotHash`, decisao, horario, operador e aprovador.

## Comunicacao ao Usuario

Use linguagem curta e sem detalhe interno:

- Envio externo ambiguo: "Estamos verificando a confirmacao do provedor antes de concluir ou estornar a operacao."
- Regressao de confirmacoes: "A rede reduziu temporariamente a profundidade de confirmacao. A operacao esta protegida enquanto aguardamos confirmacao final."
- Refund aplicado: "A tentativa externa nao foi concluida e o saldo foi devolvido."
- Settlement confirmado: "A operacao foi confirmada pelo provedor e seguira o prazo normal da rede."

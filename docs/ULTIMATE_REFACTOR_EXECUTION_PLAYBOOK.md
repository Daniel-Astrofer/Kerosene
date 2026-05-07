# Ultimate Refactor Execution Playbook - Kerosene

Este playbook complementa `docs/ULTIMATE_REFACTOR.md`.

O primeiro documento e o checklist amplo de produto e arquitetura. Este arquivo e o guia de execucao para o agente implementador: ordem recomendada, dependencias entre tarefas, receitas de codigo, migracoes, testes minimos e formato de handoff.

Escopo de execucao primario: `backend/kerosene`.

Fronteiras que devem ser alteradas quando necessario: `frontend`, `backend/mpc-sidecar`, `backend/vault`, `scripts`, `docs`.

## Regra principal para o agente implementador

- [ ] Nao tente implementar tudo em uma unica passada.
  - Execute por pacote, nesta ordem:
    1. Baseline e inventario.
    2. Contratos canonicos de API.
    3. Ledger/wallet/destination index.
    4. Payments API e outbox.
    5. Rails externas e reconciliacao.
    6. Security/prod fail-closed.
    7. WebSocket/notificacoes.
    8. Observabilidade/testes/CI.
    9. Frontend alinhado aos contratos.
    10. Limpeza e declaracao de pronto.
  - Nao marque checkbox se:
    - Teste focado nao foi executado.
    - Contrato frontend/backend ficou divergente.
    - Operacao financeira ficou com estado ambiguo sem reconciliacao.
    - Producao depende de mock, fallback silencioso ou configuracao local.
  - Descricao obrigatoria ao concluir:
    - Pacote:
    - Implementado:
    - Arquivos alterados:
    - Migracoes:
    - Testes executados:
    - Contratos alterados:
    - Risco residual:
    - Proximo pacote recomendado:

## Prompt recomendado para o agente implementador

Use este prompt quando for iniciar uma nova sessao de implementacao:

```text
Voce esta trabalhando no repo Kerosene. Leia primeiro:
- docs/ULTIMATE_REFACTOR.md
- docs/ULTIMATE_REFACTOR_EXECUTION_PLAYBOOK.md

Implemente somente o proximo pacote pendente de maior prioridade. Antes de editar, leia os arquivos citados no pacote e os testes correspondentes. Nao reverta alteracoes de usuario. Nao introduza fallback silencioso em fluxo financeiro. Ao concluir, rode testes focados e preencha a descricao do checkbox com arquivos, testes e risco residual.
```

## Baseline de codigo observado nesta passada

- [ ] Confirmar baseline local antes de iniciar pacote.
  - Observacoes:
    - Controllers principais encontrados em auth, ledger, wallet, transactions, payments, notification, bitcoinaccounts, mining, treasury, common/admin e security.
    - `PaymentExternalExecutionProcessor` marca outbox como `DISPATCHED`, mas mantem intent como `PROCESSING`; precisa de reconciliacao/status final explicito.
    - `PaymentExecutionOutboxEntity`/migration permitem status `PENDING`, `DISPATCHED`, `FAILED_RETRYABLE`, `FAILED_FINAL`; faltam estados como `PROCESSING`, `ACCEPTED`, `UNKNOWN`, `SETTLED` se o modelo de executor exigir.
    - `PaymentConfirmService` debita/locka saldo via `ledgerService.updateBalance` e enfileira outbox; precisa confirmar atomicidade, idempotencia e compensacao final.
    - `TransactionParticipantResolver` ainda varre `walletLookupPort.findAll()` para destination hash.
    - `FinancialReconciliationService` detecta regressao/provider stale e move para `AUTO_RESOLUTION_PENDING`, mas nao executa compensacao contabil automatica.
    - `ExternalProviderOutboxService` tem enqueue/mark dispatched/mark failed/find due, mas nao ha worker completo de replay seguro no legado.
    - `SubscribeAuthorizationStompMessageHandler` so valida usuario autenticado no SUBSCRIBE; nao valida ownership de destination.
    - `PaymentRequestEventPublisher` publica em `/topic/payment-request/{linkId}`; esse topico precisa de regra de ownership ou migracao para `/user/queue`.
    - `BalanceEventPublisher` usa `convertAndSendToUser`, mais adequado para eventos privados.
    - `Security.java` deixa `/integrations/btcpay/webhook/**` publico; webhook precisa validacao propria robusta.
    - `GlobalExceptionHandler` ainda mistura mensagens longas/tecnicas em ingles e portugues; padronizar por codigo.
    - Migration `V2__operational_hardening.sql` ja tem muitos objetos financeiros, payment intents e outbox; cuidado para nao criar migrations conflitantes.
  - Comandos de baseline:
    ```bash
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar
    cd frontend && flutter analyze --no-pub
    cd frontend && flutter test --no-pub
    ```
  - Descricao obrigatoria ao concluir:
    - Baseline executado:
    - Falhas de ambiente:
    - Falhas de codigo:
    - Suite minima disponivel:
    - Proximo pacote:

## Pacote A - Inventario e contrato canonico

Objetivo: impedir que o agente implemente regra nova em endpoint legado errado.

- [ ] A1 - Gerar inventario de endpoints reais.
  - Arquivos a ler:
    - `backend/kerosene/src/main/java/source/**/controller/*.java`
    - `backend/kerosene/src/main/java/source/**/Controller.java`
    - `backend/kerosene/src/main/java/source/auth/application/infra/security/Security.java`
  - Endpoints ja observados que precisam ser classificados:
    - `/payments/quote`
    - `/payments/{paymentIntentId}/confirm`
    - `/payments/{paymentIntentId}`
    - `/users/{receiverIdentifier}/receiving-capabilities`
    - `/transactions/network/onchain/address`
    - `/transactions/network/wallet-profile`
    - `/transactions/network/onchain/send`
    - `/transactions/network/lightning/invoice`
    - `/transactions/network/lightning/pay`
    - `/transactions/network/transfers`
    - `/transactions/network/transfers/{transferId}`
    - `/transactions/network/transfers/{transferId}/cancel`
    - `/deposit/{transferId}/cancel`
    - `/transactions/deposit-address`
    - `/transactions/estimate-fee`
    - `/transactions/create-unsigned`
    - `/transactions/status`
    - `/transactions/broadcast`
    - `/transactions/create-payment-link`
    - `/transactions/payment-link/{linkId}`
    - `/transactions/payment-link/{linkId}/confirm`
    - `/transactions/payment-link/{linkId}/complete`
    - `/transactions/payment-link/{linkId}/cancel`
    - `/transactions/payment-links`
    - `/transactions/withdraw`
    - `/ledger/transaction`
    - `/ledger/history`
    - `/ledger/all`
    - `/ledger/find`
    - `/ledger/balance`
    - `/ledger/payment-request`
    - `/ledger/payment-request/{linkId}`
    - `/ledger/payment-request/{linkId}/pay`
    - `/v1/audit/siphon`
    - `/integrations/btcpay/webhook/{storeId}`
    - `/wallet/*`
    - `/auth/*`
    - `/bitcoin/*`
    - `/notifications`
    - `/treasury/overview`
    - `/mining/*`
    - `/sovereignty/*`
    - `/api/admin/operations/*`
  - Como implementar:
    1. Criar `docs/API_INVENTORY.md`.
    2. Para cada endpoint, registrar:
       - metodo HTTP;
       - path;
       - controller;
       - service/use case;
       - autenticacao;
       - permissao/role;
       - DTO request;
       - DTO response;
       - idempotency key;
       - altera saldo: sim/nao;
       - status: canonico, legado, admin, publico, webhook, health, frontend static.
    3. Marcar endpoint legado quando existir implementacao canonica melhor.
    4. Marcar endpoint perigoso quando altera saldo sem idempotencia duravel.
  - Testes/comandos:
    ```bash
    rg "@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|RequestMapping)" backend/kerosene/src/main/java/source
    ```
  - Criterios de aceite:
    - Todo controller exposto esta no inventario.
    - O inventario mostra claramente o endpoint canonico para pagamento interno, onchain, Lightning e payment link.
  - Descricao obrigatoria ao concluir:
    - Inventario criado em:
    - Endpoints canonicos:
    - Endpoints legados:
    - Endpoints de alto risco:
    - Testes/comandos:

- [ ] A2 - Definir tabela de endpoints canonicos vs legados.
  - Decisao recomendada:
    - `payments` deve ser API canonica para quote/confirm/status.
    - `transactions/network` deve ser API tecnica de rail externa enquanto ainda nao estiver absorvida por `payments`.
    - `TransactionController` deve virar compatibilidade ou ser removido por etapas.
    - `LedgerController` deve deixar de ser ponto publico de pagamento se `payments` cobrir o fluxo.
  - Como implementar:
    1. Adicionar secao em `docs/API_INVENTORY.md`: `Canonical Routing Decision`.
    2. Para cada fluxo, escolher uma rota:
       - Transferencia interna: `/payments/quote` + `/payments/{id}/confirm`.
       - Saque onchain: `/payments/quote` + confirmacao externa ou `/transactions/network/onchain/send` temporario.
       - Pagamento Lightning: `/payments/quote` + confirmacao externa ou `/transactions/network/lightning/pay` temporario.
       - Deposito onchain: `/transactions/network/onchain/address` enquanto `payments` nao modelar inbound.
       - Invoice Lightning inbound: `/transactions/network/lightning/invoice` enquanto `payments` nao modelar inbound.
       - Payment link: decidir se vira `PaymentIntent` ou permanece modulo separado.
    3. Criar lista de endpoints que devem responder `410` ou delegar para use case canonico.
  - Criterios de aceite:
    - Nao existe fluxo financeiro com duas fontes de verdade.
    - Frontend sabe qual rota chamar.
  - Descricao obrigatoria ao concluir:
    - Rotas canonicas decididas:
    - Rotas temporarias:
    - Rotas a remover:
    - Impacto frontend:

- [ ] A3 - Criar mapa de estados financeiros.
  - Arquivos a ler:
    - `source/payments/model/PaymentEnums.java`
    - `source/payments/model/PaymentIntentEntity.java`
    - `source/payments/model/PaymentExecutionOutboxEntity.java`
    - `source/transactions/model/ExternalTransferEntity.java`
    - `source/transactions/model/ExternalProviderOutboxEntity.java`
    - `source/transactions/service/NetworkTransferLifecycleService.java`
    - `source/transactions/service/FinancialReconciliationService.java`
  - Como implementar:
    1. Criar `docs/FINANCIAL_STATE_MACHINE.md`.
    2. Documentar estados de:
       - PaymentIntent.
       - PaymentExecutionOutbox.
       - ExternalTransfer.
       - ExternalProviderOutbox.
       - PaymentLink.
       - Ledger transaction/history.
    3. Para cada estado, indicar:
       - estado inicial;
       - estado final;
       - transicoes permitidas;
       - quem pode mudar;
       - se altera ledger;
       - se publica evento;
       - se notifica usuario;
       - se entra em reconciliacao.
  - Criterios de aceite:
    - Toda transicao critica tem dono de codigo.
    - Estados finais sao imutaveis.
  - Descricao obrigatoria ao concluir:
    - Documento criado:
    - Estados finais:
    - Estados ambiguos:
    - Transicoes que precisam de codigo:

## Pacote B - Error contract e compatibilidade frontend

Objetivo: impedir que backend exponha mensagem tecnica e que frontend dependa de texto bruto.

- [ ] B1 - Criar contrato unico de erro.
  - Arquivos a alterar:
    - `backend/kerosene/src/main/java/source/common/exception/GlobalExceptionHandler.java`
    - `backend/kerosene/src/main/java/source/common/dto/ApiResponse.java`
    - possivel novo `source/common/dto/ApiError.java`
    - `frontend/lib/core/network`
  - Contrato recomendado:
    ```json
    {
      "success": false,
      "error": {
        "code": "PAYMENT_INSUFFICIENT_FUNDS",
        "message": "Saldo insuficiente para concluir esta operacao.",
        "correlationId": "req_...",
        "details": {}
      }
    }
    ```
  - Como implementar:
    1. Verificar formato atual de `ApiResponse`.
    2. Criar um adaptador que preserve compatibilidade temporaria se frontend ainda espera campos antigos.
    3. Normalizar `GlobalExceptionHandler` para sempre retornar codigo estavel.
    4. Remover concatenacao de `ex.getMessage()` em mensagens publicas, exceto excecoes de dominio ja sanitizadas.
    5. Adicionar `correlationId` vindo de filtro/log context.
  - Testes minimos:
    - `GlobalExceptionHandlerTest`.
    - Teste de validacao DTO.
    - Teste de erro financeiro.
    - Teste de erro inesperado.
  - Criterios de aceite:
    - Resposta nao contem `java.`, `source.`, `SQL`, `JDBC`, stack trace, URL interna ou segredo.
    - Frontend mostra copy baseada em `code`.
  - Descricao obrigatoria ao concluir:
    - Contrato final:
    - Campos legados mantidos:
    - Codigos adicionados:
    - Testes executados:

- [ ] B2 - Padronizar codigos de erro por dominio.
  - Prefixos recomendados:
    - `AUTH_`
    - `PASSKEY_`
    - `RECOVERY_`
    - `WALLET_`
    - `LEDGER_`
    - `PAYMENT_`
    - `EXTERNAL_TRANSFER_`
    - `ONCHAIN_`
    - `LIGHTNING_`
    - `WEBHOOK_`
    - `SECURITY_`
    - `PRODUCTION_`
    - `VALIDATION_`
    - `ADMIN_`
  - Como implementar:
    1. Criar classe/enum de codigos ou constantes por dominio.
    2. Atualizar excecoes de dominio para carregar codigo.
    3. Mapear excecoes antigas em `GlobalExceptionHandler`.
    4. Criar documento `docs/API_ERROR_CODES.md`.
  - Criterios de aceite:
    - Nenhum codigo generico em fluxo financeiro novo.
    - Frontend consegue mapear codigo desconhecido para fallback seguro.
  - Descricao obrigatoria ao concluir:
    - Codigos criados:
    - Excecoes migradas:
    - Compatibilidade:
    - Testes:

## Pacote C - Wallet index e ledger invariants

Objetivo: remover lookup inseguro por varredura, estabilizar extrato duravel e proteger invariantes contabeis.

- [x] C1 - Remover `walletLookupPort.findAll()` de request path.
  - Problema exato:
    - `TransactionParticipantResolver.findWalletByDestinationHash` percorre `walletLookupPort.findAll()`.
  - Arquivos a alterar:
    - `source/ledger/application/transaction/TransactionParticipantResolver.java`
    - `source/wallet/application/port/in/WalletLookupPort.java`
    - `source/wallet/infra/WalletPersistenceAdapter.java`
    - `source/wallet/repository/WalletRepository.java`
    - `source/ledger/application/paymentrequest/PaymentRequestDestinationHashService.java`
    - migration nova em `src/main/resources/db/migration`.
  - Implementacao recomendada:
    1. Adicionar coluna em `financial.wallets`:
       ```sql
       ALTER TABLE financial.wallets
           ADD COLUMN IF NOT EXISTS destination_hash VARCHAR(64);

       CREATE UNIQUE INDEX IF NOT EXISTS idx_wallet_destination_hash
           ON financial.wallets(destination_hash)
           WHERE destination_hash IS NOT NULL;
       ```
    2. Criar backfill:
       - Se `PaymentRequestDestinationHashService` depende de dados de wallet disponiveis no banco, criar job de aplicacao idempotente.
       - Se o hash pode ser calculado via SQL com dados existentes, preferir migration SQL.
       - Se depende de segredo/app service, criar `ApplicationRunner` admin/local ou comando documentado, nao migration com segredo.
    3. Atualizar `WalletLookupPort`:
       ```java
       WalletEntity findByDestinationHash(String destinationHash);
       ```
    4. Implementar query no repository:
       ```java
       Optional<WalletEntity> findByDestinationHashIgnoreCase(String destinationHash);
       ```
    5. Na criacao/atualizacao de wallet, persistir `destinationHash`.
    6. No resolver, trocar loop por query indexada.
  - Testes minimos:
    - `TransactionParticipantResolverTest` para destination hash encontrado.
    - Teste para destination hash inexistente.
    - Teste para nao chamar `findAll()`.
    - Teste de criacao de wallet persistindo hash.
  - Criterios de aceite:
    - `rg "walletLookupPort.findAll\\(" backend/kerosene/src/main/java/source` nao encontra uso em resolver.
    - Destination hash tem indice.
    - Dados legados tem estrategia de backfill.
  - Descricao obrigatoria ao concluir:
    - Campo/indice criado: `financial.wallets.destination_hash` com indice unico parcial `idx_wallet_destination_hash` em `V3__wallet_destination_hash_index.sql`.
    - Backfill: `WalletDestinationHashBackfillService` preenche hashes ausentes em lotes de 500 no `ApplicationReadyEvent`, controlado por `wallet.destination-hash.backfill-on-startup`.
    - Portas alteradas: `WalletLookupPort`, `WalletPersistencePort`, `WalletPersistenceAdapter`, `WalletReader`, `WalletService` e `WalletRepository` ganharam lookup por `destinationHash`.
    - Testes: testes focados de resolver/hash, pacote wallet/ledger relacionado, suite completa `./gradlew test` e `./gradlew bootJar` passaram.
    - Risco residual: ambientes grandes podem preferir executar dry-run/backfill operacional controlado antes do startup automatico de producao.

- [ ] C2 - Definir extrato duravel baseado em ledger.
  - Problema:
    - `financial.ledger_transaction_history` esta documentado como buffer operacional/efemero.
  - Arquivos a ler:
    - `source/ledger/controller/LedgerController.java`
    - `source/ledger/service/*History*`
    - `source/transactions/infra/transaction/LedgerTransactionHistoryAdapter.java`
    - migration `V2__operational_hardening.sql`
  - Implementacao recomendada:
    1. Criar query de extrato a partir de ledger entries duraveis.
    2. Criar DTO `LedgerStatementEntryDTO`.
    3. Incluir campos:
       - id;
       - walletId;
       - userId;
       - direction;
       - amount;
       - asset;
       - balanceAfter se existir;
       - sourceType;
       - sourceId;
       - idempotencyKey fingerprint;
       - createdAt;
       - status.
    4. Endpoint recomendado:
       - `GET /ledger/statement?walletId=&cursor=&limit=`
    5. Manter `/ledger/history` como alias temporario ou compatibilidade.
  - Testes minimos:
    - Paginacao estavel.
    - Usuario nao acessa wallet de outro.
    - Entradas aparecem apos transferencia interna.
    - Buffer legado nao e fonte unica.
  - Criterios de aceite:
    - Extrato do usuario e duravel.
    - Endpoint antigo nao apresenta comportamento contraditorio.
  - Descricao obrigatoria ao concluir:
    - Endpoint final:
    - DTO final:
    - Alias legado:
    - Testes:

- [ ] C3 - Proteger escrita unica de saldo.
  - Arquivos a ler:
    - `source/ledger/service/LedgerService.java`
    - `source/ledger/service/LedgerContract.java`
    - `source/ledger/application/transaction`
    - todos os usos de `updateBalance`
  - Como implementar:
    1. Fazer `rg "updateBalance\\(" backend/kerosene/src/main/java/source`.
    2. Classificar cada uso:
       - pagamento interno;
       - lock externo;
       - refund externo;
       - settlement inbound;
       - mining;
       - admin/test/dev.
    3. Criar metodo canonico de lancamento com metadata:
       - walletId;
       - amount;
       - sourceType;
       - sourceId;
       - idempotencyKey;
       - correlationId;
       - direction;
    4. Evitar chamadas soltas com string livre como unica referencia.
    5. Preservar compatibilidade com `LedgerContract` enquanto migrar.
  - Testes minimos:
    - Mesmo `sourceType/sourceId/idempotencyKey` nao duplica.
    - Falha no segundo lancamento de transferencia interna rollbacka ambos.
    - Refund externo nao duplica em retry.
  - Criterios de aceite:
    - Todo movimento financeiro tem metadata auditavel.
    - Nao ha mutacao de saldo fora do ledger canonico.
  - Descricao obrigatoria ao concluir:
    - API de ledger criada:
    - Usos migrados:
    - Usos pendentes:
    - Testes:

## Pacote D - Payments API e outbox canonica

Objetivo: fazer `payments` virar fluxo confiavel, idempotente e reconciliavel.

- [x] D1 - Criar maquina de estados de `PaymentIntent`.
  - Progresso ja implementado:
    - Estados externos intermediarios adicionados: `ACCEPTED_BY_PROVIDER` e `REQUIRES_RECONCILIATION`.
    - Migration `V4__payment_intent_external_states.sql` atualiza o check constraint de `financial.payment_intents.status`.
    - `PaymentStateMachine` foi criada e os services de quote, confirmacao e execucao externa passaram a usa-la.
    - Testes focados de payments, suite completa backend e `bootJar` passaram.
  - Arquivos a alterar:
    - `source/payments/model/PaymentEnums.java`
    - `source/payments/model/PaymentIntentEntity.java`
    - `source/payments/service/PaymentConfirmService.java`
    - `source/payments/service/PaymentExternalExecutionProcessor.java`
  - Transicoes recomendadas:
    - `CREATED -> QUOTED`
    - `QUOTED -> EXPIRED`
    - `QUOTED -> CONFIRMED`
    - `CONFIRMED -> PROCESSING`
    - `PROCESSING -> ACCEPTED_BY_PROVIDER`
    - `ACCEPTED_BY_PROVIDER -> SETTLED`
    - `PROCESSING -> FAILED`
    - `ACCEPTED_BY_PROVIDER -> FAILED`
    - `PROCESSING -> REQUIRES_RECONCILIATION`
    - `ACCEPTED_BY_PROVIDER -> REQUIRES_RECONCILIATION`
    - `REQUIRES_RECONCILIATION -> SETTLED`
    - `REQUIRES_RECONCILIATION -> FAILED`
    - `QUOTED -> CANCELED`
  - Como implementar:
    1. Criar service `PaymentStateMachine`.
    2. Toda alteracao de status passa por ele.
    3. Estado final nao permite transicao.
    4. Salvar motivo/codigo em transicoes de falha.
    5. Registrar audit event por transicao.
  - Testes minimos:
    - Transicoes permitidas.
    - Transicoes proibidas.
    - Estado final imutavel.
  - Criterios de aceite:
    - `PaymentConfirmService` nao seta status arbitrariamente sem state machine.
    - `PaymentExternalExecutionProcessor` nao deixa intent em `PROCESSING` sem proxima acao.
  - Descricao obrigatoria ao concluir:
    - Estados finais: `SETTLED`, `FAILED`, `CANCELED`, `EXPIRED`.
    - Estados intermediarios: `CREATED`, `QUOTED`, `CONFIRMED`, `PROCESSING`, `ACCEPTED_BY_PROVIDER`, `REQUIRES_RECONCILIATION`.
    - State machine criada: `source.payments.service.PaymentStateMachine`.
    - Testes: `PaymentStateMachineTest`, payments service tests, `./gradlew test`, `./gradlew bootJar`.

- [x] D2 - Evoluir `PaymentExecutionOutbox` para modelo de claim/retry/resultado.
  - Progresso ja implementado:
    - Migration `V5__payment_execution_reconciliation_states.sql` expandiu os estados permitidos da outbox com `SETTLED` e `UNKNOWN`.
    - `PaymentExternalReconciliationService` atualiza outbox para `SETTLED`, `UNKNOWN` ou `FAILED_FINAL` conforme resultado de reconciliacao.
    - Migration `V6__payment_execution_claims.sql` adicionou `PROCESSING`, `claimed_by`, `claimed_at` e indice de claim.
    - `PaymentExecutionOutboxService.claimDue` faz claim atomico antes de executar o provider.
    - `PaymentExternalExecutionWorker` chama o processor apenas para outbox claimada.
    - `PaymentExternalExecutionProcessor` ignora outbox nao claimada, limpa claim em estados finais/intermediarios e trata excecao de executor como `UNKNOWN`/reconciliacao.
    - Retry automatico de execucao ficou restrito a `FAILED_RETRYABLE` retornado explicitamente pelo executor.
  - Arquivos a alterar:
    - `source/payments/model/PaymentExecutionOutboxEntity.java`
    - `source/payments/repository/PaymentExecutionOutboxRepository.java`
    - `source/payments/service/PaymentExecutionOutboxService.java`
    - `source/payments/service/PaymentExternalExecutionWorker.java`
    - `source/payments/service/PaymentExternalExecutionProcessor.java`
    - migration nova.
  - Estados recomendados:
    - `PENDING`
    - `PROCESSING`
    - `DISPATCHED`
    - `SETTLED`
    - `UNKNOWN`
    - `FAILED_RETRYABLE`
    - `FAILED_FINAL`
  - Campos recomendados:
    - `claimed_by`
    - `claimed_at`
    - `provider_status`
    - `provider_reference`
    - `last_error_code`
    - `last_error_message`
    - `next_attempt_at`
    - `attempts`
    - `settled_at`
  - Como implementar:
    1. Criar migration idempotente adicionando campos e expandindo check constraint.
    2. Ajustar repository para claim atomico:
       - selecionar due;
       - marcar `PROCESSING`;
       - salvar `claimed_by`.
    3. Worker chama processor apenas para item claimado.
    4. Processor trata resultado tipado do executor.
    5. Backoff deve ser calculado em um metodo testavel.
  - Testes minimos:
    - Dois workers nao processam mesmo item.
    - `PENDING -> PROCESSING -> DISPATCHED`.
    - Falha retryable calcula `nextAttemptAt`.
    - Falha final executa compensacao idempotente.
    - Unknown vai para reconciliacao.
  - Criterios de aceite:
    - Outbox due nao fica presa sem `nextAttemptAt`.
    - Status de intent acompanha status de outbox.
  - Descricao obrigatoria ao concluir:
    - Migration: `V6__payment_execution_claims.sql`.
    - Estados adicionados: `PROCESSING` na outbox, mantendo `PENDING`, `DISPATCHED`, `SETTLED`, `UNKNOWN`, `FAILED_RETRYABLE`, `FAILED_FINAL`.
    - Claim implementado: `PaymentExecutionOutboxService.claimDue(workerId)` usa update atomico por id, status due, `nextAttemptAt` vencido e reclaim de `PROCESSING` stale.
    - Concorrencia testada: teste unitario cobre item claimado vs item perdido no claim; falta teste integrado multi-worker com Postgres real.

- [x] D3 - Tipar resultado de `PaymentRailExecutor`.
  - Progresso ja implementado:
    - `PaymentRailExecutor.ExecutionResult` agora tem outcome tipado e construtor compativel para resultado aceito.
    - `PaymentExternalExecutionProcessor` trata `ACCEPTED`, `SETTLED`, `FAILED_RETRYABLE`, `FAILED_FINAL` e `UNKNOWN`.
    - Excecao do executor agora vira `REQUIRES_RECONCILIATION` e outbox `UNKNOWN`, sem refund automatico nem retry cego.
    - Ainda falta migrar executores reais, se forem adicionados fora dos testes, para retornarem outcomes especificos.
  - Arquivos a alterar:
    - `source/payments/service/PaymentRailExecutor.java`
    - implementacoes de executor se existirem.
    - `PaymentExternalExecutionProcessor.java`
  - Modelo recomendado:
    ```java
    enum ExecutionOutcome {
        ACCEPTED,
        SETTLED,
        FAILED_RETRYABLE,
        FAILED_FINAL,
        UNKNOWN
    }

    record ExecutionResult(
        ExecutionOutcome outcome,
        String providerReference,
        String providerStatus,
        String failureCode,
        String safeFailureMessage
    ) {}
    ```
  - Como implementar:
    1. Substituir resultado que so carrega providerReference.
    2. Cada executor deve declarar se a rail liquida imediatamente ou apenas aceitou envio.
    3. Processor deve:
       - `SETTLED`: marcar intent `SETTLED`.
       - `ACCEPTED`: marcar intent `ACCEPTED_BY_PROVIDER` ou manter processing com reconciliacao agendada.
       - `UNKNOWN`: marcar `REQUIRES_RECONCILIATION`.
       - `FAILED_RETRYABLE`: retry automatico apenas quando o executor sabe que o provider nao aceitou.
       - `FAILED_FINAL`: refundar somente se nao ha risco de pagamento externo ter sido aceito.
  - Criterios de aceite:
    - Timeout de provider nao vira refund automatico se resultado e ambiguo.
    - Cada resultado tem teste.
  - Descricao obrigatoria ao concluir:
    - Resultado tipado: `PaymentRailExecutor.ExecutionResult` expoe `ExecutionOutcome` com `ACCEPTED`, `SETTLED`, `FAILED_RETRYABLE`, `FAILED_FINAL` e `UNKNOWN`; outcome nulo permanece compativel como `ACCEPTED`.
    - Processor: `PaymentExternalExecutionProcessor` trata cada outcome explicitamente; `SETTLED` agora marca a outbox como `SETTLED`, nao apenas `DISPATCHED`.
    - Executors migrados: nao ha executor real de `PaymentRailExecutor` registrado no codigo de producao nesta passada; os executores existentes no teste retornam outcomes especificos.
    - Politica de refund: refund automatico fica restrito a executor ausente ou `FAILED_FINAL`; `UNKNOWN` e excecao do executor entram em `REQUIRES_RECONCILIATION` sem refund nem retry cego; `FAILED_RETRYABLE` mantem intent em `PROCESSING` e agenda retry.
    - Arquivos alterados: `PaymentExternalExecutionProcessor.java`, `PaymentExternalExecutionProcessorTest.java`.
    - Testes: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.payments.service.PaymentExternalExecutionProcessorTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests 'source.payments.service.*'`.
    - Proximo pacote recomendado: `E1`, se a trilha continuar em rails externas; `C2/C3` permanecem pendentes se o proximo foco for ledger.

- [x] D4 - Criar reconciliador de PaymentIntent externo.
  - Progresso ja implementado:
    - `PaymentExternalReconciliationService` busca intents em `ACCEPTED_BY_PROVIDER` e `REQUIRES_RECONCILIATION`.
    - `PaymentRailStatusClient` define contrato de status por rail.
    - Sem client configurado, intent aceita vai para `REQUIRES_RECONCILIATION` sem refund nem sucesso presumido.
    - Resultado `SETTLED` fecha a intent; resultado `UNKNOWN` mantem reconciliacao; resultado `FAILED_FINAL` executa refund e falha terminal.
    - Testes cobrem ausencia de client, settled, unknown e final failure.
  - Arquivos a criar/alterar:
    - `source/payments/service/PaymentExternalReconciliationService.java`
    - `source/payments/repository/PaymentIntentRepository.java`
    - `source/payments/service/PaymentRailStatusClient.java` ou equivalente.
  - Como implementar:
    1. Buscar intents em `ACCEPTED_BY_PROVIDER` ou `REQUIRES_RECONCILIATION`.
    2. Consultar provider por rail/reference quando possivel.
    3. Marcar `SETTLED`, `FAILED`, ou manter pendente com backoff.
    4. Executar refund/compensacao apenas em falha terminal comprovada.
    5. Publicar audit event e notification pos-commit.
  - Testes minimos:
    - Provider retorna settled.
    - Provider retorna failed final.
    - Provider retorna unknown.
    - Provider indisponivel.
  - Criterios de aceite:
    - Intent externo nunca fica infinitamente `PROCESSING` sem run de reconciliacao.
    - Reconciliador e idempotente.
  - Descricao obrigatoria ao concluir:
    - Service criado: `source.payments.service.PaymentExternalReconciliationService`.
    - Providers suportados: contrato `PaymentRailStatusClient`; nenhum client real de LND/onchain foi implementado neste lote.
    - Estados reconciliados: `ACCEPTED_BY_PROVIDER` e `REQUIRES_RECONCILIATION` para `SETTLED`, `FAILED`, ou permanencia em reconciliacao/unknown.
    - Testes: `PaymentExternalReconciliationServiceTest`, suite focada de payments, `./gradlew test`, `./gradlew bootJar`.

## Pacote E - External transfers legado e rails externas

Objetivo: fechar o fluxo antigo enquanto `payments` nao absorve tudo.

- [x] E1 - Implementar worker real para `ExternalProviderOutboxService`.
  - Arquivos a alterar:
    - `source/transactions/service/ExternalProviderOutboxService.java`
    - `source/transactions/repository/ExternalProviderOutboxRepository.java`
    - novo worker/processor em `source/transactions/service`
  - Como implementar:
    1. Adicionar claim atomico semelhante ao pacote D.
    2. Criar processor por `operationType`.
    3. Nao processar item sem transfer existente.
    4. Respeitar idempotency key no provider.
    5. Registrar `NetworkTransferEventService` em sucesso/falha.
    6. Expor metricas: backlog, attempts, oldest pending.
  - Testes minimos:
    - Retry success depois de falha.
    - Duplo worker.
    - Transfer ausente.
    - Provider timeout.
  - Criterios de aceite:
    - `findDueForAutomaticResolution` nao e apenas relatorio; existe caminho de execucao ou decisao documentada de desativar legado.
  - Descricao obrigatoria ao concluir:
    - Worker: `ExternalProviderOutboxWorker` agenda claims por `transactions.provider-outbox.*` e chama `ExternalProviderOutboxProcessor` somente para itens claimados.
    - Operation types: `ONCHAIN_SEND` via `ExternalPaymentsCustodyPort.sendOnchain` e `LIGHTNING_PAY` via `CustodyGateway.payLightning`; ambos carregam `idempotencyKey` no comando de provider.
    - Concorrencia: `ExternalProviderOutboxRepository.claimDue` faz update atomico para `PROCESSING` com `claimed_by`/`claimed_at`; claims stale podem ser retomados apos 10 minutos.
    - Migracao: `V7__external_provider_outbox_claims.sql` adiciona `claimed_by`, `claimed_at` e indice `idx_external_outbox_claim`.
    - Eventos/metricas: sucesso, falha retryable e falha final registram `NetworkTransferEventService`; `ExternalProviderOutboxService.backlogSnapshot()` expoe backlog, oldest pending e max attempts para o worker/operacao.
    - Testes: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.ExternalProviderOutboxServiceTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.ExternalPaymentsServiceTest`.
    - Risco residual: o worker nao executa compensacao contabil em falha final; isso fica para `E2/P5-05`, porque refund automatico sem prova de nao aceite do provider pode duplicar dinheiro.

- [x] E2 - Completar compensacao em `FinancialReconciliationService`.
  - Progresso nesta passada:
    - `FinancialReconciliationService` agora faz auto-refund idempotente para `PROVIDER_FAILED` sem `externalReference`, `blockchainTxid`, `paymentHash` ou `providerReference` no outbox.
    - O refund usa `ProcessedTransactionService.processOnce("external-provider-final-refund:{transferId}", "EXTERNAL_PROVIDER_FINAL_REFUND", ...)` antes de chamar `ExternalPaymentsLedgerPort.updateBalance`.
    - Falha de provider com referencia externa continua manual e vai para `AUTO_RESOLUTION_PENDING`, bloqueando refund automatico ambiguo.
    - `FinancialReconciliationIssueEntity` ganhou campos de resolucao (`resolution_status`, `resolved_at`, `resolved_by`, `resolution_note`) via `V8__financial_reconciliation_resolution_fields.sql`.
    - Testes adicionados em `FinancialReconciliationServiceTest` cobrem auto-refund seguro e falha ambigua manual.
    - Ainda pendente para fechar E2: regressao/reorg antes/depois de credito e stale provider pending com acao coordenada com o worker.
  - Arquivos a alterar:
    - `source/transactions/service/FinancialReconciliationService.java`
    - `source/transactions/service/NetworkTransferLifecycleService.java`
    - `source/transactions/service/ExternalInboundSettlementService.java`
    - `source/ledger/service`
  - Como implementar:
    1. Para regressao de confirmacao:
       - se credito ainda esta bloqueado/pending, manter bloqueado;
       - se credito ja ficou disponivel, criar entry compensatoria ou caso manual.
    2. Para provider stale:
       - consultar provider/outbox;
       - se sem envio, retry;
       - se ambiguo, `AUTO_RESOLUTION_PENDING`;
       - se falha terminal, refund.
    3. Registrar `FinancialReconciliationIssueEntity` com codigo, severity e acao sugerida.
    4. Adicionar campo de resolucao se necessario: `resolution_status`, `resolved_at`, `resolved_by`, `resolution_note`.
  - Testes minimos:
    - Confirmation regression antes do credito.
    - Confirmation regression apos credito.
    - Provider pending stale com retry.
    - Provider failed final com refund.
  - Criterios de aceite:
    - Reconciliacao nao so detecta; ela encaminha resolucao segura.
    - Caso manual tem dados suficientes para operador.
  - Descricao obrigatoria ao concluir:
    - Casos automaticos: `PROVIDER_FAILED`/outbox `FAILED_FINAL` sem referencia externa executa refund idempotente; regressao de inbound `COMPLETED` debita o credito liquido se o saldo ainda cobre a reversao; `PROVIDER_PENDING` stale com outbox retryable permanece pendente para o worker retry.
    - Casos manuais: falha de provider com `externalReference`/`blockchainTxid`/`paymentHash`/`providerReference`, regressao sem net credit derivavel, regressao com saldo insuficiente e provider pending sem outbox confiavel ficam em `AUTO_RESOLUTION_PENDING` com issue `PENDING_MANUAL`.
    - Ledger entries: compensacoes usam `ExternalPaymentsLedgerPort.updateBalance` com contextos `EXTERNAL_PROVIDER_FINAL_REFUND:{transferId}` e `CONFIRMATION_REGRESSION_REVERSAL:{transferId}`, protegidos por `ProcessedTransactionService`.
    - Migracao: `V8__financial_reconciliation_resolution_fields.sql` adiciona campos de resolucao em `financial_reconciliation_issues`.
    - Testes: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.FinancialReconciliationServiceTest`.

- [x] E3 - Separar LND Lightning de onchain Bitcoin Core.
  - Arquivos a alterar:
    - `source/transactions/service/BitcoinNodeService.java`
    - `source/transactions/infra/BitcoinCoreRpcClient.java`
    - `source/transactions/infra/LightningClient.java`
    - `source/transactions/infra/LndRestLightningClient.java`
    - `source/transactions/infra/CustodyGateway.java`
    - use cases externos.
  - Problema:
    - `BitcoinNodeService` possui metodos onchain que lancam `UnsupportedOperationException`.
  - Como implementar:
    1. Criar interfaces pequenas:
       - `LightningInvoiceGateway`.
       - `LightningPaymentGateway`.
       - `OnchainAddressGateway`.
       - `OnchainPsbtGateway`.
       - `OnchainBroadcastGateway`.
    2. Injetar cada interface apenas nos use cases que precisam dela.
    3. Remover implementacao falsa de onchain em LND service.
    4. Criar config que falha se uma rail obrigatoria nao tem bean.
  - Testes minimos:
    - Contexto com LND habilitado e onchain desabilitado.
    - Contexto prod com rail obrigatoria ausente falha.
    - Use case onchain nao recebe bean Lightning por engano.
  - Criterios de aceite:
    - Nenhum `UnsupportedOperationException` em provider de producao.
    - Rail ativa tem provider explicito.
  - Descricao obrigatoria ao concluir:
    - Interfaces criadas: `LightningInvoiceGateway` e `LightningPaymentGateway`; `CustodyGateway` passou a estender essas interfaces para manter compatibilidade com BTCPay/configurable providers.
    - Beans removidos/renomeados: `BitcoinNodeService` deixou de implementar `CustodyGateway` e agora expõe somente contratos Lightning, `LightningClient` e `WatchOnlyAddressImportPort`; metodos onchain falsos foram removidos dele.
    - Use cases migrados: `CreateLightningInvoiceUseCase`, `CancelInboundTransferUseCase`, `ExternalPaymentsQueryService` e `InboundTransferMonitorService` usam `LightningInvoiceGateway`; `PayLightningPaymentUseCase` e `ExternalProviderOutboxProcessor` usam `LightningPaymentGateway`.
    - Onchain: envio onchain continua pelo contrato estreito `ExternalPaymentsCustodyPort`/`QuorumPsbtSigningService`, e broadcast/monitoramento continuam por `BlockchainClient`.
    - P5-03 follow-up: beans canonicos por rail (`externalLightningInvoiceGateway`, `externalLightningPaymentGateway`, `bitcoinCorePsbtExternalPaymentsCustodyPort`) e check de producao bloqueiam rail obrigatoria sem provider vivo ou usando gateway configuravel fraco.
    - Testes: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.BitcoinNodeServiceRailContractTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest --tests source.transactions.service.InboundTransferMonitorServiceTest --tests source.transactions.application.externalpayments.CancelInboundTransferUseCaseTest --tests source.transactions.service.ExternalPaymentsServiceTest`.

- [x] E4 - Endurecer PSBT/quorum onchain.
  - Arquivos a alterar:
    - `source/transactions/application/externalpayments/SendOnchainPaymentUseCase.java`
    - `source/transactions/service/QuorumPsbtSigningService.java`
    - `source/transactions/infra/MpcSidecarClient.java`
    - `source/transactions/infra/MpcPlatformTransactionSignerAdapter.java`
  - Como implementar:
    1. Validar endereco por network antes de qualquer debito.
    2. Validar fee cap.
    3. Criar preflight de funding quando possivel.
    4. Persistir metadata do PSBT: hash, signers aceitos, provider ref, txid.
    5. Validar identidade dos signers e numero minimo.
    6. Tratar broadcast timeout como `UNKNOWN`, nao sucesso/falha imediata.
  - Testes minimos:
    - Endereco network errada.
    - Signer insuficiente.
    - Signer invalido.
    - Broadcast timeout.
    - Retry idempotente.
  - Criterios de aceite:
    - Timeout no broadcast nao causa refund inseguro.
    - Signer nao autorizado nao entra no quorum.
  - Descricao obrigatoria ao concluir:
    - Validacoes: destino onchain validado por `bitcoin.network` antes de ledger; fee cap absoluto/percentual em `ExternalPaymentsFeePolicy`; preflight de funding via `ExternalPaymentsCustodyPort.preflightOnchain`; quorum exige endpoints suficientes e signer identity quando `quorum.psbt.require-signer-identity=true`.
    - Metadata persistida: `QuorumPsbtSigningService` persiste somente metadata sem segredo (`fundedPsbtHash`, `combinedPsbtHash`, `rawTxHash`, signers aceitos, fee, status e txid), substituindo payload bruto de PSBT.
    - Estados ambiguos: falha/timeout depois de finalize/broadcast vira `ProviderExecutionAmbiguous`; `SendOnchainPaymentUseCase` mantem debito, marca transfer `AUTO_RESOLUTION_PENDING` e outbox `UNKNOWN`, sem refund automatico inseguro.
    - Testes: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.service.QuorumPsbtSigningServiceTest --tests source.transactions.service.ExternalPaymentsServiceTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest --tests source.transactions.service.ExternalProviderOutboxServiceTest --tests source.config.ProductionMockProfileConditionTest`.

- [ ] E5 - Endurecer Lightning inbound/outbound.
  - Arquivos a alterar:
    - `source/transactions/application/externalpayments/*Lightning*`
    - `source/transactions/service/NetworkTransferLifecycleService.java`
    - `source/transactions/service/InboundTransferMonitorService.java`
    - `source/transactions/monitoring/LightningNetworkMonitorService.java`
  - Como implementar inbound:
    1. Invoice tem payment hash unico.
    2. Settlement dedupe por payment hash.
    3. Amount recebido precisa bater com esperado ou politica de over/under payment.
    4. Invoice expirada nao liquida sem evento valido.
  - Como implementar outbound:
    1. Validar invoice, expiry, amount, fee limit.
    2. Debitar/lockar antes de enviar.
    3. `IN_FLIGHT/UNKNOWN` vai para reconciliacao.
    4. Refund apenas em falha terminal.
  - Testes minimos:
    - Invoice duplicada.
    - Invoice expirada.
    - Payment in flight.
    - Fee acima do limite.
    - Retry nao paga duas vezes.
  - Criterios de aceite:
    - Payment hash e chave de dedupe.
    - Unknown nao e tratado como falha final.
  - Descricao obrigatoria ao concluir:
    - Inbound:
    - Outbound:
    - Politica unknown:
    - Testes:

- [ ] E6 - Validar webhook BTCPay.
  - Arquivos a alterar:
    - `source/transactions/controller/BtcPayWebhookController.java`
    - `source/transactions/service/BtcPayWebhookService.java`
  - Como implementar:
    1. Validar assinatura/token por store.
    2. Dedupe por event id.
    3. Comparar amount/currency/invoice id com registro interno.
    4. Ignorar evento fora de ordem que tenta regredir estado final.
    5. Registrar evento de auditoria.
  - Testes minimos:
    - Assinatura invalida.
    - Replay.
    - Amount divergente.
    - Evento desconhecido.
    - Evento fora de ordem.
  - Criterios de aceite:
    - Webhook publico nao muta estado sem autenticacao propria.
  - Descricao obrigatoria ao concluir:
    - Verificacao:
    - Dedupe:
    - Testes:

## Pacote F - Security, prod e attestation

Objetivo: producao nao sobe com simulacao, segredo fraco, origin errada ou attestation falsa.

- [ ] F1 - Revisar `Security.java` com inventario.
  - Arquivo:
    - `source/auth/application/infra/security/Security.java`
  - Como implementar:
    1. Comparar `requestMatchers(...).permitAll()` com `docs/API_INVENTORY.md`.
    2. Remover permissao para endpoint inexistente.
    3. Webhook publico precisa validacao propria.
    4. Swagger/docs publicos so se politica permitir.
    5. `/ws/**` pode ser publico no handshake, mas CONNECT deve exigir token.
  - Testes minimos:
    - Endpoint financeiro anonimo retorna 401/403.
    - Webhook anonimo sem assinatura retorna 401/403 ou erro seguro.
    - Health live continua publico.
  - Criterios de aceite:
    - Superficie publica documentada e testada.
  - Descricao obrigatoria ao concluir:
    - Permissoes removidas:
    - Permissoes mantidas:
    - Testes:

- [ ] F2 - Endurecer checks de producao.
  - Arquivos:
    - `source/config/production/BooleanPropertyProductionSafetyCheck.java`
    - `source/config/production/TextPropertyProductionSafetyCheck.java`
    - `source/config/production/MockBeanProductionSafetyCheck.java`
    - `application-prod.properties`
  - Como implementar:
    1. Adicionar novas propriedades criadas pelos pacotes D/E/F.
    2. Bloquear localhost, wildcard, changeme, example, secret curto.
    3. Validar xpub, URLs de signer, LND TLS/macaroon, Bitcoin RPC, Vault/Raft.
    4. Garantir que status admin mascara valores.
  - Testes minimos:
    - Profile prod com placeholder falha.
    - Profile local permite simulacao apenas quando explicitamente local.
  - Criterios de aceite:
    - Prod fail-closed.
  - Descricao obrigatoria ao concluir:
    - Propriedades adicionadas:
    - Placeholders bloqueados:
    - Testes:

- [ ] F3 - Remote attestation sem fallback silencioso em prod.
  - Arquivos:
    - `source/security/RemoteAttestationService.java`
    - `backend/vault/src/main/java/vault/security/TpmAttestationService.java`
    - docs de security.
  - Como implementar:
    1. Separar modos:
       - `LOCAL_SIMULATED`.
       - `HMAC_ATTESTATION`.
       - `TPM_QUOTE_REAL`.
    2. Em prod, `LOCAL_SIMULATED` deve falhar.
    3. Detectar versao de `tpm2-tools` antes de montar comando.
    4. Validar nonce, PCRs, assinatura e freshness.
    5. Documentar claramente o que o vault valida hoje.
  - Testes minimos:
    - Local sem TPM gera status simulated.
    - Prod sem TPM falha.
    - Nonce replay falha.
  - Criterios de aceite:
    - Produto nao declara TPM real quando esta usando HMAC/simulacao.
  - Descricao obrigatoria ao concluir:
    - Modo prod:
    - Modo local:
    - Vault alinhado:
    - Testes:

- [ ] F4 - Migrar crypto legacy sem HMAC.
  - Arquivos:
    - `source/security/StringCryptoConverter.java`
    - entidades com campos criptografados.
  - Como implementar:
    1. Detectar leituras legacy e metricar.
    2. Criar job dry-run de contagem.
    3. Criar job de regravacao versionada.
    4. Depois da migracao, bloquear legacy em prod.
    5. Documentar rollback por backup.
  - Testes minimos:
    - Valor legacy decrypta local.
    - Job migra para formato novo.
    - HMAC adulterado falha.
    - Prod recusa legacy apos flag.
  - Criterios de aceite:
    - Campo criptografado sem autenticacao nao permanece aceito em prod.
  - Descricao obrigatoria ao concluir:
    - Campos migrados:
    - Job:
    - Flag prod:
    - Testes:

## Pacote G - WebSocket e notificacoes

Objetivo: eventos privados so chegam ao dono e eventos sao enviados apos commit.

- [ ] G1 - Criar policy de autorizacao por destino STOMP.
  - Arquivos:
    - `source/config/websocket/inbound/SubscribeAuthorizationStompMessageHandler.java`
    - `source/config/websocket/inbound/StompMessageContext.java`
    - testes em `source/config`
  - Como implementar:
    1. Criar classe `StompDestinationAuthorizationPolicy`.
    2. Regras recomendadas:
       - `/user/queue/**`: autenticado.
       - `/queue/**`: bloquear subscribe direto se nao for user destination seguro.
       - `/topic/payment-request/{linkId}`: permitir apenas criador/pagador se houver lookup seguro; caso contrario migrar para `/user/queue/payment-request`.
       - `/topic/balance/**`: bloquear; usar `/user/queue/balance`.
       - destinos desconhecidos: bloquear.
    3. Handler chama policy no SUBSCRIBE.
  - Testes minimos:
    - Usuario sem auth bloqueado.
    - Usuario autenticado em destino publico permitido se existir.
    - Usuario tenta assinar recurso de outro e falha.
    - Destino desconhecido falha.
  - Criterios de aceite:
    - Nao ha topico privado aberto por obscuridade de id.
  - Descricao obrigatoria ao concluir:
    - Policy:
    - Destinos permitidos:
    - Destinos bloqueados:
    - Testes:

- [ ] G2 - Migrar payment request event para user destination ou validar ownership.
  - Arquivos:
    - `source/ledger/event/PaymentRequestEventPublisher.java`
    - services de payment request.
  - Como implementar:
    1. Preferir `convertAndSendToUser(userId, "/queue/payment-request", event)`.
    2. Se manter `/topic/payment-request/{linkId}`, criar lookup do link no SUBSCRIBE para validar dono.
    3. Nao enviar DTO completo com dados sensiveis para topico adivinhavel.
    4. Adicionar event id e schema version.
  - Testes minimos:
    - Dono recebe evento.
    - Outro usuario nao assina.
    - Evento apos rollback nao e enviado.
  - Criterios de aceite:
    - Link id nao e segredo de autorizacao.
  - Descricao obrigatoria ao concluir:
    - Estrategia escolhida:
    - DTO/evento:
    - Testes:

- [ ] G3 - Completar device token e preferencias.
  - Arquivos:
    - `source/notification/controller/NotificationController.java`
    - `source/notification`
    - `frontend/lib`
  - Como implementar:
    1. Criar endpoints:
       - `POST /notifications/device-tokens`
       - `DELETE /notifications/device-tokens/{id}`
       - `GET /notifications/preferences`
       - `PUT /notifications/preferences`
    2. Armazenar token com hash unico e valor criptografado se necessario.
    3. Nao retornar token puro.
    4. Frontend deve chamar endpoint real.
  - Testes minimos:
    - Registro duplicado.
    - Revogacao.
    - Usuario nao revoga token de outro.
    - Preferencia opt-out.
  - Criterios de aceite:
    - Config frontend nao aponta para endpoint inexistente.
  - Descricao obrigatoria ao concluir:
    - Endpoints:
    - Entidades:
    - Frontend:
    - Testes:

## Pacote H - Frontend alinhado ao backend

Objetivo: o app ficar pronto de verdade, sem UI chamando contrato morto.

- [ ] H1 - Mapear chamadas HTTP do frontend.
  - Arquivos:
    - `frontend/lib`
    - `docs/API_INVENTORY.md`
  - Como implementar:
    1. Rodar:
       ```bash
       rg -n "http|dio|ApiClient|/auth|/wallet|/ledger|/payments|/transactions|/deposit|/notifications|/bitcoin|/mining" frontend/lib
       ```
    2. Criar tabela `docs/FRONTEND_BACKEND_CONTRACT_MATRIX.md`.
    3. Para cada chamada:
       - tela/feature;
       - endpoint;
       - DTO esperado;
       - status: canonico, legado, inexistente, precisa migrar.
  - Criterios de aceite:
    - Nenhuma chamada frontend fica sem endpoint backend correspondente.
  - Descricao obrigatoria ao concluir:
    - Matriz criada:
    - Chamadas canonicas:
    - Chamadas legadas:
    - Chamadas inexistentes:

- [ ] H2 - Migrar frontend para `payments` onde for canonico.
  - Como implementar:
    1. Trocar chamadas de transferencia interna para quote/confirm/status.
    2. Adaptar UI para estados:
       - quoted;
       - processing;
       - accepted by provider;
       - requires reconciliation;
       - settled;
       - failed;
       - expired;
       - canceled.
    3. Mostrar erro por `code`, nao por string bruta.
    4. Garantir idempotency key persistida por tentativa.
  - Testes minimos:
    - Parse de DTO payment status.
    - UI de erro por codigo.
    - Retry com mesma idempotency key.
  - Criterios de aceite:
    - Frontend nao usa endpoint legado para fluxo migrado.
  - Descricao obrigatoria ao concluir:
    - Features migradas:
    - DTOs:
    - Testes:

- [ ] H3 - Revisar beleza e estados visuais dos fluxos criticos.
  - Telas a revisar:
    - Login/signup/passkey/TOTP.
    - Security status.
    - Wallet summary.
    - Enviar pagamento.
    - Receber deposito.
    - Historico/extrato.
    - Notificacoes.
    - Admin/status se exposto.
  - Como implementar:
    1. Usar design system existente.
    2. Garantir estados loading, empty, error, success, pending, requires action.
    3. Evitar texto tecnico.
    4. Garantir que botoes nao estouram em mobile.
    5. Garantir que valores financeiros tem formatacao consistente.
  - Testes/comandos:
    ```bash
    cd frontend && flutter analyze --no-pub
    cd frontend && flutter test --no-pub
    cd frontend && flutter build web --no-pub
    ```
  - Criterios de aceite:
    - Fluxos financeiros nao exibem estado inexistente no backend.
  - Descricao obrigatoria ao concluir:
    - Telas alteradas:
    - Estados cobertos:
    - Testes:

## Pacote I - Observabilidade, CI e release

Objetivo: operacao consegue detectar falha antes de virar perda financeira.

- [ ] I1 - Correlation id de ponta a ponta.
  - Arquivos:
    - filtros web/logging.
    - `GlobalExceptionHandler`.
    - ledger/outbox/audit services.
  - Como implementar:
    1. Criar/confirmar filtro que injeta `X-Correlation-Id`.
    2. Incluir no MDC de logs.
    3. Persistir em audit/outbox/ledger metadata.
    4. Retornar no erro da API.
  - Testes minimos:
    - Request sem id gera id.
    - Request com id valido preserva.
    - Erro retorna id.
  - Criterios de aceite:
    - Um pagamento pode ser rastreado por correlation id.
  - Descricao obrigatoria ao concluir:
    - Filtro:
    - Persistencia:
    - Testes:

- [ ] I2 - Metricas financeiras obrigatorias.
  - Metricas recomendadas:
    - `payment_intent_created_total`
    - `payment_intent_settled_total`
    - `payment_intent_failed_total`
    - `payment_outbox_backlog`
    - `payment_outbox_oldest_age_seconds`
    - `external_transfer_auto_resolution_pending`
    - `ledger_idempotency_duplicate_total`
    - `financial_reconciliation_issues_total`
    - `webhook_replay_rejected_total`
    - `attestation_simulated_status`
    - `provider_down_total`
  - Como implementar:
    1. Usar Micrometer/metric abstraction existente.
    2. Taggear por rail/status/provider sem dados pessoais.
    3. Criar docs de alerta.
  - Criterios de aceite:
    - Backlog/outbox e reconciliacao aparecem em metricas.
  - Descricao obrigatoria ao concluir:
    - Metricas:
    - Tags:
    - Alertas:
    - Testes:

- [ ] I3 - CI minimo de release.
  - Comandos:
    ```bash
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar
    cd backend/mpc-sidecar && go test ./...
    cd frontend && flutter analyze --no-pub
    cd frontend && flutter test --no-pub
    cd frontend && flutter build web --no-pub
    cd backend/vault && mvn test
    ```
  - Como implementar:
    1. Atualizar pipeline existente ou criar workflow.
    2. Separar job local/unit de job staging/provider.
    3. Configurar NVD key para dependency check se usado.
    4. Arquivar relatorios.
  - Criterios de aceite:
    - Merge bloqueia teste quebrado em backend/frontend/sidecar.
    - Falha por `mvn` ausente e resolvida no runner.
  - Descricao obrigatoria ao concluir:
    - Workflow:
    - Jobs:
    - Artefatos:
    - Falhas conhecidas:

## Pacote J - Cleanup e declaracao de pronto

- [ ] J1 - Procurar e resolver marcadores de risco.
  - Comando:
    ```bash
    rg -n "TODO|FIXME|HACK|temporary|legacy|deprecated|UnsupportedOperationException|simulation|mock|stub|findAll\\(" backend/kerosene/src/main/java/source frontend/lib backend/mpc-sidecar backend/vault docs
    ```
  - Como implementar:
    1. Classificar cada ocorrencia.
    2. Resolver as que afetam producao, dinheiro ou seguranca.
    3. Documentar as que ficam.
  - Criterios de aceite:
    - Nenhum risco P0/P1 fica apenas como TODO.
  - Descricao obrigatoria ao concluir:
    - Ocorrencias resolvidas:
    - Ocorrencias aceitas:
    - Justificativa:

- [ ] J2 - Atualizar readiness final.
  - Arquivos:
    - `docs/PRODUCTION_READINESS.md`
    - `backend/kerosene/docs/FINANCIAL_HARDENING_STATUS.md`
    - `docs/ULTIMATE_REFACTOR.md`
    - este playbook.
  - Como implementar:
    1. Marcar o que foi fechado.
    2. Separar pendencias bloqueantes e nao bloqueantes.
    3. Criar secao `Release decision`.
  - Criterios de aceite:
    - Existe resposta objetiva: pronto ou nao pronto para producao.
  - Descricao obrigatoria ao concluir:
    - Status final:
    - Bloqueadores:
    - Nao bloqueadores:
    - Testes finais:

## Matriz de testes por pacote

| Pacote | Testes focados | Suite ampla |
| --- | --- | --- |
| A | inventario manual + controller tests existentes | `./gradlew test` |
| B | `GlobalExceptionHandlerTest`, parse frontend | backend + frontend tests |
| C | `TransactionParticipantResolverTest`, wallet tests, ledger tests | backend tests |
| D | `PaymentConfirmServiceTest`, `PaymentExecutionOutboxServiceTest`, `PaymentExternalExecutionProcessorTest`, novos tests de state machine | backend tests |
| E | transactions service tests, reconciliation tests, webhook tests | backend tests + staging smoke |
| F | security/prod config tests, attestation tests | backend bootJar + prod context tests |
| G | websocket interceptor tests, notification tests | backend tests |
| H | Flutter parse/widget tests | `flutter analyze --no-pub`, `flutter test --no-pub`, `flutter build web --no-pub` |
| I | metric/correlation tests, CI dry run | CI |
| J | full validation | all commands aplicaveis |

## Ordem de merge recomendada

1. Docs de inventario e state machine.
2. Error contract com compatibilidade.
3. Wallet destination hash migration + resolver.
4. Ledger metadata/idempotencia.
5. Payment state machine.
6. Payment outbox claim/retry.
7. Payment external reconciliation.
8. Legacy external provider outbox worker.
9. Onchain/Lightning provider split.
10. Webhook BTCPay hardening.
11. Security/prod checks.
12. WebSocket ownership.
13. Notifications device tokens.
14. Frontend migration.
15. Observability/CI/readiness.

## Checklist final para o agente antes de encerrar qualquer sessao

- [ ] Rodei `git status --short` e sei quais arquivos eu alterei.
- [ ] Nao reverti alteracao do usuario.
- [ ] Atualizei o checkbox correspondente.
- [ ] Preenchi a descricao obrigatoria.
- [ ] Rodei teste focado.
- [ ] Rodei suite ampla se toquei dinheiro, auth, ledger, security ou provider externo.
- [ ] Atualizei docs quando contrato mudou.
- [ ] Nao deixei endpoint frontend quebrado.
- [ ] Nao deixei fallback silencioso em producao.
- [ ] Nao adicionei segredo, valor real de env, token, macaroon, chave ou compose materializado.

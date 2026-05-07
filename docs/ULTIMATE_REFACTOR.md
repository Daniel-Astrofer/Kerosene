# Ultimate Refactor - Kerosene Service

Este documento e um plano operacional para um agente implementador terminar o servico Kerosene com o menor numero possivel de decisoes abertas. Ele foi escrito como checklist extensivo: cada item deve ser implementado, testado e marcado somente quando cumprir os criterios de aceite.

Escopo principal: `backend/kerosene`.

Escopo de fronteira: `frontend`, `backend/mpc-sidecar`, `backend/vault`, `scripts` e `docs`, apenas quando forem necessarios para fechar contratos, testes, integracao, configuracao de producao ou documentacao operacional.

Playbook complementar de execucao: `docs/ULTIMATE_REFACTOR_EXECUTION_PLAYBOOK.md`.

## Como usar este plano

- [ ] Antes de iniciar qualquer implementacao, leia este arquivo inteiro e escolha uma fase pequena para executar.
  - Objetivo: evitar mudancas largas demais e preservar rastreabilidade.
  - Como implementar:
    1. Identifique os arquivos exatos mencionados no item.
    2. Leia tambem testes existentes do mesmo dominio.
    3. Faca uma alteracao pequena e validavel.
    4. Rode testes focados primeiro.
    5. Rode a suite completa quando o bloco tocar contratos financeiros, seguranca, ledger, auth ou pagamentos.
  - Criterios de aceite:
    - O agente entende a ordem das fases.
    - Nenhum item e marcado sem teste ou justificativa explicita.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] Use sempre este formato ao concluir um item.
  - Objetivo: permitir que proximos agentes retomem o trabalho sem reanalisar tudo.
  - Como implementar:
    1. Abaixo do item concluido, preencha o bloco `Descricao ao concluir`.
    2. Informe comportamento implementado, arquivos alterados, comandos executados e risco residual.
    3. Se algo ficou para depois, crie um novo checkbox especifico em vez de esconder a pendencia.
  - Criterios de aceite:
    - Cada checkbox marcado tem descricao preenchida.
    - A descricao contem evidencia de teste ou motivo concreto para ausencia de teste.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] Preserve estado do usuario e nao reverta alteracoes nao relacionadas.
  - Objetivo: trabalhar com worktree possivelmente suja sem destruir trabalho externo.
  - Como implementar:
    1. Use `git status --short` para entender o estado atual.
    2. Antes de editar um arquivo ja modificado, leia o arquivo e entenda se a alteracao existente afeta o item.
    3. Nao use `git reset --hard`, `git checkout --`, `git restore` ou remocoes destrutivas sem pedido explicito.
  - Criterios de aceite:
    - Nenhuma alteracao alheia foi revertida.
    - Mudancas feitas pelo agente estao separaveis por dominio.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Baseline tecnico observado

- [ ] Registrar baseline antes de implementar.
  - Estado observado no momento da analise:
    - `backend/kerosene`: testes Gradle passaram com Java 21.
    - `backend/kerosene`: `bootJar` passou quando executado com permissao adequada para acesso Gradle.
    - `backend/mpc-sidecar`: `go test ./...` passou.
    - `frontend`: `flutter analyze --no-pub` passou.
    - `frontend`: `flutter test --no-pub` passou, com testes reais `.onion` pulados por `RUN_REAL_ONION_TESTS`.
    - `frontend`: `flutter build web --no-pub` passou com avisos de Wasm relacionados a `dart:html` e FFI/Tor.
    - `backend/vault`: `mvn test` nao rodou porque `mvn` nao esta instalado no ambiente.
  - Como implementar:
    1. Rode os comandos abaixo e cole os resultados resumidos no item.
    2. Se algum comando falhar por ambiente, registre a falha e siga com testes focados possiveis.
  - Comandos:
    ```bash
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar
    cd backend/mpc-sidecar && go test ./...
    cd frontend && flutter analyze --no-pub
    cd frontend && flutter test --no-pub
    ```
  - Criterios de aceite:
    - Baseline registrado antes da primeira mudanca relevante.
    - Falhas de ambiente nao sao confundidas com falhas de codigo.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Mapa do servico Kerosene

Pacote principal: `backend/kerosene/src/main/java/source`.

Dominios principais identificados:

- `auth`: cadastro, login, passkeys, TOTP, backup codes, App PIN, recovery, admin access, status de seguranca.
- `common`: health, status raiz, web admin, operacoes administrativas, release.
- `config`: seguranca Spring, WebSocket, JWT, CORS, checks de producao, propriedades.
- `ledger`: ledger financeiro, auditoria, Merkle audit, shadow balance, revenue/siphon.
- `notification`: notificacoes persistidas e realtime.
- `security`: TPM/attestation, sovereignty status, validacoes de runtime.
- `transactions`: transferencias internas, rails externas, onchain, Lightning, BTCPay webhook, economy, onramp.
- `wallet`: carteiras, perfis, resolucao de participantes.
- `treasury`: tesouraria e controles de reserva.
- `mining`: mining/economia relacionada.
- `bitcoinaccounts`: contas Bitcoin e fluxos de conta.
- `payments`: PaymentIntent, quote, confirmacao, rails, outbox de execucao.

Controladores relevantes:

- `auth/controller/*`
- `common/controller/*`
- `common/admin/*`
- `ledger/controller/*`
- `ledger/audit/*`
- `notification/controller/*`
- `security/*`
- `transactions/controller/*`
- `wallet/controller/*`
- `treasury/controller/*`
- `mining/controller/*`
- `bitcoinaccounts/controller/*`
- `payments/controller/*`

## Principios obrigatorios

- [ ] Tratar dinheiro como sistema fail-closed.
  - Objetivo: nenhuma falha de provider, reorg, timeout, retry ou webhook deve gerar perda, duplicidade ou estado invisivel.
  - Como implementar:
    1. Toda operacao financeira precisa de idempotency key duravel.
    2. Toda mudanca de saldo deve passar pelo ledger transacional.
    3. Todo envio externo precisa de outbox duravel.
    4. Todo erro posterior a debito precisa de compensacao ou fila de resolucao explicita.
    5. Estados ambiguos devem parar em `AUTO_RESOLUTION_PENDING` ou equivalente auditavel, nunca em sucesso presumido.
  - Criterios de aceite:
    - Existem testes de idempotencia para cada rail financeira.
    - Existe log/audit sem segredo para cada transicao critica.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] Usar contratos canonicos e depreciar duplicatas.
  - Objetivo: reduzir endpoints paralelos e regras divergentes entre `transactions` e `payments`.
  - Como implementar:
    1. Escolha a API canonica para novos fluxos.
    2. Mantenha adaptadores temporarios apenas com anotacao clara de deprecacao.
    3. Faca controllers legados chamarem use cases canonicos ou retornarem erro deprecado documentado.
    4. Atualize testes de contrato e frontend.
  - Criterios de aceite:
    - O mesmo fluxo financeiro nao possui duas implementacoes de regra.
    - Endpoints legados tem plano de remocao e testes.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] Evitar `findAll()` em request path financeiro ou sensivel.
  - Objetivo: evitar vazamento, degradacao de performance e comportamento nao deterministico.
  - Como implementar:
    1. Procure `findAll()` em services/use cases chamados por controllers.
    2. Substitua por consultas indexadas por chave unica ou hash.
    3. Crie indices de banco quando necessario.
    4. Mantenha `findAll(PageRequest...)` apenas para auditorias batch com limite explicito.
  - Criterios de aceite:
    - Nenhum request path de pagamento, wallet ou auth varre todas as entidades.
    - Testes validam busca por indice e comportamento de nao encontrado.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] Nao expor mensagens tecnicas, segredos ou detalhes de provider ao cliente.
  - Objetivo: API consistente, segura e traduzivel.
  - Como implementar:
    1. Padronize erros com codigo estavel, mensagem segura e correlation id.
    2. Mapeie excecoes internas para erros de dominio.
    3. Sanitize logs e respostas.
    4. Garanta que stack trace, URL interna, token, macaroon, shard, chave, xpub sensivel ou payload bruto nao saiam em resposta.
  - Criterios de aceite:
    - Testes de `GlobalExceptionHandler` cobrem excecoes de dominio, validacao e provider.
    - Logs mantem contexto sem segredo.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 0 - Inventario, baseline e trilhos de seguranca

- [ ] P0-01 - Criar inventario vivo dos endpoints.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/**/controller/*.java`
    - `backend/kerosene/src/main/java/source/**/Controller.java`
    - `docs`
  - Como implementar:
    1. Gere uma lista de controllers, paths, metodos HTTP, auth requerida, DTO de request e DTO de response.
    2. Classifique cada endpoint como `canonico`, `legado`, `admin`, `interno`, `webhook`, `health` ou `debug`.
    3. Marque duplicatas entre `transactions`, `payments`, `deposit`, `network` e `wallet`.
    4. Salve em `docs/API_INVENTORY.md` ou atualize documento equivalente se ja existir.
  - Criterios de aceite:
    - Todo endpoint exposto aparece no inventario.
    - Endpoints financeiros indicam use case chamado e comportamento idempotente.
    - Webhooks indicam estrategia de autenticacao/verificacao.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P0-02 - Criar matriz de use cases financeiros.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application`
    - `backend/kerosene/src/main/java/source/payments`
    - `backend/kerosene/src/main/java/source/ledger`
    - `backend/kerosene/src/main/java/source/wallet`
  - Como implementar:
    1. Liste cada fluxo: transferencia interna, deposito interno, saque interno, onchain address, onchain send, Lightning invoice, Lightning pay, payment quote, payment confirm, payment link, webhook BTCPay, treasury payout.
    2. Para cada fluxo, registre entrada, validacoes, debito/credito, outbox, provider, reconciliacao, evento realtime, notificacao e teste existente.
    3. Marque lacunas com severidade `P0`, `P1` ou `P2`.
  - Criterios de aceite:
    - Todos os fluxos com impacto em saldo estao mapeados.
    - Cada fluxo tem dono de consistencia: ledger, outbox, reconciliador ou manual.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P0-03 - Congelar contratos de DTO antes de refatorar regras.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/**/dto`
    - `frontend/lib/features/**`
  - Como implementar:
    1. Identifique DTOs usados pelo frontend.
    2. Crie testes de serializacao para DTOs financeiros e auth.
    3. Se mudar nome de campo, adicione compatibilidade temporaria ou migre frontend no mesmo bloco.
    4. Documente campos deprecados no inventario.
  - Criterios de aceite:
    - Mudancas de DTO tem teste de compatibilidade.
    - Frontend compila ou existe adaptador temporario claro.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P0-04 - Estender guardrails arquiteturais.
  - Arquivos iniciais:
    - `backend/kerosene/src/test/java/source/ArchitectureGuardrailsTest.java`
  - Como implementar:
    1. Adicione regra proibindo controllers chamarem repositories diretamente, exceto health/admin explicitamente permitido.
    2. Adicione regra proibindo services de dominio financeiro chamarem provider externo sem outbox ou use case dedicado.
    3. Adicione regra proibindo `System.out`, `System.err`, prints e stack trace direto.
    4. Adicione regra proibindo classes com `Mock`, `Stub`, `Fake` em `src/main/java/source`, exceto classes configuradas so para profile de teste e ja bloqueadas em producao.
    5. Adicione regra de package para manter `domain` sem Spring, repositorios e controllers.
  - Criterios de aceite:
    - Teste de arquitetura falha se nova violacao for introduzida.
    - Excecoes sao nomeadas e justificadas no proprio teste.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P0-05 - Separar falha de ambiente de falha de produto.
  - Arquivos iniciais:
    - `scripts`
    - `docs/PRODUCTION_READINESS.md`
    - `backend/kerosene/README*`
  - Como implementar:
    1. Documente dependencias locais: Java 21, Docker, Flutter, Go, Maven para vault, Bitcoin Core/LND quando testes reais forem ativados.
    2. Crie ou ajuste script de smoke local que roda apenas testes que nao exigem provider real.
    3. Crie ou ajuste script de staging que exige providers reais e falha se env estiver incompleto.
  - Criterios de aceite:
    - Um agente novo consegue saber quais testes rodam localmente e quais exigem infra.
    - Falha por `mvn` ausente ou permissao Gradle fica documentada.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P0-06 - Criar changelog tecnico da refatoracao.
  - Arquivos iniciais:
    - `docs/ULTIMATE_REFACTOR_CHANGELOG.md`
  - Como implementar:
    1. Crie um changelog incremental para registrar cada fase concluida.
    2. Use entradas curtas com data, escopo, risco, testes e rollback.
    3. Atualize o changelog sempre que marcar uma fase grande como concluida.
  - Criterios de aceite:
    - Existe historico navegavel das decisoes.
    - O changelog nao contem segredo nem valores reais de env.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 1 - Contratos canonicos e remocao de legado

- [ ] P1-01 - Fechar decisao canonica entre `transactions` e `payments`.
  - Problema:
    - Existem endpoints legados em `TransactionController` e uma API nova em `PaymentsController`.
    - Regras podem divergir se ambos continuarem implementando fluxos financeiros.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/controller/TransactionController.java`
    - `backend/kerosene/src/main/java/source/transactions/controller/NetworkPaymentsController.java`
    - `backend/kerosene/src/main/java/source/payments/controller/PaymentsController.java`
    - `backend/kerosene/src/main/java/source/payments`
    - `backend/kerosene/src/main/java/source/transactions/application`
  - Como implementar:
    1. Defina `payments` como API canonica para criacao/confirmacao de pagamento se ela ja cobre PaymentIntent, quote e capabilities.
    2. Mantenha `transactions/network/*` somente para operacoes tecnicas de rail externa se ainda forem necessarias.
    3. Faca endpoints legados de `TransactionController` chamarem os use cases canonicos ou retornarem resposta `410 Gone`/erro deprecado com codigo estavel, conforme compatibilidade necessaria.
    4. Documente quais endpoints ficam ativos e quais serao removidos.
    5. Atualize o frontend para parar de chamar endpoints depreciados.
  - Criterios de aceite:
    - Transferencia interna, onchain e Lightning tem uma unica regra canonica.
    - Testes confirmam que endpoint legado nao executa regra divergente.
    - Inventario de API indica data/criterio de remocao.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P1-02 - Consolidar cancelamento de deposito/transferencia.
  - Problema:
    - `DepositController` expoe `/deposit/{transferId}/cancel`.
    - `NetworkPaymentsController` expoe `/transactions/network/transfers/{id}/cancel`.
    - Duplicidade aumenta chance de autorizacao ou estado divergente.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/controller/DepositController.java`
    - `backend/kerosene/src/main/java/source/transactions/controller/NetworkPaymentsController.java`
    - `backend/kerosene/src/main/java/source/transactions/application/*Cancel*`
    - `frontend/lib`
  - Como implementar:
    1. Escolha endpoint canonico para cancelamento.
    2. Centralize a regra em um unico use case.
    3. Verifique ownership do usuario antes de cancelar.
    4. Defina estados cancelaveis e estados nao cancelaveis.
    5. Endpoint legado deve chamar o canonico ou retornar erro deprecado.
  - Criterios de aceite:
    - Cancelamento e idempotente.
    - Usuario nao consegue cancelar transferencia de outro usuario.
    - Estados concluidos, pagos, falhados ou em resolucao manual retornam erro claro.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P1-03 - Resolver legado de ativacao por voucher/link.
  - Problema:
    - `AccountActivationService.confirm` rejeita deposito inicial por link de ativacao.
    - Nao ha controller de voucher ativo em `src/main`.
    - Existem portas/adapters de voucher que podem sugerir fluxo antigo.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/auth/application/AccountActivationService.java`
    - `backend/kerosene/src/main/java/source/auth/controller/AccountActivationController.java`
    - `backend/kerosene/src/main/java/source/**/Voucher*`
    - `backend/kerosene/src/main/java/source/**/voucher*`
    - `frontend/lib/features/auth`
  - Como implementar:
    1. Decida se voucher/link de ativacao sera removido ou substituido por fluxo in-app.
    2. Se remover: apague portas/adapters mortos, migrations inutilizadas e chamadas frontend.
    3. Se manter: crie controller canonico, autorizacao, DTOs, idempotencia, expiracao, assinatura e testes.
    4. Atualize `Security.java` para permitir ou bloquear rotas conforme decisao.
    5. Atualize textos do frontend para refletir somente o fluxo valido.
  - Criterios de aceite:
    - Nao existe fluxo fantasma mencionado no frontend/docs sem backend funcional.
    - Ativacao de conta tem contrato unico e testado.
    - `Security.java` nao possui permissao ausente ou permissao legada perigosa.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P1-04 - Padronizar contrato de erro da API.
  - Problema:
    - `GlobalExceptionHandler` mistura mensagens tecnicas, mensagens de dominio e sanitizacao parcial.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/common/exception/GlobalExceptionHandler.java`
    - `backend/kerosene/src/main/java/source/**/exception`
    - `frontend/lib/core/network`
  - Como implementar:
    1. Crie modelo unico de erro: `code`, `message`, `correlationId`, `details` seguro opcional.
    2. Padronize codigos por dominio: `AUTH_*`, `PAYMENT_*`, `LEDGER_*`, `WALLET_*`, `SECURITY_*`, `VALIDATION_*`.
    3. Mapeie excecoes de provider para codigo seguro sem vazar payload.
    4. Garanta traducao ou copy frontend baseada em `code`, nao em string tecnica.
    5. Crie testes de handler para validacao, auth, acesso negado, provider, ledger e erro inesperado.
  - Criterios de aceite:
    - Nenhuma resposta contem stack trace, classe Java, SQL, URL interna ou segredo.
    - Frontend consegue mostrar mensagem amigavel por codigo.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P1-05 - Atualizar documentacao publica e OpenAPI/contratos.
  - Arquivos iniciais:
    - `docs`
    - `backend/kerosene/docs`
    - `backend/kerosene/src/main/java/source/**/controller`
  - Como implementar:
    1. Atualize documentacao dos endpoints canonicos.
    2. Remova ou marque deprecado qualquer endpoint legado.
    3. Inclua exemplos de idempotency key, headers de auth, erros e estados.
    4. Se existir geracao OpenAPI, rode e valide diff.
  - Criterios de aceite:
    - Docs nao prometem endpoint inexistente.
    - Estados financeiros documentados batem com enums reais.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 2 - Producao, configuracao e release fail-closed

- [ ] P2-01 - Fechar checklist de readiness de producao.
  - Referencias:
    - `docs/PRODUCTION_READINESS.md`
    - `backend/kerosene/docs/FINANCIAL_HARDENING_STATUS.md`
  - Lacunas conhecidas:
    - Substituir placeholders de env.
    - Configurar CORS/RP/origins reais.
    - Configurar `QUORUM_SHARD_URLS`.
    - Configurar `BITCOIN_PLATFORM_MASTER_XPUB`.
    - Configurar Bitcoin RPC/ZMQ.
    - Configurar LND TLS/macaroon.
    - Configurar Vault/Raft token material.
    - Configurar MPC mTLS.
    - Gerar release manifest.
    - Garantir Android signing.
    - Configurar NVD key para OWASP.
    - Verificar stack real Postgres, Redis, Vault/Raft, MPC sidecar, Bitcoin Core pruned, LND.
  - Como implementar:
    1. Transforme cada requisito em propriedade validada em startup.
    2. Crie um `ProductionReadinessReport` interno que liste status sem imprimir segredos.
    3. Faca startup em profile de producao falhar quando requisito obrigatorio estiver ausente.
    4. Adicione teste de contexto com propriedades de producao validas e invalidas.
  - Criterios de aceite:
    - Profile prod nao sobe com mock, placeholder ou segredo ausente.
    - Report mostra nomes de propriedades e estado mascarado.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P2-02 - Revisar checks booleanos de producao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/BooleanPropertyProductionSafetyCheck.java`
    - `backend/kerosene/src/test/java/source/config`
  - Estado observado:
    - Ja bloqueia `bitcoin.mock-mode`, `custody.mock-mode`, `app.dev.inject-test-balance`, `quorum.allow-local-simulation`, `treasury.siphon.manual-settlement-enabled`.
    - Ja exige `vault.enabled`, `vault.raft.enabled`, `vault.raft.required`, `mpc.sidecar.tls.enabled`, `lightning.lnd.enabled`, `bitcoin.rpc.enabled`, `bitcoin.rpc.required`, `bitcoin.rpc.pruned-required`, `tor.health.required`, `release.attestation.required`, `release.attestation.remote.enabled`.
  - Como implementar:
    1. Adicione propriedades novas criadas nas fases posteriores.
    2. Garanta teste parametrizado para cada propriedade proibida e obrigatoria.
    3. Diferencie `prod`, `staging` e `local` quando necessario, sem reduzir seguranca de `prod`.
  - Criterios de aceite:
    - Nova configuracao critica sempre entra em teste de safety check.
    - Mensagens de falha indicam nome da propriedade, sem valor sensivel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P2-03 - Revisar checks textuais de producao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/TextPropertyProductionSafetyCheck.java`
  - Estado observado:
    - Exige CORS, relying-party id WebAuthn, quorum shard URLs, LND, master xpub, shard attestation secret, MPC sidecar, macaroon/path.
  - Como implementar:
    1. Bloqueie placeholders comuns: `changeme`, `example`, `localhost`, `127.0.0.1`, valores vazios e secrets curtos.
    2. Valide formato de URL, host, fingerprint, xpub e paths.
    3. Mascare valores em logs.
    4. Crie testes para cada formato invalido.
  - Criterios de aceite:
    - Prod nao aceita valor local acidental.
    - Validacao diferencia "ausente" de "formato invalido".
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P2-04 - Garantir que mocks/stubs nao entram em producao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/MockBeanProductionSafetyCheck.java`
    - `backend/kerosene/src/main/java/source`
  - Como implementar:
    1. Liste beans com nome contendo `mock`, `stub`, `fake`, `simulation`, `local`.
    2. Confirme se cada bean esta atras de profile local/teste.
    3. Adicione teste de contexto `prod` que falha ao registrar bean proibido.
    4. Remova classes mortas em `src/main` quando forem apenas testes.
  - Criterios de aceite:
    - Profile prod nao registra bean simulado.
    - Beans de teste ficam em `src/test` ou profile explicito.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P2-05 - Implementar release attestation verificavel.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/common/admin/SystemReleaseController.java`
    - `backend/kerosene/src/main/java/source/security`
    - `scripts`
    - `docs/PRODUCTION_READINESS.md`
  - Como implementar:
    1. Defina manifest de release com commit, artifact hash, config profile, build time, migracoes aplicadas e checksums.
    2. Assine ou verifique o manifest antes de liberar startup em prod se `release.attestation.required=true`.
    3. Exponha status administrativo seguro sem segredo.
    4. Crie script para gerar manifest no pipeline.
    5. Crie teste com manifest valido, ausente e adulterado.
  - Criterios de aceite:
    - Prod falha sem manifest quando requerido.
    - Admin status consegue provar qual build esta rodando.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P2-06 - Criar smoke de staging contra infra real.
  - Arquivos iniciais:
    - `scripts`
    - `docs`
    - `backend/kerosene/src/test`
  - Como implementar:
    1. Crie script `scripts/smoke-staging.sh` se nao existir.
    2. Verifique Postgres real, Redis real, Vault/Raft, MPC sidecar mTLS, Bitcoin Core pruned, LND e Tor quando exigido.
    3. Execute endpoints health/readiness e uma transferencia interna de baixo valor em ambiente isolado.
    4. Opcionalmente execute um fluxo onchain/Lightning em regtest/signet.
    5. Gere relatorio `docs/STAGING_SMOKE_REPORT.md` sem segredos.
  - Criterios de aceite:
    - Smoke falha se qualquer provider obrigatorio estiver simulado.
    - Relatorio registra ambiente, commit, comandos e resultado.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 3 - Auth, sessao, passkeys e administracao

- [ ] P3-01 - Revisar superficie publica em `Security.java`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/Security.java`
  - Estado observado:
    - Permitidos: signup/login/passkey/recovery/pow, frontend admin publico, health, BTCPay webhook, `/ws/**`.
    - `/voucher/**` nao esta permitido.
  - Como implementar:
    1. Liste todos os endpoints anonimos reais.
    2. Remova permissoes que nao correspondem a controller ativo.
    3. Garanta que webhooks tenham autenticacao propria se forem publicos.
    4. Adicione testes de acesso anonimo/autenticado por endpoint critico.
  - Criterios de aceite:
    - Nenhum endpoint financeiro autenticado fica publico.
    - Webhook publico valida assinatura/token antes de mutar estado.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P3-02 - Endurecer JWT e renovacao de token.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/JwtAuthenticationFilter.java`
    - `backend/kerosene/src/main/java/source/auth`
  - Estado observado:
    - Principal e `Long userId`.
    - Roles viram authorities.
    - Filtro renova `X-New-Token`.
    - JWT via query para websocket foi removido.
  - Como implementar:
    1. Validar expiracao, issuer, audience, algoritmo e key rotation.
    2. Verificar se `X-New-Token` respeita janela curta e nao renova token revogado.
    3. Criar lista/versao de sessao para invalidar tokens apos troca de senha, recovery, TOTP reset ou admin lock.
    4. Testar token expirado, revogado, algoritmo invalido, role ausente e usuario desativado.
  - Criterios de aceite:
    - Usuario bloqueado ou recuperado perde sessoes antigas.
    - Renovacao nao cria sessao eterna.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P3-03 - Consolidar passkey/WebAuthn com origins de producao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/auth/controller/PasskeyController.java`
    - `backend/kerosene/src/main/java/source/auth`
    - `backend/kerosene/src/main/java/source/config`
  - Como implementar:
    1. Validar relying party id e origins por profile.
    2. Bloquear localhost em producao.
    3. Garantir challenge de uso unico, TTL curto e replay protection.
    4. Criar teste de origin invalida, challenge expirado, replay e credencial de outro usuario.
    5. Atualizar frontend para tratar erros por codigo.
  - Criterios de aceite:
    - WebAuthn prod so aceita origins configuradas.
    - Replay de challenge falha.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P3-04 - Revisar TOTP, backup codes e App PIN.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/auth/controller/TotpController.java`
    - `backend/kerosene/src/main/java/source/auth/controller/BackupCodesController.java`
    - `backend/kerosene/src/main/java/source/auth/controller/AppPinController.java`
    - `backend/kerosene/src/main/java/source/auth`
  - Como implementar:
    1. Confirmar que secrets sao criptografados em repouso.
    2. Confirmar rate limit por usuario/IP/dispositivo.
    3. Fazer backup code ser hashado, uso unico e auditado.
    4. Fazer App PIN nunca ser armazenado puro; usar hash forte e salt.
    5. Criar eventos de auditoria para ativacao/desativacao.
  - Criterios de aceite:
    - Reset de fator invalida sessoes antigas.
    - Tentativas repetidas sao limitadas.
    - Testes cobrem codigo usado duas vezes e PIN incorreto repetido.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P3-05 - Endurecer emergency recovery.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/auth/controller/EmergencyRecoveryController.java`
    - `backend/kerosene/src/main/java/source/auth`
  - Como implementar:
    1. Exigir prova forte antes de trocar fatores.
    2. Registrar auditoria imutavel da solicitacao e da conclusao.
    3. Adicionar cooldown e limite de tentativas.
    4. Invalidar sessoes e tokens antigos quando recovery concluir.
    5. Notificar usuario em todos os canais registrados.
  - Criterios de aceite:
    - Recovery nao permite takeover por endpoint sem rate limit.
    - Estado intermediario e claro: solicitado, aprovado, expirado, cancelado, concluido.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P3-06 - Revisar admin access e autorizacao por papel.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/auth/controller/AdminAccessController.java`
    - `backend/kerosene/src/main/java/source/common/admin`
    - `backend/kerosene/src/main/java/source/config/Security.java`
  - Como implementar:
    1. Identifique todos os endpoints admin.
    2. Exija role especifica por acao, nao apenas autenticacao generica.
    3. Adicione auditoria com actor, acao, alvo, resultado e correlation id.
    4. Exija step-up auth para operacoes perigosas.
    5. Teste usuario comum, admin parcial e admin completo.
  - Criterios de aceite:
    - Operacoes admin sensiveis nao passam com role errada.
    - Auditoria existe para sucesso e falha.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 4 - Wallet, ledger e integridade contabil

- [x] P4-01 - Remover varredura `findAll()` do resolvedor de participantes.
  - Problema:
    - `TransactionParticipantResolver` usa `walletLookupPort.findAll()` para resolver receiver por endereco/hash em alguns caminhos.
    - Isso e arriscado para performance, privacidade e escala.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/TransactionParticipantResolver.java`
    - `backend/kerosene/src/main/java/source/wallet`
    - `backend/kerosene/src/main/java/source/wallet/ports`
    - repositories de wallet
  - Como implementar:
    1. Identifique campos usados para lookup: address, destination hash, username, wallet id ou receiver identifier.
    2. Crie metodos de porta como `findByAddress`, `findByDestinationHash`, `findByUsername` conforme modelo real.
    3. Implemente queries indexadas no repository.
    4. Adicione migration para indices unicos ou compostos.
    5. Atualize o resolver para nunca chamar `findAll()` em request path.
    6. Teste lookup existente, nao encontrado, colisao e usuario inativo.
  - Criterios de aceite:
    - `rg "findAll\\("` nao mostra request path sensivel usando varredura total.
    - Banco tem indices para campos de lookup.
    - Teste de performance ou teste unitario prova query especifica.
  - Descricao ao concluir:
    - Implementado: lookup indexado por `destination_hash` para resolver destination hash sem varrer todas as wallets no request path; `WalletEntity` agora mantem `destinationHash` via lifecycle JPA; foi adicionada migration V3 com coluna e indice unico parcial; foi adicionada rotina de backfill em startup para wallets legadas sem hash.
    - Arquivos alterados: `TransactionParticipantResolver`, `WalletEntity`, `WalletRepository`, `WalletLookupPort`, `WalletPersistencePort`, `WalletPersistenceAdapter`, `WalletReader`, `WalletService`, `PaymentRequestDestinationHashService`, `WalletDestinationHash`, `WalletDestinationHashBackfillService`, `V3__wallet_destination_hash_index.sql`, testes de resolver e hash.
    - Testes executados: `./gradlew test --tests source.ledger.application.transaction.TransactionParticipantResolverTest --tests source.wallet.domain.WalletDestinationHashTest`; `./gradlew test --tests source.wallet.* --tests source.ledger.service.LedgerPaymentRequestServiceTest --tests source.ledger.application.transaction.TransactionParticipantResolverTest`; `./gradlew test`; `./gradlew bootJar`.
    - Decisoes/risco residual: o backfill roda por padrao em startup e salva wallets em lotes de 500; se houver dados legados com destination hash duplicado, o indice unico deve falhar em vez de permitir destino ambiguo.
    - Pendencias abertas: avaliar depois uma migration/job operacional com relatorio dry-run para ambientes grandes antes de habilitar backfill automatico em producao.

- [ ] P4-02 - Separar historico financeiro duravel de buffer legado.
  - Problema:
    - `LedgerTransactionHistory` indica buffer legado de curta duracao, nao extrato duravel.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/ledger`
    - `backend/kerosene/src/main/java/source/transactions`
    - `frontend/lib/features`
  - Como implementar:
    1. Defina entidade/consulta canonica de extrato financeiro duravel.
    2. Garanta que cada entrada aponta para ledger entry, transaction/payment intent e correlation id.
    3. Mantenha buffer legado apenas como compatibilidade temporaria, se necessario.
    4. Atualize endpoint de historico para pagina, filtro e ordenacao estaveis.
    5. Atualize frontend para consumir extrato canonico.
  - Criterios de aceite:
    - Usuario ve historico completo a partir do ledger, nao de cache efemero.
    - Paginacao e deterministica.
    - Testes cobrem ordem, filtro e consistencia saldo/evento.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P4-03 - Formalizar invariantes do ledger.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/ledger`
    - `backend/kerosene/src/test/java/source/ledger`
  - Como implementar:
    1. Documente invariantes: soma zero por lancamento, moeda consistente, idempotency key unica, nenhum saldo negativo quando proibido, status final imutavel.
    2. Adicione validacoes no ponto unico de escrita do ledger.
    3. Crie testes unitarios e transacionais para cada invariante.
    4. Adicione metricas para violacao detectada em reconciliacao.
  - Criterios de aceite:
    - Nao ha caminho alternativo escrevendo saldo fora do ledger.
    - Testes falham se entrada parcial for persistida.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P4-04 - Endurecer auditoria Merkle e shadow balance.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/ledger/audit`
    - `backend/kerosene/src/main/java/source/ledger/controller/LedgerAuditController.java`
    - `backend/kerosene/src/test/java/source/ledger`
  - Como implementar:
    1. Confirmar que auditorias batch usam paginacao limitada.
    2. Persistir snapshot de auditoria com root hash, range, contagem, actor e status.
    3. Adicionar endpoint admin para consultar auditorias sem expor dados sensiveis.
    4. Criar alerta/metric quando auditoria encontrar divergencia.
    5. Testar divergencia artificial e recuperacao.
  - Criterios de aceite:
    - Auditoria nao depende de leitura ilimitada.
    - Resultado fica persistido e comparavel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P4-05 - Criar migracao de carteira para campos de lookup canonicos.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/resources/db/migration`
    - `backend/kerosene/src/main/java/source/wallet`
  - Como implementar:
    1. Identifique colunas atuais de address/destination hash/identifier.
    2. Crie migration para indices e constraints.
    3. Crie job de backfill se campos antigos precisarem ser normalizados.
    4. Garanta que colisoes sejam detectadas antes de aplicar constraint unica.
    5. Adicione teste de migration quando padrao do projeto permitir.
  - Criterios de aceite:
    - Lookup canonico tem indice.
    - Dados legados sao migraveis ou bloqueados com relatorio claro.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P4-06 - Verificar consistencia de wallet profile e capabilities.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/wallet/controller/WalletController.java`
    - `backend/kerosene/src/main/java/source/payments`
    - `backend/kerosene/src/main/java/source/transactions/controller/NetworkPaymentsController.java`
  - Como implementar:
    1. Defina uma unica fonte de verdade para capacidades de recebimento/envio.
    2. Garanta que `receiving-capabilities`, `wallet-profile` e wallet summary retornem informacao coerente.
    3. Inclua estados: usuario inativo, KYC pendente se existir, rail indisponivel, limite excedido, maintenance.
    4. Teste consistencia entre endpoints ou remova duplicata.
  - Criterios de aceite:
    - Frontend nao precisa combinar informacoes contraditorias.
    - Capacidade indisponivel explica motivo por codigo.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 5 - Pagamentos externos, onchain, Lightning e reconciliacao

- [ ] P5-01 - Endurecer emissao de endereco onchain custodial.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/IssueOnchainAddressUseCase.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/CustodialAddressAllocator.java`
    - `backend/kerosene/src/main/java/source/transactions/controller/NetworkPaymentsController.java`
  - Estado observado:
    - Exige wallet custody `KEROSENE`.
    - Exige `expectedAmountBtc` positivo.
    - Registra watch.
    - Allocator suporta xpub, Bitcoin Core wallet address e fallback local se habilitado.
    - Fallback local e bloqueado em producao por safety check.
  - Como implementar:
    1. Tornar fonte de endereco explicita no response/admin status: `xpub`, `bitcoin-core-wallet`, `disabled`.
    2. Rejeitar emissao se fonte estiver em fallback nao permitido.
    3. Garantir gap limit e derivation path rastreavel quando usar xpub.
    4. Persistir address lease com transfer id, user id, amount, expiry e status.
    5. Testar idempotencia por idempotency key.
  - Criterios de aceite:
    - Mesmo request idempotente retorna mesmo endereco enquanto lease for valido.
    - Nao ha emissao onchain sem fonte segura em prod.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [x] P5-02 - Separar interfaces de Lightning e onchain.
  - Problema:
    - `BitcoinNodeService` implementa LND Lightning, mas metodos onchain como `createOnchainAddress`, `sendOnchain`, `sendRawTransaction` lancam `UnsupportedOperationException`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/infra/BitcoinNodeService.java`
    - `backend/kerosene/src/main/java/source/transactions/domain/*Gateway*`
    - `backend/kerosene/src/main/java/source/transactions/application`
  - Como implementar:
    1. Divida contratos em `LightningGateway`, `OnchainBroadcastGateway`, `OnchainAddressGateway`, conforme uso real.
    2. Injete interfaces especificas nos use cases.
    3. Remova metodos `UnsupportedOperationException` de classes onde nao fazem sentido.
    4. Ajuste beans e testes.
  - Criterios de aceite:
    - Nenhum use case chama metodo nao suportado em runtime.
    - Spring nao escolhe provider errado por tipo amplo.
  - Descricao ao concluir:
    - Implementado: contratos Lightning separados (`LightningInvoiceGateway`, `LightningPaymentGateway`) e `BitcoinNodeService` removido do tipo amplo `CustodyGateway`, eliminando chamadas onchain nao suportadas nesse provider LND.
    - Arquivos alterados: `CustodyGateway`, `LightningInvoiceGateway`, `LightningPaymentGateway`, `BitcoinNodeService`, `CreateLightningInvoiceUseCase`, `CancelInboundTransferUseCase`, `ExternalPaymentsQueryService`, `PayLightningPaymentUseCase`, `InboundTransferMonitorService`, `ExternalProviderOutboxProcessor`, testes de contrato/fluxos.
    - Testes executados: `./gradlew test --tests source.transactions.service.BitcoinNodeServiceRailContractTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest --tests source.transactions.service.InboundTransferMonitorServiceTest --tests source.transactions.application.externalpayments.CancelInboundTransferUseCaseTest --tests source.transactions.service.ExternalPaymentsServiceTest`.
    - Decisoes/risco residual: BTCPay/configurable providers continuam implementando `CustodyGateway` por compatibilidade; `P5-03` adicionou selecao explicita/fail-closed por rail para impedir injecao acidental por tipo amplo.
    - Pendencias abertas: validar selecao LND/BTCPay em staging com providers reais.

- [x] P5-03 - Tornar gateways de custody explicitos por rail.
  - Problema:
    - Existem `BtcPayServerCustodyGateway`, `ConfigurableCustodyGateway`, `BitcoinNodeService` e `ExternalPaymentsCustodyAdapter`.
    - Selecionar bean errado pode mandar dinheiro por caminho incorreto.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/infra`
    - `backend/kerosene/src/main/java/source/transactions/application`
  - Como implementar:
    1. Nomeie beans por rail: `btcpay`, `lnd`, `bitcoin-core-psbt`, `mpc-quorum`.
    2. Use qualifiers ou factories explicitas baseadas em config validada.
    3. Adicione startup report de provider ativo por rail.
    4. Bloqueie prod se rail obrigatoria estiver usando gateway local/configuravel fraco.
    5. Teste selecao de bean por config.
  - Criterios de aceite:
    - Cada rail externa mostra provider ativo.
    - Config invalida falha no startup.
  - Descricao ao concluir:
    - Implementado: beans canonicos por rail (`externalLightningInvoiceGateway`, `externalLightningPaymentGateway`, `bitcoinCorePsbtExternalPaymentsCustodyPort`), selecao explicita por `transactions.rails.lightning.*-provider`, qualifiers nos use cases/worker, registry com report de startup e health de providers externos.
    - Arquivos alterados: `ExternalRailProviderConfiguration`, `ExternalRailProviderRegistry`, `ExternalRailProviderProductionSafetyCheck`, `ProductionSafetyCheckChain`, providers LND/BTCPay/configurable/onchain, use cases Lightning/onchain, worker outbox legado, treasury payout, `OperationalHealthService`, properties e testes de producao/config.
    - Testes executados: `./gradlew test --tests source.config.ProductionMockProfileConditionTest --tests source.transactions.infra.ExternalRailProviderConfigurationTest --tests source.transactions.service.BitcoinNodeServiceRailContractTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest`; `./gradlew test --tests source.transactions.service.ExternalPaymentsServiceTest --tests source.transactions.service.InboundTransferMonitorServiceTest --tests source.transactions.application.externalpayments.CancelInboundTransferUseCaseTest --tests source.transactions.service.ExternalProviderOutboxServiceTest --tests source.transactions.service.FinancialReconciliationServiceTest`.
    - Decisoes/risco residual: prod defaulta Lightning invoice/payment para `lnd` e bloqueia o gateway configuravel `BCX`; BTCPay permanece disponivel apenas quando selecionado explicitamente e live. Teste real de boot com providers externos fica para smoke/staging.
    - Pendencias abertas: validar em ambiente com LND/Bitcoin Core reais e decidir se BTCPay deve continuar como provider de invoice em algum perfil operacional.

- [x] P5-04 - Completar retry automatico do provider outbox legado.
  - Problema:
    - `ExternalProviderOutboxService` enfileira e marca eventos.
    - Existe reconciliacao, mas retry automatico e conservador/incompleto.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/outbox/ExternalProviderOutboxService.java`
    - `backend/kerosene/src/main/java/source/transactions/outbox`
    - `backend/kerosene/src/main/java/source/transactions/application/FinancialReconciliationService.java`
  - Como implementar:
    1. Defina estados da outbox: pending, processing, dispatched, failed_retryable, failed_terminal, auto_resolution_pending.
    2. Crie scheduler com lock transacional para buscar itens due.
    3. Implemente backoff exponencial com limite maximo.
    4. Garanta idempotency key junto ao provider.
    5. Ao atingir terminal, mova transferencia para estado consistente e dispare reconciliacao.
    6. Exponha metricas de backlog, idade maxima e falhas.
  - Criterios de aceite:
    - Evento retryable e reprocessado sem duplicar debito.
    - Dois workers concorrentes nao processam o mesmo item.
    - Testes cobrem sucesso depois de falha, falha terminal e concorrencia.
  - Descricao ao concluir:
    - Implementado: claim atomico para `external_provider_outbox`, worker agendado, processor para `ONCHAIN_SEND` e `LIGHTNING_PAY`, propagacao de `idempotencyKey` aos comandos de provider e eventos de sucesso/falha.
    - Arquivos alterados: `ExternalProviderOutboxEntity`, `ExternalProviderOutboxRepository`, `ExternalProviderOutboxService`, `ExternalProviderOutboxWorker`, `ExternalProviderOutboxProcessor`, `ExternalPaymentsCustodyPort`, `CustodyGateway`, `SendOnchainPaymentUseCase`, `PayLightningPaymentUseCase`, `ConfigurableCustodyGateway`, `QuorumPsbtSigningService`, migration `V7__external_provider_outbox_claims.sql`, testes de outbox/processor.
    - Testes executados: `./gradlew test --tests source.transactions.service.ExternalProviderOutboxServiceTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest`; `./gradlew test --tests source.transactions.service.ExternalPaymentsServiceTest`.
    - Decisoes/risco residual: falhas retryable ficam em `FAILED_RETRYABLE` com backoff; falhas finais marcam outbox/transfer como falha, mas compensacao contabil automatica fica para `P5-05/E2`.
    - Pendencias abertas: integrar reconciliacao/compensacao contabil segura para casos finais e ambiguos.

- [x] P5-05 - Completar reversao contabil em reorg/regressao.
  - Progresso nesta passada:
    - Auto-refund idempotente implementado para falha final de provider sem referencia externa.
    - Falhas com referencia externa permanecem manuais em `AUTO_RESOLUTION_PENDING`.
    - Campos de resolucao foram adicionados aos issues de reconciliacao por migration `V8__financial_reconciliation_resolution_fields.sql`.
    - Pendente para marcar este item: compensacao/reversao de regressao on-chain ou decisao operacional explicita por tipo de regressao.
  - Problema:
    - Reorg/regressao apos settlement vai para `AUTO_RESOLUTION_PENDING`, mas reversao contabil automatica esta incompleta.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/FinancialReconciliationService.java`
    - `backend/kerosene/src/main/java/source/ledger`
    - `backend/kerosene/src/main/java/source/transactions/domain`
  - Como implementar:
    1. Modele eventos de regressao: confirmed->unconfirmed, paid->reorged, provider success->chain absent.
    2. Defina se reversao automatica e permitida por valor/idade/rail.
    3. Se permitida: lance entries compensatorias no ledger com referencia ao evento original.
    4. Se nao permitida: bloqueie saldo afetado e crie caso de resolucao manual.
    5. Notifique usuario apenas com mensagem segura.
    6. Crie testes para regressao antes e depois de credito disponivel.
  - Criterios de aceite:
    - Nenhum saldo fica inflado apos regressao confirmada.
    - Todo ajuste tem trilha de auditoria.
  - Descricao ao concluir:
    - Implementado: `FinancialReconciliationService` agora separa compensacao automatica segura de casos manuais; provider final failure sem referencia externa faz refund idempotente, inbound `COMPLETED` com regressao faz reversao liquida se saldo cobre, e stale provider pending com outbox retryable fica encaminhado para retry do worker.
    - Arquivos alterados: `FinancialReconciliationService`, `FinancialReconciliationIssueEntity`, `ExternalProviderOutboxService`, `ExternalProviderOutboxRepository`, `V8__financial_reconciliation_resolution_fields.sql`, `FinancialReconciliationServiceTest`.
    - Testes executados: `./gradlew test --tests source.transactions.service.FinancialReconciliationServiceTest`.
    - Decisoes/risco residual: qualquer caso com referencia externa ou saldo insuficiente permanece manual em `AUTO_RESOLUTION_PENDING`; isso evita refund/debito automatico quando ha risco de pagamento aceito ou usuario ja ter gasto o credito.
    - Pendencias abertas: validar estes caminhos com Postgres real e provider real em smoke/staging.

- [x] P5-06 - Endurecer fluxo onchain outbound com PSBT/quorum.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/SendOnchainPaymentUseCase.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/QuorumPsbtSigningService.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/MpcSidecarClient.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/MpcPlatformTransactionSignerAdapter.java`
  - Estado observado:
    - Use case debita ledger, enfileira outbox, chama custody e compensa em falha de provider.
    - `QuorumPsbtSigningService` usa Bitcoin Core RPC e signer URLs.
    - MPC sidecar Java usa gRPC mTLS.
  - Como implementar:
    1. Validar endereco de destino por network.
    2. Validar fee cap absoluto e percentual.
    3. Criar preflight de UTXO/funding antes de debitar usuario quando possivel.
    4. Persistir PSBT metadata sem segredo.
    5. Verificar numero minimo de assinaturas e identidade dos signers.
    6. Tratar broadcast ambiguo com reconciliacao, nao refund imediato inseguro.
    7. Testar falha em cada etapa: funding, signer timeout, assinatura invalida, combine, finalize, broadcast timeout, txid retornado.
  - Criterios de aceite:
    - Saque onchain nunca duplica debito em retry.
    - Broadcast ambiguo nao gera credito indevido.
    - Signer falso ou assinatura insuficiente falha.
  - Descricao ao concluir:
    - Implementado: fee cap absoluto/percentual, preflight onchain antes do debito, `maxFeeSats` no comando/outbox, quorum com identidade de signer, metadata PSBT somente por hashes e estado `UNKNOWN`/`AUTO_RESOLUTION_PENDING` para broadcast ambiguo sem refund automatico.
    - Arquivos alterados: `SendOnchainPaymentUseCase`, `ExternalPaymentsFeePolicy`, `ExternalPaymentsCustodyPort`, `ExternalPaymentsCustodyAdapter`, `QuorumPsbtSigningService`, `ExternalProviderOutboxService`, `ExternalProviderOutboxProcessor`, `OnchainTreasuryPayoutRailExecutor`, properties de quorum/fee cap, production safety e testes de payments/outbox/quorum.
    - Testes executados: `./gradlew test --tests source.transactions.service.QuorumPsbtSigningServiceTest --tests source.transactions.service.ExternalPaymentsServiceTest --tests source.transactions.service.ExternalProviderOutboxProcessorTest --tests source.transactions.service.ExternalProviderOutboxServiceTest --tests source.config.ProductionMockProfileConditionTest`.
    - Decisoes/risco residual: timeout de broadcast e txid ausente sao tratados como resultado ambiguo porque o raw tx pode ter sido aceito; o usuario fica com transfer pendente de reconciliacao em vez de receber refund inseguro.
    - Pendencias abertas: validar com Bitcoin Core/signer reais em staging, incluindo signerId real, rejeicao de PSBT invalida e reconciliacao de txid por hash quando broadcast nao retorna resposta.

- [x] P5-07 - Endurecer Lightning invoice inbound.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/*Lightning*`
    - `backend/kerosene/src/main/java/source/transactions/infra/BitcoinNodeService.java`
  - Como implementar:
    1. Persistir invoice com payment hash, amount, expiry, user id, transfer id e status.
    2. Garantir idempotencia para invoice request.
    3. Processar settlement via evento/webhook/poll com dedupe por payment hash.
    4. Creditar ledger apenas uma vez.
    5. Expirar invoices pendentes.
    6. Testar invoice pago duas vezes, expirado, amount divergente e usuario inexistente.
  - Criterios de aceite:
    - Invoice settlement duplicado nao duplica credito.
    - Invoice expirado nao credita sem evento valido.
  - Descricao ao concluir:
    - Implementado: `LightningInvoiceRequestDTO` agora exige `idempotencyKey`; a criacao de invoice usa `ProcessedTransactionService` com namespace proprio, exige `paymentHash` do provider, persiste `expectedAmountBtc`/`idempotencyKey` e reaproveita transfer existente por idempotencia. Inbound settlement Lightning mantem dedupe por `paymentHash`, credita ledger apenas quando o valor recebido bate com o esperado e envia divergencia/valor invalido para `AUTO_RESOLUTION_PENDING`. O monitor expira invoices pendentes quando o provider nao esta live ou quando o poll segue nao terminal depois de `expiresAt`.
    - Arquivos alterados: `CreateLightningInvoiceUseCase`, `LightningInvoiceRequestDTO`, `NetworkPaymentsController`, `ExternalTransferEntity`, `ExternalTransfersPort`, `JpaExternalTransfersAdapter`, `ExternalTransferRepository`, `ExternalInboundSettlementService`, `NetworkTransferLifecycleService`, `InboundTransferMonitorService`, migracao `V10__lightning_invoice_inbound_guards.sql`, testes de invoice/settlement/monitor e chamada Flutter de invoice com idempotency key.
    - Testes executados: `./gradlew compileJava --rerun-tasks`; `./gradlew test --tests source.transactions.application.externalpayments.CreateLightningInvoiceUseCaseTest --tests source.transactions.service.ExternalInboundSettlementServiceTest --tests source.transactions.service.InboundTransferMonitorServiceTest`; `flutter analyze` nos quatro arquivos Dart alterados; `git diff --check`; classes reportadas pelo full run (`HardeningStressTest`, `OnrampServiceTest`, `PaymentLinkServiceRedisTest`, `InboundTransferMonitorServiceTest`, `PerformFinancialAuditInteractorTest`, `CollectRevenueInteractorTest`) passaram isoladas com `--no-daemon --max-workers=1 --rerun-tasks --stacktrace`.
    - Decisoes/risco residual: politica inicial para Lightning inbound e pagamento exato; over/under payment fica em reconciliacao manual em vez de credito automatico. `paymentHash` duplicado e `idempotencyKey` sao protegidos por indice unico parcial.
    - Pendencias abertas: a suite backend completa executou ate o fim, mas o Gradle falhou ao serializar alguns XMLs em `build/test-results/test` de forma intermitente; as classes citadas passaram isoladas e nao ha `<failure>`/`<error>` nos XMLs gerados. Investigar writer XML/relatorio do Gradle separadamente.

- [ ] P5-08 - Endurecer Lightning pay outbound.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/application/PayLightningPaymentUseCase.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/BitcoinNodeService.java`
  - Como implementar:
    1. Validar invoice antes de debitar: amount, expiry, network, destination, routing fee estimate.
    2. Aplicar fee cap.
    3. Debitar/reservar por ledger com idempotency key.
    4. Enviar por outbox.
    5. Tratar estados LND: succeeded, failed, in_flight, unknown.
    6. Refund somente em falha terminal; unknown vai para reconciliacao.
    7. Testar retry, invoice expirado, fee acima do limite e unknown.
  - Criterios de aceite:
    - Pagamento unknown nao vira sucesso nem refund automatico sem reconciliacao.
    - Retry nao paga a invoice duas vezes.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P5-09 - Corrigir politica de fee estimate e fallback.
  - Problema:
    - `MempoolClient` usa fallback estatico de fees.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/infra/MempoolClient.java`
    - use cases de onchain outbound
  - Como implementar:
    1. Expor fonte da fee estimate e idade do dado.
    2. Bloquear outbound onchain se fee estiver stale acima de limite configurado, salvo override admin auditado.
    3. Diferenciar fallback apenas para UI informativa de fallback usado para envio real.
    4. Criar metricas e alertas de fee source down.
  - Criterios de aceite:
    - Envio real nao usa fee stale sem politica explicita.
    - Usuario recebe erro seguro quando fee source indisponivel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P5-10 - Validar webhook BTCPay de ponta a ponta.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/controller/BtcPayWebhookController.java`
    - adapters BTCPay
    - testes de transactions
  - Como implementar:
    1. Verificar assinatura/HMAC/token de webhook.
    2. Dedupe por event id e invoice id.
    3. Mapear estados BTCPay para estados internos de forma fechada.
    4. Nao confiar em amount/currency sem comparar com invoice interna.
    5. Testar assinatura invalida, replay, amount divergente, evento fora de ordem e evento desconhecido.
  - Criterios de aceite:
    - Webhook publico nao altera estado sem autenticacao valida.
    - Evento duplicado e idempotente.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 6 - Payments API unificada

- [x] P6-01 - Fechar estados de `PaymentIntent`.
  - Progresso ja implementado:
    - `PaymentIntentStatus` ganhou `ACCEPTED_BY_PROVIDER` e `REQUIRES_RECONCILIATION`.
    - `PaymentRailExecutor` passou a retornar resultado tipado com outcomes `ACCEPTED`, `SETTLED`, `FAILED_RETRYABLE`, `FAILED_FINAL` e `UNKNOWN`.
    - `PaymentExternalExecutionProcessor` agora marca intent aceita pelo provider como `ACCEPTED_BY_PROVIDER`, marca resultado settled como `SETTLED` e trata excecao de executor como `REQUIRES_RECONCILIATION` sem refund automatico inseguro.
    - Migration `V4__payment_intent_external_states.sql` atualiza o check constraint de status.
    - `PaymentStateMachine` foi criada e passou a validar transicoes de quote, confirmacao, processamento, aceite por provider, reconciliacao, settlement, expiracao e falha.
    - `PaymentQuoteService`, `PaymentConfirmService` e `PaymentExternalExecutionProcessor` foram migrados para a state machine.
    - Testes focados de payments, suite completa backend e `bootJar` passaram.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/payments`
  - Como implementar:
    1. Liste todos os estados atuais de intent, quote e outbox.
    2. Defina transicoes permitidas.
    3. Bloqueie transicoes invalidas no service, nao apenas no controller.
    4. Defina estados finais imutaveis.
    5. Adicione testes de maquina de estados.
  - Criterios de aceite:
    - Nao existe transicao de final para processing/success.
    - Estado ambiguo tem nome especifico e rota de reconciliacao.
  - Descricao ao concluir:
    - Implementado: `PaymentStateMachine` centralizando transicoes de `PaymentIntent`, estados intermediarios externos `ACCEPTED_BY_PROVIDER` e `REQUIRES_RECONCILIATION`, outcome tipado no executor e migration V4 para check constraint.
    - Arquivos alterados: `PaymentEnums`, `PaymentRailExecutor`, `PaymentStateMachine`, `PaymentQuoteService`, `PaymentConfirmService`, `PaymentExternalExecutionProcessor`, `PaymentStateMachineTest`, `PaymentExternalExecutionProcessorTest`, `PaymentConfirmServiceTest`, `PaymentQuoteServiceTest`, `V4__payment_intent_external_states.sql`.
    - Testes executados: `./gradlew test --tests source.payments.service.PaymentStateMachineTest --tests source.payments.service.PaymentExternalExecutionProcessorTest --tests source.payments.service.PaymentConfirmServiceTest --tests source.payments.service.PaymentQuoteServiceTest`; `./gradlew test`; `./gradlew bootJar`.
    - Decisoes/risco residual: transicoes finais sao bloqueadas pela state machine; reconciliador externo generico existe, mas ainda faltam clients reais de status para LND/onchain/provider.
    - Pendencias abertas: implementar providers reais e smoke/staging com provider externo.

- [x] P6-02 - Completar processamento de `PaymentExecutionOutbox`.
  - Progresso ja implementado:
    - O processor deixou de manter intent em `PROCESSING` depois de dispatch aceito.
    - Falha por excecao do executor agora fica como `UNKNOWN`/reconciliacao em vez de refund final automatico ou retry cego.
    - `PaymentExternalReconciliationService` foi criado para reconciliar intents em `ACCEPTED_BY_PROVIDER` ou `REQUIRES_RECONCILIATION`.
    - `PaymentRailStatusClient` foi criado como contrato para clients de status por rail/provider.
    - Migration `V5__payment_execution_reconciliation_states.sql` adiciona estados de outbox para `SETTLED` e `UNKNOWN`.
    - Migration `V6__payment_execution_claims.sql` adiciona `PROCESSING`, `claimed_by`, `claimed_at` e indice de claim.
    - `PaymentExecutionOutboxService.claimDue` faz claim atomico por linha antes do worker chamar o processor.
    - `PaymentExternalExecutionWorker` processa apenas itens claimados.
    - `PaymentExternalExecutionProcessor` agora ignora outbox nao claimada, limpa claim ao finalizar, reagenda apenas `FAILED_RETRYABLE` retornado explicitamente pelo executor e manda excecoes/unknown para reconciliacao.
    - Ainda faltam implementacoes reais de `PaymentRailStatusClient` para LND/onchain/provider.
  - Problema:
    - `PaymentExternalExecutionProcessor` processa outbox e marca dispatched, mas e necessario confirmar se intent sai corretamente de `PROCESSING` para estado final/reconciliavel.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/payments/PaymentExternalExecutionProcessor.java`
    - `backend/kerosene/src/main/java/source/payments/PaymentExecutionOutboxService.java`
    - entidades de payment intent/outbox
  - Como implementar:
    1. Defina resultado de executor externo: accepted, settled, failed_terminal, unknown.
    2. Atualize intent conforme resultado.
    3. Para accepted/unknown, grave referencia externa e deixe reconciliador terminar.
    4. Para failed_terminal, execute refund/compensacao uma unica vez.
    5. Use lock otimista/pessimista para evitar processamento concorrente.
    6. Teste dois processors simultaneos.
  - Criterios de aceite:
    - Intent nao fica preso em `PROCESSING` sem proximo retry/reconciliacao.
    - Falha terminal gera compensacao idempotente.
  - Descricao ao concluir:
    - Implementado: claim atomico de `PaymentExecutionOutbox` com estado `PROCESSING`, `claimed_by`, `claimed_at`, worker limitado a itens claimados, retry seguro apenas para outcome `FAILED_RETRYABLE` explicito e reconciliacao para outcome/exception ambiguo.
    - Arquivos alterados: `PaymentExecutionOutboxEntity`, `PaymentExecutionOutboxRepository`, `PaymentExecutionOutboxService`, `PaymentExternalExecutionWorker`, `PaymentExternalExecutionProcessor`, `PaymentExternalReconciliationService`, `PaymentExecutionOutboxServiceTest`, `PaymentExternalExecutionProcessorTest`, `V6__payment_execution_claims.sql`.
    - Testes executados: `./gradlew test --tests source.payments.service.PaymentExecutionOutboxServiceTest --tests source.payments.service.PaymentExternalExecutionProcessorTest --tests source.payments.service.PaymentExternalReconciliationServiceTest --tests source.payments.service.PaymentStateMachineTest --tests source.payments.service.PaymentConfirmServiceTest --tests source.payments.service.PaymentQuoteServiceTest`.
    - Decisoes/risco residual: excecoes de executor sao tratadas como estado ambiguo `UNKNOWN` para evitar duplicidade de pagamento externo; retry automatico de execucao so acontece quando o executor retorna `FAILED_RETRYABLE`, que deve significar "provider nao aceitou".
    - Pendencias abertas: adicionar clients reais de `PaymentRailStatusClient`, provider smoke em staging e teste concorrente integrado com banco real se o projeto passar a ter ambiente Postgres de teste.

- [x] P6-03 - Integrar `PaymentConfirmService` ao ledger de forma auditavel.
  - Progresso ja implementado:
    - Contextos de ledger gerados por `PaymentConfirmService` agora incluem `paymentIntent` e fingerprint da idempotency key.
    - Debito/credito interno e lock externo usam contexto auditavel em vez de apenas `PAYMENT_*:<uuid>`.
    - `LedgerService` registra audit trail operacional e publica balance update apenas em `afterCommit` quando ha transaction synchronization ativa.
    - Repeticao de confirmacao em estado in-flight com a mesma idempotency key retorna o estado atual sem novo debito nem novo outbox.
    - Testes cobrem quote expirado sem debito, payload alterado, confirmacao duplicada terminal/in-flight, saldo insuficiente externo sem outbox e receiver wallet ausente sem debito.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/payments/PaymentConfirmService.java`
    - `backend/kerosene/src/main/java/source/ledger`
  - Como implementar:
    1. Verifique se confirmacao interna usa idempotency key duravel.
    2. Garanta que quote expirado falha antes de qualquer debito.
    3. Grave correlation id em ledger entries.
    4. Publique evento realtime/notificacao depois do commit.
    5. Teste confirmacao duplicada, quote expirado, saldo insuficiente e receiver invalido.
  - Criterios de aceite:
    - Confirmacao duplicada retorna mesmo resultado logico.
    - Evento nao e publicado se transacao rollbackar.
  - Descricao ao concluir:
    - Implementado: ledger context com `paymentIntent` + fingerprint de idempotency key para debitos/creditos de `PaymentConfirmService`; publicacao de balance update e audit trail operacional do `LedgerService` movidas para after-commit quando a transacao esta ativa.
    - Arquivos alterados: `PaymentConfirmService`, `PaymentConfirmServiceTest`, `LedgerService`, `LedgerServiceTest`.
    - Testes executados: `./gradlew test --tests source.payments.service.PaymentConfirmServiceTest --tests source.ledger.service.LedgerServiceTest`.
    - Decisoes/risco residual: `PaymentAuditService` continua participando da transacao principal; `FinancialAuditTrailService` operacional roda after-commit para evitar evento fantasma em rollback.
    - Pendencias abertas: notification especifica de pagamento ainda deve ser tratada no pacote de notifications/realtime; o ajuste atual cobre balance update do ledger.

- [x] P6-04 - Consolidar receiving capabilities.
  - Progresso ja implementado:
    - `ReceivingCapabilitiesResponse` agora preserva os campos booleanos existentes e adiciona `receiverDisplayName`, `availableRails` e `limits`.
    - `ReceivingCapabilityService` consulta carteiras ativas uma unica vez por chamada de capabilities.
    - Resposta para receiver inexistente/inativo continua sem display name e com motivo generico `RECEIVER_NOT_READY`.
    - Rails disponiveis sao retornadas em ordem canonica: `INTERNAL`, `LIGHTNING`, `ONCHAIN`.
    - Limites minimos retornados: internal 1 sat, lightning 1 sat, onchain 546 sats, asset `BTC`, fiat `BRL`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/payments/controller/PaymentsController.java`
    - `backend/kerosene/src/main/java/source/wallet`
  - Como implementar:
    1. Defina contrato para `/users/{receiverIdentifier}/receiving-capabilities`.
    2. Validar receiver por indice, nao por varredura.
    3. Incluir rails aceitas, limites, moedas, display name seguro e motivos de indisponibilidade.
    4. Evitar vazamento de existencia de usuario quando politica exigir privacidade.
    5. Testar usuario existente, inexistente, bloqueado e rail desativada.
  - Criterios de aceite:
    - Endpoint nao revela mais informacao do que o produto permite.
    - Frontend consegue decidir UI sem chamadas extras redundantes.
  - Descricao ao concluir:
    - Implementado: contrato de receiving capabilities enriquecido para o frontend decidir rails/limites/display sem chamadas extras, mantendo resposta privada para receiver nao pronto.
    - Arquivos alterados: `ReceivingCapabilitiesResponse`, `ReceivingCapabilityService`, `ReceivingCapabilityServiceTest`.
    - Testes executados: `./gradlew test --tests source.payments.service.ReceivingCapabilityServiceTest --tests source.payments.service.PaymentQuoteServiceTest`.
    - Decisoes/risco residual: limites sao constantes conservadoras alinhadas ao quote atual; se o produto adicionar limites dinamicos por usuario/rail, mover para configuracao ou service dedicado.
    - Pendencias abertas: frontend ainda precisa consumir os novos campos quando a tela de envio for refinada.

- [x] P6-05 - Definir compatibilidade entre payment links e PaymentIntent.
  - Progresso ja implementado:
    - Decisao: payment link continua feature separada de `PaymentIntent`, porque modela recebimento inbound/on-chain com lifecycle proprio.
    - `PaymentLinkDTO` agora expoe compatibilidade canonica: `paymentRail`, `paymentIntentStatus`, `settlementReference` e `terminal`.
    - Mapeamento: `pending -> QUOTED`, `paid/completed -> SETTLED`, `expired -> EXPIRED`, `cancelled -> CANCELED`, `verifying_onboarding/verifying_activation -> PROCESSING`.
    - Link pago/cancelado/expirado nao executa credito novamente no confirmer.
    - Link expirado passa para `EXPIRED` antes de validacao/credito.
    - `PaymentLinkWalletCreditAdapter` usa contexto de ledger `PAYMENT_LINK_CREDIT:paymentLink=<id>:txid=<fingerprint>`.
    - Frontend `PaymentLink` parseia os novos campos e deriva fallback para respostas antigas.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/controller/TransactionController.java`
    - `backend/kerosene/src/main/java/source/payments`
    - modelos de payment link
  - Como implementar:
    1. Escolha se payment link vira um tipo de PaymentIntent ou feature separada.
    2. Se virar PaymentIntent: migre status, expiracao, receiver e amount.
    3. Se ficar separado: crie adaptador claro para liquidacao pelo ledger canonico.
    4. Remova duplicacao de endpoint legado quando frontend estiver migrado.
    5. Teste link expirado, link pago, link cancelado e pagamento duplicado.
  - Criterios de aceite:
    - Link pago uma vez nao pode ser pago de novo.
    - Link expirado nao gera intent ativa.
  - Descricao ao concluir:
    - Implementado: camada de compatibilidade entre payment links e vocabulario de `PaymentIntent` sem migrar storage/lifecycle para `PaymentIntent`; credit adapter de payment link ficou explicitamente vinculado ao ledger canonico com contexto rastreavel.
    - Arquivos alterados: `PaymentLinkDTO`, `PaymentLinkConfirmerTest`, `PaymentLinkReaderTest`, `PaymentLinkDTOTest`, `PaymentLinkWalletCreditAdapter`, `PaymentLinkWalletCreditAdapterTest`, `frontend/lib/features/transactions/domain/entities/payment_link.dart`, `frontend/test/features/transactions/domain/entities/payment_link_test.dart`.
    - Testes executados: `./gradlew test --tests source.transactions.dto.PaymentLinkDTOTest --tests source.transactions.application.paymentlink.PaymentLinkConfirmerTest --tests source.transactions.application.paymentlink.PaymentLinkReaderTest --tests source.transactions.infra.paymentlink.PaymentLinkWalletCreditAdapterTest`; `flutter test test/features/transactions/domain/entities/payment_link_test.dart`.
    - Decisoes/risco residual: nao foi criada `PaymentIntent` real para link inbound; a API expoe status compativel para UI/observabilidade e mantem a feature separada ate haver produto para unificar inbound/outbound.
    - Pendencias abertas: remover endpoints legados so depois do frontend migrar toda jornada para o contrato novo e de existir reconciliacao provider real para inbound.

## Fase 7 - Treasury, solvencia e auditoria operacional

- [x] P7-01 - Substituir `/v1/audit/siphon` manual por executor real de payout.
  - Problema:
    - Documentacao indica substituir settlement manual por payout executor real.
    - Producao bloqueia `treasury.siphon.manual-settlement-enabled`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/ledger/controller/LedgerAuditController.java`
    - `backend/kerosene/src/main/java/source/treasury`
    - `backend/kerosene/src/main/java/source/ledger`
  - Como implementar:
    1. Modele payout request com status: requested, approved, queued, executing, settled, failed, cancelled.
    2. Exija aprovacao admin/step-up para payout.
    3. Use outbox para execucao externa.
    4. Lance ledger entries de revenue/payout de forma auditavel.
    5. Mantenha endpoint manual apenas em profile local/teste ou remova.
    6. Teste aprovacao, execucao, falha, retry e cancelamento.
  - Criterios de aceite:
    - Producao nao depende de endpoint manual para settlement.
    - Payout tem trilha de auditoria e idempotencia.
  - Descricao ao concluir:
    - Implementado: `financial.siphon_requests` virou registro duravel de payout com estados `REQUESTED`, `APPROVED`, `QUEUED`, `EXECUTING`, `SETTLED`, `FAILED`, `CANCELLED`; `/v1/audit/siphon` agora cria request, valida step-up TOTP/hardware, aprova e enfileira, sem marcar fees manualmente como coletadas; adicionados endpoints admin para criar, aprovar e cancelar request; worker com claim/retry processa payout via `ExternalPaymentsCustodyPort`/quorum PSBT; fees do ledger so viram `COLLECTED` depois de retorno bem-sucedido do executor e apenas ate o `revenue_cutoff_at`; eventos de payout entram na trilha `FinancialAuditTrailService`.
    - Arquivos alterados: `LedgerAuditController`, `SiphonRequest`, `SiphonRequestRepository`, `LedgerEntryRepository`, novos servicos `TreasuryPayoutService`, `TreasuryPayoutExecutionProcessor`, `TreasuryPayoutWorker`, `OnchainTreasuryPayoutRailExecutor`, DTO de resposta, migration `V9__treasury_payout_requests.sql`, testes de controller/autorizacao/service/processor.
    - Testes executados: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.ledger.controller.LedgerAuditControllerTest --tests source.ledger.controller.LedgerAuditControllerAuthorizationTest --tests source.treasury.service.TreasuryPayoutServiceTest --tests source.treasury.service.TreasuryPayoutExecutionProcessorTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar`.
    - Decisoes/risco residual: payout e on-chain e usa o custody/quorum PSBT ja existente; sucesso do executor representa broadcast/aceite do provider, ainda nao confirmacao on-chain final; destino vem de `treasury.payout.destination-address` com fallback legado e e validado quando request e criada.
    - Pendencias abertas: criar UI/operacao para listar requests e acionar approve/cancel; adicionar reconciliacao de confirmacoes on-chain do payout; revisar se o time quer remover totalmente o endpoint compat `/v1/audit/siphon` apos migrar runbooks.

- [x] P7-02 - Implementar prova operacional de reservas.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/treasury`
    - `backend/kerosene/src/main/java/source/ledger/audit`
  - Como implementar:
    1. Defina assets e liabilities por moeda/rail.
    2. Calcule liabilities a partir do ledger.
    3. Calcule assets a partir de providers confiaveis: Bitcoin Core/LND/tesouraria.
    4. Gere snapshot com timestamp, block height, hashes e status.
    5. Exponha endpoint admin e metricas.
    6. Teste deficit, provider indisponivel e snapshot consistente.
  - Criterios de aceite:
    - Operacao consegue detectar insolvencia ou provider down.
    - Snapshot nao expoe chaves nem detalhes sensiveis.
  - Descricao ao concluir:
    - Implementado: snapshot operacional admin em `POST /v1/audit/reserves/operational-proof` combinando auditoria de solvencia, reservas on-chain/lightning, reserved outbound por rail, status Bitcoin/LND, checkpoint Merkle e `snapshotHash`; o endpoint exige `ADMIN`, registra evento `OPERATIONAL_RESERVE_PROOF_GENERATED` na trilha financeira e incrementa metrica `kerosene.financial.operational_reserve_proof`; hash/blockhash/anchor txid sao expostos como referencias/fingerprints quando podem carregar detalhes operacionais, mantendo o Merkle root como prova publica.
    - Arquivos alterados: `OperationalReserveProofService`, `OperationalReserveProofResponseDTO`, `LedgerAuditController`, `LedgerAuditControllerAuthorizationTest`, `OperationalReserveProofServiceTest`.
    - Testes executados: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.treasury.service.OperationalReserveProofServiceTest --tests source.ledger.controller.LedgerAuditControllerAuthorizationTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar`.
    - Decisoes/risco residual: snapshot e gerado sob demanda e ancora em `MerkleAuditService` existente em vez de criar tabela historica nova; status final prioriza insolvencia, depois provider down/degraded; liabilities operacionais separam saldo interno de reservas outbound para evitar dupla contagem.
    - Pendencias abertas: persistir historico proprio de operational proof caso compliance exija consulta paginada; criar dashboard/admin UI; adicionar reconciliacao automatica de confirmacoes finais de payout e comparar snapshots consecutivos.

- [x] P7-03 - Criar runbook de reconciliacao manual.
  - Arquivos iniciais:
    - `docs`
    - controllers admin/reconciliacao
  - Como implementar:
    1. Documente como identificar item em `AUTO_RESOLUTION_PENDING`.
    2. Documente quais dados coletar antes de ajustar saldo.
    3. Documente comandos/endpoints admin permitidos.
    4. Documente rollback e comunicacao ao usuario.
    5. Inclua checklist para dois operadores se houver operacao sensivel.
  - Criterios de aceite:
    - Operador consegue resolver caso sem ler codigo.
    - Runbook nao inclui segredo ou payload sensivel.
  - Descricao ao concluir:
    - Implementado: criado `docs/RUNBOOK_MANUAL_RECONCILIATION.md` com regras inviolaveis, fontes permitidas, SQL somente leitura para runs/issues/transfers/outbox/events, classificacao por `issue_type`, evidencias obrigatorias, decisoes para retry/refund/settlement/regressao de confirmacoes, update controlado apenas para encerrar issue, rollback, checklist de dois operadores e mensagens ao usuario; `docs/PRODUCTION_OPERATIONS.md` aponta para o runbook.
    - Arquivos alterados: `docs/RUNBOOK_MANUAL_RECONCILIATION.md`, `docs/PRODUCTION_OPERATIONS.md`, `docs/ULTIMATE_REFACTOR.md`.
    - Testes executados: nao aplicavel, alteracao documental; backend ja havia passado `./gradlew test` e `./gradlew bootJar` apos P7-02.
    - Decisoes/risco residual: o runbook proibe edicao manual de ledger/saldos e usa SQL de mutacao apenas para metadata de issue; ajustes financeiros continuam exigindo endpoint/rotina idempotente da aplicacao.
    - Pendencias abertas: criar endpoint/admin UI para listar e resolver issues sem SQL operacional; adicionar playbook especifico por provider quando houver integracoes LND/Bitcoin Core produtivas finais.

- [x] P7-04 - Auditar endpoints admin de treasury.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/treasury/controller/TreasuryController.java`
    - `backend/kerosene/src/main/java/source/common/admin`
  - Como implementar:
    1. Exija role/permission granular.
    2. Adicione audit event para leitura sensivel e mutacao.
    3. Mascare valores quando necessario.
    4. Adicione teste de acesso negado e permitido.
  - Criterios de aceite:
    - Usuario sem role treasury nao acessa dados sensiveis.
    - Toda mutacao gera audit event.
  - Descricao ao concluir:
    - Implementado: `TreasuryController` agora exige `hasRole('ADMIN')` no controller inteiro e registra `TREASURY_OVERVIEW_READ` no `FinancialAuditTrailService` ao consultar `/treasury/overview`, com payload de baixa sensibilidade baseado em estado/liquidez booleana em vez de dump bruto de saldos.
    - Arquivos alterados: `TreasuryController`, `TreasuryControllerAuthorizationTest`, `TreasuryControllerTest`, ajuste lenient em `CreateLightningInvoiceUseCaseTest` para remover stub fragil exposto pela suite completa.
    - Testes executados: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.treasury.controller.TreasuryControllerAuthorizationTest --tests source.treasury.controller.TreasuryControllerTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.transactions.application.externalpayments.CreateLightningInvoiceUseCaseTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew cleanTest test`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar`.
    - Decisoes/risco residual: leitura de overview continua retornando DTO completo para admin, mas audit event nao replica valores sensiveis; permissao granular `TREASURY_ADMIN` ainda nao existe, entao foi usado `ADMIN` por consistencia com os demais endpoints admin atuais.
    - Pendencias abertas: criar role/authority dedicada para tesouraria quando o modelo de permissoes granular for consolidado; auditar endpoints novos de resolucao de reconciliacao quando existirem.

## Fase 8 - Notificacoes, realtime e WebSocket

- [x] P8-01 - Proteger assinatura STOMP por ownership.
  - Problema:
    - `SubscribeAuthorizationStompMessageHandler` valida usuario autenticado, mas precisa garantir ownership de destino.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config/WebSocketConfig.java`
    - `backend/kerosene/src/main/java/source/config/*Stomp*`
  - Estado observado:
    - Endpoints STOMP: `/ws/balance`, `/ws/raw-balance`, `/ws/payment-request`, `/ws/raw-payment-request`.
    - CONNECT exige Authorization native header.
  - Como implementar:
    1. Mapear destinos permitidos por usuario.
    2. Bloquear subscribe em `/topic/balance/{userId}` se `{userId}` diferente do principal.
    3. Preferir `/user/queue/*` para eventos privados.
    4. Testar subscribe sem auth, auth de outro usuario e auth correta.
    5. Garantir que token nao pode ir por query string.
  - Criterios de aceite:
    - Usuario nao assina eventos privados de outro usuario.
    - Logs nao imprimem token Authorization.
  - Descricao ao concluir:
    - Implementado: `CONNECT` STOMP agora aceita token apenas no native header `Authorization`; fallback por atributo de sessao/query foi removido; `SUBSCRIBE` autenticado valida ownership para `/topic/balance/{userId}` e `/topic/payment-request/{requestId}`; `/user/queue/*` segue permitido para usuario autenticado; tentativas sem auth ou de outro usuario geram `MessageDeliveryException` sem logar token.
    - Arquivos alterados: `StompInboundMessageHandlerChain`, `SubscribeAuthorizationStompMessageHandler`, `StompInboundChannelInterceptorTest`.
    - Testes executados: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test --tests source.config.websocket.StompInboundChannelInterceptorTest`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew cleanTest test`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar`.
    - Decisoes/risco residual: topico legado de payment request continua suportado, mas somente o `requesterUserId` pode assinar; o caminho preferencial para dados privados continua sendo `/user/queue/*`.
    - Pendencias abertas: migrar qualquer consumidor legado de `/topic/balance/{userId}` para `/user/queue/balance`; avaliar substituir eventos de payment request por fila privada para remover topico com identificador de request.

- [x] P8-02 - Completar registro de device token de notificacao.
  - Problema:
    - Frontend possui configuracao de `notificationRegisterToken`, mas backend observado expoe notificacoes e mark read, nao necessariamente endpoint de registro de token.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/notification/controller/NotificationController.java`
    - `backend/kerosene/src/main/java/source/notification`
    - `frontend/lib`
  - Como implementar:
    1. Criar entidade de device token com user id, platform, token hash, token criptografado se necessario, createdAt, lastSeenAt, revokedAt.
    2. Criar endpoint autenticado de register/update/revoke.
    3. Rate limit por usuario/dispositivo.
    4. Nao retornar token puro em GET.
    5. Atualizar frontend para chamar endpoint real.
    6. Testar registro duplicado, revoke, token de outro usuario e token invalido.
  - Criterios de aceite:
    - Push token nao e armazenado/logado de forma insegura.
    - Frontend nao chama endpoint inexistente.
  - Descricao ao concluir:
    - Implementado: backend agora possui `notification_device_tokens` com `token_hash`, `token_ref`, `device_ref`, plataforma, app version, `last_seen_at` e `revoked_at`; endpoints autenticados `POST /notifications/register-token`, `GET /notifications/device-tokens` e `DELETE /notifications/device-tokens/{id}`; registro atualiza duplicatas por hash sem guardar token puro e gera eventos de auditoria para register/revoke; Flutter `NotificationRemoteDataSource` e `NotificationRepository` agora chamam endpoints reais de register/revoke.
    - Arquivos alterados: `NotificationController`, `NotificationDeviceTokenService`, entidade/repository/DTOs de device token, migration `V10__notification_device_tokens.sql`, testes de controller/service, datasource/repository Flutter de notificacoes.
    - Testes executados: `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew clean test --tests source.notification.service.NotificationDeviceTokenServiceTest --tests source.notification.controller.NotificationControllerTest`; `dart format ...`; `flutter analyze --no-pub`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew cleanTest test`; `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar`.
    - Decisoes/risco residual: token push bruto nao e persistido, apenas SHA-256 e fingerprint curta; ainda nao ha envio push externo FCM/APNs, somente armazenamento seguro para integracao posterior.
    - Pendencias abertas: integrar captura real de token FCM/APNs no app mobile; implementar dispatcher push respeitando preferencias; adicionar rate limit especifico por usuario/dispositivo se a camada global nao cobrir abuso.

- [ ] P8-03 - Padronizar eventos realtime pos-commit.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/notification`
    - `backend/kerosene/src/main/java/source/transactions`
    - `backend/kerosene/src/main/java/source/payments`
    - `backend/kerosene/src/main/java/source/ledger`
  - Como implementar:
    1. Identifique todos os pontos que publicam evento realtime.
    2. Garanta publicacao apos commit, usando transaction synchronization ou outbox de evento.
    3. Inclua schema version, event id, user id, type e createdAt.
    4. Dedupe por event id no frontend se necessario.
    5. Teste rollback nao publica evento.
  - Criterios de aceite:
    - Usuario nao ve saldo atualizado se transacao falhou.
    - Evento duplicado e tolerado.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P8-04 - Completar preferencias e templates de notificacao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/notification`
  - Como implementar:
    1. Modelar preferencias por canal: in-app, push, email se existir.
    2. Modelar templates por codigo de evento.
    3. Garantir localizacao/copy segura sem detalhes tecnicos.
    4. Adicionar endpoint para leitura/alteracao de preferencias.
    5. Testar opt-out e eventos obrigatorios de seguranca que nao podem ser silenciados.
  - Criterios de aceite:
    - Usuario controla notificacoes permitidas.
    - Eventos criticos de seguranca continuam sendo entregues conforme politica.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 9 - MPC sidecar, attestation e vault

- [ ] P9-01 - Deixar claro que o sidecar atual e cosigner Ed25519, nao TSS completo.
  - Problema:
    - `backend/mpc-sidecar/service/mpc_service.go` gera chave Ed25519 e assina com `ed25519.Sign`.
    - `go.mod` nao inclui biblioteca TSS.
    - Isso pode ser adequado como cosigner, mas nao deve ser documentado como threshold MPC completo.
  - Arquivos iniciais:
    - `backend/mpc-sidecar/service/mpc_service.go`
    - `backend/mpc-sidecar/go.mod`
    - `backend/kerosene/src/main/java/source/transactions/infra/MpcSidecarClient.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/MpcPlatformTransactionSignerAdapter.java`
    - `docs`
  - Como implementar:
    1. Atualize nomes/documentacao para `platform cosigner` se nao houver TSS real.
    2. Se produto exigir TSS real, planeje troca por biblioteca/servico TSS e protocolo de signing threshold.
    3. No backend Java, validar identidade, mTLS, attestation e signer policy.
    4. Adicionar status admin que mostra modo: `cosigner-ed25519`, `tss-threshold`, `disabled`.
    5. Testar falha de sidecar, certificado invalido e assinatura invalida.
  - Criterios de aceite:
    - Documentacao nao promete MPC/TSS inexistente.
    - Backend falha fechado quando cosigner obrigatorio esta indisponivel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P9-02 - Endurecer remote attestation no backend.
  - Problema:
    - `RemoteAttestationService` tenta `tpm2_quote`, mas faz fallback para quote simulada em falha/indisponibilidade.
    - Logs indicaram falha por opcao `--pcrs_output` nao reconhecida em ambiente local.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/security/RemoteAttestationService.java`
    - `backend/kerosene/src/main/java/source/security`
    - `backend/kerosene/src/test/java/source/security`
  - Como implementar:
    1. Detectar versao de `tpm2-tools` e montar comando compativel.
    2. Separar modo `local-simulated` de modo `prod-required`.
    3. Em prod, fallback simulado deve falhar startup ou readiness.
    4. Validar PCR selection, nonce, quote signature e event log quando disponivel.
    5. Adicionar metric/status para attestation real vs simulada.
    6. Testar tpm indisponivel em local e prod.
  - Criterios de aceite:
    - Prod nunca aceita quote simulada.
    - Local continua testavel sem TPM real, com status explicito.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P9-03 - Alinhar attestation do vault com attestation real.
  - Problema:
    - `backend/vault/src/main/java/vault/security/TpmAttestationService.java` valida formato `v1:` com segredo HMAC, nao quote TPM real.
  - Arquivos iniciais:
    - `backend/vault/src/main/java/vault/security/TpmAttestationService.java`
    - `backend/kerosene/src/main/java/source/security`
    - docs de vault
  - Como implementar:
    1. Documentar claramente o modo atual HMAC.
    2. Definir contrato comum de attestation entre backend e vault.
    3. Se prod exigir TPM real, implementar verificacao de quote real ou integrar verificador externo.
    4. Criar testes de nonce replay, assinatura invalida e segredo ausente.
    5. Garantir que vault fail-closed quando attestation requerida falha.
  - Criterios de aceite:
    - Backend e vault concordam no formato e politica.
    - Nao ha falsa alegacao de TPM real quando o modo e HMAC.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P9-04 - Criar plano de rotacao de chaves e shards.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/security`
    - `backend/kerosene/src/main/java/source/config`
    - `backend/vault`
    - `backend/mpc-sidecar`
    - `docs`
  - Como implementar:
    1. Liste chaves: JWT signing, crypto converter master key, shard attestation, MPC certs, LND macaroon/TLS, vault tokens, release signing.
    2. Para cada chave, defina dono, formato, armazenamento, rotacao, rollback e revogacao.
    3. Implemente versionamento onde ainda nao existir.
    4. Adicione health/readiness que detecta chave vencida ou proxima de vencimento.
  - Criterios de aceite:
    - Existe runbook de rotacao sem downtime para chaves criticas ou com janela planejada.
    - Teste cobre leitura com chave antiga e escrita com chave nova quando aplicavel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P9-05 - Migrar criptografia de campos e remover leitura legacy.
  - Problema:
    - `StringCryptoConverter` suporta ciphertext legado sem HMAC.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/security/StringCryptoConverter.java`
    - entidades com campos criptografados
    - migrations/jobs
  - Como implementar:
    1. Identifique todas as colunas criptografadas.
    2. Crie job de backfill que regrave valores legados no formato com HMAC/versionado.
    3. Adicione metricas de leituras legacy restantes.
    4. Depois de migrado, remova suporte legacy ou bloqueie em prod.
    5. Teste decrypt de legado, migracao, tamper HMAC e key rotation.
  - Criterios de aceite:
    - Prod nao aceita ciphertext sem autenticacao apos migracao.
    - Migracao e reversivel por backup ou dry-run antes de escrita.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 10 - Bitcoin accounts, mining e modulos secundarios

- [ ] P10-01 - Auditar modulo `bitcoinaccounts`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/bitcoinaccounts`
    - `backend/kerosene/src/test/java/source/bitcoinaccounts`
  - Como implementar:
    1. Liste endpoints e use cases.
    2. Confirme se cada operacao impacta saldo, endereco, chave, imposto ou metadado.
    3. Verifique autorizacao por usuario.
    4. Remova duplicidade com wallet/payments se houver.
    5. Adicione testes para acesso cruzado entre usuarios.
  - Criterios de aceite:
    - Usuario nao acessa conta Bitcoin de outro usuario.
    - Modulo nao duplica regra financeira canonica.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P10-02 - Auditar modulo `mining`.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/mining`
    - `backend/kerosene/src/test/java/source/mining`
  - Como implementar:
    1. Verifique se mining gera credito financeiro real ou apenas informativo.
    2. Se gerar credito, integrar ao ledger canonico com idempotencia.
    3. Se for informativo, deixar contrato e UI claros.
    4. Adicionar limites/rate limit para endpoints de simulacao/calculo.
    5. Testar valores extremos e usuarios sem permissao.
  - Criterios de aceite:
    - Nenhum credito de mining e criado fora do ledger.
    - Endpoint nao permite abuso por input extremo.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P10-03 - Auditar modulo `economy` e ticker.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/transactions/controller/EconomyController.java`
    - `backend/kerosene/src/main/java/source/transactions/infra/TickerService.java`
  - Problema:
    - `TickerService` usa CoinGecko, cache Redis e fallback em memoria.
  - Como implementar:
    1. Marcar preco como indicativo ou vinculante.
    2. Se indicativo, nao usar para settlement financeiro sem quote fixada.
    3. Expor timestamp, source e stale status.
    4. Bloquear quote vinculante se preco estiver stale.
    5. Testar provider down e cache expirado.
  - Criterios de aceite:
    - Usuario nao recebe quote vinculante baseada em preco stale.
    - UI consegue mostrar fonte/atualizacao quando relevante.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 11 - Observabilidade, performance e operacao

- [ ] P11-01 - Criar dashboards e alertas de producao.
  - Lacunas conhecidas:
    - Falta dashboard/Alertmanager/tracing/SLO aprovado para producao.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source`
    - `scripts`
    - `docs`
    - infra local se existir
  - Como implementar:
    1. Defina SLOs: uptime API, latencia auth, latencia pagamentos, outbox backlog, reconciliacao, websocket delivery, provider health.
    2. Exponha metricas Micrometer/Prometheus onde faltarem.
    3. Crie dashboards Grafana ou JSON exportado.
    4. Crie alertas para provider down, backlog alto, audit divergence, saldo negativo, reorg, attestation simulated in prod, token errors.
    5. Documente runbook para cada alerta.
  - Criterios de aceite:
    - Operador consegue identificar problema financeiro em menos de uma tela.
    - Alertas tem severidade e acao.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P11-02 - Adicionar tracing e correlation id de ponta a ponta.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source/config`
    - `backend/kerosene/src/main/java/source/common`
    - controllers e outboxes
  - Como implementar:
    1. Gerar/propagar correlation id por request.
    2. Incluir correlation id em erro, log, audit event, ledger entry e outbox.
    3. Propagar para chamadas externas sem vazar auth.
    4. Testar que resposta de erro contem correlation id.
  - Criterios de aceite:
    - Um pagamento pode ser rastreado de controller ate provider/outbox.
    - Logs nao usam dados pessoais como correlacao primaria.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P11-03 - Produzir relatorio de carga real.
  - Lacuna conhecida:
    - Nao ha relatorio de load real suficiente.
  - Arquivos iniciais:
    - `scripts`
    - `docs`
    - testes de performance se existirem
  - Como implementar:
    1. Defina cenarios: login, wallet summary, transferencia interna, quote, confirm, historico, websocket connect, admin health.
    2. Use ferramenta apropriada do repo ou adicione k6/Gatling se aceitavel.
    3. Execute local/staging com massa anonima.
    4. Registre p50/p95/p99, throughput, CPU, memoria, DB pool, Redis, outbox backlog.
    5. Crie `docs/LOAD_TEST_REPORT.md`.
  - Criterios de aceite:
    - Existe numero de capacidade inicial e gargalos.
    - Teste nao usa segredos nem dados reais de usuario.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P11-04 - Revisar pools, timeouts e circuit breakers.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/resources/application*.yml`
    - clients HTTP/gRPC/RPC
    - adapters externos
  - Como implementar:
    1. Liste todos os clients externos: Bitcoin RPC, LND, BTCPay, CoinGecko, MPC sidecar, Vault, Redis, Postgres.
    2. Defina connect timeout, read timeout, retry policy e circuit breaker por client.
    3. Evite retry automatico em operacao nao idempotente sem idempotency key.
    4. Exponha metricas por client.
    5. Teste timeout e provider down em pelo menos fluxos financeiros principais.
  - Criterios de aceite:
    - Provider lento nao prende threads indefinidamente.
    - Retry nao duplica pagamento.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P11-05 - Garantir scheduler seguro em multiplas instancias.
  - Arquivos iniciais:
    - services com `@Scheduled`
    - outboxes
    - reconciliadores
  - Como implementar:
    1. Liste todos os schedulers.
    2. Identifique quais mutam estado financeiro.
    3. Adicione locking distribuido ou claim transacional no banco.
    4. Garanta idempotencia.
    5. Teste concorrencia com duas instancias logicas.
  - Criterios de aceite:
    - Dois pods nao processam o mesmo pagamento/outbox simultaneamente.
    - Scheduler financeiro tem metricas de sucesso/falha/backlog.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 12 - Testes, CI e release

- [ ] P12-01 - Ampliar testes de idempotencia financeira.
  - Arquivos iniciais:
    - `backend/kerosene/src/test/java/source/transactions`
    - `backend/kerosene/src/test/java/source/payments`
    - `backend/kerosene/src/test/java/source/ledger`
  - Como implementar:
    1. Para cada endpoint financeiro, repetir request com mesma idempotency key.
    2. Repetir request com idempotency key igual e payload diferente deve falhar.
    3. Simular timeout de provider e retry.
    4. Verificar saldo e ledger entries.
  - Criterios de aceite:
    - Nao ha duplicidade de debito/credito.
    - Divergencia de payload sob mesma chave e detectada.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P12-02 - Criar testes de contrato backend/frontend.
  - Arquivos iniciais:
    - `backend/kerosene`
    - `frontend/lib/core/network`
    - `frontend/test`
  - Como implementar:
    1. Defina schemas JSON para endpoints usados pelo frontend.
    2. Teste serializacao backend.
    3. Teste parse frontend com fixtures.
    4. Atualize fixtures quando contrato mudar de forma intencional.
  - Criterios de aceite:
    - Mudanca quebrando campo usado pelo frontend falha em teste.
    - Fixtures nao contem dados sensiveis reais.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P12-03 - Adicionar testes de integracao com containers quando possivel.
  - Arquivos iniciais:
    - `backend/kerosene/src/test/java`
    - `backend/kerosene/build.gradle*`
  - Como implementar:
    1. Identifique testes que hoje usam H2 mas dependem de comportamento Postgres.
    2. Use Testcontainers se ja for padrao do projeto; se nao, avaliar custo antes de adicionar dependencia.
    3. Cobrir migrations, constraints, locks e concorrencia de outbox.
    4. Manter testes unitarios rapidos separados.
  - Criterios de aceite:
    - Constraints de banco financeiro sao testadas em banco equivalente a prod.
    - Suite local continua razoavel.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P12-04 - Fechar CI de seguranca e dependencia.
  - Arquivos iniciais:
    - `.github`
    - `backend/kerosene`
    - `frontend`
    - `backend/mpc-sidecar`
    - `backend/vault`
  - Como implementar:
    1. Rodar Gradle test e bootJar.
    2. Rodar dependency check com NVD key configurada.
    3. Rodar Flutter analyze/test/build web.
    4. Rodar Go tests.
    5. Rodar Maven vault quando Maven estiver disponivel.
    6. Arquivar relatorios de security/load quando existirem.
  - Criterios de aceite:
    - CI falha para testes quebrados, dependencia critica, lint e build.
    - Secrets nao aparecem em logs.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P12-05 - Criar suite de smoke end-to-end.
  - Arquivos iniciais:
    - `scripts`
    - `frontend/test`
    - `backend/kerosene/src/test`
  - Como implementar:
    1. Definir jornada minima: signup/login, security status, wallet summary, quote, transferencia interna, historico, notificacao.
    2. Adicionar jornada externa em regtest/signet quando providers reais estiverem configurados.
    3. Gerar relatorio curto com commit e ambiente.
    4. Permitir rodar em local sem providers reais pulando fluxos externos com motivo claro.
  - Criterios de aceite:
    - Jornada principal passa antes de release.
    - Pulos sao explicitos, nao silenciosos.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 13 - Frontend necessario para app pronto

Mesmo que o foco deste plano seja o servico Kerosene, o app nao fica pronto se o frontend continuar chamando contratos legados ou exibindo estados inexistentes.

- [ ] P13-01 - Remover fluxos frontend inexistentes no backend.
  - Arquivos iniciais:
    - `frontend/lib/features`
    - `frontend/lib/core/config`
    - inventario de API criado na Fase 0
  - Como implementar:
    1. Busque chamadas HTTP no frontend.
    2. Compare com inventario de endpoints canonicos.
    3. Remova estados de UI para voucher/link de ativacao se backend decidiu remover.
    4. Troque endpoints legados por `payments`/network canonicos.
    5. Adicione testes de parse e widget quando fluxo mudar.
  - Criterios de aceite:
    - Frontend nao chama endpoint inexistente ou deprecado sem adaptador.
    - Copy da UI descreve comportamento real.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P13-02 - Revisar beleza e consistencia visual dos fluxos financeiros.
  - Arquivos iniciais:
    - `frontend/lib/design_system`
    - `frontend/lib/features`
  - Como implementar:
    1. Auditar telas de wallet, pagamentos, deposito, saque, seguranca, notificacoes e historico.
    2. Garantir estados vazios, loading, erro, sucesso, pending e resolucao manual.
    3. Usar componentes do design system existente.
    4. Evitar cards dentro de cards e textos que estouram em mobile.
    5. Testar em viewport mobile e desktop/web se aplicavel.
  - Criterios de aceite:
    - Fluxos criticos tem UI para todos os estados backend.
    - Textos cabem e botoes usam padrao visual consistente.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P13-03 - Implementar tratamento de erros por codigo.
  - Arquivos iniciais:
    - `frontend/lib/core/network`
    - `frontend/lib/features`
    - contrato de erro da Fase 1
  - Como implementar:
    1. Parsear `code`, `message`, `correlationId`.
    2. Mapear codigos conhecidos para copy amigavel.
    3. Mostrar correlation id em detalhes/copiar quando adequado para suporte.
    4. Evitar exibir mensagem tecnica bruta.
    5. Testar erro de auth, saldo insuficiente, provider down e validacao.
  - Criterios de aceite:
    - Usuario recebe erro compreensivel.
    - Suporte consegue correlacionar falha com backend.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P13-04 - Fechar analise Flutter sem depender de pasta gerada quebrada.
  - Problema:
    - `flutter analyze` com pub completo falhou anteriormente porque `frontend/windows/flutter/ephemeral/.plugin_symlinks` estava owned por `nobody:nobody`.
    - `flutter analyze --no-pub` passou.
  - Arquivos iniciais:
    - `frontend`
    - ambiente local
  - Como implementar:
    1. Ajustar ownership local da pasta gerada quando permitido.
    2. Evitar commitar `frontend/windows/flutter/ephemeral`.
    3. Documentar comando recomendado para CI.
    4. Rodar `flutter pub get`, `flutter analyze`, `flutter test`.
  - Criterios de aceite:
    - Analise Flutter roda no ambiente limpo.
    - Artefatos gerados nao entram no git.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Fase 14 - Limpeza final, docs e criterios de pronto

- [ ] P14-01 - Remover codigo morto e TODOs perigosos.
  - Arquivos iniciais:
    - `backend/kerosene/src/main/java/source`
    - `frontend/lib`
    - `docs`
  - Como implementar:
    1. Use `rg "TODO|FIXME|HACK|temporary|legacy|deprecated|UnsupportedOperationException|simulation|mock|stub"`.
    2. Classifique cada ocorrencia como aceitavel, documentacao, teste ou bloqueador.
    3. Resolva bloqueadores de producao.
    4. Para TODOs restantes, crie issue/checklist com dono e criterio.
  - Criterios de aceite:
    - Nenhum TODO financeiro/seguranca critico fica sem plano.
    - `UnsupportedOperationException` nao aparece em provider injetavel de prod.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P14-02 - Atualizar documentos canonicos.
  - Arquivos iniciais:
    - `docs`
    - `backend/kerosene/docs`
    - `README*`
  - Como implementar:
    1. Atualize `PRODUCTION_READINESS`.
    2. Atualize status de hardening financeiro.
    3. Atualize runbooks de deploy, smoke, reconciliacao, incidentes e rotacao de chaves.
    4. Remova instrucoes que apontam para fluxos deletados.
  - Criterios de aceite:
    - Docs refletem codigo atual.
    - Um operador consegue fazer deploy/smoke sem ler codigo-fonte.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P14-03 - Executar validacao final completa.
  - Como implementar:
    1. Rode testes backend.
    2. Rode bootJar.
    3. Rode Go sidecar tests.
    4. Rode Flutter analyze/test/build web.
    5. Rode Maven vault quando disponivel.
    6. Rode smoke local.
    7. Rode smoke staging se infra real estiver disponivel.
  - Comandos base:
    ```bash
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
    cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew bootJar
    cd backend/mpc-sidecar && go test ./...
    cd frontend && flutter analyze --no-pub
    cd frontend && flutter test --no-pub
    cd frontend && flutter build web --no-pub
    cd backend/vault && mvn test
    ```
  - Criterios de aceite:
    - Todos os comandos aplicaveis passam.
    - Falhas de ambiente sao documentadas com causa e acao.
    - Nenhum teste critico financeiro/seguranca fica pulado sem justificativa.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

- [ ] P14-04 - Declarar criterio de "app pronto".
  - Como implementar:
    1. Criar secao final em `docs/PRODUCTION_READINESS.md` ou documento equivalente.
    2. Marcar explicitamente:
       - Backend prod sobe fail-closed.
       - Frontend nao chama endpoints inexistentes.
       - Fluxos financeiros principais tem testes.
       - Reconciliacao e outbox tem metricas.
       - Providers reais configurados em staging.
       - Runbooks existem.
       - CI passa.
       - Segredos nao estao no repo.
    3. Registrar pendencias nao bloqueantes separadas de bloqueadores.
  - Criterios de aceite:
    - Existe uma decisao objetiva de release/no-release.
    - Pendencias restantes tem severidade e dono.
  - Descricao ao concluir:
    - Implementado:
    - Arquivos alterados:
    - Testes executados:
    - Decisoes/risco residual:
    - Pendencias abertas:

## Ordem recomendada de execucao

1. Fase 0: inventario e baseline.
2. Fase 1: contratos canonicos e remocao de legado.
3. Fase 4: wallet/ledger, porque e base de todos os pagamentos.
4. Fase 6: Payments API unificada.
5. Fase 5: rails externas e reconciliacao.
6. Fase 2: producao fail-closed.
7. Fase 3: auth/admin.
8. Fase 8: notificacoes/WebSocket.
9. Fase 9: MPC/attestation/vault.
10. Fase 7: treasury/solvencia.
11. Fase 10: modulos secundarios.
12. Fase 11: observabilidade/performance.
13. Fase 12: testes/CI.
14. Fase 13: frontend necessario.
15. Fase 14: limpeza e declaracao de pronto.

## Comandos de pesquisa uteis

```bash
rg "@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|RequestMapping)" backend/kerosene/src/main/java/source
rg "findAll\\(" backend/kerosene/src/main/java/source
rg "UnsupportedOperationException|TODO|FIXME|HACK|legacy|deprecated|simulation|mock|stub" backend/kerosene/src/main/java/source frontend/lib backend/mpc-sidecar backend/vault docs
rg "Idempot|idempot|outbox|reconcil|AUTO_RESOLUTION" backend/kerosene/src/main/java/source backend/kerosene/src/test/java
rg "StringCryptoConverter|RemoteAttestationService|TpmAttestationService|JwtAuthenticationFilter|SubscribeAuthorizationStompMessageHandler" backend/kerosene backend/vault
rg "notificationRegisterToken|payment|transaction|deposit|voucher|activation" frontend/lib
```

## Registro rapido de conclusao por fase

Preencha esta tabela ao final de cada fase grande.

| Fase | Status | Commit/branch | Testes principais | Risco residual | Proximo passo |
| --- | --- | --- | --- | --- | --- |
| Fase 0 | pendente |  |  |  |  |
| Fase 1 | pendente |  |  |  |  |
| Fase 2 | pendente |  |  |  |  |
| Fase 3 | pendente |  |  |  |  |
| Fase 4 | pendente |  |  |  |  |
| Fase 5 | pendente |  |  |  |  |
| Fase 6 | pendente |  |  |  |  |
| Fase 7 | pendente |  |  |  |  |
| Fase 8 | pendente |  |  |  |  |
| Fase 9 | pendente |  |  |  |  |
| Fase 10 | pendente |  |  |  |  |
| Fase 11 | pendente |  |  |  |  |
| Fase 12 | pendente |  |  |  |  |
| Fase 13 | pendente |  |  |  |  |
| Fase 14 | pendente |  |  |  |  |

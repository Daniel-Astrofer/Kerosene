# AI Refactor Context

Atualizado em: 2026-04-24

## Objetivo desta sessão

Refatorar backend e frontend com foco em clareza, separação de responsabilidades, tratamento correto de erros e preservação exata das regras de negócio, especialmente nos fluxos financeiros internos e de ativação de conta.

## Avisos de contexto

- O repositório já está com alterações locais não feitas nesta sessão.
- Há também várias mudanças pré-existentes no frontend fora do escopo deste bloco, incluindo arquivos de design system e telas grandes.
- Arquivos sensíveis já modificados no worktree:
  - `backend/kerosene/src/main/java/source/common/exception/GlobalExceptionHandler.java`
  - `backend/kerosene/src/main/java/source/ledger/application/transaction/TransactionParticipantResolver.java`
  - `backend/kerosene/src/main/java/source/ledger/exceptions/LedgerExceptions.java`
  - `backend/kerosene/src/test/java/source/ledger/application/transaction/TransactionParticipantResolverTest.java`
  - `backend/kerosene/src/main/java/source/wallet/dto/WalletRequestDTO.java`
  - `backend/kerosene/src/test/java/source/ledger/application/transaction/WalletRequestDTOJacksonTest.java`
- Essas mudanças não devem ser revertidas por padrão.

## Mapa da arquitetura atual

### Backend

- Stack principal: Java 21 + Spring Boot 3.3.2 + Gradle Kotlin DSL.
- Principais dependências: Spring Web, Security, Data JPA, Validation, Redis, WebSocket, PostgreSQL, H2 para testes, ArchUnit, gRPC, OWASP dependency check.
- Diretório principal: `backend/kerosene/src/main/java/source`.
- Padrão atual: mistura de pacotes antigos por camada (`controller`, `service`, `repository`) com pacotes mais novos orientados a casos de uso (`application`, `domain`, `infra`, `port`, `handler`, `orchestrator`).
- Controllers/endpoints:
  - `source/auth/controller`
  - `source/ledger/controller`
  - `source/transactions/controller`
  - `source/wallet/controller`
  - `source/mining/controller`
  - `source/notification/controller`
  - `source/treasury/controller`
  - `source/common/controller`
- Services/use cases:
  - `source/*/application/**`
  - `source/*/service/**`
  - `source/*/orchestrator/**`
- Repositories/data access:
  - `source/*/repository/**`
  - adapters em `source/*/infra/**`
- DTOs/schemas/validators:
  - `source/*/dto/**`
  - validações explícitas em controllers/services e handlers transacionais
- Middlewares/guards/auth:
  - `source/auth/application/infra/security/**`
  - `source/security/**`
  - filtros websocket em `source/config/websocket/**`
- Error handlers:
  - `source/common/exception/GlobalExceptionHandler`
  - `source/auth/controller/RestResponseErrors` ainda existe como legado/paralelo
- Testes:
  - `backend/kerosene/src/test/java/**`
  - há testes unitários, controller tests com MockMvc, ArchUnit e testes de integração/estresse localizados

### Frontend

- Stack principal: Flutter + Dart 3 + Riverpod + Dio.
- Repositório único atende:
  - app mobile do usuário final
  - console web/admin da empresa
- Diretórios centrais:
  - `frontend/lib/bootstrap`
  - `frontend/lib/core`
  - `frontend/lib/features`
  - `frontend/lib/shared`
  - `frontend/test`
- Bootstraps:
  - mobile: `frontend/lib/bootstrap/mobile_bootstrap.dart`
  - web/admin: `frontend/lib/bootstrap/web_bootstrap.dart`
- Estado global/frontend:
  - providers em `frontend/lib/core/providers/**`
  - providers por feature em `frontend/lib/features/**/presentation/providers` e `controller`
- Camada de API/frontend:
  - `frontend/lib/core/network/api_client.dart`
  - `frontend/lib/core/network/api_response_interceptor.dart`
  - datasources em `frontend/lib/features/**/data/datasources`
- Repositórios/use cases:
  - `frontend/lib/features/**/data/repositories`
  - `frontend/lib/features/**/domain/repositories`
  - `frontend/lib/features/**/domain/usecases`
- Componentes reutilizáveis:
  - `frontend/lib/core/widgets`
  - `frontend/lib/core/presentation/widgets`
  - `frontend/lib/shared/widgets`
- Telas/páginas:
  - mobile em `frontend/lib/features/**/presentation/screens`
  - admin web em `frontend/lib/features/web_admin/screens`
- Testes:
  - `frontend/test/**`
  - cobertura atual existe para utilitários, alguns widgets, integração e alguns repositórios

## Principais fluxos de negócio mapeados

1. Autenticação e onboarding:
   - signup usa PoW, TOTP/passkey e cria conta inicialmente inativa
   - login pode exigir TOTP
   - conta inativa pode autenticar, mas não recebe inbound protegido
2. Wallet + ledger:
   - muitas features assumem wallet primária
   - ledger interno é usado para transferências entre usuários
3. Transferência interna:
   - endpoint `POST /ledger/transaction`
   - sender é sempre resolvido a partir do usuário autenticado
   - receiver pode ser username, wallet id, endereço deposit, hash de destino ou hash legado
4. Recebimento interno bloqueado até ativação:
   - `AccountActivationService.assertInboundEnabled(...)`
   - frontend já trata estado de bloqueio em `ReceiveScreen`
5. Payment requests internos:
   - `POST /ledger/payment-request`
   - `POST /ledger/payment-request/{linkId}/pay`
6. Saques e depósitos externos:
   - endpoints em `/transactions/**` e `/transactions/network/**`
   - coexistem superfícies legadas e novas
7. Admin web:
   - usa mesmo backend, mas bootstrap e shell separados em `features/web_admin`

## Regras críticas encontradas

### Regra: ownership do remetente em transferência interna

- Onde: `backend/kerosene/src/main/java/source/ledger/controller/LedgerController.java`, `source/ledger/application/transaction/TransactionParticipantResolver.java`
- Entrada esperada: `sender` opcional como dica de wallet do próprio usuário autenticado
- Saída esperada: wallet remetente resolvida apenas dentro das wallets do usuário do JWT
- Erros possíveis:
  - `LedgerNotFoundException` se wallet do remetente não existir
- API response esperada:
  - erro padronizado via `GlobalExceptionHandler`
- Impacto no frontend:
  - telas de envio não podem assumir posse de wallet baseada só no campo digitado
- Testes existentes:
  - `backend/kerosene/src/test/java/source/ledger/orchestrator/TransactionTest.java`
- Testes ausentes:
  - controller test cobrindo tentativa de uso de wallet de outro usuário

### Regra: resolução do destinatário aceita múltiplos identificadores

- Onde: `backend/kerosene/src/main/java/source/ledger/application/transaction/TransactionParticipantResolver.java`
- Entrada esperada: username, wallet id, endereço BTC, hash Argon2 legado, destination hash
- Saída esperada: wallet de destino real
- Erros possíveis:
  - `ReceiverNotFoundException`
  - `ReceiverNotReadyException` com `reason=NO_RECEIVING_WALLET` quando o usuário existe sem wallet pronta
  - `ReceiverNotReadyException` com `reason=INBOUND_BLOCKED` quando o usuário existe, mas o inbound ainda está bloqueado
- API response esperada:
  - `ERR_LEDGER_RECEIVER_NOT_FOUND` para destinatário inexistente
  - `ERR_LEDGER_RECEIVER_NOT_READY` com `data.reason`
- Impacto no frontend:
  - o erro precisa diferenciar “destino inexistente” de “destino existe, mas não está pronto”
- Testes existentes:
  - `backend/kerosene/src/test/java/source/ledger/application/transaction/TransactionParticipantResolverTest.java`
- Testes ausentes:
  - cobertura integrada mais ampla com a suíte completa do backend

### Regra: conta inativa não pode receber inbound

- Onde: `backend/kerosene/src/main/java/source/auth/application/service/account/AccountActivationService.java`
- Entrada esperada: userId ou `UserDataBase`
- Saída esperada: nenhuma; validação passa silenciosamente
- Erros possíveis:
  - `AuthExceptions.InboundReceivingBlockedException`
- Mensagem/API response atual:
  - mensagem base: `Para receber fundos dentro da plataforma, deposite algum valor primeiro.`
  - handler atual responde `ERR_ACCOUNT_DEPOSIT_REQUIRED` com HTTP 402
- Impacto no frontend:
  - `ReceiveScreen` já usa esse conceito no fluxo do próprio usuário
  - em fluxo de envio para terceiro, essa mensagem pode confundir o remetente
- Testes existentes:
  - `backend/kerosene/src/test/java/source/auth/application/service/account/AccountActivationServiceTest.java`
  - `frontend/test/features/wallet/receive_screen_activation_block_test.dart`
- Testes ausentes:
  - caracterização explícita do comportamento quando o destinatário do envio está inativo

### Regra: rate limit financeiro no ledger

- Onde: `backend/kerosene/src/main/java/source/ledger/controller/LedgerController.java`
- Entrada esperada: usuário autenticado chamando `/ledger/transaction` ou pagamento de payment request
- Saída esperada: operação permitida até 3 tentativas por 60 segundos
- Erros possíveis:
  - `LedgerExceptions.TransactionReplayException`
- Impacto no frontend:
  - retries automáticos não devem mascarar limite financeiro
- Testes existentes:
  - cobertura parcial em `TransactionTest`
- Testes ausentes:
  - controller test do limite por Redis

### Regra: resposta HTTP é envelopada e o frontend a desembrulha

- Onde:
  - backend: `backend/kerosene/src/main/java/source/common/dto/ApiResponse.java`
  - frontend: `frontend/lib/core/network/api_response_interceptor.dart`
  - frontend: `frontend/lib/core/network/api_client.dart`
- Entrada esperada: payload `{ success, message, data, errorCode }`
- Saída esperada:
  - sucesso: `response.data` vira apenas `data`
  - erro: `AppException`/`ValidationException`/`AuthException`/`ServerException`
- Erros possíveis:
  - perda de granularidade se `errorCode` novo não for traduzido
- Impacto no frontend:
  - `ErrorTranslator` é responsável pela mensagem final apresentada
- Testes existentes:
  - `frontend/test/core/utils/error_translator_test.dart`
  - `frontend/test/core/network/api_client_route_policy_test.dart`
- Testes ausentes:
  - tradução para `ERR_ACCOUNT_DEPOSIT_REQUIRED`
  - tradução para `ERR_LEDGER_RECEIVER_NOT_READY`

## Arquivos sensíveis

- Backend:
  - `backend/kerosene/src/main/java/source/ledger/application/transaction/TransactionParticipantResolver.java`
  - `backend/kerosene/src/main/java/source/common/exception/GlobalExceptionHandler.java`
  - `backend/kerosene/src/main/java/source/auth/application/service/account/AccountActivationService.java`
  - `backend/kerosene/src/main/java/source/ledger/controller/LedgerController.java`
  - `backend/kerosene/src/main/java/source/ledger/application/transaction/**`
  - `backend/kerosene/src/main/java/source/transactions/**`
- Frontend:
  - `frontend/lib/core/network/api_client.dart`
  - `frontend/lib/core/network/api_response_interceptor.dart`
  - `frontend/lib/core/utils/error_translator.dart`
  - `frontend/lib/features/wallet/presentation/screens/send_money_screen.dart`
  - `frontend/lib/features/wallet/data/repositories/wallet_repository_impl.dart`
  - `frontend/lib/features/wallet/data/datasources/ledger_remote_datasource.dart`
  - `frontend/lib/features/transactions/presentation/providers/transaction_provider.dart`

## Pontos frágeis

- Há coexistência de arquitetura antiga e nova no backend.
- Há duas superfícies de erro no backend: `GlobalExceptionHandler` e `RestResponseErrors`.
- `ErrorTranslator` do Flutter mistura mapeamento por `errorCode` com heurística por texto livre.
- `wallet_repository_impl.dart` usa `ledgerRemoteDataSource.sendInternalTransaction(...)` dentro de um caso de uso chamado `sendBitcoin`, o que mistura envio interno e externo.
- O admin web e o app mobile convivem no mesmo código Flutter; alterações compartilhadas precisam preservar os dois contextos.
- Existem endpoints legados e novos para transações externas.

## Dívidas técnicas observadas

- Falta cobertura automatizada para alguns erros financeiros específicos.
- Alguns nomes e contratos no frontend ainda carregam semântica antiga ou genérica.
- O fluxo de erro “destinatário existe, mas não está pronto para receber” não está fechado ponta a ponta.
- O frontend ainda depende bastante de parsing textual para remediação.
- Existem arquivos grandes no frontend, especialmente telas e providers de wallet/transações.

## Ambiguidades registradas

- Ambiguidade resolvida neste bloco para o fluxo de transferência interna:
  - `ReceiverNotReadyException` agora cobre tanto “sem wallet apta a receber” quanto “inbound bloqueado”
- O erro `ERR_ACCOUNT_DEPOSIT_REQUIRED` permanece válido para fluxos do próprio usuário, como verificação de ativação/recebimento no app.

## Comandos de validação

### Backend

- `cd backend/kerosene && ./gradlew test`
- `cd backend/kerosene && ./gradlew compileJava compileTestJava`
- `cd backend/kerosene && ./gradlew bootJar`
- `cd backend/kerosene && ./gradlew dependencyCheckAnalyze`

### Frontend

- `cd frontend && flutter analyze`
- `cd frontend && flutter test`
- `cd frontend && flutter build apk --release`
- `cd frontend && flutter gen-l10n`

## Decisões tomadas durante a refatoração

- O primeiro alvo de refatoração será um fluxo financeiro pequeno e verificável, não uma reestruturação ampla do sistema.
- As alterações locais pré-existentes no backend serão tratadas como contexto a preservar e completar, não como algo a sobrescrever.
- Mudança aplicada neste bloco:
  - o fluxo de transferência interna agora converte estados do destinatário não pronto em erro de ledger específico, sem reutilizar a mensagem de depósito obrigatório do próprio remetente
- Decisão de contrato:
  - `ReceiverNotReadyException` carrega `reason`
  - `GlobalExceptionHandler` expõe `ERR_LEDGER_RECEIVER_NOT_READY` com `data.reason`
  - o Flutter traduz `INBOUND_BLOCKED` e `NO_RECEIVING_WALLET` com mensagens distintas

## Plano do bloco atual

1. Problema encontrado
   - O fluxo de envio interno ainda pode devolver erro ambíguo ou incompleto quando o destinatário existe, mas não está pronto para receber fundos.
   - O backend já tem uma mudança local parcial para o caso “sem wallet”, mas ela ainda não cobre o fluxo inteiro e o frontend não traduz o novo contrato.
2. Causa raiz provável
   - Regra de prontidão do destinatário está espalhada entre `TransactionParticipantResolver`, `AccountActivationService` e `GlobalExceptionHandler`.
   - O frontend depende de `errorCode` traduzido, mas ainda não conhece `ERR_LEDGER_RECEIVER_NOT_READY`.
3. Arquivos que serão alterados
   - `backend/kerosene/src/main/java/source/ledger/application/transaction/TransactionParticipantResolver.java`
   - `backend/kerosene/src/main/java/source/ledger/exceptions/LedgerExceptions.java`
   - `backend/kerosene/src/main/java/source/common/exception/GlobalExceptionHandler.java`
   - `backend/kerosene/src/test/java/source/ledger/application/transaction/TransactionParticipantResolverTest.java`
   - `backend/kerosene/src/test/java/source/common/exception/GlobalExceptionHandlerTest.java`
   - possivelmente `backend/kerosene/src/test/java/source/ledger/controller/LedgerControllerTest.java`
   - `frontend/lib/core/utils/error_translator.dart`
   - `frontend/test/core/utils/error_translator_test.dart`
   - `frontend/lib/l10n/app_pt.arb`
   - `frontend/lib/l10n/app_en.arb`
   - `frontend/lib/l10n/app_es.arb`
   - arquivos gerados de localização se necessário
4. Arquivos que NÃO devem ser alterados neste bloco
   - fluxos de saque externo
   - controllers de auth fora do necessário
   - telas admin web
   - cálculo de saldo, taxa ou autenticação transacional
   - `backend/kerosene/src/main/java/source/wallet/dto/WalletRequestDTO.java`
5. Riscos
   - mudar mensagem/código de erro e quebrar expectativas já existentes
   - tocar em arquivos já modificados localmente e perder contexto
   - cobrir apenas um caminho de resolução do destinatário e deixar outro inconsistente
6. Testes que serão criados ou atualizados
   - resolver do backend para destinatário sem wallet e destinatário bloqueado para inbound
   - handler global para `ERR_LEDGER_RECEIVER_NOT_READY`
   - opcionalmente controller test de `/ledger/transaction` para o novo contrato
   - `ErrorTranslator` para o novo código e razões vindas do backend
7. Como validar que nada quebrou
   - rodar testes direcionados do backend e frontend relacionados ao fluxo
   - confirmar status HTTP, `errorCode`, mensagem e `data.reason`
   - confirmar que o frontend traduz corretamente o erro sem confundir remetente e destinatário
8. Critérios objetivos de conclusão
   - backend retorna erro específico de destinatário não pronto em todos os caminhos relevantes do envio interno
   - frontend exibe mensagem clara e não ambígua para esse erro
   - testes automatizados cobrindo backend e frontend passam
   - este arquivo é atualizado com o resultado final

## Progresso

### O que já foi entendido

- Stack real de backend e frontend.
- Separação mobile x web/admin no Flutter.
- Cadeia de transferência interna no backend:
  - controller fino
  - orchestrator
  - `TransactionProcessingUseCase`
  - handlers
  - `TransactionParticipantResolver`
  - `TransactionLedgerService`
- Cadeia de erro no frontend:
  - `ApiResponse`
  - `ApiResponseInterceptor`
  - `ApiClient`
  - `ErrorTranslator`
- Fluxo de bloqueio de inbound até depósito inicial.

### O que já foi alterado

- Backend:
  - `ReceiverNotReadyException` agora diferencia `NO_RECEIVING_WALLET` e `INBOUND_BLOCKED`
  - `TransactionParticipantResolver` converte bloqueio de inbound do destinatário em erro específico de ledger
  - `GlobalExceptionHandler` agora devolve `data.reason`
- Frontend:
  - `ErrorTranslator` passou a traduzir `ERR_LEDGER_RECEIVER_NOT_READY` por razão
  - novas chaves de localização foram adicionadas em `pt`, `en` e `es`
  - localizações geradas foram atualizadas
- Testes:
  - testes do tradutor e do backend foram ampliados

### O que falta alterar

- Rodar a suíte completa do backend quando o ambiente permitir.
- Investigar e estabilizar os erros de compilação já existentes no frontend e em testes de backend fora deste escopo.

### Regras críticas preservadas até aqui

- Sender continua sendo resolvido pelo usuário autenticado.
- Conta inativa continua sem poder receber inbound.
- O que mudou foi apenas a tradução contextual desse estado dentro do fluxo de envio para terceiros.

### Decisões arquiteturais em aberto

- Avaliar se outros fluxos além de `/ledger/transaction` também devem reutilizar `ReceiverNotReadyException`.

### Riscos ainda abertos

- Há vários erros de compilação pré-existentes no frontend fora do bloco alterado.
- A suíte de testes do backend continua parcialmente bloqueada por problemas já existentes em outros testes e por limitação do ambiente.

### Testes executados

- `cd frontend && flutter gen-l10n`
  - executado com sucesso
  - observação: o projeto já tem avisos de mensagens não traduzidas em `es`
- `cd frontend && dart format lib/core/utils/error_translator.dart test/core/utils/error_translator_test.dart`
  - executado com sucesso
- `cd frontend && flutter analyze lib/core/utils/error_translator.dart test/core/utils/error_translator_test.dart`
  - executado com sucesso
- `cd frontend && flutter test test/core/utils/error_translator_test.dart`
  - executado com sucesso
- `cd frontend && flutter test test/core/utils/error_translator_test.dart test/features/wallet/receive_screen_activation_block_test.dart`
  - falhou por erros de compilação já existentes em arquivos não relacionados do app/design system
- `cd backend/kerosene && ./gradlew test --tests source.ledger.application.transaction.TransactionParticipantResolverTest --tests source.common.exception.GlobalExceptionHandlerTest`
  - execução fora do sandbox iniciada para obter wrapper Gradle
  - falhou em `compileTestJava` por erros já existentes em testes fora do escopo, incluindo `CustodialAddressAllocatorTest` e `UpdateWalletInteractorTest`
- `cd backend/kerosene && ./gradlew compileJava`
  - tentativa em sandbox bloqueada por limitação de socket/daemon do Gradle no ambiente
  - tentativa fora do sandbox não pôde prosseguir por limite de uso do aprovador automático

### Testes pendentes

- Suíte completa do backend
- `LedgerControllerTest` e `TransactionParticipantResolverTest` em ambiente estável
- `receive_screen_activation_block_test.dart` após estabilização dos erros globais de compilação do frontend

## Lista de tarefas pendentes

- Revisar novamente este arquivo antes de cada etapa.
- Considerar o próximo bloco apenas depois de estabilizar os bloqueios globais de compilação.
- Se continuar no fluxo financeiro, revisar payment requests internos e outros pontos que ainda possam reutilizar mensagem errada de ativação.

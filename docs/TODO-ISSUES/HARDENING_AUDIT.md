# Auditoria de Endurecimento

Data: 2026-06-14

Escopo:
- `TreasuryService`
- `CaptureReserveSnapshotInteractor`
- `ExternalPaymentsLedgerAdapter`
- `BitcoinBlockchainMonitorService`
- `BitcoinCoreRpcClient`
- Fronteiras financeiras adjacentes usadas por essas classes.

## Resumo Executivo

A implementação está estruturalmente correta: débitos no razão são protegidos por locks pessimistas de linha, submissões de saída usam uma barreira de idempotência persistente, e o monitor encapsula falhas do Bitcoin Core RPC em vez de deixar que sondas agendadas quebrem. Encontrei diversas lacunas de endurecimento relacionadas a arredondamento conservador, entradas de reserva inválidas, isolamento de consulta de taxa PLATFORM e disparos concorrentes de sincronização automática. As lacunas concretas foram corrigidas.

Os itens de endurecimento arquitetural restantes são principalmente defesa em profundidade no nível do banco de dados: adicionar constraints CHECK para escala BTC/campos de taxa não negativos, constraints únicas de idempotência de transferência e constraints explícitas de dono de entrada do razão para que o banco de dados imponha os mesmos invariantes que a aplicação.

## Alterações Aplicadas

### Segurança Numérica

Corrigido:
- Os ativos do Tesouro agora são normalizados de forma conservadora com `RoundingMode.DOWN`.
- As obrigações e taxas do Tesouro agora são normalizadas com `RoundingMode.CEILING`, para que obrigações sub-satoshi ou com precisão excessiva não possam ser arredondadas para baixo e inflacionar os fundos disponíveis.
- Entradas negativas de reserva/lucro são ignoradas e registradas em vez de aumentar o saldo disponível do tesouro.
- A disponibilidade de saída Lightning agora rejeita valores de satoshi não positivos antes da matemática de reserva.
- Snapshots de reserva rejeitam saldos de satoshi negativos e impossíveis `> 21M BTC` vindos de adaptadores RPC.
- A agregação de reserva usa adição segura e falha fechada em caso de estouro ou valores agregados impossíveis.
- A conversão BTC-para-sats em `ExternalPaymentsMath` agora rejeita valores negativos e sub-satoshi e usa `longValueExact()`.
- A conversão BTC-para-sats de taxa do Bitcoin Core agora arredonda resultados positivos de taxa do Core para o próximo satoshi e usa `longValueExact()`.

Avaliação:
- A segurança de débito do usuário ainda depende principalmente de `LedgerService.updateBalance()`, que usa `findByWalletIdForUpdate()` mais uma verificação de saldo negativo dentro da transação lockeada. Essa é a fronteira de solvência correta.
- Pré-verificações como `ensureBalance()` podem se tornar obsoletas sob concorrência, mas o débito lockeado captura a condição de corrida e previne o saque a descoberto. A pré-verificação obsoleta pode produzir uma falha limpa, não um saldo negativo.

### Isolamento PLATFORM

Corrigido:
- `ExternalPaymentsLedgerAdapter.recordPlatformFee()` agora valida id da transferência, id do usuário, valor total, precisão da taxa plataforma, não negatividade e `platformFee <= totalDebited`.
- Entradas de taxa plataforma no razão continuam sendo escritas sob o dono literal `PLATFORM` com valor líquido do usuário zero.
- `LedgerEntryRepository.calculatePlatformProfitPending*()` agora soma apenas `userId = 'PLATFORM'`.
- `LedgerEntryRepository.markFeesAsCollected*()` agora marca apenas linhas `userId = 'PLATFORM'`.

Avaliação:
- O isolamento em nível de aplicação agora é mais forte: entradas do razão não-PLATFORM não podem ser varridas ou contadas como lucro da plataforma por consultas do repositório.
- Endurecimento de BD recomendado permanece: adicionar uma constraint CHECK para que linhas PLATFORM tenham `amount_net = 0`, `fee_amount >= 0`, e linhas não-PLATFORM não possam ser marcadas como `COLLECTED` por fluxos de pagamento de taxa.

### Robustez para Nó Podado

Corrigido:
- Sondas agendadas do monitor agora capturam falhas inesperadas de runtime em torno de `snapshot()` para proteger a thread do agendador.
- RPCs de melhor-bloco e info-carteira permanecem sondas seguras; falhas não derrubam o snapshot.
- Falhas de snapshot de transferência no BD não fazem mais o nó Bitcoin parecer indisponível.
- A execução do gatilho de sincronização automática é serializada com um lock, impedindo que chamadas agendadas e manuais lancem tentativas sobrepostas de `loadwallet`/`rescanblockchain`.
- A altura inicial do rescan agora ajusta `pruneheight > blocks` malformado para uma altura atual válida.
- Uma carteira Bitcoin Core configurada mas não carregada agora dispara `loadwallet` e um rescan recente limitado mesmo quando a chain está atualizada.
- Exceções RPC do Bitcoin Core agora preservam método, código de erro do Core e mensagem de erro do Core, o que torna falhas de histórico podado diagnosticáveis sem quebrar o monitor.

Avaliação:
- Consultar um bloco histórico podado ainda pode falhar, como esperado para nós podados, mas essa falha agora é representada como uma exceção RPC que os chamadores podem classificar.
- O rescan automático é intencionalmente limitado ao intervalo recente/podado disponível. Não deve tentar recuperar dados mais antigos que o horizonte de poda.

### Concorrência e Condições de Corrida

Confirmado:
- A mutação de saldo do razão usa um lock pessimista de escrita e valida saldos negativos após o lock ser adquirido.
- A idempotência persistente de transação processada tem um índice único de id da transação nas migrações.
- Os fluxos de requisição e reivindicação de pagamento do Tesouro usam locks do repositório/atualizações de reivindicação.

Corrigido:
- O gatilho de sincronização automática do Bitcoin Core agora tem uma seção crítica em processo para evitar rescans sobrepostos desta instância do serviço.

Preocupação arquitetural:
- Implantações multi-instância ainda precisam de um lock distribuído para trabalho de sincronização automática/rescan. O lock atual é local à JVM. Use um lock de advisory do BD, lock Redis com token de fencing, ou uma única instância do monitor com líder eleito antes de executar mais de uma instância de backend contra a mesma carteira Core.

## Recomendações de Endurecimento Restantes

1. Adicionar constraints de banco de dados para colunas monetárias:
   - `amount_btc`, `network_fee_btc`, `platform_fee_btc`, `total_debited_btc` escala <= 8.
   - Colunas de taxa não negativas.
   - Totais de transferência de saída satisfazem `total_debited_btc >= amount_btc + network_fee_btc`.

2. Adicionar uma constraint única de banco de dados para `financial.network_transfers.idempotency_key` quando não nulo. O caminho de saída atual tem uma barreira de idempotência de transação processada separada, mas a unicidade da linha de transferência deve ser uma segunda linha de defesa.

3. Adicionar um invariante em nível de banco de dados para `financial.ledger_entries`:
   - Linhas com `user_id = 'PLATFORM'` são as únicas linhas elegíveis para coleta de pagamento da plataforma.
   - Linhas com `user_id = 'PLATFORM'` devem ter `amount_net = 0`.
   - `fee_amount >= 0` e `amount_net >= 0`.

4. Adicionar um lock distribuído em torno de operações de rescan/carregamento de carteira Bitcoin Core antes de escalar horizontalmente. O lock em nível de serviço previne apenas corridas locais.

5. Revisar helpers de conversão BTC/sats legados/privados fora deste escopo. Várias classes adjacentes ainda usam helpers `btcToSats` privados; eles devem seguir a mesma política de conversão exata usada por `ExternalPaymentsMath`.

## Verificação

Testes unitários focados foram adicionados para:
- Arredondamento conservador do Tesouro e rejeição de valor Lightning não positivo.
- Rejeição de saldo impossível de snapshot de reserva e ajuste de intervalo de varredura.
- Validação do adaptador de taxa PLATFORM e isolamento de dono.
- Ajuste de altura de rescan para nó podado e recuperação de carteira configurada não carregada.
- Preservação de erro RPC do Bitcoin Core.
- Conversão exata BTC-para-sats.

A execução dos testes não pôde ser concluída no sandbox atual:
- O Gradle wrapper usando o home padrão falhou porque `/home/codex3/.gradle` é somente leitura.
- Um `GRADLE_USER_HOME` local ao repositório então falhou porque o wrapper precisava de acesso à rede para baixar o Gradle.
- Invocar a distribuição Gradle em cache diretamente falhou porque este sandbox bloqueia a criação de socket local necessária para a inicialização do daemon Gradle.

Execute localmente ou no CI:

```bash
cd backend/kerosene
./gradlew test \
  --tests source.treasury.service.TreasuryServiceTest \
  --tests source.treasury.application.usecase.CaptureReserveSnapshotInteractorTest \
  --tests source.transactions.infra.externalpayments.ExternalPaymentsLedgerAdapterTest \
  --tests source.transactions.monitoring.BitcoinBlockchainMonitorServiceTest \
  --tests source.transactions.infra.BitcoinCoreRpcClientTest \
  --tests source.transactions.application.externalpayments.ExternalPaymentsMathTest
```

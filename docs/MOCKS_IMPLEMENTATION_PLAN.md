# Plano de Implementacao de Mocks e Fallbacks

Escopo: remover comportamento simulado de fluxos reais do app sem tocar nos
mocks do Storybook. Storybook continua autorizado a usar dados isolados para
renderizacao de componentes.

## Status aplicado

### Contas Bitcoin

- Removido o `LocalBitcoinAccountsService`, que criava contas, requests e
  enderecos `bc1qkerosene...` localmente.
- `bitcoinAccountsServiceProvider` agora usa `RemoteBitcoinAccountsService`
  com o `ApiClient` real.
- Fluxos integrados:
  - `GET /bitcoin/accounts`
  - `POST /bitcoin/accounts/internal-card`
  - `POST /bitcoin/accounts/cold-wallet`
  - `POST /bitcoin/accounts/{accountId}/receive-requests`
  - `GET /bitcoin/receive-requests/{id}/status`
- Removido `BitcoinAccountsLocalStore` e o teste que validava a persistencia
  local desse mock.

Gap real pendente:

- O backend ainda nao expoe uma rota de historico/listagem de receive requests
  por conta. O app nao fabrica mais uma lista local; agora propaga erro com
  `ERR_BITCOIN_RECEIVE_REQUEST_HISTORY_UNAVAILABLE`.

Plano:

1. Criar no backend `GET /bitcoin/accounts/{accountId}/receive-requests`.
2. Retornar lista paginavel com `id`, `accountId`, `address`, `bip21`,
   `status`, `amountSats`, `expiry` ou `expiresAt`, `oneTime`, `createdAt`.
3. Trocar `listReceiveRequestsForAccount` para consumir essa rota.
4. Adicionar teste de datasource/provider cobrindo sucesso, erro de backend e
   resposta invalida.

### Transacoes

- Removido o sucesso fabricado em `sendTransaction` quando o ledger respondia
  com payload vazio.
- Agora o app falha explicitamente com
  `ERR_LEDGER_EMPTY_TRANSACTION_RESPONSE`.

Plano:

1. Garantir que `POST /ledger/transaction` sempre retorne o status real da
   transacao.
2. Tratar respostas vazias como regressao de contrato no backend.
3. Adicionar teste do datasource validando que payload vazio nao vira
   `confirmed`.

### Precos

- Removida cotacao fixa EUR/USD `0.92`.
- Removido fallback fixo USD/BRL `5.0`.
- Removido valor fixo BTC/USD `65000.0` do `WalletRepositoryImpl`.
- BRL agora usa `btcBrl` real do backend ou calcula a partir de `btcUsd` e
  `usdBrl` reais. EUR so aparece quando `btcEur` vier do backend.

Plano:

1. Estender `/api/economy/btc-price` para retornar `btcEur` quando EUR for
   suportado na UI.
2. Expor timestamp/origem da cotacao para permitir estado "cotacao
   indisponivel" em vez de valor estatico.
3. Adicionar testes para garantir que EUR/BRL retornem `null` quando nao houver
   cotacao real suficiente.

### Admin

- `AdminDataService` nao retorna mais `{}`, `[]` ou preco zerado quando o
  backend falha ou responde com formato inesperado.
- Acoes administrativas de dispositivo nao engolem mais erro silenciosamente.

Plano:

1. Ajustar as telas admin para renderizarem os estados de erro dos
   `FutureProvider`s de forma explicita.
2. Padronizar contratos de resposta admin no backend.
3. Adicionar testes de provider/servico para resposta invalida e falha HTTP.

### Taxas de rede

- Removida a aproximacao fixa `estimatedTxSize: 250`.
- O tamanho estimado agora e derivado dos dados reais de fee retornados pelo
  backend. Se os dados forem insuficientes, a estimativa falha explicitamente.

Plano:

1. Preferir que o backend retorne `estimatedTxSize` diretamente.
2. Enquanto isso, manter a derivacao por fee total e sat/vB apenas quando todos
   os campos necessarios existirem.

## Permitido

- `frontend/lib/storybook/**` pode continuar com mocks.
- Adapters de plataforma que fazem no-op por impossibilidade da plataforma
  continuam permitidos quando nao simulam sucesso de negocio.
- Fallbacks de apresentacao, labels, localizacao e placeholders visuais nao
  substituem dados de servico e nao entram neste plano.

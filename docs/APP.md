# App Documentation

Esta documentacao descreve o app Flutter atual em `frontend/lib`, incluindo mobile, web admin, integracao de API e fluxos principais.

## Estrutura

| Pasta | Responsabilidade |
| --- | --- |
| `frontend/lib/core` | Config global, client HTTP, providers globais, seguranca local, servicos, tema, widgets comuns, navegacao e utilitarios. |
| `frontend/lib/design_system` | Motion/design system compartilhado. |
| `frontend/lib/features/auth` | Login, signup, passkey, TOTP, recovery e estado de auth. |
| `frontend/lib/features/home` | Shell principal do app mobile, saldo, acoes e entrada de payment link. |
| `frontend/lib/features/wallet` | Wallets, cartoes, envio, recebimento, deposito, NFC, QR e providers de wallet. |
| `frontend/lib/features/transactions` | Depositos, saques, confirmacao de pagamentos e historico operacional. |
| `frontend/lib/features/bitcoin_accounts` | Contas Bitcoin, internal BTC card, cold wallet watch-only, PSBT, receive requests e tax events. |
| `frontend/lib/features/security` | Status de soberania, PIN local de entrada e treasury overview. |
| `frontend/lib/features/web_admin` | Painel web/admin empresarial servido pelo backend. |
| `frontend/lib/features/landing` | Landing publica, download e status publico. |
| `frontend/lib/l10n` | ARB e localizacoes pt/en/es. |

## Bootstraps

`frontend/lib/main.dart` escolhe bootstrap por plataforma.

Mobile (`bootstrap/mobile_bootstrap.dart`):

1. Inicializa notificacao local, background service e audio.
2. Tenta iniciar Tor local.
3. Se Tor subir, abre relay local `127.0.0.1:<porta>` para o onion ativo e atualiza `AppConfig.apiUrl`.
4. Configura `MaterialApp` com rotas mobile e gate privado.
5. Quando autenticado e PIN local satisfeito, inicia provider de WebSocket de saldo/notificacoes.

Web (`bootstrap/web_bootstrap.dart`):

1. Resolve API por `WEB_API_URL`, `WEB_ONION_GATEWAY`, origem `.onion` do browser ou same-origin.
2. Usa rotas `/`, `/bitcoin-banking`, `/admin`, `/download`, `/status`.
3. O `/admin` exige usuario autenticado com `isAdmin` no estado local.

## Client HTTP

`core/network/api_client.dart` usa Dio com:

- Base URL dinamica por provider (`torApiUrlProvider`).
- Headers base `Content-Type: application/json` e `Accept: application/json`.
- Retry para 408/502/503/504/440/522/524/598/599.
- Interceptor de envelope `ApiResponseInterceptor`.
- Limite local de payload alinhado ao backend: `2048` bytes padrao, `64 KiB` para PSBT.
- Roteamento por Tor/SOCKS quando a URL alvo e `.onion` e a plataforma permite.

`features/auth/data/interceptors/token_interceptor.dart`:

- Injeta `Authorization: Bearer <jwt>` fora das rotas publicas de auth/onboarding.
- Em mobile, quando usa relay local, injeta `Host` com o onion original.
- Injeta `X-Device-Hash` em mobile quando disponivel.
- Persiste `X-New-Token` retornado pelo backend.
- Derruba sessao local em 401/403 de auth fora de fluxos transacionais com step-up.

## Rotas mobile

| Rota | Tela |
| --- | --- |
| `/welcome` | `WelcomeScreen` |
| `/login` | `LoginUsernameScreen` |
| `/signup` | `SignupFlowScreen` |
| `/home` | `HomeScreen` |
| `/home_loading` | `HomeLoadingScreen` |
| `/settings` | `SettingsScreen` |
| `/history` e `/deposits` | `DepositsScreen` |
| `/card` | `BitcoinAccountsScreen` |
| `/receive` | `ReceiveHubScreen` |
| `/create_wallet` | `CreateWalletScreen` |
| `/send-money` | `SendMoneyScreen` |

Payment links tambem podem ser detectados por `QrPaymentParser` em `onGenerateRoute`.

## Rotas web

| Rota | Tela |
| --- | --- |
| `/` | `KeroseneLandingPage` |
| `/bitcoin-banking` | `KeroseneLandingPage` |
| `/admin` | `AdminShell` depois de login admin, ou `AdminLoginScreen` |
| `/download` | Landing com foco em download |
| `/status` | `KerosenePublicStatusPage` |

O backend encaminha essas rotas para `index.html` por `WebAdminController`.

## Funcionalidades principais

### Auth e seguranca

- Signup com PoW, passphrase, opcoes de account security, TOTP opcional e onboarding de passkey.
- Login por passphrase + segundo fator quando necessario.
- Login por passkey via challenge/verify.
- Passkey usa `PASSKEY_RP_ID` no Flutter, com default `kerosene-device`; o backend espera o mesmo valor em `WEBAUTHN_RP_ID` nos perfis local/docker.
- Recovery emergencial com recovery codes, nova passphrase, novo TOTP/passkey.
- PIN local de app por dispositivo via `/auth/security/app-pin`.
- Inventario, bloqueio e revogacao de passkeys.

### Wallet, ledger e pagamentos

- Criacao/listagem/busca/update/delete de wallets.
- Transferencia interna por `/ledger/transaction`.
- Payment request interno por `/ledger/payment-request`.
- Payment link externo por `/transactions/create-payment-link` e rotas de confirm/complete/cancel.
- Depositos on-chain, invoices Lightning, pagamentos Lightning/on-chain e historico por `/transactions/network/*`.
- Novo dominio `/payments/*` para quote/confirm/status com `PaymentIntent`.

### Bitcoin accounts

- Lista/criacao de internal BTC card e cold wallet watch-only.
- Receive requests com public code.
- UTXOs e PSBT workflow para cold wallets.
- Tax events temporarios e classificacao.

### Admin/web

- Painel com dashboard, monitoring, transactions, lightning, onchain, checks, payment links, analytics, volatility, companies, audit, authenticated devices, notifications e settings.
- Consome `/api/admin/operations/*`, `/v1/audit/*`, `/audit/*`, `/auth/admin/*` e endpoints de device/passkey.

### Realtime

- `BalanceWebSocketService` conecta em `/ws/balance`.
- Assina `/user/queue/balance` e `/user/queue/notifications`.
- Eventos atualizam saldo, notificacoes de sessao, popups e notificacoes locais.
- O preco BTC usa WebSocket externo Binance/Coinbase em `PriceWebSocketService`, com fallback HTTP `/api/economy/btc-price`.

## Contratos de API usados pelo frontend

A lista fonte fica em `core/config/app_config.dart`. Ha constantes que nao possuem controller atual e precisam limpeza:

- `notificationsSend = /notifications/send` nao existe no `NotificationController` atual.
- `transactionsConfirmDeposit`, `transactionsDeposits`, `transactionsDepositBalance`, `transactionsDeposit` sao legacy e comentados como compatibilidade.
- `auditMerkleTrigger = /audit/trigger` existe no backend, mas nao apareceu no parser simples porque usa anotacao fully-qualified.
- `vaultArm`, `vaultAttest`, `vaultProvision` apontam para o vault service, nao para o backend Spring principal.

## Testes relevantes

- `frontend/test/core/network/token_interceptor_test.dart`
- `frontend/test/core/network/api_client_route_policy_test.dart`
- `frontend/test/features/auth/*`
- `frontend/test/features/wallet/*`
- `frontend/test/features/bitcoin_accounts/*`
- `frontend/test/bootstrap/web_bootstrap_test.dart`
- `frontend/test/l10n/arb_parity_test.dart`

Comandos:

```bash
cd frontend && flutter pub get && flutter analyze && flutter test
```

# Guia do Aplicativo Frontend Kerosene

Este documento descreve o frontend Flutter atual em `frontend/lib`. Ele é
destinado a engenheiros e agentes que alteram o aplicativo, admin web, integração
de API ou fluxos voltados ao usuário.

## Escopo

Kerosene oferece três superfícies de entrada Flutter a partir da mesma base de código:

| Superfície | Ponto de entrada | Bootstrap | Propósito em tempo de execução |
| --- | --- | --- | --- |
| Aplicativo móvel | `frontend/lib/main.dart` | `bootstrap/mobile_bootstrap.dart` | Fluxos de carteira autenticada, recebimento, envio, configurações e segurança. |
| Aplicativo web/admin | `frontend/lib/web_main.dart` | `bootstrap/web_bootstrap.dart` | Páginas públicas de destino/status mais admin empresarial autenticado. |
| Storybook | `frontend/lib/storybook_main.dart` | `storybook/storybook_app.dart` | Pré-visualizações isoladas e cenários de fluxo com suporte de mocks. |

O frontend é orientado a funcionalidades. A infraestrutura compartilhada reside em `core`, enquanto
as superfícies de produto residem em `features`.

| Diretório | Responsabilidade |
| --- | --- |
| `core/config` | Configuração de API/nó em tempo de execução e constantes de rota. |
| `core/network` | Cliente Dio, manipulação de envelope de resposta, roteamento de plataforma, retry e provedor de API. |
| `core/providers` | Estado global Riverpod para aparência, localidade, URL Tor, preços, invalidação de sessão e preferências do aplicativo. |
| `core/security` | PIN local, armazenamento seguro e auxiliares biométricos. |
| `core/services` | Bootstrap Tor, serviços WebSocket, notificações, áudio, passkeys, chaves de dispositivo, serviços em segundo plano. |
| `core/theme` | Tema móvel, tipografia, espaçamento, cor e auxiliares de componente monocromático. |
| `core/presentation` e `core/widgets` | Widgets compartilhados, superfícies de shell do aplicativo, diálogos, hosts de feedback e primitivas de UI reutilizáveis. |
| `features/auth` | Cadastro, login, passkey, TOTP, recuperação de emergência, estado de autenticação, persistência de token. |
| `features/home` | Shell inicial móvel, exibição de saldo, entrada de link de pagamento, atalhos de envio/recebimento. |
| `features/wallet` | Estado da carteira, fluxos de recebimento, tela de envio, telas de depósito, cartões de carteira, vinculação WebSocket de saldo. |
| `features/transactions` | Contratos de dados de transação, provedores de histórico, depósitos, saques, links de pagamento, UI de confirmação. |
| `features/payments` | Fluxo de cotação/confirmação/status de intenção de pagamento para `REMOVED_LEGACY_FINANCIAL_ROUTE`. |
| `features/bitcoin_accounts` | Contas Bitcoin com suporte KFE, cartões internos, carteiras frias watch-only, manipulação de endereço de recebimento. |
| `features/security` | Status de soberania, inventário de passkeys, perfil PIN do aplicativo, visão geral de tesouraria/segurança. |
| `features/notifications` | Repositório de notificação de sessão, central, barra lateral e host de notificação global. |
| `features/web_admin` | Shell admin, navegação, dashboard, telas operacionais, tema admin e serviços de API admin. |
| `features/landing` | Página de destino pública, metadados de download móvel, status de prontidão e lançamento. |

## Runtime Móvel

`bootstrap/mobile_bootstrap.dart` gerencia o ciclo de vida do aplicativo móvel.

Sequência de inicialização:

1. Criar um `ProviderContainer` com `SharedPreferences` injetado.
2. Instalar manipuladores de erro globais do Flutter e da plataforma.
3. Iniciar bootstrap Tor assincronamente através de `bootstrapTorNetwork`; quando pronto,
   atualiza `torApiUrlProvider`.
4. Inicializar notificações locais, serviço em segundo plano e áudio.
5. Aumentar limites de cache de imagem do Flutter para a UI com uso intenso de mídia.
6. Construir `MaterialApp` com `AppTheme.themeFor(appearance.themeVariant)`,
   delegates de localização, limite responsivo, limite de desempenho, listener
   de invalidação de sessão, host de notificação e porta de rota privada.

Usuários móveis autenticados passam por `AppEntryPinGate` antes das telas privadas.
Após a autenticação e os requisitos de PIN local serem satisfeitos, `_AppRealtimeBootstrap`
se inscreve em `balanceWebSocketServiceProvider`.

Rotas móveis atuais:

| Rota | Tela |
| --- | --- |
| `/welcome` | `WelcomeScreen` |
| `/login` | `LoginScreen` |
| `/recovery/emergency` | `EmergencyRecoveryScreen` |
| `/signup` | `SignupFlowScreen` |
| `/server-unavailable` | `ServerUnavailableScreen` |
| `/home` | `HomeScreen` atrás de `_PrivateMobileRoute` |
| `/home_loading` | `HomeLoadingScreen` atrás de `_PrivateMobileRoute` |
| `/settings` | `SettingsScreen(showPrimaryNavigation: true)` atrás de `_PrivateMobileRoute` |
| `/history` | `TransactionStatementScreen` atrás de `_PrivateMobileRoute` |
| `/card` | `BitcoinAccountsScreen` atrás de `_PrivateMobileRoute` |
| `/bitcoin/advanced` | `BitcoinAccountsScreen` atrás de `_PrivateMobileRoute` |
| `/receive` | `DepositsScreen` atrás de `_PrivateMobileRoute` |
| `/send-money` | `SendMoneyScreen` atrás de `_PrivateMobileRoute` |
| `/deposits` | `DepositsScreen` atrás de `_PrivateMobileRoute` |

`onGenerateRoute` também detecta URIs de link de pagamento Kerosene através de
`QrPaymentParser.extractPaymentLinkId` e abre `SendMoneyScreen` com a
solicitação de pagamento codificada.

## Runtime Web/Admin

`bootstrap/web_bootstrap.dart` gerencia o runtime do navegador.

Ordem de resolução de origem da API:

1. Variável de ambiente de tempo de compilação `WEB_API_URL`.
2. Variável de ambiente de tempo de compilação `WEB_ONION_GATEWAY`.
3. Origem atual do navegador quando servido de um host `.onion`.
4. `Uri.base.origin` para implantações de mesma origem.

`configureResolvedApiUrl` escreve a origem selecionada em `AppConfig.apiUrl`,
`AppConfig.activeNodeUrl` e `torApiUrlProvider`, mantendo a validação de RP
passkey alinhada com o host que o backend recebe.

Rotas web atuais:

| Rota | Tela |
| --- | --- |
| `/` | `KeroseneLandingPage` |
| `/bitcoin-banking` | `KeroseneLandingPage` |
| `/admin` | `_AdminAuthGate`; usuários admin entram em `AdminShell(child: AdminContentRouter())` |
| `/download` | `KeroseneLandingPage(focusDownload: true)` |
| `/status` | `KerosenePublicStatusPage` |

Rotas web desconhecidas redirecionam para a página de destino. `/admin` requer um
estado de autenticação local autenticado com `user.isAdmin == true`.

## Cliente de API

`core/network/api_client.dart` encapsula Dio e deve permanecer o único ponto de
entrada HTTP geral para fontes de dados de funcionalidades.

Comportamento do cliente:

- URL base vem de `torApiUrlProvider`.
- Cabeçalhos JSON são aplicados por padrão.
- `ApiResponseInterceptor` desencapsula envelopes do backend formatados como
  `{ success: true, data: ... }` e converte `{ success: false, ... }` em um
  erro Dio.
- Retry está habilitado para códigos de status de gateway/rede transitórios:
  `408`, `502`, `503`, `504`, `440`, `522`, `524`, `598`, `599`.
- Retry é bloqueado para rotas/corpos que consomem challenge de passkey/WebAuthn
  (`passkey` finish/verify/register, recuperação emergencial e payloads com
  prova passkey), porque repetir a mesma assinatura transforma uma falha
  transitória real em replay/challenge inválido.
- Payloads têm limite de tamanho antes do envio: `2048` bytes por padrão e `64 KiB`
  para caminhos PSBT.
- Roteamento de plataforma prepara suporte Tor/SOCKS quando aplicável.

`features/auth/data/interceptors/token_interceptor.dart` adiciona credenciais do aplicativo:

- Injeta `Authorization: Bearer <jwt>` fora de rotas públicas de autenticação/onboarding.
- Em rotas de relay local móvel/desktop, preserva o `Host` onion original.
- Adiciona `X-Device-Hash` em plataformas não-web quando disponível.
- Persiste credenciais de sessão rotacionadas de `X-New-Token`.
- Emite invalidação de sessão local para casos explícitos de sessão inválida 401/403.
- Preserva falhas de step-up de transação em `/kfe/transactions` e
  `/transactions/` para que erros de TOTP/passkey não forcem um logout.

## Integração do Financial Engine

KFE é o backend financeiro ativo para carteiras, projeções de ledger, histórico
de transações, envio/recebimento externo e telas de conta Bitcoin. Constantes de
rota residem em `core/config/app_config.dart`.

Rotas KFE primárias:

| Rota | Uso no frontend |
| --- | --- |
| `GET /kfe/dashboard` | Lista de carteiras, saldos, extrato recente, depósitos, transferências externas, lista de contas Bitcoin. |
| `POST /kfe/wallets` | Criação de carteira/cartão interno e importação de carteira watch-only. |
| `POST /kfe/wallets/{walletId}/addresses/rotate` | Alocação de endereço de recebimento e criação de link de pagamento on-chain com suporte KFE. |
| `POST /kfe/transactions` | Transferências internas, saques on-chain, saques Lightning. |
| `GET /kfe/transactions/{transactionId}` | Status da transação, detalhe da transferência, status do link de pagamento com suporte KFE. |

Comportamento atual por fluxo:

- Criação/lista/busca de carteiras usam dados de carteira/dashboard KFE. A criação retorna um
  payload de carteira estruturado e é mapeado para `Wallet`.
- Atualização/exclusão de carteiras são intencionalmente bloqueadas no frontend com
  erros de indisponibilidade específicos do KFE até que o KFE exponha essas operações.
- Saldo/histórico do ledger são projeções de `/kfe/dashboard`.
- Transferências internas usam `POST /kfe/transactions` com `rail: INTERNAL` e
  `direction: INTERNAL`.
- Saques on-chain usam `POST /kfe/transactions` com `rail: ONCHAIN`,
  `direction: OUTBOUND`, valores em satoshi, taxas e referência externa.
- Pagamentos de saída Lightning usam a mesma rota de transação com
  `rail: LIGHTNING`.
- Criação de recebimento/link de pagamento on-chain aloca um endereço de carteira via
  `/kfe/wallets/{walletId}/addresses/rotate` e mapeia o resultado para
  `PaymentLink`.
- Status/detalhe do link de pagamento lê `/kfe/transactions/{id}`. A listagem é derivada
  de payloads de extrato KFE on-chain de entrada em `/kfe/dashboard`.
- Cancelamento de link de pagamento está intencionalmente indisponível no frontend até
  que exista um endpoint de cancelamento KFE.
- Fluxos legados de transação não assinada direta e broadcast direto estão intencionalmente
  desabilitados; KFE prepara/transmite transações durante o envio.
- Recebimento de fatura Lightning e fluxos de trabalho PSBT de carteira fria ainda estão
  marcados como indisponíveis onde o KFE não expõe a operação.

`REMOVED_LEGACY_FINANCIAL_ROUTE` permanece um domínio separado de intenção de pagamento:

| Rota | Uso no frontend |
| --- | --- |
| `GET /users/{receiverIdentifier}/receiving-capabilities` | Determinar trilhos suportados para um destinatário. |
| `POST /payments/quote` | Criar uma cotação para pagamento interno, Lightning ou on-chain. |
| `POST /payments/{paymentIntentId}/confirm` | Confirmar uma cotação com totais aceitos e chave de idempotência. |
| `GET /payments/{paymentIntentId}` | Consultar status da intenção de pagamento. |

`/api/onramp/urls`, `/api/economy/btc-price`, endpoints de notificação,
endpoints de autenticação/admin, endpoints de soberania e operações de auditoria/admin não
fazem parte do KFE e não devem ser migrados para `/kfe/*` sem alterações no backend.

## Autenticação e Segurança

O estado de autenticação é gerenciado através de `authControllerProvider`, `AuthRemoteDataSource`
e `AuthLocalDataSource`.

Fluxos suportados:

- Cadastro com desafio de proof-of-work, frase-senha, postura opcional de segurança
  de conta, TOTP opcional e onboarding de passkey.
- Login com frase-senha e TOTP quando necessário.
- Fluxos de desafio/verificação de passkey.
- Recuperação de emergência com códigos de recuperação e credenciais de substituição.
- Perfil do usuário atual através de `/auth/me`.
- Status de segurança, status de ativação, configuração/verificação/desabilitação de TOTP, códigos de backup.
- Estado do PIN do aplicativo através de `/auth/security/app-pin` e controle de entrada local.
- Inventário de passkeys, bloqueio/revogação de dispositivo e fluxos de aprovação de acesso admin.

Configuração de passkey:

- Flutter usa `PASSKEY_RP_ID` com valor padrão `kerosene-device`.
- Origem padrão móvel é `android:apk-key-hash:kerosene`.
- Web admin mantém `AppConfig.activeNodeUrl` alinhado com a origem resolvida do
  navegador/API para que as verificações de RP do backend vejam o host esperado.

## Tempo Real e Notificações

Atualizações em tempo real de saldo/sessão são coordenadas por:

- `BalanceWebSocketService`
- `balanceWebSocketServiceProvider`
- `sessionNotificationProvider`
- `GlobalNotificationHost`
- serviços de notificação local e áudio

O WebSocket de saldo é preparado apenas para sessões autenticadas que tenham
satisfeito os requisitos de PIN local do aplicativo. Atualizações de preço BTC usam
feeds WebSocket externos da Binance e Coinbase em `PriceWebSocketService`, com
fallback HTTP através de `/api/economy/btc-price`.

## Localização

Código de localização gerado e arquivos ARB residem em `frontend/lib/core/l10n`.

Arquivos importantes:

- `app_en.arb`
- `app_pt.arb`
- `app_es.arb`
- `app_localizations.dart`
- `app_localizations_en.dart`
- `app_localizations_pt.dart`
- `app_localizations_es.dart`
- `l10n_extension.dart`
- `frontend/l10n.yaml`

Use `context.tr.<key>` de `core/l10n/l10n_extension.dart` para strings visíveis
ao usuário. Mantenha as chaves sincronizadas entre inglês, português e espanhol.

## Testes e Verificação

Verificações comuns do frontend:

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```

Áreas direcionadas com testes existentes incluem:

- `frontend/test/core/network/token_interceptor_test.dart`
- `frontend/test/core/network/api_client_route_policy_test.dart`
- `frontend/test/features/auth/*`
- `frontend/test/features/wallet/*`
- `frontend/test/features/bitcoin_accounts/*`
- `frontend/test/bootstrap/web_bootstrap_test.dart`
- `frontend/test/l10n/arb_parity_test.dart`

Para alterações que afetam o KFE, verifique pelo menos:

1. A criação de carteira retorna um `Wallet` estruturado.
2. A lista de carteiras baseada no dashboard e o histórico de transações renderizam corretamente.
3. A criação de endereço de recebimento/link de pagamento usa `/kfe/wallets/{walletId}/addresses/rotate`.
4. O envio/saque de transação usa `/kfe/transactions`.
5. Nenhuma chamada legada `REMOVED_LEGACY_FINANCIAL_ROUTE`, `REMOVED_LEGACY_FINANCIAL_ROUTE`
   ou `REMOVED_LEGACY_FINANCIAL_ROUTE` é emitida a partir de fluxos de recebimento ativos.

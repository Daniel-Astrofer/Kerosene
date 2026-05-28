# Inventario de telas e cobertura do Storybook

Data da auditoria: 2026-05-27

Escopo analisado: `frontend/lib/features`, rotas mobile em
`frontend/lib/bootstrap/mobile_bootstrap.dart`, rotas web em
`frontend/lib/bootstrap/web_bootstrap.dart`, roteador admin em
`frontend/lib/features/web_admin/navigation/admin_content_router.dart` e stories
em `frontend/lib/storybook`.

## Resumo

- O Storybook agora registra 52 stories.
- O grupo correto de autenticacao e apenas `Auth/*`.
- Fluxos legados/dormentes e a galeria de debug foram removidos do Storybook e
  do codigo.
- As telas publicas importaveis atuais foram cadastradas no Storybook,
  incluindo telas mobile, web/admin e componentes compartilhados.
- Telas privadas iniciadas por `_` nao podem ser importadas diretamente fora do
  arquivo/biblioteca Dart. Elas aparecem abaixo como internas e devem ser
  verificadas pela tela publica dona.
- O Storybook continua sendo catalogo visual com mocks. Ele nao substitui teste
  de backend ou fluxo real com `WEB_API_URL`.

## Telas atualmente utilizadas

### Mobile/auth

| Tela | Arquivo | Uso atual | Storybook |
| --- | --- | --- | --- |
| `WelcomeScreen` | `frontend/lib/features/auth/presentation/screens/welcome_screen.dart` | Home unauth e rota `/welcome` | `Auth/Welcome Screen` |
| `LoginScreen` | `frontend/lib/features/auth/presentation/screens/login_screen.dart` | Rota `/login` | `Auth/Login` |
| `SignupFlowScreen` | `frontend/lib/features/auth/presentation/screens/signup/signup_flow_screen.dart` | Rota `/signup` | `Auth/Signup - Main Flow` |
| `PasskeyVerificationScreen` | `frontend/lib/features/auth/presentation/screens/passkey_verification_screen.dart` | Fluxo de login por passkey | `Auth/Login - Passkey Verification` |
| `ServerUnavailableScreen` | `frontend/lib/features/auth/presentation/screens/server_unavailable_screen.dart` | Estado de auth servidor indisponivel e rota `/server-unavailable` | Sem story |

### Mobile principal

| Tela | Arquivo | Uso atual | Storybook |
| --- | --- | --- | --- |
| `HomeLoadingScreen` | `frontend/lib/features/home/presentation/screens/home_loading_screen.dart` | Entrada autenticada e rota `/home_loading` | `Wallet/Home Loading` |
| `HomeScreen` | `frontend/lib/features/home/presentation/screens/home_screen.dart` | Rota `/home` | `Wallet/Home Dashboard` |
| `SettingsScreen` | `frontend/lib/features/settings/presentation/screens/settings_screen.dart` | Rota `/settings` e navegacao primaria | `Current/Mobile/Settings` |
| `DepositsScreen` | `frontend/lib/features/transactions/presentation/screens/deposits_screen.dart` | Rotas `/history` e `/deposits` | `Current/Mobile/Deposits & History` |
| `BitcoinAccountsScreen` | `frontend/lib/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart` | Rota `/card` | `Current/Mobile/Bitcoin Accounts` |
| `MiningScreen` | `frontend/lib/features/mining/presentation/screens/mining_screen.dart` | Rota `/mining` e detalhe de transacao mineravel | `Current/Mobile/Mining Dashboard` |
| `ReceiveHubScreen` | `frontend/lib/features/wallet/presentation/screens/receive_hub_screen.dart` | Rota `/receive` e acao de receber na Home | `Current/Mobile/Receive Hub` |
| `SendMoneyScreen` | `frontend/lib/features/wallet/presentation/screens/send_money_screen.dart` | Rota `/send-money`, payment links e acao de envio | `Wallet/Send Money` |
| `QrScannerScreen` | `frontend/lib/features/home/presentation/screens/qr_scanner_screen.dart` | Acao de scan em envio/saque | `Wallet/QR Scanner` |

### Wallet, recebimento e pagamentos

| Tela | Arquivo | Uso atual | Storybook |
| --- | --- | --- | --- |
| `ReceiveScreen` | `frontend/lib/features/wallet/presentation/screens/receive_screen.dart` | Subfluxo de `ReceiveHubScreen` | `Wallet/Receive` |
| `ReceivePaymentLinkScreen` | `frontend/lib/features/wallet/presentation/screens/receive_payment_link_screen.dart` | Link de pagamento criado no fluxo de recebimento | `Current/Receive/Payment Link` |
| `DepositAmountScreen` | `frontend/lib/features/wallet/presentation/screens/deposit/deposit_amount_screen.dart` | Entrada do fluxo de deposito | `Wallet/Deposit - Amount` |
| `DepositMethodScreen` | `frontend/lib/features/wallet/presentation/screens/deposit/deposit_method_screen.dart` | Escolha Lightning/on-chain no fluxo de deposito | `Wallet/Deposit - Method` |
| `DepositOnchainInvoiceScreen` | `frontend/lib/features/wallet/presentation/screens/deposit/deposit_onchain_invoice_screen.dart` | Invoice/endereco on-chain | `Wallet/Deposit - Onchain Invoice` |
| `DepositLightningInvoiceScreen` | `frontend/lib/features/wallet/presentation/screens/deposit/deposit_lightning_invoice_screen.dart` | Invoice Lightning | `Wallet/Deposit - Lightning Invoice` |
| `transaction_withdraw.WithdrawScreen` | `frontend/lib/features/transactions/presentation/screens/withdraw_screen.dart` | Saque externo atual a partir da Home | `Current/Withdraw/External Withdraw` |
| `PaymentConfirmationScreen` | `frontend/lib/features/transactions/presentation/screens/payment_confirmation_screen.dart` | Confirmacao reutilizavel de operacoes financeiras | `Current/Payments/Confirmation` |
| `WithdrawReceiptScreen` | `frontend/lib/features/wallet/presentation/screens/withdraw_receipt_screen.dart` | Recibo do fluxo de saque legado/local | `Current/Withdraw/Receipt` |

### Conta, seguranca e notificacoes

| Tela | Arquivo | Uso atual | Storybook |
| --- | --- | --- | --- |
| `SecuritySettingsScreen` | `frontend/lib/features/profile/presentation/screens/security_settings_screen.dart` | Centro de seguranca a partir de Settings | `Current/Account/Security Settings` |
| `NotificationSettingsScreen` | `frontend/lib/features/profile/presentation/screens/notification_settings_screen.dart` | Configuracao aberta pelo centro de notificacoes | `Current/Account/Notification Settings` |
| `NotificationCenterScreen` | `frontend/lib/features/notifications/presentation/screens/notification_center_screen.dart` | Centro de notificacoes via overlay | `Current/Notifications/Notification Center` |
| `SovereigntyStatusScreen` | `frontend/lib/features/security/presentation/screens/sovereignty_status_screen.dart` | Painel de soberania a partir de seguranca | `Current/Security/Sovereignty Status` |

### Web publico/admin

| Tela | Arquivo | Uso atual | Storybook |
| --- | --- | --- | --- |
| `KeroseneLandingPage` | `frontend/lib/features/landing/presentation/kerosene_landing_page.dart` | Rotas `/`, `/bitcoin-banking`, `/download` | `Current/Web/Public Landing`, `Current/Web/Download Landing` |
| `KerosenePublicStatusPage` | `frontend/lib/features/landing/presentation/kerosene_landing_page.dart` | Rota `/status` | `Current/Web/Public Status` |
| `AdminLoginScreen` | `frontend/lib/features/web_admin/screens/login/admin_login_screen.dart` | Login de `/admin` | `Current/Web Admin/Login` |
| `DashboardScreen` | `frontend/lib/features/web_admin/screens/dashboard/dashboard_screen.dart` | Admin dashboard | `Current/Web Admin/Dashboard` |
| `MonitoringScreen` | `frontend/lib/features/web_admin/screens/monitoring/monitoring_screen.dart` | Admin monitoring | `Current/Web Admin/Monitoring` |
| `TransactionsScreen` | `frontend/lib/features/web_admin/screens/transactions/transactions_screen.dart` | Admin integrity proofs/transacoes | `Current/Web Admin/Transactions` |
| `LightningScreen` | `frontend/lib/features/web_admin/screens/lightning/lightning_screen.dart` | Admin Lightning | `Current/Web Admin/Lightning` |
| `OnchainScreen` | `frontend/lib/features/web_admin/screens/onchain/onchain_screen.dart` | Admin on-chain | `Current/Web Admin/On-chain` |
| `ChecksScreen` | `frontend/lib/features/web_admin/screens/checks/checks_screen.dart` | Admin hash chain/checks | `Current/Web Admin/Checks` |
| `AnalyticsScreen` | `frontend/lib/features/web_admin/screens/analytics/analytics_screen.dart` | Admin analytics | `Current/Web Admin/Analytics` |
| `VolatilityScreen` | `frontend/lib/features/web_admin/screens/volatility/volatility_screen.dart` | Admin volatility | `Current/Web Admin/Volatility` |
| `AuditScreen` | `frontend/lib/features/web_admin/screens/audit/audit_screen.dart` | Admin audit/security | `Current/Web Admin/Audit` |
| `NotificationsScreen` | `frontend/lib/features/web_admin/screens/notifications/notifications_screen.dart` | Admin notifications | `Current/Web Admin/Notifications` |

## Telas privadas/internas nao importaveis diretamente

Estas classes comecam com `_`, portanto sao privadas ao arquivo/biblioteca Dart e
nao podem ser registradas diretamente em `frontend/lib/storybook/stories/*`:

| Tela privada | Arquivo | Como validar |
| --- | --- | --- |
| `_PaymentLinkEntryScreen` | `frontend/lib/features/home/presentation/screens/home_screen_payment_link.dart` | Pela story de `HomeScreen` |
| `_SendMethodScreen` | `frontend/lib/features/home/presentation/screens/home_screen_send_method.dart` | Pela story de `HomeScreen` |
| `_AppEntryPinLockScreen` | `frontend/lib/features/security/presentation/widgets/app_entry_pin_gate.dart` | Pelo fluxo autenticado real ou story futura especifica do widget publico |
| `_InternalTransferReviewScreen` | `frontend/lib/features/wallet/presentation/screens/send_money_screen_review.dart` | Pelo fluxo de `SendMoneyScreen` |
| `ColdWalletCreationScreen` | `frontend/lib/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart` | Story `Wallet/Cold Wallet — Create`, com seleção de finalidade antes da geração |

## Observacoes

- O fluxo dormente de wallet/debug foi removido do codigo e do Storybook.
- Os steps legados de signup foram removidos do codigo e do Storybook. A rota
  `/signup` usa apenas `SignupFlowScreen`.
- As telas standalone `TotpScreen`, `BiometricAuthScreen`,
  `UnknownDeviceScreen`, `CreateWalletScreen`, `WalletDetailsScreen`,
  `WalletConfigScreen` e `NfcInteractionScreen` foram removidas do codigo e do
  Storybook. O desafio TOTP de login agora fica inline em `LoginScreen` e
  `PasskeyVerificationScreen`.
- Quando uma tela depender de plugin de plataforma, como WebView/camera, a
  story pode exigir o device correto para renderizar completamente.
- Para teste de chamadas reais, use o app/web bootstrap normal, nao o Storybook.

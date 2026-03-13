/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== API Configuration ====================

  // ==================== Node Configuration ====================

  /// Endereços .onion dos nós remotos
  static const String nodeIS = 'http://gi6catvghtt6n6ldjl2woyzw4lolevmhb6e46b74dxopytid5f2ovlad.onion';
  static const String nodeCH = 'http://qo7t6dvhegbiejgva2oo72w2harfcjzcfxh53mo7igvy565jozdnd2ad.onion';
  static const String nodeSG = 'http://j7lkbq37m2i4mqf7du3fnhiqc6uqizh2vkgtodm45pkbcfzt3fnuqdyd.onion';

  /// Mapeamento de nós com nomes amigáveis
  static const Map<String, String> nodes = {
    'Node IS': nodeIS,
    'Node CH': nodeCH,
    'Node SG': nodeSG,
  };

  /// Nó ativo atualmente (URL .onion remota)
  static String activeNodeUrl = nodeIS;

  /// Nome do nó ativo
  static String get activeNodeName => 
      nodes.entries.firstWhere((e) => e.value == activeNodeUrl).key;

  /// Endereço .onion base — Atualmente espelha o activeNodeUrl para compatibilidade
  static String get onionBaseUrl => activeNodeUrl;

  /// URL ativa da API — Aponta para o relay local (configurado no main.dart)
  static String apiUrl = nodeIS; 

  /// Timeout para requisições HTTP (em milissegundos)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ==================== API Headers ====================
  /// Header enviado pelo servidor quando o JWT está próximo de expirar.
  static const String newTokenHeader = 'X-New-Token';
  // NOTE: x-device-hash foi REMOVIDO do backend. Não enviar esse header.

  // ==================== API Endpoints ====================

  // Auth
  static const String authSignup = '/auth/signup';
  static const String authSignupVerify = '/auth/signup/totp/verify';
  static const String authLogin = '/auth/login';
  static const String authLoginVerify = '/auth/login/totp/verify';
  // NOTE: /auth/refresh e /auth/logout não estão na documentação atual do backend.
  // Mantidos como comentários para compatibilidade futura.
  // static const String authRefresh = '/auth/refresh';
  // static const String authLogout = '/auth/logout';
  static const String authPowChallenge = '/auth/pow/challenge';
  static const String authPasskeyOnboardingStart =
      '/auth/passkey/register/onboarding/start';
  static const String authPasskeyOnboardingFinish =
      '/auth/passkey/register/onboarding/finish';
  static const String authPasskeyLoginStart = '/auth/passkey/login/start';
  static const String authPasskeyLoginFinish = '/auth/passkey/login/finish';
   static const String authPasskeyRegisterStart = '/auth/passkey/register/start';
  static const String authPasskeyRegisterFinish = '/auth/passkey/register/finish';
  
  // Sovereign Auth (Hardware Ed25519)
  static const String authHardwareOnboardingStart = '/auth/hardware/register/onboarding/start';
  static const String authHardwareOnboardingFinish = '/auth/hardware/register/onboarding/finish';
  static const String authHardwareChallenge = '/auth/hardware/challenge';
  static const String authHardwareVerify = '/auth/hardware/verify';
  static const String authHardwareRegisterStart = '/auth/hardware/register/start';
  static const String authHardwareRegisterFinish = '/auth/hardware/register/finish';
  static const String voucherOnboardingLink = '/voucher/onboarding-link';
  static const String voucherOnboardingMockConfirm =
      '/voucher/onboarding-mock-confirm';
  static const String voucherConfirm = '/voucher/confirm';

  // Notifications
  static const String notificationRegisterToken =
      '/notifications/register-token';

  // Wallet
  static const String walletCreate = '/wallet/create';
  static const String walletUpdate = '/wallet/update';
  static const String walletFind = '/wallet/find';
  static const String walletAll = '/wallet/all';
  static const String walletDelete = '/wallet/delete';

  // Ledger
  static const String ledgerTransaction = '/ledger/transaction';
  static const String ledgerFind = '/ledger/find';
  static const String ledgerBalance = '/ledger/balance';
  static const String ledgerAll = '/ledger/all';
  // NOTE: DELETE /ledger/delete NÃO EXISTE no servidor atual (doc seção 3.6).
  static const String ledgerHistory = '/ledger/history';

  // Transactions - Fee & Status
  static const String transactionsEstimateFee = '/transactions/estimate-fee';
  static const String transactionsStatus = '/transactions/status';

  // Transactions - Send & Broadcast
  static const String transactionsCreateUnsigned =
      '/transactions/create-unsigned';
  static const String transactionsBroadcast = '/transactions/broadcast';
  static const String transactionsWithdraw = '/transactions/withdraw';

  // Transactions - On-Chain Payment Links
  static const String transactionsCreatePaymentLink =
      '/transactions/create-payment-link';
  static const String transactionsPaymentLink =
      '/transactions/payment-link'; // + /{linkId}, /confirm, /complete
  static const String transactionsPaymentLinksList =
      '/transactions/payment-links';

  // Transactions - Deposits
  static const String transactionsDepositAddress =
      '/transactions/deposit-address';
  static const String transactionsConfirmDeposit =
      '/transactions/confirm-deposit';
  static const String transactionsDeposits = '/transactions/deposits';
  static const String transactionsDepositBalance =
      '/transactions/deposit-balance';
  static const String transactionsDeposit = '/transactions/deposit';

  // Ledger - Payment Requests
  static const String ledgerPaymentRequest = '/ledger/payment-request';
  static const String ledgerPaymentRequestPay =
      '/ledger/payment-request'; // + /{linkId}/pay

  // ==================== Storage Keys ====================

  /// Chave para armazenar o token JWT
  static const String authTokenKey = 'auth_token';

  /// Chave para armazenar dados do usuário
  static const String userDataKey = 'user_data';

  /// Chave para armazenar TOTP secret
  static const String totpSecretKey = 'totp_secret';

  /// Chave para armazenar refresh token
  static const String refreshTokenKey = 'refresh_token';

  // ==================== Feature Flags ====================

  /// Habilitar modo debug
  static const bool enableDebugMode = true;

  /// Habilitar logs
  static const bool enableLogs = true;

  /// Habilitar analytics
  static const bool enableAnalytics = false;

  /// Habilitar crash reporting
  static const bool enableCrashReporting = false;

  // ==================== Environment ====================

  /// Ambiente atual (development, staging, production)
  static const String environment = 'production';

  /// Verificar se está em produção
  static bool get isProduction => environment == 'production';

  /// Verificar se está em desenvolvimento
  static bool get isDevelopment => environment == 'development';

  /// Verificar se está em staging
  static bool get isStaging => environment == 'staging';

  // ==================== App Info ====================

  /// Nome da aplicação
  static const String appName = 'Kerosene';

  /// Versão da aplicação
  static const String appVersion = '1.0.0';
}

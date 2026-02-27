/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== API Configuration ====================

  /// Endereço .onion da API no Tor (Modo Seguro Obrigatório)
  static const String onionBaseUrl =
      'http://sc3mol7ughlcsazgt2najfhgbjmwq74gmy4jclnkcjrwc4kc7shmzjad.onion';

  /// URL ativa — Exclusiva para a Onion Network. (Mutável pelo relay)
  static String apiUrl = onionBaseUrl;

  /// Timeout para requisições HTTP (em milissegundos)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ==================== API Headers ====================
  // ==================== API Headers ====================
  static const String newTokenHeader = 'X-New-Token';
  static const String deviceHashHeader = 'X-Device-Hash';

  // ==================== API Endpoints ====================

  // Auth
  static const String authSignup = '/auth/signup';
  static const String authSignupVerify = '/auth/signup/totp/verify';
  static const String authLogin = '/auth/login';
  static const String authLoginVerify = '/auth/login/totp/verify';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authPowChallenge = '/auth/pow/challenge';
  static const String authPasskeyOnboardingStart =
      '/auth/passkey/register/onboarding/start';
  static const String authPasskeyOnboardingFinish =
      '/auth/passkey/register/onboarding/finish';
  static const String voucherOnboardingLink = '/voucher/onboarding-link';

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
  static const String ledgerDelete = '/ledger/delete';
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

  /// Chave para armazenar device hash
  static const String deviceHashKey = 'device_hash';

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

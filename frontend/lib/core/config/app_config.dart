/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== API Configuration ====================

  /// URL base da API Kerosene
  static const String apiBaseUrl =
      'https://disingenuously-undelightful-lino.ngrok-free.dev';

  /// Timeout para requisições HTTP (em milissegundos)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ==================== API Headers ====================
  static const String newTokenHeader = 'X-New-Token';

  // ==================== API Endpoints ====================

  // Auth
  static const String authSignup = '/auth/signup';
  static const String authTotpVerify = '/auth/signup/totp/verify';
  static const String authLogin = '/auth/login';
  static const String authLoginVerify = '/auth/login/totp/verify';

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

  // Transactions - Fee & Status
  static const String transactionsEstimateFee = '/transactions/estimate-fee';
  static const String transactionsStatus = '/transactions/status';

  // Transactions - Send & Broadcast
  static const String transactionsSend = '/transactions/send';
  static const String transactionsBroadcast = '/transactions/broadcast';

  // Transactions - Deposits
  static const String transactionsDepositAddress =
      '/transactions/deposit-address';
  static const String transactionsConfirmDeposit =
      '/transactions/confirm-deposit';
  static const String transactionsDeposits = '/transactions/deposits';
  static const String transactionsDepositBalance =
      '/transactions/deposit-balance';
  static const String transactionsDeposit =
      '/transactions/deposit'; // + /{txid}

  // Transactions - Payment Links
  static const String transactionsCreatePaymentLink =
      '/transactions/create-payment-link';
  static const String transactionsPaymentLink =
      '/transactions/payment-link'; // + /{linkId}
  static const String transactionsPaymentLinks = '/transactions/payment-links';

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
  static const String environment = 'development';

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

  // ==================== URLs ====================

  /// URL completa da API
  static String get apiUrl => apiBaseUrl;
}

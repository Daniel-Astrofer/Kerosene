/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== API Configuration ====================

  /// URL base da API Kerosene
  static const String apiBaseUrl = 'http://18.117.96.94:8080';

  /// Timeout para requisições HTTP (em milissegundos)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

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

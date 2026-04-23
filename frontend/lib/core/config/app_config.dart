/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== API Configuration ====================

  // ==================== Node Configuration ====================

  /// Endereços .onion dos nós remotos
  static const String nodeIS =
      'http://epef24frbttdyirb45zif4smrkmhfd4di34my7wdhadzomfcpcf5fbyd.onion';
  static const String nodeCH =
      'http://aznllofvisv5xryqumr7ikbprgjvhyh6izyyslhgx4v3lsgydoegixid.onion';
  static const String nodeSG =
      'http://vck7thw2lk4yoxwtwwmwdndbwxjfkvdxck2ys25lkzrqiusbclak2kqd.onion';

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
  // NOTE: x-device-hash foi REMOVIDO do backend. Não e  // ==================== API Endpoints ====================
  // (Mapped according to API_REFERENCE.md)

  // 1. Authentication & Users
  static const String authSignup = '/auth/signup';
  static const String authSignupVerify = '/auth/signup/totp/verify';
  static const String authLogin = '/auth/login';
  static const String authLoginVerify = '/auth/login/totp/verify';
  static const String authPowChallenge = '/auth/pow/challenge';

  // 1.2 WebAuthn / Passkeys
  // 1.2 WebAuthn / Passkeys
  static const String authPasskeyChallenge = '/auth/passkey/challenge';
  static const String authPasskeyRegister = '/auth/passkey/register';
  static const String authPasskeyVerify = '/auth/passkey/verify';
  static const String authPasskeyOnboardingStart =
      '/auth/passkey/onboarding/start';
  static const String authPasskeyOnboardingFinish =
      '/auth/passkey/onboarding/finish';
  static const String authRecoveryEmergencyStart =
      '/auth/recovery/emergency/start';
  static const String authRecoveryEmergencyFinish =
      '/auth/recovery/emergency/finish';
  static const String passkeyOrigin = String.fromEnvironment(
    'PASSKEY_ORIGIN',
    defaultValue: 'android:apk-key-hash:kerosene',
  );
  static const String passkeyRpId = String.fromEnvironment(
    'PASSKEY_RP_ID',
    defaultValue: '',
  );

  static String get effectivePasskeyRpId {
    final explicit = passkeyRpId.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    try {
      final onionHost = Uri.parse(onionBaseUrl).host.trim();
      if (onionHost.isNotEmpty) {
        return onionHost;
      }
    } catch (_) {}

    try {
      final apiHost = Uri.parse(apiUrl).host.trim();
      if (apiHost.isNotEmpty) {
        return apiHost;
      }
    } catch (_) {}

    return 'localhost';
  }

  // 1.3 Profile
  static const String authMe = '/auth/me';
  static const String authSecurityProfile = '/auth/security/profile';
  static const String authSecurityStatus = '/auth/security-status';
  static const String authActivationStatus = '/auth/activation-status';
  static const String authActivationDepositLink =
      '/auth/activation-status/deposit-link';
  static const String authBackupCodes = '/auth/backup-codes';
  static const String authBackupCodesRegenerate =
      '/auth/backup-codes/regenerate';
  static const String authTotpSetup = '/auth/totp/setup';
  static const String authTotpVerify = '/auth/totp/verify';
  static const String authTotpDisable = '/auth/totp';

  // 2. Wallets
  static const String walletCreate = '/wallet/create';
  static const String walletAll = '/wallet/all';
  static const String walletFind = '/wallet/find';
  static const String walletUpdate = '/wallet/update';
  static const String walletDelete = '/wallet/delete';

  // 3. Ledger & Internal Finances
  static const String ledgerAll = '/ledger/all';
  static const String ledgerFind = '/ledger/find';
  static const String ledgerBalance = '/ledger/balance';
  static const String ledgerHistory = '/ledger/history';
  static const String ledgerTransaction = '/ledger/transaction';

  // 3.1 Payment Requests (Internal)
  static const String ledgerPaymentRequest = '/ledger/payment-request';
  static const String ledgerPaymentRequestPay =
      '/ledger/payment-request/{linkId}/pay';
  static const String ledgerDelete = '/ledger';

  // 4. Bitcoin Transactions
  static const String transactionsDepositAddress =
      '/transactions/deposit-address';
  static const String transactionsEstimateFee = '/transactions/estimate-fee';
  static const String transactionsCreateUnsigned =
      '/transactions/create-unsigned';
  static const String transactionsBroadcast = '/transactions/broadcast';
  static const String transactionsStatus = '/transactions/status';
  static const String transactionsWithdraw = '/transactions/withdraw';
  static const String transactionsNetworkOnchainAddress =
      '/transactions/network/onchain/address';
  static const String transactionsNetworkWalletProfile =
      '/transactions/network/wallet-profile';
  static const String transactionsNetworkOnchainSend =
      '/transactions/network/onchain/send';
  static const String transactionsNetworkLightningInvoice =
      '/transactions/network/lightning/invoice';
  static const String transactionsNetworkLightningPay =
      '/transactions/network/lightning/pay';
  static const String transactionsNetworkTransfers =
      '/transactions/network/transfers';

  // 4.1 Payment Links (External BTC)
  static const String transactionsCreatePaymentLink =
      '/transactions/create-payment-link';
  static const String transactionsPaymentLink =
      '/transactions/payment-link'; // + /{linkId}
  static const String transactionsPaymentLinkConfirm =
      '/transactions/payment-link/{linkId}/confirm';
  static const String transactionsPaymentLinkComplete =
      '/transactions/payment-link/{linkId}/complete';
  static const String transactionsPaymentLinksList =
      '/transactions/payment-links';
  static const String transactionsOnrampUrls = '/api/onramp/urls';

  // 5. Vouchers (legacy / transitional)
  static const String voucherRequest = '/voucher/request';
  static const String voucherConfirm = '/voucher/confirm';
  static const String voucherOnboardingLink = '/voucher/onboarding-link';
  static const String voucherOnboardingLinkStatus =
      '/voucher/onboarding-link/{linkId}';
  static const String voucherOnboardingLinkConfirm =
      '/voucher/onboarding-link/{linkId}/confirm';
  static const String voucherOnboardingMockConfirm =
      '/voucher/onboarding-mock-confirm';
  static const String voucherTestClaim = '/voucher/test-claim';

  // 6. Notifications
  static const String notificationsSend = '/notifications/send';
  static const String notificationRegisterToken =
      '/notifications/register-token';

  // 7. Sovereignty & Audit
  static const String sovereigntyStatus = '/sovereignty/status';
  static const String sovereigntyPing = '/sovereignty/ping';
  static const String sovereigntyTelemetry = '/sovereignty/telemetry';
  static const String sovereigntyReattest = '/sovereignty/reattest';

  // 7.2 Proof of Reserves & Audit
  static const String auditStats = '/v1/audit/stats';
  static const String auditSiphon = '/v1/audit/siphon';
  static const String auditMerkleLatestRoot = '/audit/latest-root';
  static const String auditMerkleHistory = '/audit/history';
  static const String auditMerkleTrigger = '/audit/trigger';

  // 8. Vault System
  static const String vaultArm = '/v1/vault/arm';
  static const String vaultAttest = '/v1/vault/attest';
  static const String vaultProvision = '/v1/vault/provision';

  // (Legacy / Extra - Checking for compatibility)
  static const String transactionsConfirmDeposit =
      '/transactions/confirm-deposit';
  static const String transactionsDeposits = '/transactions/deposits';
  static const String transactionsDepositBalance =
      '/transactions/deposit-balance';
  static const String transactionsDeposit = '/transactions/deposit';

  // 4.3 Mining Marketplace
  static const String miningRigs = '/mining/rigs';
  static const String miningAllocations = '/mining/allocations';

  // ==================== Storage Keys ====================

  /// Chave para armazenar o token JWT
  static const String authTokenKey = 'auth_token';

  /// Chave para armazenar dados do usuário
  static const String userDataKey = 'user_data';

  /// Chave para armazenar TOTP secret
  static const String totpSecretKey = 'totp_secret';

  /// Chave para armazenar backup codes
  static const String backupCodesKey = 'backup_codes';

  /// Chave para armazenar refresh token
  static const String refreshTokenKey = 'refresh_token';

  // ==================== Feature Flags ====================

  /// Habilitar modo debug
  static const bool enableDebugMode = false;

  /// Habilitar logs
  static const bool enableLogs = true;

  /// Status do Tor
  static bool isTorEnabled = false;

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
  static const String appName = 'Kerosene Bank';

  /// Versão da aplicação
  static const String appVersion = '1.0.0';
}

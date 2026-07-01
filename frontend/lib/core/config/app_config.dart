/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== Node Routing ====================

  // Local-full Kubernetes onion currently persisted under
  // /home/omega/.local/state/kerosene/tor/keys/local-full.
  // Production builds should override this with KERO_NODE_*_URL.
  static const String _localFullDefaultOnionUrl =
      'http://exze5uokdpao4lwdodnlsd4pvfm25ntpkwh7xas5fefuzdmiisr4u7yd.onion';

  /// Endereços .onion dos nós remotos
  static const String nodeIS = String.fromEnvironment(
    'KERO_NODE_IS_URL',
    defaultValue: _localFullDefaultOnionUrl,
  );
  static const String nodeCH = String.fromEnvironment(
    'KERO_NODE_CH_URL',
    defaultValue: _localFullDefaultOnionUrl,
  );
  static const String nodeSG = String.fromEnvironment(
    'KERO_NODE_SG_URL',
    defaultValue: _localFullDefaultOnionUrl,
  );

  /// Mapeamento de nós com nomes amigáveis
  static const Map<String, String> nodes = {
    'Node IS': nodeIS,
    'Node CH': nodeCH,
    'Node SG': nodeSG,
  };

  /// Nó ativo atualmente (URL .onion remota)
  static String activeNodeUrl = nodeIS;

  /// Nome do nó ativo. Ambientes web/local podem injetar uma URL fora do mapa.
  static String get activeNodeName {
    for (final entry in nodes.entries) {
      if (entry.value == activeNodeUrl) return entry.key;
    }
    return Uri.tryParse(activeNodeUrl)?.host ?? 'Custom Node';
  }

  /// Endereço .onion base — Atualmente espelha o activeNodeUrl para compatibilidade
  static String get onionBaseUrl => activeNodeUrl;

  /// URL ativa da API — Aponta para o relay local (configurado no main.dart)
  static String apiUrl = nodeIS;

  /// Timeout para requisições HTTP (em milissegundos)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  /// Header enviado pelo servidor quando o JWT está próximo de expirar.
  static const String newTokenHeader = 'X-New-Token';

  // ==================== Auth ====================
  static const String authSignup = '/auth/signup';
  static const String authSignupVerify = '/auth/signup/totp/verify';
  static const String authLogin = '/auth/login';
  static const String authLoginVerify = '/auth/login/totp/verify';
  static const String authPowChallenge = '/auth/pow/challenge';
  static const String authEmergencyRecoveryStart =
      '/auth/recovery/emergency/start';
  static const String authEmergencyRecoveryFinish =
      '/auth/recovery/emergency/finish';
  static const String authPasskeyChallenge = '/auth/passkey/challenge';
  static const String authPasskeyRegister = '/auth/passkey/register';
  static const String authPasskeyVerify = '/auth/passkey/verify';
  static const String authPasskeyDevices = '/auth/passkey/devices';
  static const String authPasskeyOnboardingStart =
      '/auth/passkey/onboarding/start';
  static const String authPasskeyOnboardingFinish =
      '/auth/passkey/onboarding/finish';
  static String authPasskeyDeviceBlock(String deviceInstallId) =>
      '/auth/passkey/devices/$deviceInstallId/block';
  static String authPasskeyDeviceRevoke(String deviceInstallId) =>
      '/auth/passkey/devices/$deviceInstallId/revoke';
  static const String passkeyOrigin = String.fromEnvironment(
    'PASSKEY_ORIGIN',
    defaultValue: 'android:apk-key-hash:kerosene',
  );
  static const String defaultPasskeyRpId = 'kerosene-device';
  static const String passkeyRpId = String.fromEnvironment(
    'PASSKEY_RP_ID',
    defaultValue: defaultPasskeyRpId,
  );

  static String get effectivePasskeyRpId {
    final explicit = passkeyRpId.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return defaultPasskeyRpId;
  }

  // 1.3 Profile
  static const String authMe = '/auth/me';
  static const String authSecurityProfile = '/auth/security/profile';
  static const String authAppPin = '/auth/security/app-pin';
  static const String authAppPinVerify = '/auth/security/app-pin/verify';
  static const String authSecurityStatus = '/auth/security-status';
  static const String authActivationStatus = '/auth/activation-status';
  static const String authActivationFundingLink =
      '/auth/activation-status/funding-link';
  static const String authBackupCodes = '/auth/backup-codes';
  static const String authBackupCodesRegenerate =
      '/auth/backup-codes/regenerate';
  static const String authTotpSetup = '/auth/totp/setup';
  static const String authTotpVerify = '/auth/totp/verify';
  static const String authTotpDisable = '/auth/totp';
  static const String authAdminLogin = '/auth/admin/login';
  static const String authAdminKey = '/auth/admin/key';
  static const String authAdminPendingAttempts =
      '/auth/admin/access-attempts/pending';
  static const String authAdminDevices = '/auth/admin/devices';

  static String authAdminLoginPoll(String attemptId) =>
      '/auth/admin/login/$attemptId';
  static String authAdminAttemptDecision(String attemptId) =>
      '/auth/admin/access-attempts/$attemptId/decision';
  static String authAdminDeviceBlock(String deviceId) =>
      '/auth/admin/devices/$deviceId/block';
  static String authAdminDeviceRevoke(String deviceId) =>
      '/auth/admin/devices/$deviceId/revoke';

  // ==================== KFE Financial Engine ====================
  static const String kfeWallets = '/kfe/wallets';
  static const String kfeDashboard = '/kfe/dashboard';
  static const String kfeTransactions = '/kfe/transactions';
  static String kfeTransaction(String transactionId) =>
      '$kfeTransactions/$transactionId';
  static String kfeWallet(String walletId) => '$kfeWallets/$walletId';
  static String kfeWalletArchive(String walletId) =>
      '${kfeWallet(walletId)}/archive';
  static String kfeWalletAddressRotate(String walletId) =>
      '$kfeWallets/$walletId/addresses/rotate';

  static const String kfeTransactionQuote = '$kfeTransactions/quote';
  static const String kfePaymentRequests = '/kfe/payment-requests';
  static String kfePaymentRequest(String requestId) =>
      '$kfePaymentRequests/$requestId';
  static String kfePublicPaymentRequest(String publicId) =>
      '/api/public/kfe/payment-requests/$publicId';
  static String kfePaymentRequestExpire(String requestId) =>
      '$kfePaymentRequests/$requestId/expire';
  static String kfePaymentRequestHide(String requestId) =>
      '$kfePaymentRequests/$requestId/hide';
  static String kfePaymentRequestCancel(String requestId) =>
      '$kfePaymentRequests/$requestId/cancel';
  static const String kfeOnrampUrls = '$kfeTransactions/onramp-urls';
  static const String kfeReserveOverview = '/api/admin/kfe/reserves/overview';
  static String kfeReceivingCapabilities(String receiverIdentifier) =>
      '/kfe/users/${Uri.encodeComponent(receiverIdentifier.trim())}/receiving-capabilities';

  static String kfeColdWalletPsbtCreate(String walletId) =>
      '$kfeWallets/$walletId/cold-wallet/psbt';
  static String kfeColdWalletUtxos(String walletId) =>
      '$kfeWallets/$walletId/utxos';
  static const String kfeTaxEvents = '/kfe/tax-events';
  static String kfeTaxEventsExport(String format) =>
      '$kfeTaxEvents/export?format=$format';
  static String kfeTaxEventClassify(String eventId) =>
      '$kfeTaxEvents/$eventId/classify';
  static const String kfeColdWalletPsbts = '/kfe/cold-wallet/psbts';
  static String kfeColdWalletPsbtWorkflow(String workflowId) =>
      '$kfeColdWalletPsbts/$workflowId';
  static String kfeColdWalletPsbtSigned(String workflowId) =>
      '$kfeColdWalletPsbts/$workflowId/signed';
  static String kfeColdWalletPsbtBroadcast(String workflowId) =>
      '$kfeColdWalletPsbts/$workflowId/broadcast';

  // ==================== Notifications ====================
  static const String notificationsList = '/notifications';
  static const String notificationsRead = '/notifications/{id}/read';
  static const String notificationRegisterToken =
      '/notifications/register-token';
  static const String notificationDeviceTokens = '/notifications/device-tokens';
  static String notificationDeviceToken(String tokenId) =>
      '$notificationDeviceTokens/$tokenId';

  // ==================== Security ====================
  static const String sovereigntyStatus = '/sovereignty/status';
  static const String sovereigntyPing = '/sovereignty/ping';
  static const String sovereigntyTelemetry = '/sovereignty/telemetry';
  static const String sovereigntyReattest = '/sovereignty/reattest';
  static String get auditStats => throw UnsupportedError(
        'Legacy financial audit stats are unavailable in the KFE-only client.',
      );
  static const String auditMerkleLatestRoot = '/api/admin/kfe/audit/latest';
  static const String auditMerkleHistory = '/api/admin/kfe/audit/events';
  static const String auditMerkleTrigger = '/api/admin/kfe/audit/root';

  // ==================== Admin ====================
  static const String adminOperationsOverview =
      '/api/admin/operations/overview';
  static const String adminOperationsHealth = '/api/admin/operations/health';
  static const String adminOperationsBlockchain =
      '/api/admin/operations/blockchain';
  static String get adminOperationsBlockchainSync => throw UnsupportedError(
        'Legacy blockchain sync visualization is unavailable in the KFE-only client.',
      );
  static const String adminOperationsLightning =
      '/api/admin/operations/lightning';
  static const String adminOperationsVaultRaft =
      '/api/admin/operations/vault-raft';
  static const String adminOperationsRelease = '/api/admin/operations/release';
  static const String adminOperationsLogs = '/api/admin/operations/logs';
  static const String adminOperationsMobile = '/api/admin/operations/mobile';
  static const String adminOperationsMetrics = '/api/admin/operations/metrics';

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
  static const String appName = 'Kerosene';

  /// Versão da aplicação
  static const String appVersion = '1.0.0';
}

/// Configurações globais da aplicação Kerosene
class AppConfig {
  // ==================== Node Routing ====================

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
  static const String authActivationDepositLink =
      '/auth/activation-status/deposit-link';
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
  static String kfeWalletAddressRotate(String walletId) =>
      '$kfeWallets/$walletId/addresses/rotate';

  // ==================== Wallets ====================
  static const String walletCreate = kfeWallets;
  static const String walletAll = kfeDashboard;
  static const String walletFind = kfeWallets;
  static const String walletUpdate = kfeWallets;
  static const String walletDelete = kfeWallets;

  // ==================== Ledger ====================
  static const String ledgerAll = kfeDashboard;
  static const String ledgerFind = kfeDashboard;
  static const String ledgerBalance = kfeDashboard;
  static const String ledgerHistory = kfeDashboard;
  static const String ledgerTransaction = kfeTransactions;
  static const String ledgerPaymentRequest = kfeTransactions;
  static String ledgerPaymentRequestPayPath(String linkId) =>
      kfeTransaction(linkId);
  static const String ledgerPaymentRequestPay = kfeTransactions;
  static const String ledgerDelete = kfeDashboard;

  // ==================== Payments ====================
  static const String transactionsDepositAddress = kfeDashboard;
  static const String transactionsEstimateFee = kfeTransactions;
  static const String transactionsCreateUnsigned = kfeTransactions;
  static const String transactionsBroadcast = kfeTransactions;
  static const String transactionsStatus = kfeTransactions;
  static const String transactionsWithdraw = kfeTransactions;
  static const String transactionsNetworkOnchainAddress = kfeWallets;
  static const String transactionsNetworkWalletProfile = kfeDashboard;
  static const String transactionsNetworkOnchainSend = kfeTransactions;
  static const String transactionsNetworkLightningInvoice = kfeTransactions;
  static const String transactionsNetworkLightningPay = kfeTransactions;
  static const String transactionsNetworkTransfers = kfeDashboard;
  static const String legacyTransactionsDepositAddress =
      '/transactions/deposit-address';
  static const String legacyTransactionsEstimateFee =
      '/transactions/estimate-fee';
  static const String legacyTransactionsCreateUnsigned =
      '/transactions/create-unsigned';
  static const String legacyTransactionsBroadcast = '/transactions/broadcast';
  static const String legacyTransactionsStatus = '/transactions/status';
  static const String legacyTransactionsWithdraw = '/transactions/withdraw';
  static const String legacyTransactionsNetworkOnchainAddress =
      '/transactions/network/onchain/address';
  static const String legacyTransactionsNetworkWalletProfile =
      '/transactions/network/wallet-profile';
  static const String legacyTransactionsNetworkOnchainSend =
      '/transactions/network/onchain/send';
  static const String legacyTransactionsNetworkLightningInvoice =
      '/transactions/network/lightning/invoice';
  static const String legacyTransactionsNetworkLightningPay =
      '/transactions/network/lightning/pay';
  static const String legacyTransactionsNetworkTransfers =
      '/transactions/network/transfers';
  static const String depositRoot = '/deposit';
  static const String treasuryOverview = '/treasury/overview';
  static const String transactionsCreatePaymentLink =
      '/transactions/create-payment-link';
  static const String transactionsPaymentLink = '/transactions/payment-link';
  static const String transactionsPaymentLinksList =
      '/transactions/payment-links';
  static const String transactionsOnrampUrls = '/api/onramp/urls';
  static const String paymentsQuote = '/payments/quote';
  static String paymentsConfirm(String paymentIntentId) =>
      '/payments/$paymentIntentId/confirm';
  static String paymentsStatus(String paymentIntentId) =>
      '/payments/$paymentIntentId';
  static String paymentReceivingCapabilities(String receiverIdentifier) =>
      '/kfe/users/$receiverIdentifier/receiving-capabilities';

  // ==================== Bitcoin Accounts ====================
  static const String bitcoinAccounts = kfeDashboard;
  static const String bitcoinAccountsInternalCard = kfeWallets;
  static const String bitcoinAccountsColdWallet = kfeWallets;
  static const String legacyBitcoinAccounts = '/bitcoin/accounts';
  static const String legacyBitcoinAccountsInternalCard =
      '/bitcoin/accounts/internal-card';
  static const String legacyBitcoinAccountsColdWallet =
      '/bitcoin/accounts/cold-wallet';
  static const String bitcoinReceivePublic = kfeDashboard;
  static String bitcoinAccountReceiveRequests(String accountId) =>
      kfeWalletAddressRotate(accountId);
  static String bitcoinReceiveRequestStatus(String id) => kfeTransactions;
  static String bitcoinReceiveRequestExpire(String id) => kfeTransactions;
  static String bitcoinReceiveRequestHide(String id) => kfeTransactions;
  static String bitcoinReceiveRequestUserAction(String id) => kfeTransactions;
  static String bitcoinColdWalletPsbt(String coldWalletId) => kfeWallets;
  static String bitcoinColdWalletUtxos(String coldWalletId) => kfeWallets;
  static const String bitcoinTaxEvents = kfeDashboard;
  static String bitcoinTaxEventsExport(String format) => kfeDashboard;
  static String bitcoinTaxEventClassify(String eventId) => kfeDashboard;
  static String bitcoinPsbt(String workflowId) => kfeTransactions;
  static String bitcoinPsbtSigned(String workflowId) => kfeTransactions;
  static const String legacyBitcoinReceivePublic = '/bitcoin/receive';
  static String legacyBitcoinAccountReceiveRequests(String accountId) =>
      '/bitcoin/accounts/$accountId/receive-requests';
  static String legacyBitcoinReceiveRequestStatus(String id) =>
      '/bitcoin/receive-requests/$id/status';
  static String legacyBitcoinReceiveRequestExpire(String id) =>
      '/bitcoin/receive-requests/$id/expire';
  static String legacyBitcoinReceiveRequestHide(String id) =>
      '/bitcoin/receive-requests/$id/hide';
  static String legacyBitcoinReceiveRequestUserAction(String id) =>
      '/bitcoin/receive-requests/$id/user-action';
  static String legacyBitcoinColdWalletPsbt(String coldWalletId) =>
      '/bitcoin/cold-wallets/$coldWalletId/psbt';
  static String legacyBitcoinColdWalletUtxos(String coldWalletId) =>
      '/bitcoin/cold-wallets/$coldWalletId/utxos';
  static const String legacyBitcoinTaxEvents = '/bitcoin/tax-events';
  static String legacyBitcoinTaxEventsExport(String format) =>
      '/bitcoin/tax-events/export?format=$format';
  static String legacyBitcoinTaxEventClassify(String eventId) =>
      '/bitcoin/tax-events/$eventId/classify';
  static String legacyBitcoinPsbt(String workflowId) =>
      '/bitcoin/psbt/$workflowId';
  static String legacyBitcoinPsbtSigned(String workflowId) =>
      '/bitcoin/psbt/$workflowId/signed';

  // ==================== Notifications ====================
  static const String notificationsList = '/notifications';
  static const String notificationsRead = '/notifications/{id}/read';
  static const String notificationRegisterToken =
      '/notifications/register-token';

  // ==================== Security ====================
  static const String sovereigntyStatus = '/sovereignty/status';
  static const String sovereigntyPing = '/sovereignty/ping';
  static const String sovereigntyTelemetry = '/sovereignty/telemetry';
  static const String sovereigntyReattest = '/sovereignty/reattest';
  static const String auditStats = '/v1/audit/stats';
  static const String auditSiphon = '/v1/audit/siphon';
  static const String auditMerkleLatestRoot = '/audit/latest-root';
  static const String auditMerkleHistory = '/audit/history';
  static const String auditMerkleTrigger = '/audit/trigger';

  // ==================== Admin ====================
  static const String adminOperationsOverview =
      '/api/admin/operations/overview';
  static const String adminOperationsHealth = '/api/admin/operations/health';
  static const String adminOperationsBlockchain =
      '/transactions/visualization/blockchain';
  static const String adminOperationsBlockchainSync =
      '/transactions/visualization/blockchain/sync';
  static const String adminOperationsLightning =
      '/transactions/visualization/lightning';
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

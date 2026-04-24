import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

// ─── DTO returned from signup ─────────────────────────────────────────────────
class SignupInitResult {
  final String sessionId;
  final String totpSecret;
  final String qrCodeUri;
  final List<String> backupCodes;
  final bool totpOptional;

  const SignupInitResult({
    required this.sessionId,
    required this.totpSecret,
    required this.qrCodeUri,
    this.backupCodes = const [],
    this.totpOptional = true,
  });
}

class LoginResult {
  final String userId;
  final String jwt;
  final bool requiresTotp;

  const LoginResult({
    this.userId = '',
    this.jwt = '',
    this.requiresTotp = false,
  });

  /// Parses the backend response according to API v5.8:
  /// - Login returns 202: data = "pre_auth_token" (UUID string) → requiresTotp = true
  /// - Login returns 200: data = "userId jwt_token" (space-separated) → requiresTotp = false
  factory LoginResult.fromResponseData(dynamic data) {
    if (data == null) {
      return const LoginResult(requiresTotp: true);
    }

    String raw;
    if (data is Map) {
      raw = (data['data'] ??
              data['token'] ??
              data['jwt'] ??
              data['sessionId'] ??
              '')
          .toString()
          .trim();
      if (raw.isEmpty) {
        raw = data.toString().trim();
      }
    } else {
      raw = data.toString().trim();
    }

    final spaceIdx = raw.indexOf(' ');

    if (spaceIdx <= 0) {
      // No space: either a pre_auth_token (UUID-like) or a final JWT.
      if (raw.contains('.')) {
        return LoginResult(requiresTotp: false, jwt: raw);
      }

      if (raw.isNotEmpty && !raw.startsWith('{')) {
        return LoginResult(requiresTotp: true, jwt: raw);
      }

      if (data is Map && data.containsKey('token')) {
        return LoginResult(
          userId: (data['userId'] ?? '').toString(),
          jwt: (data['token'] ?? data['jwt'] ?? '').toString(),
          requiresTotp: false,
        );
      }

      throw AuthException(
        message: 'Login: formato de resposta inválido ou incompleto',
        statusCode: 200,
        errorCode: 'ERR_AUTH_PARSE',
      );
    }
    return LoginResult(
      userId: raw.substring(0, spaceIdx),
      jwt: raw.substring(spaceIdx + 1).trim(),
      requiresTotp: false,
    );
  }
}

// ─── Legacy DTO kept for compile compatibility with older onboarding widgets ─
class OnboardingPaymentLinkDto {
  final String linkId;
  final double amountBtc;
  final String depositAddress;
  final String type;
  final String status;

  const OnboardingPaymentLinkDto({
    required this.linkId,
    required this.amountBtc,
    required this.depositAddress,
    this.type = 'ONBOARDING_VOUCHER',
    this.status = 'pending',
  });

  factory OnboardingPaymentLinkDto.fromJson(Map<String, dynamic> json) {
    double btc = (json['amountBtc'] as num?)?.toDouble() ?? 0.0;
    if (btc == 0 && json.containsKey('amountSats')) {
      btc = ((json['amountSats'] as num?)?.toDouble() ?? 0.0) / 100000000.0;
    }
    if (btc == 0 && json.containsKey('satoshiAmount')) {
      btc = ((json['satoshiAmount'] as num?)?.toDouble() ?? 0.0) / 100000000.0;
    }

    return OnboardingPaymentLinkDto(
      linkId: (json['id'] ?? json['linkId'] ?? '').toString(),
      amountBtc: btc,
      depositAddress:
          (json['address'] ?? json['depositAddress'] ?? '').toString(),
      type: (json['type'] ?? 'ONBOARDING_VOUCHER').toString(),
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}

class ActivationStatusResult {
  final bool activated;
  final bool canReceiveInbound;
  final bool requiresActivationDeposit;
  final String paymentLinkId;
  final double amountBtc;
  final String depositAddress;
  final String paymentStatus;
  final String warningMessage;

  const ActivationStatusResult({
    this.activated = false,
    this.canReceiveInbound = false,
    this.requiresActivationDeposit = true,
    this.paymentLinkId = '',
    this.amountBtc = 0,
    this.depositAddress = '',
    this.paymentStatus = 'pending',
    this.warningMessage =
        'Para receber fundos dentro da plataforma, deposite algum valor primeiro.',
  });

  factory ActivationStatusResult.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
        : json;
    return ActivationStatusResult(
      activated: payload['activated'] == true,
      canReceiveInbound: payload['canReceiveInbound'] == true,
      requiresActivationDeposit: payload['requiresActivationDeposit'] != false,
      paymentLinkId: (payload['paymentLinkId'] ?? '').toString(),
      amountBtc: (payload['requiredAmountBtc'] as num?)?.toDouble() ?? 0,
      depositAddress: (payload['depositAddress'] ?? '').toString(),
      paymentStatus: (payload['paymentStatus'] ?? 'pending').toString(),
      warningMessage: (payload['warningMessage'] ?? '').toString(),
    );
  }
}

class AccountSecurityStatusResult {
  final bool passwordConfigured;
  final bool passkeyRegistered;
  final bool totpEnabled;
  final int backupCodesRemaining;
  final bool unprotected;
  final String warningMessage;
  final bool accountActivated;
  final bool inboundEnabled;

  const AccountSecurityStatusResult({
    this.passwordConfigured = false,
    this.passkeyRegistered = false,
    this.totpEnabled = false,
    this.backupCodesRemaining = 0,
    this.unprotected = true,
    this.warningMessage = '',
    this.accountActivated = false,
    this.inboundEnabled = false,
  });

  factory AccountSecurityStatusResult.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
        : json;
    return AccountSecurityStatusResult(
      passwordConfigured: payload['passwordConfigured'] == true,
      passkeyRegistered: payload['passkeyRegistered'] == true,
      totpEnabled: payload['totpEnabled'] == true,
      backupCodesRemaining:
          (payload['backupCodesRemaining'] as num?)?.toInt() ?? 0,
      unprotected: payload['unprotected'] != false,
      warningMessage: (payload['warningMessage'] ?? '').toString(),
      accountActivated: payload['accountActivated'] == true,
      inboundEnabled: payload['inboundEnabled'] == true,
    );
  }
}

class BackupCodesStatusResult {
  final bool enabled;
  final int remainingCodes;
  final List<String> newlyGeneratedCodes;

  const BackupCodesStatusResult({
    this.enabled = false,
    this.remainingCodes = 0,
    this.newlyGeneratedCodes = const [],
  });

  factory BackupCodesStatusResult.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
        : json;
    return BackupCodesStatusResult(
      enabled: payload['enabled'] == true,
      remainingCodes: (payload['remainingCodes'] as num?)?.toInt() ?? 0,
      newlyGeneratedCodes:
          ((payload['newlyGeneratedCodes'] ?? const <dynamic>[]) as List)
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class TotpSetupResult {
  final String otpUri;
  final String secret;

  const TotpSetupResult({
    this.otpUri = '',
    this.secret = '',
  });

  factory TotpSetupResult.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
        : json;
    return TotpSetupResult(
      otpUri: (payload['otpUri'] ?? '').toString(),
      secret: (payload['secret'] ?? '').toString(),
    );
  }
}

class EmergencyRecoveryStartResult {
  final String recoverySessionId;
  final String otpUri;
  final String passkeyChallenge;
  final int expiresInSeconds;
  final int requiredRecoveryCodes;

  const EmergencyRecoveryStartResult({
    required this.recoverySessionId,
    required this.otpUri,
    required this.passkeyChallenge,
    required this.expiresInSeconds,
    required this.requiredRecoveryCodes,
  });

  factory EmergencyRecoveryStartResult.fromJson(Map<String, dynamic> json) {
    return EmergencyRecoveryStartResult(
      recoverySessionId: (json['recoverySessionId'] ?? '').toString(),
      otpUri: (json['otpUri'] ?? '').toString(),
      passkeyChallenge: (json['passkeyChallenge'] ?? '').toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
      requiredRecoveryCodes:
          (json['requiredRecoveryCodes'] as num?)?.toInt() ?? 3,
    );
  }
}

class EmergencyRecoveryFinishResult {
  final String username;
  final List<String> newBackupCodes;

  const EmergencyRecoveryFinishResult({
    required this.username,
    required this.newBackupCodes,
  });

  factory EmergencyRecoveryFinishResult.fromJson(Map<String, dynamic> json) {
    return EmergencyRecoveryFinishResult(
      username: (json['username'] ?? '').toString(),
      newBackupCodes: ((json['newBackupCodes'] ?? const <dynamic>[]) as List)
          .map((item) => item.toString())
          .toList(),
    );
  }
}

// ─── Abstract interface ───────────────────────────────────────────────────────
abstract class AuthRemoteDataSource {
  /// Obter desafio PoW
  Future<String> getPowChallenge();

  /// Signup: resolve PoW internamente e chama /auth/signup
  Future<SignupInitResult> signup({
    required String username,
    required String passphrase,
    required String accountSecurity,
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  });

  /// Verifica TOTP de cadastro — retorna sessionId (Redis)
  Future<String> verifySignupTotp({
    required String sessionId,
    String? totpCode,
  });

  /// Login — returns LoginResult with userId and JWT
  Future<LoginResult> login({
    required String username,
    required String passphrase,
  });

  /// Verifica TOTP de login — retorna JWT
  Future<String> verifyLoginTotp({
    required String username,
    required String totpCode,
    required String preAuthToken,
  });

  /// Inicia registro de passkey durante onboarding — retorna challenge JSON
  Future<String> passkeyRegisterOnboardingStart({
    required String sessionId,
    String? username,
  });

  /// Finaliza registro de passkey durante onboarding
  Future<LoginResult> passkeyRegisterOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  );

  /// Inicia login via passkey — retorna challenge JSON
  Future<String> passkeyLoginStart(String username);

  /// Finaliza login via passkey — retorna LoginResult com JWT
  Future<LoginResult> passkeyLoginFinish(
      String username, Map<String, dynamic> credential);

  /// Inicia registro de passkey para usuário logado — retorna challenge JSON
  Future<String> passkeyRegisterStart(String username);

  /// Finaliza registro de passkey para usuário logado
  Future<void> passkeyRegisterFinish(Map<String, dynamic> credential);

  /// Inicia emergency recovery com PoW e múltiplos recovery codes.
  Future<EmergencyRecoveryStartResult> startEmergencyRecovery({
    required String username,
    required String newPassphrase,
    required List<String> recoveryCodes,
  });

  /// Finaliza emergency recovery com novo TOTP e nova passkey.
  Future<EmergencyRecoveryFinishResult> finishEmergencyRecovery({
    required String recoverySessionId,
    required String totpCode,
    required Map<String, dynamic> credential,
  });

  Future<ActivationStatusResult> getActivationStatus();

  Future<ActivationStatusResult> createActivationDepositLink();

  Future<ActivationStatusResult> confirmActivationPayment({
    required String linkId,
    required String txid,
  });

  Future<AccountSecurityStatusResult> getSecurityStatus();

  Future<TotpSetupResult> setupTotp();

  Future<BackupCodesStatusResult> verifyTotpSetup({
    required String totpCode,
  });

  Future<void> disableTotp();

  Future<BackupCodesStatusResult> getBackupCodesStatus();

  Future<BackupCodesStatusResult> regenerateBackupCodes();

  /// Confirma a transação enviada para o payment link de onboarding
  Future<OnboardingPaymentLinkDto> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  });

  /// Consulta o estado atual do payment link de onboarding
  Future<OnboardingPaymentLinkDto> getOnboardingPaymentLink(String linkId);

  /// Mock de confirmação de onboarding (atalho para devs)
  Future<void> mockConfirmOnboarding(String sessionId);

  /// Confirmação de voucher (com suporte a mock_tx_)


  /// Refresh token (usando cookie)
  Future<String> refreshToken();

  /// Logout
  Future<void> logout();

  /// Obter usuário atual via GET /auth/me
  Future<UserModel> getCurrentUser();
}

// ─── Top-level PoW Task for Isolate (compute) ──────────────────────────────────
String _solvePoWTask(String challenge) {
  int nonce = 0;
  const prefix = '0000';
  while (true) {
    final input = '$challenge$nonce';
    final digest = crypto.sha256.convert(utf8.encode(input));
    final hash = digest.toString();
    if (hash.startsWith(prefix)) {
      return nonce.toString();
    }
    nonce++;
    if (nonce > 10000000) break; // safety escape
  }
  return nonce.toString();
}

// ─── Implementation ───────────────────────────────────────────────────────────
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  // ─── PoW helper ─────────────────────────────────────────────────────────────

  @override
  Future<String> getPowChallenge() async {
    try {
      final response = await apiClient.get(AppConfig.authPowChallenge);
      final body = response.data;
      if (body is Map) {
        final challenge = body['challenge']?.toString();
        if (challenge != null && challenge.isNotEmpty) {
          debugPrint(
            '🔐 PoW Challenge received: ${challenge.substring(0, 16)}...',
          );
          return challenge;
        }
      }
      throw ServerException(
        message: 'PoW challenge missing from response: $body',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter desafio PoW: $e');
    }
  }

  // ─── Signup ──────────────────────────────────────────────────────────────────

  @override
  Future<SignupInitResult> signup({
    required String username,
    required String passphrase,
    required String accountSecurity,
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    try {
      // 1. Get PoW challenge
      final challenge = await getPowChallenge();

      // 2. Solve — brute force nonce (offloads heavy lifting to an Isolate)
      final nonce = await compute(_solvePoWTask, challenge);

      // 3. Call /auth/signup.
      // Keep `passphrase` on the wire for compatibility with older auth clients/contracts.
      final response = await apiClient.post(
        AppConfig.authSignup,
        data: {
          'username': username,
          'passphrase': passphrase,
          'accountSecurity': accountSecurity,
          if (shamirTotalShares != null) 'shamirTotalShares': shamirTotalShares,
          if (shamirThreshold != null) 'shamirThreshold': shamirThreshold,
          if (multisigThreshold != null) 'multisigThreshold': multisigThreshold,
          'challenge': challenge,
          'nonce': nonce,
        },
      );

      // ApiResponseInterceptor already unwraps the ApiResponse envelope.
      // API v5.8 returns: { otpUri: "otpauth://...", backupCodes: ["12345678", ...] }
      final body = response.data;
      debugPrint('🌐 [SIGNUP] Body received: $body');

      dynamic parsedBody = body;
      if (body is String) {
        final trimmedBody = body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            parsedBody = jsonDecode(trimmedBody);
          } catch (_) {
            parsedBody = trimmedBody;
          }
        } else {
          parsedBody = trimmedBody;
        }
      }

      String qrCodeUri = '';
      String totpSecret = '';
      List<String> backupCodes = [];
      String sessionId = '';
      bool totpOptional = true;

      if (parsedBody is String) {
        if (parsedBody.startsWith('otpauth://')) {
          qrCodeUri = parsedBody;
          final uri = Uri.tryParse(parsedBody);
          totpSecret = uri?.queryParameters['secret'] ?? '';
        } else {
          totpSecret = parsedBody;
          qrCodeUri =
              'otpauth://totp/Kerosene:$username?secret=$totpSecret&issuer=Kerosene';
        }
      } else if (parsedBody is Map) {
        Map dataMap = parsedBody;
        if (dataMap.containsKey('data') && dataMap['data'] is Map) {
          dataMap = dataMap['data'];
        }

        // API v5.8: field is `otpUri`
        qrCodeUri = (dataMap['otpUri'] ??
                dataMap['otp_uri'] ??
                dataMap['qrCodeUri'] ??
                dataMap['qr_code_uri'] ??
                dataMap['uri'] ??
                '')
            .toString();

        totpSecret = (dataMap['setupKey'] ??
                dataMap['setup_key'] ??
                dataMap['totpSecret'] ??
                dataMap['totp_secret'] ??
                dataMap['secret'] ??
                dataMap['secret_key'] ??
                '')
            .toString();

        if (totpSecret.isEmpty && qrCodeUri.startsWith('otpauth://')) {
          final uri = Uri.tryParse(qrCodeUri);
          totpSecret = uri?.queryParameters['secret'] ?? '';
        }

        // API v5.8: backupCodes is a List<String> of 10 single-use codes
        if (dataMap['backupCodes'] is List) {
          backupCodes = (dataMap['backupCodes'] as List)
              .map((e) => e.toString())
              .toList();
        } else if (dataMap['backup_codes'] is List) {
          backupCodes = (dataMap['backup_codes'] as List)
              .map((e) => e.toString())
              .toList();
        }

        sessionId = (dataMap['sessionId'] ?? '').toString();
        totpOptional = dataMap['totpOptional'] != false;

        debugPrint(
            '🔐 TOTP Data extracted. Secret length: ${totpSecret.length}, BackupCodes: ${backupCodes.length}');
      }

      if (totpSecret.isEmpty || totpSecret.startsWith('{')) {
        throw ServerException(
            message: 'Invalid TOTP secret received from server.');
      }

      return SignupInitResult(
        sessionId: sessionId,
        totpSecret: totpSecret,
        qrCodeUri: qrCodeUri,
        backupCodes: backupCodes,
        totpOptional: totpOptional,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar cadastro: $e');
    }
  }

  // ─── Signup TOTP verify — returns sessionId ──────────────────────────────────

  @override
  Future<String> verifySignupTotp({
    required String sessionId,
    String? totpCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authSignupVerify,
        data: {
          'sessionId': sessionId,
          if (totpCode != null && totpCode.isNotEmpty) 'totpCode': totpCode,
        },
      );
      final body = response.data;
      final verifiedSessionId =
          body is String ? body.trim() : body?.toString().trim();
      if (verifiedSessionId == null || verifiedSessionId.isEmpty) {
        throw ServerException(
          message: 'Signup TOTP verify: sessionId não retornado',
        );
      }
      return verifiedSessionId;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar TOTP de cadastro: $e');
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  @override
  Future<LoginResult> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLogin,
        data: {'username': username, 'password': passphrase},
      );
      return LoginResult.fromResponseData(response.data);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao fazer login: $e');
    }
  }

  // ─── Login TOTP verify ──────────────────────────────────────────────────────

  @override
  Future<String> verifyLoginTotp({
    required String username,
    required String totpCode,
    required String preAuthToken,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLoginVerify,
        data: {
          'username': username,
          'totpCode': totpCode,
          'preAuthToken': preAuthToken,
        },
      );
      final result = LoginResult.fromResponseData(response.data);
      return result.jwt;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar 2FA de login: $e');
    }
  }

  // ─── Passkey Onboarding ───────────────────────────────────────────────────────

  @override
  Future<String> passkeyRegisterOnboardingStart({
    required String sessionId,
    String? username,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authPasskeyOnboardingStart,
        queryParameters: {'sessionId': sessionId},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de passkey: $e');
    }
  }

  @override
  Future<LoginResult> passkeyRegisterOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  ) async {
    try {
      final response = await apiClient.post(
        AppConfig.authPasskeyOnboardingFinish,
        queryParameters: {'sessionId': sessionId},
        data: credential,
      );
      return LoginResult.fromResponseData(response.data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Erro ao finalizar registro de passkey: $e');
    }
  }

  // ─── Real Passkey Login/Register ──────────────────────────────────────────────

  @override
  Future<String> passkeyLoginStart(String username) async {
    try {
      final response = await apiClient.get(
        AppConfig.authPasskeyChallenge,
        queryParameters: {'username': username},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar login via passkey: $e');
    }
  }

  @override
  Future<LoginResult> passkeyLoginFinish(
    String username,
    Map<String, dynamic> credential,
  ) async {
    try {
      final response = await apiClient.post(
        AppConfig.authPasskeyVerify,
        data: {
          'username': username,
          'signature': credential['signature'],
          'authData': credential['authData'],
          'clientDataJSON': credential['clientDataJSON'],
          'credentialId': credential['credentialId'] ??
              credential['credential_id'] ??
              credential['id'],
        },
      );
      return LoginResult.fromResponseData(response.data);

    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao finalizar login via passkey: $e');
    }
  }

  @override
  Future<String> passkeyRegisterStart(String username) async {
    try {
      final response = await apiClient.get(
        AppConfig.authPasskeyChallenge,
        queryParameters: {'username': username},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de passkey: $e');
    }
  }

  @override
  Future<void> passkeyRegisterFinish(Map<String, dynamic> credential) async {
    try {
      // API v5.8 expects: publicKey, publicKeyCose, credentialId, deviceName, signature
      await apiClient.post(
        AppConfig.authPasskeyRegister,
        data: credential,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Erro ao finalizar registro de passkey: $e');
    }
  }

  // ─── Emergency Recovery ───────────────────────────────────────────────────────

  @override
  Future<EmergencyRecoveryStartResult> startEmergencyRecovery({
    required String username,
    required String newPassphrase,
    required List<String> recoveryCodes,
  }) async {
    try {
      final challenge = await getPowChallenge();
      final nonce = await compute(_solvePoWTask, challenge);

      final response = await apiClient.post(
        AppConfig.authRecoveryEmergencyStart,
        data: {
          'username': username,
          'newPassphrase': newPassphrase,
          'recoveryCodes': recoveryCodes,
          'challenge': challenge,
          'nonce': nonce,
        },
      );

      final body = response.data;
      if (body is Map<String, dynamic>) {
        return EmergencyRecoveryStartResult.fromJson(body);
      }
      if (body is String) {
        final trimmed = body.trim();
        if (trimmed.startsWith('{')) {
          final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
          return EmergencyRecoveryStartResult.fromJson(parsed);
        }
      }

      throw const ServerException(
        message: 'Resposta inválida ao iniciar a recuperação emergencial.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao iniciar recuperação emergencial: $e',
      );
    }
  }

  @override
  Future<EmergencyRecoveryFinishResult> finishEmergencyRecovery({
    required String recoverySessionId,
    required String totpCode,
    required Map<String, dynamic> credential,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authRecoveryEmergencyFinish,
        data: {
          'recoverySessionId': recoverySessionId,
          'totpCode': totpCode,
          'publicKey': credential['publicKey'] ?? credential['public_key'],
          'publicKeyCose':
              credential['publicKeyCose'] ?? credential['public_key_cose'],
          'deviceName': credential['deviceName'] ?? credential['device_name'],
          'signature': credential['signature'],
          'authData': credential['authData'],
          'clientDataJSON': credential['clientDataJSON'],
          'credentialId': credential['credentialId'] ??
              credential['credential_id'] ??
              credential['id'],
          'userHandle': credential['userHandle'] ?? credential['user_handle'],
        },
      );

      final body = response.data;
      if (body is Map<String, dynamic>) {
        return EmergencyRecoveryFinishResult.fromJson(body);
      }
      if (body is String) {
        final trimmed = body.trim();
        if (trimmed.startsWith('{')) {
          final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
          return EmergencyRecoveryFinishResult.fromJson(parsed);
        }
      }

      throw const ServerException(
        message: 'Resposta inválida ao finalizar a recuperação emergencial.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao finalizar recuperação emergencial: $e',
      );
    }
  }

  // ─── Account activation deposit flow ─────────────────────────────────────────

  @override
  Future<ActivationStatusResult> getActivationStatus() async {
    try {
      final response = await apiClient.get(AppConfig.authActivationStatus);
      final body = response.data;
      if (body is Map) {
        return ActivationStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao consultar status de ativação.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar ativação: $e');
    }
  }

  @override
  Future<ActivationStatusResult> createActivationDepositLink() async {
    try {
      final response = await apiClient.post(AppConfig.authActivationDepositLink);
      final body = response.data;
      if (body is Map) {
        return ActivationStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao gerar link de ativação.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao gerar link de ativação: $e');
    }
  }

  @override
  Future<ActivationStatusResult> confirmActivationPayment({
    required String linkId,
    required String txid,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.authActivationStatus}/$linkId/confirm',
        data: {'txid': txid},
      );
      final body = response.data;
      if (body is Map) {
        return ActivationStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao confirmar depósito de ativação.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Erro ao confirmar depósito de ativação: $e');
    }
  }

  @override
  Future<AccountSecurityStatusResult> getSecurityStatus() async {
    try {
      final response = await apiClient.get(AppConfig.authSecurityStatus);
      final body = response.data;
      if (body is Map) {
        return AccountSecurityStatusResult.fromJson(
          Map<String, dynamic>.from(body),
        );
      }
      throw const ServerException(
        message: 'Resposta inválida ao consultar segurança da conta.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar segurança da conta: $e');
    }
  }

  @override
  Future<TotpSetupResult> setupTotp() async {
    try {
      final response = await apiClient.post(AppConfig.authTotpSetup);
      final body = response.data;
      if (body is Map) {
        return TotpSetupResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao iniciar configuração de TOTP.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar configuração de TOTP: $e');
    }
  }

  @override
  Future<BackupCodesStatusResult> verifyTotpSetup({
    required String totpCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authTotpVerify,
        data: {'totpCode': totpCode},
      );
      final body = response.data;
      if (body is Map) {
        return BackupCodesStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao confirmar configuração de TOTP.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao confirmar configuração de TOTP: $e');
    }
  }

  @override
  Future<void> disableTotp() async {
    try {
      await apiClient.delete(AppConfig.authTotpDisable);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao desativar TOTP: $e');
    }
  }

  @override
  Future<BackupCodesStatusResult> getBackupCodesStatus() async {
    try {
      final response = await apiClient.get(AppConfig.authBackupCodes);
      final body = response.data;
      if (body is Map) {
        return BackupCodesStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao consultar backup codes.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar backup codes: $e');
    }
  }

  @override
  Future<BackupCodesStatusResult> regenerateBackupCodes() async {
    try {
      final response = await apiClient.post(AppConfig.authBackupCodesRegenerate);
      final body = response.data;
      if (body is Map) {
        return BackupCodesStatusResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao regenerar backup codes.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao regenerar backup codes: $e');
    }
  }

  @override
  Future<OnboardingPaymentLinkDto> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.transactionsPaymentLink}/$linkId/confirm',
        data: {
          'txid': txid,
        },
      );
      final body = response.data;
      if (body is Map) {
        return OnboardingPaymentLinkDto.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao confirmar pagamento de onboarding.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao confirmar pagamento de onboarding: $e');
    }
  }

  @override
  Future<OnboardingPaymentLinkDto> getOnboardingPaymentLink(String linkId) async {
    try {
      final response = await apiClient.get('${AppConfig.transactionsPaymentLink}/$linkId');
      final body = response.data;
      if (body is Map) {
        return OnboardingPaymentLinkDto.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Resposta inválida ao consultar status do onboarding.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar status do onboarding: $e');
    }
  }

  @override
  Future<void> mockConfirmOnboarding(String sessionId) async {
    debugPrint(
      '⚠️ mockConfirmOnboarding sem endpoint backend. Ignorando atalho local para sessionId=$sessionId',
    );
  }

  // ─── Refresh / Logout / CurrentUser ──────────────────────────────────────────

  @override
  Future<String> refreshToken() async {
    return '';
  }

  @override
  Future<void> logout() async {
    // Logout é realizado localmente limpando o token armazenado.
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get(AppConfig.authMe);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        return UserModel.fromJson(body);
      }

      // Fallback para quando o response é string JSON
      if (body is String) {
        final trimmed = body.trim();
        if (trimmed.startsWith('{')) {
          final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
          return UserModel.fromJson(parsed);
        }
      }

      throw ServerException(
          message: 'Formato de resposta inválido em /auth/me');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter usuário: $e');
    }
  }
}

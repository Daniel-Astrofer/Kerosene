import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../models/user_model.dart';
import 'package:kerosene/features/auth/domain/entities/login_result.dart';

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

class AdminLoginResult {
  final String status;
  final bool requiresMobileApproval;
  final String attemptId;
  final String token;
  final String message;

  const AdminLoginResult({
    this.status = '',
    this.requiresMobileApproval = false,
    this.attemptId = '',
    this.token = '',
    this.message = '',
  });

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) {
    return AdminLoginResult(
      status: (json['status'] ?? '').toString(),
      requiresMobileApproval: json['requiresMobileApproval'] == true,
      attemptId: (json['attemptId'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
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
    this.type = 'ONBOARDING_PAYMENT_LINK',
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
      type: (json['type'] ?? 'ONBOARDING_PAYMENT_LINK').toString(),
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

  Future<AdminLoginResult> startAdminLogin({
    required String username,
    required String password,
    required String adminKeyProof,
    required DeviceMetadata deviceMetadata,
  });

  Future<AdminLoginResult> pollAdminLogin(String attemptId);

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
        message: 'Não conseguimos preparar a proteção da conta agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos preparar a proteção da conta agora.',
      );
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
      debugPrint('🌐 [SIGNUP] Response received from auth service.');

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
          '🔐 TOTP setup metadata extracted. BackupCodes: ${backupCodes.length}',
        );
      }

      if (totpSecret.isEmpty || totpSecret.startsWith('{')) {
        throw ServerException(
          message:
              'Não conseguimos preparar o autenticador agora. Tente novamente.',
        );
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
      throw ServerException(
          message: 'Não conseguimos iniciar seu cadastro agora.');
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
          message: 'Não conseguimos confirmar o código agora.',
        );
      }
      return verifiedSessionId;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos confirmar o código agora.');
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
      throw ServerException(message: 'Não conseguimos entrar na sua conta.');
    }
  }

  @override
  Future<AdminLoginResult> startAdminLogin({
    required String username,
    required String password,
    required String adminKeyProof,
    required DeviceMetadata deviceMetadata,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authAdminLogin,
        data: {
          'username': username,
          'password': password,
          'adminKeyProof': adminKeyProof,
          ...deviceMetadata.toJson(),
        },
      );
      return AdminLoginResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Não conseguimos iniciar o acesso admin.');
    }
  }

  @override
  Future<AdminLoginResult> pollAdminLogin(String attemptId) async {
    try {
      final response =
          await apiClient.get(AppConfig.authAdminLoginPoll(attemptId));
      return AdminLoginResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos confirmar o acesso admin.');
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
      throw ServerException(
          message: 'Não conseguimos confirmar o código agora.');
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
      throw ServerException(
          message: 'Não conseguimos iniciar a confirmação por passkey.');
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
          message: 'Não conseguimos concluir a confirmação por passkey.');
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
      throw ServerException(
          message: 'Não conseguimos iniciar a entrada por passkey.');
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
      throw ServerException(
          message: 'Não conseguimos concluir a entrada por passkey.');
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
      throw ServerException(
          message: 'Não conseguimos iniciar a confirmação por passkey.');
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
          message: 'Não conseguimos concluir a confirmação por passkey.');
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
        message: 'Não conseguimos atualizar a ativação agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos atualizar a ativação agora.');
    }
  }

  @override
  Future<ActivationStatusResult> createActivationDepositLink() async {
    return getActivationStatus();
  }

  @override
  Future<ActivationStatusResult> confirmActivationPayment({
    required String linkId,
    required String txid,
  }) async {
    throw const ValidationException(
      message:
          'A confirmação manual por TXID foi descontinuada. Faça o depósito pelo fluxo de recebimento do app e aguarde o monitoramento automático.',
      errorCode: 'ERR_ACTIVATION_MANUAL_CONFIRM_DISABLED',
    );
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
        message: 'Não conseguimos atualizar a segurança da conta agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos atualizar a segurança da conta agora.');
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
        message: 'Não conseguimos configurar o autenticador agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos configurar o autenticador agora.');
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
        return BackupCodesStatusResult.fromJson(
            Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Não conseguimos confirmar o autenticador agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos confirmar o autenticador agora.');
    }
  }

  @override
  Future<void> disableTotp() async {
    try {
      await apiClient.delete(AppConfig.authTotpDisable);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos desativar o autenticador agora.');
    }
  }

  @override
  Future<BackupCodesStatusResult> getBackupCodesStatus() async {
    try {
      final response = await apiClient.get(AppConfig.authBackupCodes);
      final body = response.data;
      if (body is Map) {
        return BackupCodesStatusResult.fromJson(
            Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Não conseguimos consultar os códigos de recuperação agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message:
              'Não conseguimos consultar os códigos de recuperação agora.');
    }
  }

  @override
  Future<BackupCodesStatusResult> regenerateBackupCodes() async {
    try {
      final response =
          await apiClient.post(AppConfig.authBackupCodesRegenerate);
      final body = response.data;
      if (body is Map) {
        return BackupCodesStatusResult.fromJson(
            Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Não conseguimos gerar novos códigos de recuperação agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos gerar novos códigos de recuperação agora.');
    }
  }

  @override
  Future<OnboardingPaymentLinkDto> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  }) async {
    throw const ValidationException(
      message:
          'Pagamentos de onboarding não aceitam confirmação manual por TXID. O backend credita automaticamente quando a rede confirma o depósito.',
      errorCode: 'ERR_ONBOARDING_MANUAL_CONFIRM_DISABLED',
    );
  }

  @override
  Future<OnboardingPaymentLinkDto> getOnboardingPaymentLink(
      String linkId) async {
    try {
      final response = await apiClient.get(
        AppConfig.kfePublicPaymentRequest(linkId),
      );
      final body = response.data;
      if (body is Map) {
        return OnboardingPaymentLinkDto.fromJson(
            Map<String, dynamic>.from(body));
      }
      throw const ServerException(
        message: 'Não conseguimos atualizar esta etapa agora.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos atualizar esta etapa agora.');
    }
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
          message: 'Não conseguimos carregar os dados da sua conta agora.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Não conseguimos carregar os dados da sua conta agora.');
    }
  }
}

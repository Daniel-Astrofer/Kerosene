import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

// ─── DTO returned from signup ─────────────────────────────────────────────────
class SignupInitResult {
  final String totpSecret;
  final String qrCodeUri;

  const SignupInitResult({required this.totpSecret, required this.qrCodeUri});
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

  /// Parses the backend response format: "userId jwt_token" (space-separated)
  /// or a simple UUID (session ID) when 2FA is required.
  factory LoginResult.fromResponseData(dynamic data) {
    if (data == null) {
      return const LoginResult(requiresTotp: true);
    }
    
    String raw;
    if (data is Map) {
      // Se for um mapa, tenta extrair dos campos comuns ou do campo 'data' interno
      raw = (data['data'] ?? data['token'] ?? data['jwt'] ?? data['sessionId'] ?? '').toString().trim();
      if (raw.isEmpty) {
        // Fallback: se o mapa não tem os campos, talvez o mapa todo seja o dado (convertido pra string)
        raw = data.toString().trim();
      }
    } else {
      raw = data.toString().trim();
    }
    
    final spaceIdx = raw.indexOf(' ');
    
    if (spaceIdx <= 0) {
      // Se não há espaço, é provável que seja um UUID (sessionId) ou JWT direto
      if (raw.isNotEmpty && !raw.startsWith('{')) {
        // Se parece um token ou ID (não começa com { que indicaria JSON falho)
        return LoginResult(requiresTotp: true, jwt: raw);
      }
      
      // Se o raw é vazio ou parece JSON não processado (e o origin era Map), tenta processar o Map como sucesso direto
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

// ─── DTO returned from voucher/onboarding-link ───────────────────────────────
class OnboardingPaymentLinkDto {
  final String id;
  final double amountBtc;
  final String depositAddress;
  final String status;
  final String expiresAt;

  const OnboardingPaymentLinkDto({
    required this.id,
    required this.amountBtc,
    required this.depositAddress,
    required this.status,
    required this.expiresAt,
  });

  factory OnboardingPaymentLinkDto.fromJson(Map<String, dynamic> json) {
    // Some endpoints might return amountBtc, others satoshiAmount
    double btc = (json['amountBtc'] as num?)?.toDouble() ?? 0.0;
    if (btc == 0 && json.containsKey('satoshiAmount')) {
      btc = ((json['satoshiAmount'] as num?)?.toDouble() ?? 0.0) / 100000000.0;
    }

    return OnboardingPaymentLinkDto(
      id: json['id']?.toString() ?? '',
      amountBtc: btc,
      depositAddress: (json['depositAddress'] ?? json['address'] ?? '').toString(),
      status: json['status']?.toString() ?? 'pending',
      expiresAt: json['expiresAt']?.toString() ?? '',
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
  });

  /// Verifica TOTP de cadastro — retorna sessionId (Redis)
  Future<String> verifySignupTotp({
    required String username,
    required String totpCode,
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

  /// Registra passkey de onboarding (start)
  Future<String> registerPasskeyOnboardingStart(String sessionId);

  /// Registra passkey de onboarding (finish)
  Future<void> registerPasskeyOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  );

  /// Inicia login via passkey — retorna PublicKeyCredentialRequestOptions JSON
  Future<String> passkeyLoginStart(String username);

  /// Finaliza login via passkey — retorna LoginResult com JWT
  Future<LoginResult> passkeyLoginFinish(String username, Map<String, dynamic> credential);

  /// Inicia registro de passkey para usuário logado — retorna PublicKeyCredentialCreationOptions JSON
  Future<String> passkeyRegisterStart();

  /// Finaliza registro de passkey para usuário logado
  Future<void> passkeyRegisterFinish(Map<String, dynamic> credential);

  // Sovereign Auth (Hardware Ed25519)
  
  /// Inicia registro de hardware auth (onboarding)
  Future<String> hardwareRegisterStart(String sessionId);

  /// Finaliza registro de hardware auth (onboarding)
  Future<void> hardwareRegisterFinish({
    required String sessionId,
    required String publicKey,
    required String deviceName,
    required String signature,
  });

  /// Inicia registro de hardware auth (logado)
  Future<String> hardwareRegisterForAccountStart();

  /// Finaliza registro de hardware auth (logado)
  Future<void> hardwareRegisterForAccountFinish({
    required String publicKey,
    required String deviceName,
  });

  /// Busca desafio para login hardware
  Future<String> getHardwareChallenge(String username);

  /// Verifica assinatura hardware para login
  Future<LoginResult> verifyHardwareSignature({
    required String username,
    required String signature,
  });

  /// Gera link de pagamento de onboarding
  Future<OnboardingPaymentLinkDto> generateOnboardingLink(String sessionId);

  /// Mock de confirmação de onboarding (atalho para devs)
  Future<void> mockConfirmOnboarding(String sessionId);

  /// Confirmação de voucher (com suporte a mock_tx_)
  Future<void> confirmVoucher({
    required String voucherId,
    required String txid,
  });

  /// Refresh token (usando cookie)
  Future<String> refreshToken();

  /// Logout
  Future<void> logout();

  /// Obter usuário atual
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
      // ApiResponseInterceptor already unwraps the outer ApiResponse envelope,
      // so response.data is already the inner payload: {"challenge": "..."}
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

  // _solvePoW is now moved to the top-level _solvePoWTask.

  // ─── Signup ──────────────────────────────────────────────────────────────────

  @override
  Future<SignupInitResult> signup({
    required String username,
    required String passphrase,
    required String accountSecurity,
  }) async {
    try {
      // 1. Get PoW challenge
      final challenge = await getPowChallenge();

      // 2. Solve — brute force nonce (offloads heavy lifting to an Isolate)
      final nonce = await compute(_solvePoWTask, challenge);

      // 3. Call /auth/signup
      final response = await apiClient.post(
        AppConfig.authSignup,
        data: {
          'username': username,
          'passphrase': passphrase,
          'challenge': challenge,
          'nonce': nonce,
          'accountSecurity': accountSecurity,
        },
      );

      // ApiResponseInterceptor already unwraps the ApiResponse envelope.
      // The backend returns a plain otpauth:// URI string as `data`.
      final body = response.data;
      debugPrint('🌐 [SIGNUP] Body received: $body');

      String qrCodeUri = '';
      String totpSecret = '';

      if (body is String) {
        final trimmedBody = body.trim();
        if (trimmedBody.startsWith('otpauth://')) {
          qrCodeUri = trimmedBody;
          final uri = Uri.tryParse(trimmedBody);
          totpSecret = uri?.queryParameters['secret'] ?? '';
          debugPrint('🔐 TOTP URI received: $qrCodeUri');
        } else {
          totpSecret = trimmedBody;
          qrCodeUri = 'otpauth://totp/Kerosene:$username?secret=$totpSecret&issuer=Kerosene';
          debugPrint('🔐 TOTP Secret received as String: $totpSecret');
        }
      } else if (body is Map) {
        // Support all known variations of the secret key
        var dataMap = body;
        if (body.containsKey('data') && body['data'] is Map) {
          dataMap = body['data'];
        }
        
        totpSecret = (dataMap['setupKey'] ?? 
                      dataMap['setup_key'] ?? 
                      dataMap['totpSecret'] ?? 
                      dataMap['totp_secret'] ?? 
                      dataMap['secret'] ?? 
                      dataMap['secret_key'] ?? '').toString();
        
        qrCodeUri = (dataMap['qrCodeUri'] ?? dataMap['qr_code_uri'] ?? dataMap['uri'] ?? '').toString();
        
        if (qrCodeUri.isEmpty && totpSecret.isNotEmpty) {
           final encodedUser = Uri.encodeComponent(username);
           qrCodeUri = 'otpauth://totp/Kerosene:$encodedUser?secret=$totpSecret&issuer=Kerosene';
        }
        debugPrint('🔐 TOTP Data extracted from Map. Secret length: ${totpSecret.length}');
      }

      if (totpSecret.isEmpty || totpSecret.startsWith('{')) {
        debugPrint('⚠️ [SIGNUP] TOTP secret looks like JSON or is empty. Falling back to MDV4YK4EJXQHWAG5.');
        totpSecret = 'MDV4YK4EJXQHWAG5'; // User requested override
        final encodedUser = Uri.encodeComponent(username);
        qrCodeUri = 'otpauth://totp/Kerosene:$encodedUser?secret=$totpSecret&issuer=Kerosene';
      }

      return SignupInitResult(totpSecret: totpSecret, qrCodeUri: qrCodeUri);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar cadastro: $e');
    }
  }

  // ─── Signup TOTP verify — returns sessionId ──────────────────────────────────

  @override
  Future<String> verifySignupTotp({
    required String username,
    required String totpCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authSignupVerify,
        data: {'username': username, 'totpCode': totpCode},
      );
      // ApiResponseInterceptor unwraps the envelope — body is the raw sessionId string.
      final body = response.data;
      final sessionId = body is String ? body.trim() : body?.toString().trim();
      if (sessionId == null || sessionId.isEmpty) {
        throw ServerException(
          message: 'Signup TOTP verify: sessionId não retornado',
        );
      }
      return sessionId;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar TOTP de cadastro: $e');
    }
  }

  // ─── Login — returns "userId jwt_token" ───────────────────────────────────────

  @override
  Future<LoginResult> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLogin,
        data: {'username': username, 'passphrase': passphrase},
      );
      // ApiResponseInterceptor unwraps the envelope.
      // Backend returns data: "<userId> <jwt_token>" space-separated
      return LoginResult.fromResponseData(response.data);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao fazer login: $e');
    }
  }

  // ─── Login TOTP verify — returns "userId jwt_token" ──────────────────────────

  @override
  Future<String> verifyLoginTotp({
    required String username,
    required String totpCode,
    required String preAuthToken,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLoginVerify,
        data: {'username': username, 'totpCode': totpCode},
        options: Options(
          headers: {
            // TokenInterceptor explicitly ignores /auth routes,
            // so we inject the preAuthToken manually here.
            'Authorization': 'Bearer $preAuthToken',
          },
        ),
      );
      // ApiResponseInterceptor unwraps the envelope.
      // Backend returns data: "<userId> <jwt_token>" space-separated
      final result = LoginResult.fromResponseData(response.data);
      return result.jwt;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar 2FA de login: $e');
    }
  }

  // ─── Passkey onboarding ───────────────────────────────────────────────────────

  @override
  Future<String> registerPasskeyOnboardingStart(String sessionId) async {
    try {
      final response = await apiClient.post(
        AppConfig.authPasskeyOnboardingStart,
        queryParameters: {'sessionId': sessionId},
      );
      // ApiResponseInterceptor unwraps the payload.
      // Backend returns a JSON string (PublicKeyCredentialCreationOptions).
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de passkey: $e');
    }
  }

  @override
  Future<void> registerPasskeyOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  ) async {
    try {
      await apiClient.post(
        AppConfig.authPasskeyOnboardingFinish,
        queryParameters: {'sessionId': sessionId},
        data: credential,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao finalizar registro de passkey: $e',
      );
    }
  }

  // ─── Real Passkey Login/Register ──────────────────────────────────────────────

  @override
  Future<String> passkeyLoginStart(String username) async {
    try {
      final response = await apiClient.post(
        AppConfig.authPasskeyLoginStart,
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
        AppConfig.authPasskeyLoginFinish,
        queryParameters: {'username': username},
        data: credential,
      );
      return LoginResult.fromResponseData(response.data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao finalizar login via passkey: $e');
    }
  }

  @override
  Future<String> passkeyRegisterStart() async {
    try {
      final response = await apiClient.post(AppConfig.authPasskeyRegisterStart);
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de passkey: $e');
    }
  }

  @override
  Future<void> passkeyRegisterFinish(Map<String, dynamic> credential) async {
    try {
      await apiClient.post(
        AppConfig.authPasskeyRegisterFinish,
        data: credential,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao finalizar registro de passkey: $e');
    }
  }

  // ─── Sovereign Auth (Hardware Ed25519) ──────────────────────────────────────────

  @override
  Future<String> hardwareRegisterStart(String sessionId) async {
    try {
      final response = await apiClient.post(
        AppConfig.authHardwareOnboardingStart,
        queryParameters: {'sessionId': sessionId},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de hardware auth: $e');
    }
  }

  @override
  Future<void> hardwareRegisterFinish({
    required String sessionId,
    required String publicKey,
    required String deviceName,
    required String signature,
  }) async {
    try {
      await apiClient.post(
        AppConfig.authHardwareOnboardingFinish,
        queryParameters: {'sessionId': sessionId},
        data: {
          'publicKey': publicKey,
          'deviceName': deviceName,
          'signature': signature,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao finalizar registro de hardware auth: $e');
    }
  }

  @override
  Future<String> hardwareRegisterForAccountStart() async {
    try {
      final response = await apiClient.post(AppConfig.authHardwareRegisterStart);
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de hardware: $e');
    }
  }

  @override
  Future<void> hardwareRegisterForAccountFinish({
    required String publicKey,
    required String deviceName,
  }) async {
    try {
      await apiClient.post(
        AppConfig.authHardwareRegisterFinish,
        data: {
          'publicKey': publicKey,
          'deviceName': deviceName,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao finalizar registro de hardware: $e');
    }
  }

  @override
  Future<String> getHardwareChallenge(String username) async {
    try {
      final response = await apiClient.get(
        AppConfig.authHardwareChallenge,
        queryParameters: {'username': username},
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter desafio de hardware: $e');
    }
  }

  @override
  Future<LoginResult> verifyHardwareSignature({
    required String username,
    required String signature,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authHardwareVerify,
        data: {
          'username': username,
          'signature': signature,
        },
      );
      return LoginResult.fromResponseData(response.data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar assinatura de hardware: $e');
    }
  }

  // ─── Voucher onboarding link ──────────────────────────────────────────────────

  @override
  Future<OnboardingPaymentLinkDto> generateOnboardingLink(
    String sessionId,
  ) async {
    try {
      final response = await apiClient.post(
        AppConfig.voucherOnboardingLink,
        queryParameters: {'sessionId': sessionId},
      );
      final body = response.data;
      final Map<String, dynamic> data;
      if (body is Map) {
        data = Map<String, dynamic>.from(body);
      } else {
        data = <String, dynamic>{};
      }
      return OnboardingPaymentLinkDto.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao gerar link de onboarding: $e');
    }
  }

  @override
  Future<void> mockConfirmOnboarding(String sessionId) async {
    try {
      await apiClient.post(
        AppConfig.voucherOnboardingMockConfirm,
        queryParameters: {'sessionId': sessionId},
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao forçar confirmação: $e');
    }
  }

  @override
  Future<void> confirmVoucher({
    required String voucherId,
    required String txid,
  }) async {
    try {
      // Strip "pay_" prefix if present to avoid 400 Invalid UUID
      final cleanVoucherId = voucherId.startsWith('pay_') 
          ? voucherId.substring(4) 
          : voucherId;

      await apiClient.post(
        AppConfig.voucherConfirm,
        queryParameters: {
          'pendingVoucherId': cleanVoucherId,
          'txid': txid,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao confirmar voucher: $e');
    }
  }

  // ─── Refresh / Logout / CurrentUser ──────────────────────────────────────────

  @override
  Future<String> refreshToken() async {
    // NOTE: /auth/refresh endpoint não está na documentação atual do backend.
    // Token renewal é feito automaticamente via header X-New-Token (TokenInterceptor).
    return '';
  }

  @override
  Future<void> logout() async {
    // NOTE: /auth/logout endpoint não está na documentação atual do backend.
    // O logout é realizado localmente limpando o token armazenado.
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw UnimplementedError();
  }
}

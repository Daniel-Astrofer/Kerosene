import 'dart:convert';

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

// ─── DTO returned from login ("userId jwt_token" space-separated) ────────────
class LoginResult {
  final String userId;
  final String jwt;

  const LoginResult({required this.userId, required this.jwt});

  /// Parses the backend response format: "userId jwt_token" (space-separated)
  factory LoginResult.fromResponseData(dynamic data) {
    final raw = data.toString().trim();
    final spaceIdx = raw.indexOf(' ');
    if (spaceIdx <= 0) {
      throw AuthException(
        message: 'Login: formato de resposta inválido',
        statusCode: 200,
        errorCode: 'ERR_AUTH_PARSE',
      );
    }
    return LoginResult(
      userId: raw.substring(0, spaceIdx),
      jwt: raw.substring(spaceIdx + 1).trim(),
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
    return OnboardingPaymentLinkDto(
      id: json['id']?.toString() ?? '',
      amountBtc: (json['amountBtc'] as num?)?.toDouble() ?? 0.0,
      depositAddress: json['depositAddress']?.toString() ?? '',
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
  });

  /// Registra passkey de onboarding (start)
  Future<String> registerPasskeyOnboardingStart(String sessionId);

  /// Registra passkey de onboarding (finish)
  Future<void> registerPasskeyOnboardingFinish(
    String sessionId,
    String credentialJson,
  );

  /// Gera link de pagamento de onboarding
  Future<OnboardingPaymentLinkDto> generateOnboardingLink(String sessionId);

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

      String qrCodeUri = '';
      String totpSecret = '';

      if (body is String && body.startsWith('otpauth://')) {
        // response.data is the full otpauth:// URI — use it directly as QR data
        qrCodeUri = body;
        // Extract the secret from the URI query params
        final uri = Uri.tryParse(body);
        totpSecret = uri?.queryParameters['secret'] ?? '';
        debugPrint('🔐 TOTP URI received. secret: $totpSecret');
      } else if (body is Map) {
        // Fallback: legacy shape with explicit keys
        qrCodeUri = body['qrCodeUri']?.toString() ?? '';
        totpSecret = body['totpSecret']?.toString() ?? '';
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
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLoginVerify,
        data: {'username': username, 'totpCode': totpCode},
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
        '${AppConfig.authPasskeyOnboardingStart}?sessionId=$sessionId',
      );
      final body = response.data;
      // Returns the PublicKeyCredentialCreationOptions JSON string
      if (body is Map && body['data'] != null) {
        return body['data'].toString();
      }
      return body.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar registro de passkey: $e');
    }
  }

  @override
  Future<void> registerPasskeyOnboardingFinish(
    String sessionId,
    String credentialJson,
  ) async {
    try {
      await apiClient.post(
        '${AppConfig.authPasskeyOnboardingFinish}?sessionId=$sessionId',
        data: credentialJson,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao finalizar registro de passkey: $e',
      );
    }
  }

  // ─── Voucher onboarding link ──────────────────────────────────────────────────

  @override
  Future<OnboardingPaymentLinkDto> generateOnboardingLink(
    String sessionId,
  ) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.voucherOnboardingLink}?sessionId=$sessionId',
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

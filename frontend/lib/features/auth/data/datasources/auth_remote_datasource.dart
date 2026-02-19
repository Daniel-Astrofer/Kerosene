import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Fazer signup e retornar URI do TOTP
  Future<String> signup({required String username, required String passphrase});

  /// Verificar TOTP de cadastro e retornar sessão
  Future<Map<String, dynamic>> verifySignupTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  });

  /// Login e retornar sessão
  Future<Map<String, dynamic>> login({
    required String username,
    required String passphrase,
  });

  /// Verificar TOTP de login (quando device não reconhecido)
  Future<Map<String, dynamic>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  });

  /// Refresh token (usando cookie)
  Future<Map<String, dynamic>> refreshToken();

  /// Logout
  Future<void> logout();

  /// Obter usuário atual
  Future<UserModel> getCurrentUser();
}

/// Implementação do AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  /// Processa a resposta do servidor:
  /// - Sucesso (200): Retorna o corpo como String (texto puro ou JSON stringificado).
  /// - Erro (!= 200): Tenta parsear JSON para extrair mensagem amigável, senão lança o texto cru ou mensagem padrão.
  Map<String, dynamic> _processResponse(
    Response response, {
    bool isLoginEndpoint = false,
  }) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      return _extractSessionData(response.data);
    }

    String errorMessage = 'Ocorreu um erro (${response.statusCode}).';

    try {
      final decoded = _extractSessionData(response.data);
      if (decoded.containsKey('message')) {
        errorMessage = decoded['message'];
      } else if (decoded.containsKey('error')) {
        errorMessage = decoded['error'];
      }
    } catch (_) {
      if (response.data != null && response.data.toString().isNotEmpty) {
        errorMessage = response.data.toString();
      }
    }

    if (status == 401 || status == 403) {
      // On the login endpoint, ANY 401/403 means the device is unrecognized
      // and the user must verify via TOTP. The API may return various messages
      // ("session expired", "unauthorized", "unrecognized device", etc.)
      if (isLoginEndpoint) {
        throw AuthException(message: 'REQ_LOGIN_2FA', statusCode: status);
      }
      // For other endpoints, check for device-related keywords
      if (errorMessage.toLowerCase().contains('unrecognized') ||
          errorMessage.toLowerCase().contains('device') ||
          errorMessage.toLowerCase().contains('2fa') ||
          errorMessage.toLowerCase().contains('totp')) {
        throw AuthException(message: 'REQ_LOGIN_2FA', statusCode: status);
      }
      throw AuthException(message: errorMessage, statusCode: status);
    }

    throw ServerException(message: errorMessage, statusCode: status);
  }

  @override
  Future<String> signup({
    required String username,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authSignup,
        data: {'username': username, 'passphrase': passphrase},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) =>
              status != null && (status == 202 || status == 200),
        ),
      );

      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao iniciar cadastro: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifySignupTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authSignupVerify,
        data: {
          'username': username,
          'passphrase': passphrase,
          'totpCode': totpCode,
        },
        options: Options(responseType: ResponseType.plain),
      );

      return _processResponse(response);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar TOTP: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLogin,
        data: {'username': username, 'passphrase': passphrase},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // isLoginEndpoint: true → any 401/403 triggers REQ_LOGIN_2FA
      return _processResponse(response, isLoginEndpoint: true);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao fazer login: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authLoginVerify,
        data: {
          'username': username,
          'passphrase': passphrase,
          'totpCode': totpCode,
        },
        options: Options(responseType: ResponseType.plain),
      );

      return _processResponse(response);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao verificar 2FA: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      // Cookie é enviado automaticamente
      final response = await apiClient.post(
        AppConfig.authRefresh,
        options: Options(responseType: ResponseType.plain),
      );

      return _processResponse(response);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao renovar sessão: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Tentar chamar endpoint de logout
      await apiClient.post(AppConfig.authLogout);
      // Limpar cookies localmente seria ideal, mas CookieManager cuida da persistencia.
      // Se o backend limpar o cookie (Set-Cookie: ...; Max-Age=0), o CookieManager deve acatar.
    } catch (_) {
      // Ignorar erro de logout
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw UnimplementedError();
  }

  Map<String, dynamic> _extractSessionData(dynamic data) {
    debugPrint('🔍 Parsing Session Data: $data'); // Debug Log

    if (data == null) return {};

    // 1. Map (JSON standard)
    if (data is Map) return Map<String, dynamic>.from(data);

    // 2. String (Raw)
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return {};

      // Cleanup quotes
      var cleanBody = trimmed;
      if (cleanBody.startsWith('"') && cleanBody.endsWith('"')) {
        cleanBody = cleanBody.substring(1, cleanBody.length - 1).trim();
      }

      // Case A: "<USER_ID> <JWT_TOKEN>" (Space separated)
      // Check if it contains a space and the second part looks like a JWT
      final parts = cleanBody.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final userId = parts[0].trim();
        final potentialToken = parts.sublist(1).join('').trim(); // Concat rest

        // JWT heuristics: starts with 'ey', contains '.'
        if (potentialToken.startsWith('ey') && potentialToken.contains('.')) {
          return {
            'userId': userId,
            'accessToken': potentialToken,
            '__raw_body__': cleanBody,
          };
        }
      }

      // Case B: Just JWT
      if (cleanBody.startsWith('ey') && cleanBody.contains('.')) {
        return {'accessToken': cleanBody};
      }

      // Case C: Fallback - treat whole body as token if it looks reasonably like one
      if (cleanBody.length > 20 && !cleanBody.contains(' ')) {
        return {'accessToken': cleanBody, '__raw_body__': cleanBody};
      }
    }

    return {};
  }
}

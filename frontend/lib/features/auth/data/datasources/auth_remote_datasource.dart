import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../models/user_model.dart';

/// Interface do AuthRemoteDataSource
abstract class AuthRemoteDataSource {
  /// Fazer signup (criar usuário temporário)
  /// Retorna o TOTP secret para configurar no app autenticador
  Future<Map<String, dynamic>> signup({
    required String username,
    required String passphrase,
  });

  /// Verificar código TOTP e finalizar criação da conta
  Future<String> verifyTotp({
    required String username,
    required String passphrase,
    required String totpSecret,
    required String totpCode,
  });

  /// Fazer login
  /// Retorna JWT token
  Future<String> login({required String username, required String passphrase});

  /// Verificar TOTP para Login (2FA em novo dispositivo)
  Future<String> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  });

  /// Fazer logout
  Future<void> logout();

  /// Obter usuário atual
  Future<UserModel> getCurrentUser();

  /// Refresh token
  Future<String> refreshToken(String token);
}

/// Implementação do AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  /// Processa a resposta do servidor:
  /// - Sucesso (200): Retorna o corpo como String (texto puro ou JSON stringificado).
  /// - Erro (!= 200): Tenta parsear JSON para extrair mensagem amigável, senão lança o texto cru ou mensagem padrão.
  String _handleResponse(Response response) {
    // Se a resposta contiver otpauth, é sucesso (signup ou verify), independente do status code
    if (response.data.toString().contains('otpauth://')) {
      return response.data.toString();
    }

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data.toString();
    }

    String errorMessage = 'Ocorreu um erro desconhecido.';

    // Tentar ler erro do JSON
    try {
      if (response.data is String) {
        final json = jsonDecode(response.data);
        if (json is Map) {
          errorMessage = json['message'] ?? json['error'] ?? json.toString();
        }
      } else if (response.data is Map) {
        final json = response.data;
        errorMessage = json['message'] ?? json['error'] ?? json.toString();
      } else {
        errorMessage = response.data.toString();
      }
    } catch (_) {
      // Falha no parse, usar texto cru se disponível
      if (response.data != null) errorMessage = response.data.toString();
    }

    // Tratamento específico para 403/Forbidden se não vier mensagem clara
    if (response.statusCode == 403 &&
        (errorMessage.isEmpty || errorMessage.contains('Forbidden'))) {
      throw ServerException(
        message: 'Dispositivo ou credenciais não autorizados (403).',
      );
    }

    throw ServerException(message: errorMessage);
  }

  @override
  Future<Map<String, dynamic>> signup({
    required String username,
    required String passphrase,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.authSignup,
        data: {'username': username, 'passphrase': passphrase},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );

      final responseData = _handleResponse(response);

      // Sucesso: responseData deve conter mensagem e talvez o secret (se o backend mudou para JSON no sucesso tb, ajustar aqui)
      // O prompt diz: "somente nas mensagens de sucesso que o retorno é texto puro"

      return {
        'message': responseData,
        'totpSecret': _extractTotpSecret(responseData),
      };
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro ao criar usuário: $e');
    }
  }

  @override
  Future<String> verifyTotp({
    required String username,
    required String passphrase,
    required String totpSecret,
    required String totpCode,
  }) async {
    try {
      // Obter headers de segurança
      final securityHeaders = await DeviceHelper.getSecurityHeaders();

      // Extrair o segredo limpo se for uma URL otpauth
      String cleanSecret = totpSecret;
      if (totpSecret.contains('otpauth://')) {
        final uri = Uri.tryParse(totpSecret);
        if (uri != null) {
          cleanSecret = uri.queryParameters['secret'] ?? totpSecret;
        }
      }

      final response = await apiClient.post(
        AppConfig.authTotpVerify,
        data: {
          'username': username,
          'passphrase': passphrase,
          'totpSecret': cleanSecret,
          'totpCode': totpCode,
        },
        headers: securityHeaders,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro ao verificar TOTP: $e');
    }
  }

  @override
  Future<String> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      final securityHeaders = await DeviceHelper.getSecurityHeaders();

      final response = await apiClient.post(
        AppConfig.authLoginVerify, // Novo endpoint
        data: {
          'username': username,
          'passphrase': passphrase,
          'totpCode': totpCode,
        },
        headers: securityHeaders,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro ao verificar 2FA de login: $e');
    }
  }

  @override
  Future<String> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      // Obter headers de segurança
      final securityHeaders = await DeviceHelper.getSecurityHeaders();

      final response = await apiClient.post(
        AppConfig.authLogin,
        data: {'username': username, 'passphrase': passphrase},
        headers: securityHeaders,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );

      // Tratamento específico para 403: Requer 2FA
      if (response.statusCode == 403) {
        // Lança uma exceção específica que será capturada pelo Repo/Notifier para mudar o estado
        throw ServerException(message: 'REQ_LOGIN_2FA');
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro ao fazer login: $e');
    }
  }

  @override
  Future<void> logout() async {
    // Não há endpoint de logout na API
    // Apenas limpar dados locais
    return;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // A API não tem endpoint para obter usuário atual
    // Retornar dados mockados ou do token JWT
    throw UnimplementedError('getCurrentUser não implementado pela API');
  }

  @override
  Future<String> refreshToken(String token) async {
    // A API não tem endpoint de refresh token
    throw UnimplementedError('refreshToken não implementado pela API');
  }

  /// Extrai o TOTP secret da resposta
  String _extractTotpSecret(dynamic data) {
    if (data == null) return '';
    String stringData = data.toString();

    // Lógica existente de extração...
    // Simplificando pois reescrevi o metodo todo

    if (stringData.contains('otpauth://')) {
      return stringData;
    }

    // Tenta regex direto
    final match = RegExp(r'otpauth://[^\s"\}]+').firstMatch(stringData);
    if (match != null) {
      return match.group(0)!;
    }

    // Se falhar e for sucesso, talvez o backend mande o secret limpo?
    // Assumindo comportamento atual.
    return stringData;
  }
}

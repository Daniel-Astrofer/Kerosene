import 'dart:convert';

/// Exceção base para a aplicação
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? traceId;
  final Object? data;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.traceId,
    this.data,
  });

  @override
  String toString() {
    final payload = {
      'type': 'AppException',
      'message': message,
      'statusCode': statusCode,
      'errorCode': errorCode,
      'data': data,
    };
    if (traceId != null) {
      payload['traceId'] = traceId;
    }
    return jsonEncode(payload);
  }
}

/// Exceção de servidor
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.traceId,
    super.data,
  });
}

/// Exceção de rede
class NetworkException extends AppException {
  const NetworkException({super.message = 'Sem conexão com a internet'});
}

/// Exceção de autenticação
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.traceId,
    super.data,
  });
}

/// Exceção de validação
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.traceId,
    super.data,
  });
}

/// Exceção de cache
class CacheException extends AppException {
  const CacheException({super.message = 'Erro ao acessar cache local'});
}

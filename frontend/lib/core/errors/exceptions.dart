import 'dart:convert';

/// Exceção base para a aplicação
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Object? data;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.data,
  });

  @override
  String toString() => jsonEncode({
        'type': 'AppException',
        'message': message,
        'statusCode': statusCode,
        'errorCode': errorCode,
        'data': data,
      });
}

/// Exceção de servidor
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
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
    super.data,
  });
}

/// Exceção de validação
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.data,
  });
}

/// Exceção de cache
class CacheException extends AppException {
  const CacheException({super.message = 'Erro ao acessar cache local'});
}

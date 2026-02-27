import 'dart:convert';

/// Exceção base para a aplicação
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const AppException({required this.message, this.statusCode, this.errorCode});

  @override
  String toString() => jsonEncode({
    'type': 'AppException',
    'message': message,
    'statusCode': statusCode,
    'errorCode': errorCode,
  });
}

/// Exceção de servidor
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
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
  });
}

/// Exceção de validação
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
  });
}

/// Exceção de cache
class CacheException extends AppException {
  const CacheException({super.message = 'Erro ao acessar cache local'});
}

/// Exceção base para a aplicação
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode)';
}

/// Exceção de servidor
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Exceção de rede
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Sem conexão com a internet',
  });
}

/// Exceção de autenticação
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
  });
}

/// Exceção de validação
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
  });
}

/// Exceção de cache
class CacheException extends AppException {
  const CacheException({
    super.message = 'Erro ao acessar cache local',
  });
}

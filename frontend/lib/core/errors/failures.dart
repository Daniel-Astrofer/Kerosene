import 'dart:convert';

/// Classe base para falhas na aplicação
abstract class Failure {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Object? data;

  const Failure({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.data,
  });

  @override
  String toString() => jsonEncode({
        'type': 'Failure',
        'message': message,
        'statusCode': statusCode,
        'errorCode': errorCode,
        'data': data,
      });
}

/// Falha de servidor (5xx)
class ServerFailure extends Failure {
  const ServerFailure(
      {required super.message, super.statusCode, super.errorCode, super.data});
}

/// Falha de rede (sem conexão)
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sem conexão com a internet'});
}

/// Falha de autenticação (401, 403)
class AuthFailure extends Failure {
  const AuthFailure(
      {required super.message, super.statusCode, super.errorCode, super.data});
}

/// Falha de validação (400)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.data,
  });
}

/// Falha de cache/armazenamento local
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erro ao acessar cache local'});
}

/// Falha desconhecida
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Erro desconhecido'});
}

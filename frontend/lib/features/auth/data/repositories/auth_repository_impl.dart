import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementação do AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Fazer login e obter JWT
      final tokenResponse = await remoteDataSource.login(
        username: email,
        passphrase: password,
      );

      // Salvar token localmente
      // Parsear resposta: Pode vir "ID JWT"
      final parts = tokenResponse.trim().split(' ');
      String token;
      String userId;

      if (parts.length >= 2) {
        userId = parts[0];
        token = parts.sublist(1).join(' ');
      } else {
        token = tokenResponse;
        userId = email; // Fallback se não vier ID
      }

      await localDataSource.saveToken(token);

      // Criar modelo de usuário
      final user = UserModel(
        id: userId,
        email: '$email@kerosene.app',
        name: email, // ou userId se preferir
        createdAt: DateTime.now(),
      );

      // Salvar usuário localmente
      await localDataSource.saveUser(user);

      return Right(user);
    } on ServerException catch (e) {
      if (e.message == 'REQ_LOGIN_2FA') {
        // Retorna um erro específico que o Notifier vai capturar para mudar de tela
        return Left(AuthFailure(message: 'REQ_LOGIN_2FA'));
      }
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao fazer login: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      // 1. Verificar TOTP na API (Retorna "ID TOKEN")
      final responseString = await remoteDataSource.verifyLoginTotp(
        username: username,
        passphrase: passphrase,
        totpCode: totpCode,
      );

      // 2. Parsear resposta: Esperado "USER_ID JWT_TOKEN"
      // Reutilizando lógica existente, idealmente refatorar em um helper
      final parts = responseString.trim().split(' ');
      String token;
      String userId;

      if (parts.length >= 2) {
        userId = parts[0];
        token = parts.sublist(1).join(' ');
      } else {
        token = responseString;
        userId = username;
      }

      // 3. Salvar Token e User
      await localDataSource.saveToken(token);

      final user = UserModel(
        id: userId,
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao verificar 2FA: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Passo 1: Criar usuário e obter TOTP secret
      final signupResult = await remoteDataSource.signup(
        username: name,
        passphrase: password,
      );

      // Salvar TOTP secret para uso posterior
      final totpSecret = signupResult['totpSecret'] as String;
      // Salvar localmente também por segurança
      await localDataSource.saveTotpSecret(totpSecret);

      return Right(totpSecret);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao criar conta: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Fazer logout no servidor (se houver endpoint)
      await remoteDataSource.logout();

      // Limpar dados locais
      await localDataSource.clearAll();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao fazer logout: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Tentar obter usuário do cache local
      final cachedUser = await localDataSource.getUser();

      if (cachedUser != null) {
        return Right(cachedUser);
      }

      // Se não houver cache, tentar obter do servidor
      try {
        final user = await remoteDataSource.getCurrentUser();
        await localDataSource.saveUser(user);
        return Right(user);
      } catch (e) {
        // Se falhar, retornar erro
        return Left(CacheFailure(message: 'Usuário não encontrado'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao obter usuário: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final currentToken = await localDataSource.getToken();

      if (currentToken == null) {
        return Left(AuthFailure(message: 'Token não encontrado'));
      }

      final newToken = await remoteDataSource.refreshToken(currentToken);
      await localDataSource.saveToken(newToken);

      // Obter usuário atual
      final user = await getCurrentUser();
      return user;
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao renovar token: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      // Obter TOTP secret salvo
      final totpSecret = await localDataSource.getTotpSecret();

      if (totpSecret == null) {
        return Left(ValidationFailure(message: 'TOTP secret não encontrado'));
      }

      // 1. Verificar TOTP na API (Retorna "ID TOKEN")
      final responseString = await remoteDataSource.verifyTotp(
        username: username,
        passphrase: passphrase,
        totpSecret: totpSecret,
        totpCode: totpCode,
      );

      // 2. Parsear resposta: Esperado "USER_ID JWT_TOKEN"
      final parts = responseString.trim().split(' ');
      String token;
      String userId;

      if (parts.length >= 2) {
        // Formato ID TOKEN
        userId = parts[0];
        token = parts.sublist(1).join(' '); // O resto é o token
      } else {
        // Fallback se vier só token
        token = responseString;
        userId = username;
      }

      // 3. Salvar Token e User
      await localDataSource.saveToken(token);

      final user = UserModel(
        id: userId,
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);

      // 4. Retornar User autenticado
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao verificar TOTP: $e'));
    }
  }
}

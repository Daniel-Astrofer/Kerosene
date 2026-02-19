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
  Future<Either<Failure, User>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      final result = await remoteDataSource.verifyLoginTotp(
        username: username,
        passphrase: passphrase,
        totpCode: totpCode,
      );

      final token =
          result['accessToken'] ??
          result['token'] ??
          result['jwt'] ??
          result['access_token'] ??
          result['auth_token'];
      final userId = result['userId'] ?? result['id'] ?? result['sub'] ?? '0';

      if (token == null) {
        final keys = result.keys.join(', ');
        return Left(
          ServerFailure(
            message: 'Falha login 2FA: token não encontrado (campos: $keys)',
          ),
        );
      }

      await localDataSource.saveToken(token);
      await localDataSource.saveMnemonic(
        passphrase,
      ); // Save mnemonic for signing

      // Construir User com dados disponíveis
      final user = UserModel(
        id: userId.toString(),
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final result = await remoteDataSource.login(
        username: username,
        passphrase: passphrase,
      );

      final token =
          result['accessToken'] ??
          result['token'] ??
          result['jwt'] ??
          result['access_token'] ??
          result['auth_token'];
      final userId = result['userId'] ?? result['id'] ?? result['sub'] ?? '0';

      if (token == null) {
        final keys = result.keys.join(', ');
        final hasBody = result['__raw_body__'] != null;
        return Left(
          ServerFailure(
            message:
                'Login falhou: token não encontrado no 202 (Campos: $keys, RawBody: $hasBody)',
          ),
        );
      }

      await localDataSource.saveToken(token);
      await localDataSource.saveMnemonic(
        passphrase,
      ); // Save mnemonic for signing

      // Construir User com dados disponíveis
      final user = UserModel(
        id: userId.toString(),
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } on AppException catch (e) {
      if (e.message == 'REQ_LOGIN_2FA') {
        return const Left(
          AuthFailure(message: 'REQ_LOGIN_2FA', statusCode: 403),
        );
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signup({
    required String username,
    required String passphrase,
  }) async {
    try {
      final totpUri = await remoteDataSource.signup(
        username: username,
        passphrase: passphrase,
      );
      return Right(totpUri);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource
          .clearAll(); // Clears token, user, totp, and mnemonic
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao fazer logout: $e'));
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
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }

      try {
        final user = await remoteDataSource.getCurrentUser();
        await localDataSource.saveUser(user);
        return Right(user);
      } catch (e) {
        return Left(CacheFailure(message: 'Usuário não encontrado'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao obter usuário: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final result = await remoteDataSource.refreshToken();
      final newToken =
          result['accessToken'] ??
          result['token'] ??
          result['jwt'] ??
          result['access_token'] ??
          result['auth_token'];
      final userId = result['userId'] ?? result['id'] ?? result['sub'] ?? '0';

      if (newToken != null) {
        await localDataSource.saveToken(newToken);
        final currentUser = await localDataSource.getUser();
        final user = currentUser != null
            ? UserModel.fromEntity(currentUser)
            : UserModel(
                id: userId.toString(),
                email: 'user@kerosene.app',
                name: 'User',
                createdAt: DateTime.now(),
              );

        await localDataSource.saveUser(user);
        return Right(user);
      }

      return const Left(AuthFailure(message: 'Falha ao renovar token'));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao renovar token: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyTotp({
    required String username,
    required String passphrase,
    required String totpCode,
    String? totpSecret,
  }) async {
    try {
      final result = await remoteDataSource.verifySignupTotp(
        username: username,
        passphrase: passphrase,
        totpCode: totpCode,
      );

      final token =
          result['accessToken'] ??
          result['token'] ??
          result['jwt'] ??
          result['access_token'] ??
          result['auth_token'];
      final userId = result['userId'] ?? result['id'] ?? result['sub'] ?? '0';

      if (token == null) {
        final keys = result.keys.join(', ');
        return Left(
          ServerFailure(message: 'Token não encontrado no 202 (Campos: $keys)'),
        );
      }

      await localDataSource.saveToken(token);
      await localDataSource.saveMnemonic(passphrase);

      final user = UserModel(
        id: userId.toString(),
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);

      if (totpSecret != null) {
        await localDataSource.saveTotpSecret(totpSecret);
      }

      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao verificar TOTP: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validatePassphrase(String passphrase) async {
    try {
      final storedMnemonic = await localDataSource.getMnemonic();
      if (storedMnemonic == null) {
        return const Left(
          CacheFailure(message: 'Nenhuma passphrase salva encontrada.'),
        );
      }
      return Right(storedMnemonic == passphrase);
    } catch (e) {
      return Left(CacheFailure(message: 'Erro ao validar passphrase: $e'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:teste/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:teste/features/auth/data/models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  LedgerRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, List<dynamic>>> getAllLedgers() async {
    try {
      final result = await remoteDataSource.getAllLedgers();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> findLedger(
      String walletName) async {
    try {
      final result = await remoteDataSource.findLedger(walletName: walletName);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getBalance(String walletName) async {
    try {
      final result = await remoteDataSource.getBalance(walletName: walletName);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getHistory(
      {int page = 0, int size = 50}) async {
    final currentUser = await _currentUser();
    final currentUserId = int.tryParse(currentUser?.id ?? '');
    final currentUsername = currentUser?.username.trim();
    try {
      final rawList = await remoteDataSource.getHistory(page: page, size: size);
      final transactions = rawList.whereType<Map>().map((item) {
        final data = Map<String, dynamic>.from(item);
        if (currentUserId != null) {
          data['currentUserId'] = currentUserId;
        }
        if (currentUsername != null && currentUsername.isNotEmpty) {
          data['currentUsername'] = currentUsername;
        }
        return Transaction.fromJson(data);
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<UserModel?> _currentUser() async {
    try {
      return authLocalDataSource.getUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    String? context,
  }) async {
    try {
      final idempotencyKey = const Uuid().v4();
      final result = await remoteDataSource.sendInternalTransaction(
        senderWalletName: senderWalletName,
        receiverWalletName: receiverWalletName,
        amount: amount,
        idempotencyKey: idempotencyKey,
        requestTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
  }) async {
    try {
      final result = await remoteDataSource.createPaymentRequest(
        amount: amount,
        receiverWalletName: receiverWalletName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPaymentRequest(
      String linkId) async {
    try {
      final result = await remoteDataSource.getPaymentRequest(linkId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
    String? totpCode,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
    int? requestTimestamp,
  }) async {
    try {
      final result = await remoteDataSource.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
        totpCode: totpCode,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: passkeyAssertionJson,
        idempotencyKey: idempotencyKey,
        requestTimestamp: requestTimestamp,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteLedger(String walletName) async {
    try {
      final result =
          await remoteDataSource.deleteLedger(walletName: walletName);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar ledger: $e'));
    }
  }
}

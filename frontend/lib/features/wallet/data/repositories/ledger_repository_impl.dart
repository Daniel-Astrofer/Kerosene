import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource remoteDataSource;

  LedgerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<dynamic>>> getAllLedgers() async {
    try {
      final result = await remoteDataSource.getAllLedgers();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> findLedger(String walletName) async {
    try {
      final result = await remoteDataSource.findLedger(walletName: walletName);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getHistory({int page = 0, int size = 50}) async {
    try {
      final rawList = await remoteDataSource.getHistory(page: page, size: size);
      final transactions = rawList.map((item) => Transaction.fromJson(item as Map<String, dynamic>)).toList();
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
      final result = await remoteDataSource.sendInternalTransaction(
        senderWalletName: senderWalletName,
        receiverWalletName: receiverWalletName,
        amount: amount,
        idempotencyKey: const Uuid().v4(),
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPaymentRequest(String linkId) async {
    try {
      final result = await remoteDataSource.getPaymentRequest(linkId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  }) async {
    try {
      final result = await remoteDataSource.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteLedger(String walletName) async {
    try {
      final result = await remoteDataSource.deleteLedger(walletName: walletName);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar ledger: $e'));
    }
  }
}

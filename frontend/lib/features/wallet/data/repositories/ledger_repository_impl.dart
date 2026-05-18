import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:teste/features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final SecureStorageService localHistoryStorage;

  LedgerRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
    SecureStorageService? localHistoryStorage,
  }) : localHistoryStorage = localHistoryStorage ?? SecureStorageService();

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
    final currentUserId = await _currentUserId();
    final storageKey = _historyStorageKey(currentUserId);
    try {
      final rawList = await remoteDataSource.getHistory(page: page, size: size);
      final transactions = rawList.whereType<Map>().map((item) {
        final data = Map<String, dynamic>.from(item);
        if (currentUserId != null) {
          data['currentUserId'] = currentUserId;
        }
        return Transaction.fromJson(data);
      }).toList();
      final merged = await _mergeAndPersistLocalHistory(
        storageKey,
        transactions,
      );
      return Right(_page(merged, page, size));
    } on ServerException catch (e) {
      final local = await _readLocalHistory(storageKey);
      if (local.isNotEmpty) {
        return Right(_page(local, page, size));
      }
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      final local = await _readLocalHistory(storageKey);
      if (local.isNotEmpty) {
        return Right(_page(local, page, size));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<List<Transaction>> _mergeAndPersistLocalHistory(
    String storageKey,
    List<Transaction> remoteTransactions,
  ) async {
    final local = await _readLocalHistory(storageKey);
    final byId = <String, Transaction>{
      for (final transaction in local) transaction.id: transaction,
      for (final transaction in remoteTransactions) transaction.id: transaction,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final capped = merged.take(500).toList();
    await localHistoryStorage.write(
      key: storageKey,
      value: jsonEncode(capped.map((tx) => tx.toJson()).toList()),
    );
    return capped;
  }

  Future<List<Transaction>> _readLocalHistory(String storageKey) async {
    final payload = await localHistoryStorage.read(key: storageKey);
    if (payload == null || payload.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! List) return const [];
      final transactions = decoded
          .whereType<Map>()
          .map((item) => Transaction.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return transactions;
    } catch (_) {
      return const [];
    }
  }

  String _historyStorageKey(int? userId) {
    return 'local_transaction_history_${userId ?? 'anonymous'}';
  }

  List<Transaction> _page(List<Transaction> transactions, int page, int size) {
    final safeSize = size <= 0 ? 50 : size;
    final offset = page <= 0 ? 0 : page * safeSize;
    if (offset >= transactions.length) return const [];
    return transactions.skip(offset).take(safeSize).toList();
  }

  Future<int?> _currentUserId() async {
    try {
      final currentUser = await authLocalDataSource.getUser();
      return int.tryParse(currentUser?.id ?? '');
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

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:kerosene/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:kerosene/features/auth/data/models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  LedgerRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  Failure _failureFromAppException(AppException e) {
    if (e is ValidationException) {
      return ValidationFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      );
    }
    if (e is AuthException) {
      return AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      );
    }
    if (e is NetworkException) {
      return NetworkFailure(message: e.message);
    }
    return ServerFailure(
      message: e.message,
      statusCode: e.statusCode,
      errorCode: e.errorCode,
      data: e.data,
    );
  }

  @override
  Future<Either<Failure, List<dynamic>>> getAllLedgers() async {
    try {
      final result = await remoteDataSource.getAllLedgers();
      return Right(result);
    } on AppException catch (e) {
      return Left(_failureFromAppException(e));
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
    } on AppException catch (e) {
      return Left(_failureFromAppException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getBalance(String walletName) async {
    try {
      final result = await remoteDataSource.getBalance(walletName: walletName);
      return Right(result);
    } on AppException catch (e) {
      return Left(_failureFromAppException(e));
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
      final transactions = rawList
          .whereType<Map>()
          .where(
            (item) => _historyItemBelongsToCurrentUser(
              item,
              currentUserId: currentUserId,
              currentUsername: currentUsername,
            ),
          )
          .map((item) {
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
    } on AppException catch (e) {
      return Left(_failureFromAppException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  bool _historyItemBelongsToCurrentUser(
    Map<dynamic, dynamic> item, {
    required int? currentUserId,
    required String? currentUsername,
  }) {
    final explicitOwnerIds = [
      item['userId'],
      item['authenticatedUserId'],
      item['accountUserId'],
      item['ownerUserId'],
      item['walletOwnerUserId'],
    ].map(_parseInt).whereType<int>().toSet();

    if (explicitOwnerIds.isNotEmpty) {
      return currentUserId != null && explicitOwnerIds.contains(currentUserId);
    }

    final participantIds = [
      item['senderUserId'],
      item['senderUserID'],
      item['payerUserId'],
      item['fromUserId'],
      item['receiverUserId'],
      item['receiverUserID'],
      item['payeeUserId'],
      item['toUserId'],
    ].map(_parseInt).whereType<int>().toSet();

    if (participantIds.isNotEmpty) {
      return currentUserId != null && participantIds.contains(currentUserId);
    }

    final ownerNames = [
      item['username'],
      item['userName'],
      item['accountUsername'],
      item['ownerUsername'],
      item['walletOwnerUsername'],
    ]
        .map((value) => _normalizeIdentity(value?.toString()))
        .where((value) => value.isNotEmpty)
        .toSet();

    if (ownerNames.isNotEmpty) {
      final normalizedCurrentUsername = _normalizeIdentity(currentUsername);
      return normalizedCurrentUsername.isNotEmpty &&
          ownerNames.contains(normalizedCurrentUsername);
    }

    return true;
  }

  int? _parseInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString().trim());
  }

  String _normalizeIdentity(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'^@+'), '');
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
    } on AppException catch (e) {
      return Left(_failureFromAppException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

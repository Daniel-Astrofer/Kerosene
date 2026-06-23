import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/wallet_security_service.dart';
import '../../../../features/auth/controller/auth_controller.dart' show sessionStorageScopeFromUser;
import '../../../../core/utils/bitcoin_network.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
import '../../../transactions/domain/entities/fee_estimate.dart' as tx_fee;
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;
  final LedgerRemoteDataSource ledgerRemoteDataSource;
  final TransactionRemoteDataSource transactionRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final WalletSecurityService walletSecurityService;

  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.ledgerRemoteDataSource,
    required this.transactionRemoteDataSource,
    required this.authLocalDataSource,
    required this.walletSecurityService,
  });

  Failure _failureFromException(AppException exception) {
    if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        errorCode: exception.errorCode,
        data: exception.data,
      );
    }
    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        errorCode: exception.errorCode,
        data: exception.data,
      );
    }
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        errorCode: exception.errorCode,
        data: exception.data,
      );
    }
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message);
    }
    return UnknownFailure(message: exception.message);
  }

  Future<String?> _currentSessionStorageScope() async {
    try {
      final user = await authLocalDataSource.getUser();
      return sessionStorageScopeFromUser(
        userId: user?.id,
        username: user?.username,
      );
    } catch (_) {
      return null;
    }
  }

  AuthFailure _missingLocalSessionFailure() {
    return AuthFailure(
      message: 'Sessão local inválida para salvar cold wallet',
    );
  }

  @override
  Future<Either<Failure, Wallet>> createWallet({
    required String name,
    required String passphrase,
    String accountSecurity = 'STANDARD',
    String? xpub,
    String walletMode = 'KEROSENE',
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final normalizedMode = walletMode.trim().toUpperCase();
      final normalizedXpub = xpub?.trim();

      if (normalizedMode == 'SELF_CUSTODY' &&
          (normalizedXpub == null || normalizedXpub.isEmpty)) {
        final storageScope = await _currentSessionStorageScope();
        if (storageScope == null) {
          return Left(_missingLocalSessionFailure());
        }
        await walletSecurityService.saveMnemonic(
          passphrase,
          storageScope: storageScope,
        );
        String? address;
        try {
          address =
              await walletSecurityService.getAddressFromMnemonic(passphrase);
        } catch (_) {}
        final now = DateTime.now();
        return Right(
          Wallet(
            id: const Uuid().v4(),
            name: name,
            address: address ?? '',
            walletMode: 'SELF_CUSTODY',
            balance: 0.0,
            derivationPath: "m/84'/0'/0'/0/0",
            type: WalletType.nativeSegwit,
            createdAt: now,
            updatedAt: now,
            accountSecurity: accountSecurity,
          ),
        );
      }

      final result = await remoteDataSource.createWallet(
        name: name,
        xpub: normalizedXpub,
        walletMode: walletMode,
      );

      return Right(Wallet.fromJson(result));
    } on AppException catch (e) {
      return Left(_failureFromException(e));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao criar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Wallet>>> getWallets() async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.getWallets();
      final walletsList = result.map((data) => Wallet.fromJson(data)).toList();
      final hasKfeBalances = result.whereType<Map>().any((wallet) {
        return wallet.containsKey('availableSats') ||
            wallet.containsKey('observedSats');
      });

      if (hasKfeBalances) {
        return Right(walletsList);
      }

      // Enforce Ledger Balance: Fetch all ledgers to get real-time balances
      Map<String, double> balances = {};
      try {
        final allLedgers = await ledgerRemoteDataSource.getAllLedgers();
        for (final item in allLedgers) {
          if (item is Map) {
            final name = item['walletName'] ?? item['id'];
            final balance = item['balance'];
            if (name != null && balance != null) {
              balances[name.toString()] =
                  (balance is num) ? balance.toDouble() : 0.0;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching all ledgers: $e');
      }

      final List<Wallet> walletsWithBalance = [];

      for (final wallet in walletsList) {
        if (balances.containsKey(wallet.name)) {
          final bal = balances[wallet.name]!;
          walletsWithBalance.add(wallet.copyWith(balance: bal));
        } else {
          try {
            final bal = await ledgerRemoteDataSource.getBalance(
              walletName: wallet.name,
            );
            walletsWithBalance.add(wallet.copyWith(balance: bal));
          } catch (_) {
            walletsWithBalance.add(wallet);
          }
        }
      }

      return Right(walletsWithBalance);
    } on AppException catch (e) {
      return Left(_failureFromException(e));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao buscar carteiras: $e'));
    }
  }

  @override
  Future<Either<Failure, Wallet>> getWalletById(String id) async {
    final res = await getWallets();
    return res.fold((l) => Left(l), (r) {
      try {
        return Right(r.firstWhere((w) => w.id == id || w.name == id));
      } catch (e) {
        return Left(ValidationFailure(message: 'Carteira não encontrada'));
      }
    });
  }

  @override
  Future<Either<Failure, Wallet>> updateWalletBalance(String walletName) async {
    final walletResult = await getWalletById(walletName);

    return walletResult.fold((failure) => Left(failure), (wallet) async {
      try {
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return Left(AuthFailure(message: 'Usuário não autenticado'));
        }

        final balance = await ledgerRemoteDataSource.getBalance(
          walletName: walletName,
        );

        return Right(wallet.copyWith(balance: balance));
      } on AppException catch (e) {
        return Left(_failureFromException(e));
      } catch (e) {
        return Left(UnknownFailure(message: 'Erro ao atualizar saldo: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, Wallet>> importWallet({
    required String name,
    required String mnemonic,
    required WalletType type,
  }) async {
    try {
      final storageScope = await _currentSessionStorageScope();
      if (storageScope == null) {
        return Left(_missingLocalSessionFailure());
      }
      await walletSecurityService.saveMnemonic(
        mnemonic,
        storageScope: storageScope,
      );

      String? address;
      try {
        address = await walletSecurityService.getAddressFromMnemonic(mnemonic);
      } catch (_) {}

      return Right(
        Wallet(
          id: name,
          name: name,
          walletMode: 'SELF_CUSTODY',
          type: type,
          balance: 0.0,
          address: address ?? '',
          derivationPath: "m/84'/0'/0'/0/0",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao importar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions({
    required String walletId,
    int? limit,
    int? offset,
  }) async {
    // This now logically belongs to LedgerRepository, but implementing for interface compatibility
    try {
      final history = await ledgerRemoteDataSource.getHistory(
          page: (offset ?? 0) ~/ (limit ?? 50), size: limit ?? 50);
      return Right(history.map((e) => Transaction.fromJson(e)).toList());
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao buscar transações: $e'));
    }
  }

  @override
  Future<Either<Failure, Transaction>> sendBitcoin({
    required String fromWalletId,
    required String toAddress,
    required int amountSatoshis,
    required int feeSatoshis,
    String? description,
  }) async {
    // Internal transfer via Ledger
    try {
      final result = await ledgerRemoteDataSource.sendInternalTransaction(
        senderWalletName: fromWalletId,
        receiverWalletName: toAddress,
        amount: amountSatoshis / 100000000.0,
        idempotencyKey: const Uuid().v4(),
        requestTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      return Right(Transaction.fromJson(result));
    } on AppException catch (e) {
      return Left(_failureFromException(e));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao enviar: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateAddress(String address) async {
    return Right(looksLikeBitcoinAddress(address));
  }

  @override
  Future<Either<Failure, FeeEstimate>> estimateFee({
    required String walletId,
    required int amountSatoshis,
  }) async {
    try {
      final btcAmount = amountSatoshis / 1e8;
      final estimate = await transactionRemoteDataSource.estimateFee(btcAmount);

      return Right(
        FeeEstimate(
          fastSatoshisPerByte: estimate.fastSatPerByte.toInt(),
          mediumSatoshisPerByte: estimate.standardSatPerByte.toInt(),
          slowSatoshisPerByte: estimate.slowSatPerByte.toInt(),
          estimatedTxSize: _estimatedTxSizeFromBackend(estimate),
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao estimar taxas: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getBTCtoUSDRate() async {
    return Left(
      ServerFailure(
        message:
            'Cotação BTC/USD não deve ser simulada no repositório de carteiras.',
      ),
    );
  }

  int _estimatedTxSizeFromBackend(tx_fee.FeeEstimate estimate) {
    final candidates = <int>[
      _txSizeFromFee(
        feeBtc: estimate.estimatedStandardBtc,
        satsPerByte: estimate.standardSatPerByte,
      ),
      _txSizeFromFee(
        feeBtc: estimate.estimatedFastBtc,
        satsPerByte: estimate.fastSatPerByte,
      ),
      _txSizeFromFee(
        feeBtc: estimate.estimatedSlowBtc,
        satsPerByte: estimate.slowSatPerByte,
      ),
    ].where((value) => value > 0).toList();

    if (candidates.isEmpty) {
      throw const ServerException(
        message:
            'O backend não retornou dados suficientes para estimar o tamanho da transação.',
        errorCode: 'ERR_FEE_ESTIMATE_SIZE_UNAVAILABLE',
      );
    }

    return candidates.first;
  }

  int _txSizeFromFee({
    required double feeBtc,
    required double satsPerByte,
  }) {
    if (feeBtc <= 0 || satsPerByte <= 0) return 0;
    return ((feeBtc * 100000000) / satsPerByte).round();
  }

  @override
  Future<Either<Failure, Wallet>> findWallet(String name) async {
    try {
      final result = await remoteDataSource.findWallet(name: name);
      return Right(Wallet.fromJson(result));
    } on AppException catch (e) {
      return Left(_failureFromException(e));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao buscar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveMnemonic(String mnemonic) async {
    try {
      final storageScope = await _currentSessionStorageScope();
      if (storageScope == null) {
        return Left(_missingLocalSessionFailure());
      }
      final success = await walletSecurityService.saveMnemonic(
        mnemonic,
        storageScope: storageScope,
      );
      return Right(success);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao salvar mnemônico: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getMnemonic() async {
    try {
      final storageScope = await _currentSessionStorageScope();
      if (storageScope == null) {
        return const Right(null);
      }
      final mnemonic = await walletSecurityService.authenticateAndGetMnemonic(
        storageScope: storageScope,
      );
      return Right(mnemonic);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao recuperar mnemônico: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMnemonic() async {
    try {
      final storageScope = await _currentSessionStorageScope();
      await walletSecurityService.clearMnemonic(storageScope: storageScope);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar mnemônico: $e'));
    }
  }
}

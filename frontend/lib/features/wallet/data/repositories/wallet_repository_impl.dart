import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/wallet_security_service.dart';
import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../transactions/data/datasources/transaction_remote_datasource.dart';
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

  @override
  Future<Either<Failure, String>> createWallet({
    required String name,
    required String passphrase,
    String accountSecurity = 'STANDARD',
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.createWallet(
        name: name,
        passphrase: passphrase,
        accountSecurity: accountSecurity,
      );

      // Persist mnemonic locally for secure access
      await walletSecurityService.saveMnemonic(passphrase);

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
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
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
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
      await walletSecurityService.saveMnemonic(mnemonic);

      try {
        await remoteDataSource.createWallet(name: name, passphrase: mnemonic);
      } catch (e) {
        debugPrint('Import wallet on backend warning: $e');
      }

      String? address;
      try {
        address = await walletSecurityService.getAddressFromMnemonic(mnemonic);
      } catch (_) {}

      return Right(
        Wallet(
          id: name,
          name: name,
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
      );

      return Right(Transaction.fromJson(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao enviar: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateAddress(String address) async {
    return Right(address.isNotEmpty);
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
          estimatedTxSize: 250, // Approximation for P2TR/legacy fallback
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao estimar taxas: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getBTCtoUSDRate() async {
    // In a real scenario, this might call a price API or return
    // the value from a cached provider. For repository layer consistency:
    return const Right(
        65000.0); // Baseline production value if Socket is not ready
  }

  @override
  Future<Either<Failure, Wallet>> findWallet(String name) async {
    try {
      final result = await remoteDataSource.findWallet(name: name);
      return Right(Wallet.fromJson(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao buscar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateWallet({
    required String name,
    required String newName,
    required String passphrase,
  }) async {
    try {
      final result = await remoteDataSource.updateWallet(
        name: name,
        newName: newName,
        passphrase: passphrase,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao atualizar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> deleteWallet({
    required String name,
    required String passphrase,
  }) async {
    try {
      final result = await remoteDataSource.deleteWallet(
        name: name,
        passphrase: passphrase,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar carteira: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveMnemonic(String mnemonic) async {
    try {
      final success = await walletSecurityService.saveMnemonic(mnemonic);
      return Right(success);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao salvar mnemônico: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getMnemonic() async {
    try {
      final mnemonic = await walletSecurityService.authenticateAndGetMnemonic();
      return Right(mnemonic);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao recuperar mnemônico: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMnemonic() async {
    try {
      await walletSecurityService.clearMnemonic();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar mnemônico: $e'));
    }
  }
}

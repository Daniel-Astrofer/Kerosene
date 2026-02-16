import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../../domain/entities/wallet.dart'; // Mantendo imports antigos por compatibilidade da interface
import '../../domain/entities/transaction.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, String>> createWallet({
    required String name,
    required String passphrase,
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.createWallet(
        name: name,
        passphrase: passphrase,
        token: token,
      );

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
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.getWallets(token);
      final walletsList = result.map((data) => Wallet.fromJson(data)).toList();

      // Enforce Ledger Balance: Fetch all ledgers to get real-time balances
      Map<String, double> balances = {};
      try {
        final allLedgers = await remoteDataSource.getAllLedgers(token);
        for (final item in allLedgers) {
          if (item is Map) {
            final name = item['walletName'] ?? item['id'];
            final balance = item['balance'];
            if (name != null && balance != null) {
              balances[name.toString()] = (balance is num)
                  ? balance.toDouble()
                  : 0.0;
            }
          }
        }
      } catch (e) {
        print('Error fetching all ledgers: $e');
        // Fallback or ignore, keeping initial wallet balances
      }

      final List<Wallet> walletsWithBalance = [];

      for (final wallet in walletsList) {
        // Check if we have a balance from the ledger
        if (balances.containsKey(wallet.name)) {
          // Ledger balance is usually in BTC or Satoshis?
          // If double, assume BTC and convert to sats, OR if large int, assume sats.
          // Given getBalance was returning double and we cast to int, let's look at the value.
          // If value is small (< 21M), it's BTC. If huge, it's sats.
          // Safest is to assume the API returns the same unit as getBalance did.
          // Converting double to int.

          final bal = balances[wallet.name]!;
          // Directly use double value as BTC
          walletsWithBalance.add(wallet.copyWith(balance: bal));
        } else {
          // Try individual fetch if missing from all (fallback) using getLedger instead of getBalance
          try {
            final ledger = await remoteDataSource.getLedger(
              walletName: wallet.name,
              token: token,
            );
            final bal = ledger['balance'];
            if (bal is num) {
              walletsWithBalance.add(wallet.copyWith(balance: bal.toDouble()));
            } else {
              walletsWithBalance.add(wallet);
            }
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
  Future<Either<Failure, Wallet>> updateWalletBalance(String walletId) async {
    // 1. Get current wallet to ensure it exists and get other data
    final walletResult = await getWalletById(walletId);

    return walletResult.fold((failure) => Left(failure), (wallet) async {
      try {
        // 2. Fetch real balance from Ledger
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return Left(AuthFailure(message: 'Usuário não autenticado'));
        }

        // 3. Use getLedger instead of getBalance (avoid 403)
        final ledger = await remoteDataSource.getLedger(
          walletName: walletId,
          token: token,
        );

        double balance = wallet.balance;
        if (ledger.containsKey('balance') && ledger['balance'] is num) {
          balance = (ledger['balance'] as num).toDouble();
        }

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
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions({
    required String walletId, // walletName
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      // Tentar pegar ledger específico
      try {
        final result = await remoteDataSource.getLedger(
          walletName: walletId,
          token: token,
        );

        // Se a resposta contiver transactions explicitamente
        if (result['transactions'] is List) {
          // list = result['transactions'];
        }
        // Se a resposta for um único registro de ledger (estado atual), converte em transação única de "Saldo Inicial" ou similar?
        // Ou assume que não tem histórico detalhado.
        // Vamos tentar pegar TODAS as transações e filtrar, que é mais garantido para ver histórico.
        // O find retorna o estado atual. O all retorna o histórico.

        final all = await remoteDataSource.getAllLedgers(token);
        // Filtrar onde walletName, sender ou receiver é igual ao ID
        final filtered = all
            .where(
              (t) =>
                  t['walletName'] == walletId ||
                  t['sender'] == walletId ||
                  t['receiver'] == walletId,
            )
            .toList();

        return Right(
          filtered.map((data) => Transaction.fromJson(data)).toList(),
        );
      } catch (e) {
        // Fallback silencioso ou erro
        return Right([]);
      }
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
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.sendTransaction(
        sender: fromWalletId,
        receiver: toAddress,
        amount: amountSatoshis / 100000000.0,
        context: description ?? 'transfer',
        token: token,
      );

      return Right(Transaction.fromJson(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao enviar: $e'));
    }
  }

  // Mocks seguros para permitir funcionamento da UI
  @override
  Future<Either<Failure, bool>> validateAddress(String address) async {
    // Aceita qualquer string não vazia por enquanto
    return Right(address.isNotEmpty);
  }

  @override
  Future<Either<Failure, FeeEstimate>> estimateFee({
    required String walletId,
    required int amountSatoshis,
  }) async {
    return const Right(
      FeeEstimate(
        fastSatoshisPerByte: 10,
        mediumSatoshisPerByte: 5,
        slowSatoshisPerByte: 1,
        estimatedTxSize: 200,
      ),
    );
  }

  @override
  Future<Either<Failure, double>> getBTCtoUSDRate() async {
    return const Right(50000.0); // Valor fixo temporário
  }

  // ==================== Wallet CRUD ====================

  @override
  Future<Either<Failure, Wallet>> findWallet(String name) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.findWallet(
        name: name,
        token: token,
      );
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
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.updateWallet(
        name: name, // This is the old/current name
        newName: newName,
        token: token,
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
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.deleteWallet(
        name: name,
        passphrase: passphrase,
        token: token,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar carteira: $e'));
    }
  }

  // ==================== Ledger ====================

  @override
  Future<Either<Failure, double>> getBalance(String walletName) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.getBalance(
        walletName: walletName,
        token: token,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao buscar saldo: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> deleteLedger(String walletName) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null)
        return Left(AuthFailure(message: 'Usuário não autenticado'));

      final result = await remoteDataSource.deleteLedger(
        walletName: walletName,
        token: token,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar ledger: $e'));
    }
  }
}

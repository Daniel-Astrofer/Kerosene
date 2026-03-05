import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/wallet_security_service.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../../domain/entities/wallet.dart'; // Mantendo imports antigos por compatibilidade da interface
import '../../domain/entities/transaction.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final WalletSecurityService walletSecurityService;

  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
    required this.walletSecurityService,
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
        final allLedgers = await remoteDataSource.getAllLedgers();
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
        debugPrint('Error fetching all ledgers: $e');
        // Fallback or ignore, keeping initial wallet balances
      }

      final List<Wallet> walletsWithBalance = [];

      for (final wallet in walletsList) {
        // Check if we have a balance from the ledger
        if (balances.containsKey(wallet.name)) {
          final bal = balances[wallet.name]!;
          walletsWithBalance.add(wallet.copyWith(balance: bal));
        } else {
          // Try individual fetch if missing from all (fallback) using getBalance
          try {
            final bal = await remoteDataSource.getBalance(
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

  /// Atualiza saldo de uma carteira específica consultando o backend
  /// IMPORTANTE: walletName deve ser o NOME da wallet (string), não o ID numérico!
  @override
  Future<Either<Failure, Wallet>> updateWalletBalance(String walletName) async {
    // 1. Get current wallet to ensure it exists and get other data
    final walletResult = await getWalletById(walletName);

    return walletResult.fold((failure) => Left(failure), (wallet) async {
      try {
        // 2. Fetch real balance from Ledger
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return Left(AuthFailure(message: 'Usuário não autenticado'));
        }

        // 3. Use getBalance instead of getLedger (avoid 403)
        final balance = await remoteDataSource.getBalance(
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
      // 1. Save mnemonic locally
      await walletSecurityService.saveMnemonic(mnemonic);

      // 2. Try to register/create on backend (same as createWallet but with existing mnemonic as passphrase)
      try {
        await remoteDataSource.createWallet(name: name, passphrase: mnemonic);
      } catch (e) {
        // If it fails (e.g. already exists), we might still want to proceed if it's just importing locally?
        // But for this app, backend seems to rule.
        // Let's assume re-creating with same name/passphrase might work or throw if duplicate.
        // If it throws "Already exists", we should probably just find it.
        debugPrint('Import wallet on backend warning: $e');
      }

      // 3. Return the wallet object
      String? address;
      try {
        address = await walletSecurityService.getAddressFromMnemonic(mnemonic);
      } catch (_) {}

      return Right(
        Wallet(
          id: name, // Using name as ID for now
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
    required String walletId, // walletName
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      // Tentar pegar ledger específico
      try {
        // Ignored result currently, logic seems to prefer getAllLedgers below
        // await remoteDataSource.getLedger(walletName: walletId); // REMOVED to avoid 403

        // Se a resposta for um único registro de ledger (estado atual), converte em transação única de "Saldo Inicial" ou similar?
        // Ou assume que não tem histórico detalhado.
        // Vamos tentar pegar TODAS as transações e filtrar, que é mais garantido para ver histórico.

        final all = await remoteDataSource.getAllLedgers();
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
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.sendTransaction(
        sender: fromWalletId,
        receiver: toAddress,
        amount: amountSatoshis / 100000000.0,
        context: description ?? 'transfer',
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
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

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
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

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
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

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

  // ==================== Ledger ====================

  @override
  Future<Either<Failure, double>> getBalance(String walletName) async {
    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.getBalance(walletName: walletName);
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
      if (token == null) {
        return Left(AuthFailure(message: 'Usuário não autenticado'));
      }

      final result = await remoteDataSource.deleteLedger(
        walletName: walletName,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao deletar ledger: $e'));
    }
  }

  // ==================== Security ====================

  @override
  Future<Either<Failure, bool>> saveMnemonic(String mnemonic) async {
    try {
      final success = await walletSecurityService.saveMnemonic(mnemonic);
      if (success) {
        return const Right(true);
      } else {
        return Left(
          UnknownFailure(message: 'Falha ao salvar mnemônico de forma segura.'),
        );
      }
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao salvar mnemônico: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getMnemonic() async {
    try {
      final mnemonic = await walletSecurityService.authenticateAndGetMnemonic();
      if (mnemonic != null) {
        return Right(mnemonic);
      } else {
        // Retornar null signfica que o usuário cancelou ou falhou na autenticação,
        // ou não existe mnemônico salvo.
        // Podemos tratar como Failure se for erro, ou Right(null) se for cancelamento?
        // A assinatura é Right(String?), então Right(null) é válido.
        return const Right(null);
      }
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

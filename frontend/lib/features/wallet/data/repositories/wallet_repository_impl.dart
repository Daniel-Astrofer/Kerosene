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
      final wallets = result.map((data) => Wallet.fromJson(data)).toList();

      return Right(wallets);
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
    return getWalletById(walletId);
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

        List<dynamic> list = [];
        // Se a resposta contiver transactions explicitamente
        if (result['transactions'] is List) {
          list = result['transactions'];
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
        amount: amountSatoshis.toDouble(),
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
}

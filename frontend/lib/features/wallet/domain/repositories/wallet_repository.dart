import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';
import '../entities/transaction.dart';

/// Interface do repositório de carteiras
/// Define contratos para operações com carteiras Bitcoin/DeFi
abstract class WalletRepository {
  /// Obter todas as carteiras do usuário
  Future<Either<Failure, List<Wallet>>> getWallets();

  /// Obter carteira por ID
  Future<Either<Failure, Wallet>> getWalletById(String id);

  /// Criar nova carteira
  Future<Either<Failure, String>> createWallet({
    required String name,
    required String passphrase, // Mnemonic
  });

  /// Importar carteira existente via mnemonic
  Future<Either<Failure, Wallet>> importWallet({
    required String name,
    required String mnemonic,
    required WalletType type,
  });

  /// Atualizar saldo da carteira
  /// Consulta blockchain para obter saldo atualizado
  Future<Either<Failure, Wallet>> updateWalletBalance(String walletId);

  /// Obter transações de uma carteira
  Future<Either<Failure, List<Transaction>>> getTransactions({
    required String walletId,
    int? limit,
    int? offset,
  });

  /// Enviar Bitcoin
  /// Cria, assina e transmite transação para a rede
  Future<Either<Failure, Transaction>> sendBitcoin({
    required String fromWalletId,
    required String toAddress,
    required int amountSatoshis,
    required int feeSatoshis,
    String? description,
  });

  /// Estimar taxa de transação
  /// Retorna taxa recomendada em satoshis/byte para diferentes prioridades
  Future<Either<Failure, FeeEstimate>> estimateFee({
    required String walletId,
    required int amountSatoshis,
  });

  /// Validar endereço Bitcoin
  Future<Either<Failure, bool>> validateAddress(String address);

  /// Obter taxa de câmbio BTC/USD
  Future<Either<Failure, double>> getBTCtoUSDRate();
}

/// Estimativa de taxa de mineração
class FeeEstimate {
  /// Taxa para confirmação rápida (próximo bloco)
  final int fastSatoshisPerByte;

  /// Taxa para confirmação média (2-3 blocos)
  final int mediumSatoshisPerByte;

  /// Taxa para confirmação lenta (4-6 blocos)
  final int slowSatoshisPerByte;

  /// Tamanho estimado da transação em bytes
  final int estimatedTxSize;

  const FeeEstimate({
    required this.fastSatoshisPerByte,
    required this.mediumSatoshisPerByte,
    required this.slowSatoshisPerByte,
    required this.estimatedTxSize,
  });

  /// Calcula taxa total para prioridade rápida
  int get fastFeeSatoshis => fastSatoshisPerByte * estimatedTxSize;

  /// Calcula taxa total para prioridade média
  int get mediumFeeSatoshis => mediumSatoshisPerByte * estimatedTxSize;

  /// Calcula taxa total para prioridade lenta
  int get slowFeeSatoshis => slowSatoshisPerByte * estimatedTxSize;
}

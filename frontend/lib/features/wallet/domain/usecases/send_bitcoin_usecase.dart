import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../repositories/wallet_repository.dart';

/// Caso de uso: Enviar Bitcoin
/// Valida, cria, assina e transmite transação Bitcoin
class SendBitcoinUseCase {
  final WalletRepository repository;

  const SendBitcoinUseCase(this.repository);

  /// Executa envio de Bitcoin com validações de segurança
  Future<Either<Failure, Transaction>> call({
    required String fromWalletId,
    required String toAddress,
    required int amountSatoshis,
    required int feeSatoshis,
    String? description,
  }) async {
    // Validação 1: Valor mínimo (dust limit = 546 satoshis)
    if (amountSatoshis < 546) {
      return const Left(
        ValidationFailure(
          message: 'Valor mínimo é 546 satoshis (dust limit)',
        ),
      );
    }

    // Validação 2: Valor máximo razoável (21 milhões de BTC)
    if (amountSatoshis > 2100000000000000) {
      return const Left(
        ValidationFailure(
          message: 'Valor excede limite máximo de Bitcoin',
        ),
      );
    }

    // Validação 3: Taxa mínima (1 satoshi/byte)
    if (feeSatoshis < 250) {
      // Assumindo ~250 bytes para tx padrão
      return const Left(
        ValidationFailure(
          message: 'Taxa muito baixa, transação pode não ser confirmada',
        ),
      );
    }

    // Validação 4: Validar endereço de destino
    final addressValidation = await repository.validateAddress(toAddress);

    final isValidAddress = addressValidation.fold(
      (failure) => false,
      (isValid) => isValid,
    );

    if (!isValidAddress) {
      return const Left(
        ValidationFailure(
          message: 'Endereço Bitcoin inválido',
        ),
      );
    }

    // Validação 5: Verificar saldo suficiente
    final walletResult = await repository.getWalletById(fromWalletId);

    return await walletResult.fold(
      (failure) => Left(failure),
      (wallet) async {
        final totalRequired = amountSatoshis + feeSatoshis;

        if (wallet.balanceSatoshis < totalRequired) {
          return Left(
            ValidationFailure(
              message:
                  'Saldo insuficiente. Necessário: ${totalRequired / 100000000} BTC',
            ),
          );
        }

        // Todas as validações passaram, executar transação
        return await repository.sendBitcoin(
          fromWalletId: fromWalletId,
          toAddress: toAddress,
          amountSatoshis: amountSatoshis,
          feeSatoshis: feeSatoshis,
          description: description,
        );
      },
    );
  }
}

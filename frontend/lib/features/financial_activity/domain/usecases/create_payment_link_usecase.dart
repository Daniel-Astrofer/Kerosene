import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_link.dart';
import '../repositories/transaction_repository.dart';

class CreatePaymentLinkUseCase {
  final TransactionRepository repository;

  CreatePaymentLinkUseCase(this.repository);

  Future<Either<Failure, PaymentLink>> call({
    required double amount,
    required String receiverWalletName,
  }) async {
    try {
      final result = await repository.createPaymentLink(
        amount: amount,
        description: 'Recebimento $receiverWalletName',
        expiresInMinutes: 60,
        visibility: 'PRIVATE',
        confirmationMode: 'USER_ACTION_REQUIRED',
        amountLocked: true,
        referenceLabel: receiverWalletName,
        metadata: {
          'walletName': receiverWalletName,
          'rail': 'ONCHAIN',
          'source': 'receive_flow',
        },
      );

      return Right(result);
    } catch (error) {
      return Left(UnknownFailure(message: error.toString()));
    }
  }
}

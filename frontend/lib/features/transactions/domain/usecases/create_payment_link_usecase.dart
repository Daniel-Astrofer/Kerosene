import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/transaction_repository.dart';

class CreatePaymentLinkUseCase {
  final TransactionRepository repository;

  CreatePaymentLinkUseCase(this.repository);

  Future<Either<Failure, PaymentLink>> call({
    required double amount,
    required String receiverWalletName,
  }) async {
    try {
      final result = await repository.createPaymentRequest(
        amount: amount,
        receiverWalletName: receiverWalletName,
      );
      return Right(result);
    } catch (e) {
      return Left(
        UnknownFailure(message: 'Failed to create payment request: $e'),
      );
    }
  }
}

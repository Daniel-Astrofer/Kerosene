import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/transaction_repository.dart';

class CreatePaymentLinkUseCase {
  final TransactionRepository repository;

  CreatePaymentLinkUseCase(this.repository);

  Future<Either<Failure, PaymentLink>> call({
    required double amount,
    required String description,
  }) async {
    try {
      final result = await repository.createPaymentLink(
        amount: amount,
        description: description,
      );
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to create payment link: $e'));
    }
  }
}

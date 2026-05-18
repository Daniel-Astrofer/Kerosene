import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/repositories/ledger_repository.dart';

class CreatePaymentLinkUseCase {
  final LedgerRepository repository;

  CreatePaymentLinkUseCase(this.repository);

  Future<Either<Failure, PaymentLink>> call({
    required double amount,
    required String receiverWalletName,
  }) async {
    final result = await repository.createPaymentRequest(
      amount: amount,
      receiverWalletName: receiverWalletName,
    );

    return result.map((data) => PaymentLink.fromJson(data));
  }
}

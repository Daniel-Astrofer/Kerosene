import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../transactions/domain/entities/payment_link.dart';

abstract class VoucherRepository {
  Future<Either<Failure, Map<String, dynamic>>> requestVoucher();
  Future<Either<Failure, Map<String, dynamic>>> confirmVoucher(String pendingVoucherId, String txid);
  Future<Either<Failure, PaymentLink>> getOnboardingLink(String sessionId);
  Future<Either<Failure, PaymentLink>> getOnboardingLinkStatus(String linkId);
  Future<Either<Failure, PaymentLink>> confirmOnboardingPayment({
    required String linkId,
    required String txid,
    String? fromAddress,
  });
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId);
}

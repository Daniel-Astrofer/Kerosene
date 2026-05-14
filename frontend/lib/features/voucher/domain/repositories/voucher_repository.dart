import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class VoucherRepository {
  Future<Either<Failure, Map<String, dynamic>>> requestVoucher();
  Future<Either<Failure, Map<String, dynamic>>> confirmVoucher(String pendingVoucherId, String txid);
  Future<Either<Failure, String>> getOnboardingLink(String sessionId);
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId);
}

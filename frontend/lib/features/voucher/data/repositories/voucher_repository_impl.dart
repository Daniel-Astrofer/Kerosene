import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/voucher_remote_datasource.dart';
import '../../domain/repositories/voucher_repository.dart';
import '../../../transactions/domain/entities/payment_link.dart';

class VoucherRepositoryImpl implements VoucherRepository {
  final VoucherRemoteDataSource remoteDataSource;

  VoucherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> requestVoucher() async {
    try {
      final result = await remoteDataSource.requestVoucher();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> confirmVoucher(
    String pendingVoucherId,
    String txid,
  ) async {
    try {
      final result = await remoteDataSource.confirmVoucher(pendingVoucherId, txid);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentLink>> getOnboardingLink(String sessionId) async {
    try {
      final result = await remoteDataSource.getOnboardingLink(sessionId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentLink>> getOnboardingLinkStatus(
    String linkId,
  ) async {
    try {
      final result = await remoteDataSource.getOnboardingLinkStatus(linkId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentLink>> confirmOnboardingPayment({
    required String linkId,
    required String txid,
    String? fromAddress,
  }) async {
    try {
      final result = await remoteDataSource.confirmOnboardingPayment(
        linkId: linkId,
        txid: txid,
        fromAddress: fromAddress,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId) async {
    try {
      await remoteDataSource.mockConfirmOnboarding(sessionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

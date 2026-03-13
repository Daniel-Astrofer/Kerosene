import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class GetDepositAddressUseCase {
  final TransactionRepository repository;

  GetDepositAddressUseCase(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.getDepositAddress();
  }
}

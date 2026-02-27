import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> registerToken(String token);
}

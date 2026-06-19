import 'package:dartz/dartz.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<SessionNotificationItem>>>
      getNotifications() async {
    try {
      final items = await remoteDataSource.getNotifications();
      return Right(items);
    } on AppException catch (error) {
      return Left(ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        data: error.data,
      ));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } on AppException catch (error) {
      return Left(ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        data: error.data,
      ));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      await remoteDataSource.registerDeviceToken(
        platform: platform,
        token: token,
        deviceId: deviceId,
        appVersion: appVersion,
      );
      return const Right(null);
    } on AppException catch (error) {
      return Left(ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        data: error.data,
      ));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DeviceToken>>> activeDeviceTokens() async {
    try {
      final tokens = await remoteDataSource.activeDeviceTokens();
      return Right(tokens);
    } on AppException catch (error) {
      return Left(ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        data: error.data,
      ));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeDeviceToken(String tokenId) async {
    try {
      await remoteDataSource.revokeDeviceToken(tokenId);
      return const Right(null);
    } on AppException catch (error) {
      return Left(ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        data: error.data,
      ));
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<SessionNotificationItem>>> getNotifications();

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Future<Either<Failure, void>> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  });

  Future<Either<Failure, List<DeviceToken>>> activeDeviceTokens();

  Future<Either<Failure, void>> revokeDeviceToken(String tokenId);
}

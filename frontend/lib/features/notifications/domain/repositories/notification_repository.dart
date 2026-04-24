import 'package:dartz/dartz.dart';
import 'package:teste/core/errors/failures.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<SessionNotificationItem>>> getNotifications();

  Future<Either<Failure, void>> markAsRead(String notificationId);
}

import 'package:flutter/foundation.dart';
import '../domain/repositories/notification_repository.dart';
import '../../../../core/services/notification_service.dart'
    as local_notifications;

class NotificationService {
  final NotificationRepository repository;

  NotificationService(this.repository);

  Future<void> initializeAndRegister() async {
    try {
      // Firebase removed
      debugPrint('🔔 Local notifications only now.');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }
}

import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/errors/exceptions.dart';
import 'package:teste/core/network/api_client.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';

abstract class NotificationRemoteDataSource {
  Future<List<SessionNotificationItem>> getNotifications();
  Future<void> markAsRead(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<SessionNotificationItem>> getNotifications() async {
    try {
      final response = await apiClient.get(AppConfig.notificationsList);
      final body = response.data;

      if (body is! List) {
        return const [];
      }

      return body
          .whereType<Map>()
          .map((item) => SessionNotificationItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ServerException(message: 'Erro ao carregar notificações: $error');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await apiClient.put(
        AppConfig.notificationsRead.replaceFirst('{id}', notificationId),
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ServerException(message: 'Erro ao marcar notificação como lida: $error');
    }
  }
}

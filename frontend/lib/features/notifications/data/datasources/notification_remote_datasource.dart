import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/errors/exceptions.dart';
import 'package:teste/core/network/api_client.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';

abstract class NotificationRemoteDataSource {
  Future<List<SessionNotificationItem>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  });
  Future<void> revokeDeviceToken(String tokenId);
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
      throw ServerException(
          message: 'Erro ao marcar notificação como lida: $error');
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      await apiClient.post(
        AppConfig.notificationRegisterToken,
        data: {
          'platform': platform,
          'token': token,
          if (deviceId != null) 'deviceId': deviceId,
          if (appVersion != null) 'appVersion': appVersion,
        },
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ServerException(
          message: 'Erro ao registrar token de notificação: $error');
    }
  }

  @override
  Future<void> revokeDeviceToken(String tokenId) async {
    try {
      await apiClient.delete('/notifications/device-tokens/$tokenId');
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ServerException(
          message: 'Erro ao revogar token de notificação: $error');
    }
  }
}

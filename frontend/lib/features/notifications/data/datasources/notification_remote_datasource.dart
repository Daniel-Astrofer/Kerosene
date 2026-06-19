import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';

abstract class NotificationRemoteDataSource {
  Future<List<SessionNotificationItem>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> registerDeviceToken({
    required String platform,
    required String token,
    String? deviceId,
    String? appVersion,
  });
  Future<List<DeviceToken>> activeDeviceTokens();
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
        throw ServerException(
          message: 'Resposta inesperada ao carregar notificações.',
          errorCode: 'ERR_NOTIFICATIONS_INVALID_RESPONSE',
          data: body,
        );
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
  Future<List<DeviceToken>> activeDeviceTokens() async {
    try {
      final response = await apiClient.get(AppConfig.notificationDeviceTokens);
      final body = response.data;
      if (body is! List) {
        throw ServerException(
          message:
              'Resposta inesperada ao carregar dispositivos de notificação.',
          errorCode: 'ERR_NOTIFICATION_DEVICES_INVALID_RESPONSE',
          data: body,
        );
      }
      return body
          .whereType<Map>()
          .map((item) => DeviceToken.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      if (error is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao carregar dispositivos de notificação: $error',
      );
    }
  }

  @override
  Future<void> revokeDeviceToken(String tokenId) async {
    try {
      await apiClient.delete(AppConfig.notificationDeviceToken(tokenId));
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ServerException(
          message: 'Erro ao revogar token de notificação: $error');
    }
  }
}

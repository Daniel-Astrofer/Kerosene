import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class NotificationRemoteDataSource {
  Future<void> registerToken(String token);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> registerToken(String token) async {
    try {
      // The backend expects the token in the body: { "token": "..." }
      // Headers (X-Device-Hash) are handled by TokenInterceptor.
      await apiClient.post(
        AppConfig.notificationRegisterToken,
        data: {'token': token},
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao registrar token FCM: $e');
    }
  }
}

import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/auth_local_datasource.dart';

class TokenInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  TokenInterceptor({required this.localDataSource, required this.apiClient});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final newToken = response.headers.value(AppConfig.newTokenHeader);

    if (newToken != null && newToken.isNotEmpty) {
      print('🔄 JWT Renewal: New token received in header');

      // Save to local storage
      await localDataSource.saveToken(newToken);

      // Update ApiClient for future requests
      apiClient.setAuthToken(newToken);
    }

    super.onResponse(response, handler);
  }
}

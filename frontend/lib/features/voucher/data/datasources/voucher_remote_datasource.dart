import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';

abstract class VoucherRemoteDataSource {
  Future<Map<String, dynamic>> requestVoucher();
  Future<Map<String, dynamic>> confirmVoucher(
      String pendingVoucherId, String txid);
  Future<String> getOnboardingLink(String sessionId);
  Future<void> mockConfirmOnboarding(String sessionId);
  Future<Map<String, dynamic>> testClaimVoucher(String username);
}

class VoucherRemoteDataSourceImpl implements VoucherRemoteDataSource {
  final ApiClient apiClient;

  VoucherRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> requestVoucher() async {
    final response = await apiClient.post(AppConfig.voucherRequest, data: {});
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> confirmVoucher(
      String pendingVoucherId, String txid) async {
    final response = await apiClient.post(
      AppConfig.voucherConfirm,
      queryParameters: {
        'pendingVoucherId': pendingVoucherId,
        'txid': txid,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<String> getOnboardingLink(String sessionId) async {
    final response = await apiClient.post(
      AppConfig.voucherOnboardingLink,
      queryParameters: {'sessionId': sessionId},
    );
    return response.data.toString();
  }

  @override
  Future<void> mockConfirmOnboarding(String sessionId) async {
    await apiClient.post(
      AppConfig.voucherOnboardingMockConfirm,
      queryParameters: {'sessionId': sessionId},
    );
  }

  @override
  Future<Map<String, dynamic>> testClaimVoucher(String username) async {
    final response = await apiClient.post(
      AppConfig.voucherTestClaim,
      queryParameters: {'username': username},
    );
    return response.data is Map<String, dynamic>
        ? response.data
        : {'message': response.data.toString()};
  }
}

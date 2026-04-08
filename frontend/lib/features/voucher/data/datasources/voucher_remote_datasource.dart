import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../transactions/domain/entities/payment_link.dart';

abstract class VoucherRemoteDataSource {
  Future<Map<String, dynamic>> requestVoucher();
  Future<Map<String, dynamic>> confirmVoucher(String pendingVoucherId, String txid);
  Future<PaymentLink> getOnboardingLink(String sessionId);
  Future<PaymentLink> getOnboardingLinkStatus(String linkId);
  Future<PaymentLink> confirmOnboardingPayment({
    required String linkId,
    required String txid,
    String? fromAddress,
  });
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
  Future<Map<String, dynamic>> confirmVoucher(String pendingVoucherId, String txid) async {
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
  Future<PaymentLink> getOnboardingLink(String sessionId) async {
    final response = await apiClient.post(
      AppConfig.voucherOnboardingLink,
      queryParameters: {'sessionId': sessionId},
    );
    return PaymentLink.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<PaymentLink> getOnboardingLinkStatus(String linkId) async {
    final path = AppConfig.voucherOnboardingLinkStatus.replaceFirst(
      '{linkId}',
      linkId,
    );
    final response = await apiClient.get(path);
    return PaymentLink.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<PaymentLink> confirmOnboardingPayment({
    required String linkId,
    required String txid,
    String? fromAddress,
  }) async {
    final path = AppConfig.voucherOnboardingLinkConfirm.replaceFirst(
      '{linkId}',
      linkId,
    );
    final response = await apiClient.post(
      path,
      data: {
        'txid': txid,
        'fromAddress': fromAddress,
      },
    );
    return PaymentLink.fromJson(Map<String, dynamic>.from(response.data as Map));
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

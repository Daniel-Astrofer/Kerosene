import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/features/payments/domain/payment_intent_models.dart';

abstract class PaymentIntentService {
  Future<ReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  );

  Future<PaymentQuote> quote(PaymentQuoteDraft draft);

  Future<PaymentStatus> confirm({
    required String paymentIntentId,
    required String idempotencyKey,
    required int acceptedTotalDebitSats,
    required int acceptedReceiverAmountSats,
    String? userConfirmationToken,
  });

  Future<PaymentStatus> status(String paymentIntentId);
}

class RemotePaymentIntentService implements PaymentIntentService {
  final ApiClient _api;

  const RemotePaymentIntentService(this._api);

  @override
  Future<ReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  ) async {
    final response = await _api.get(
      AppConfig.paymentReceivingCapabilities(receiverIdentifier),
    );
    return ReceivingCapabilities.fromJson(_mapFrom(response.data));
  }

  @override
  Future<PaymentQuote> quote(PaymentQuoteDraft draft) async {
    final response = await _api.post(
      AppConfig.paymentsQuote,
      data: draft.toJson(),
    );
    return PaymentQuote.fromJson(_mapFrom(response.data));
  }

  @override
  Future<PaymentStatus> confirm({
    required String paymentIntentId,
    required String idempotencyKey,
    required int acceptedTotalDebitSats,
    required int acceptedReceiverAmountSats,
    String? userConfirmationToken,
  }) async {
    final response = await _api.post(
      AppConfig.paymentsConfirm(paymentIntentId),
      data: {
        'idempotencyKey': idempotencyKey,
        if (userConfirmationToken?.trim().isNotEmpty == true)
          'userConfirmationToken': userConfirmationToken!.trim(),
        'acceptedTotalDebitSats': acceptedTotalDebitSats,
        'acceptedReceiverAmountSats': acceptedReceiverAmountSats,
      },
    );
    return PaymentStatus.fromJson(_mapFrom(response.data));
  }

  @override
  Future<PaymentStatus> status(String paymentIntentId) async {
    final response = await _api.get(AppConfig.paymentsStatus(paymentIntentId));
    return PaymentStatus.fromJson(_mapFrom(response.data));
  }
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

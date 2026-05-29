import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/payments/data/payment_intent_service.dart';
import 'package:kerosene/features/payments/domain/payment_intent_models.dart';

final paymentIntentServiceProvider = Provider<PaymentIntentService>((ref) {
  return RemotePaymentIntentService(ref.watch(apiClientProvider));
});

final paymentIntentFlowProvider =
    NotifierProvider<PaymentIntentFlowController, PaymentIntentFlowState>(
  PaymentIntentFlowController.new,
);

enum PaymentIntentFlowError {
  receiverRequired,
  amountRequired,
}

class PaymentIntentFlowState {
  final String receiverIdentifier;
  final String amountFiat;
  final PaymentRail selectedRail;
  final PaymentFeeMode feeMode;
  final OnchainSpeed onchainSpeed;
  final ReceivingCapabilities? capabilities;
  final PaymentQuote? quote;
  final PaymentStatus? status;
  final bool isLoadingCapabilities;
  final bool isQuoting;
  final bool isConfirming;
  final String? errorMessage;
  final PaymentIntentFlowError? errorKey;

  const PaymentIntentFlowState({
    this.receiverIdentifier = '',
    this.amountFiat = '',
    this.selectedRail = PaymentRail.internal,
    this.feeMode = PaymentFeeMode.senderPays,
    this.onchainSpeed = OnchainSpeed.normal,
    this.capabilities,
    this.quote,
    this.status,
    this.isLoadingCapabilities = false,
    this.isQuoting = false,
    this.isConfirming = false,
    this.errorMessage,
    this.errorKey,
  });

  bool get hasQuote => quote != null;
  bool get hasTerminalStatus => status?.status.isTerminal ?? false;

  PaymentIntentFlowState copyWith({
    String? receiverIdentifier,
    String? amountFiat,
    PaymentRail? selectedRail,
    PaymentFeeMode? feeMode,
    OnchainSpeed? onchainSpeed,
    ReceivingCapabilities? capabilities,
    bool clearCapabilities = false,
    PaymentQuote? quote,
    bool clearQuote = false,
    PaymentStatus? status,
    bool clearStatus = false,
    bool? isLoadingCapabilities,
    bool? isQuoting,
    bool? isConfirming,
    String? errorMessage,
    PaymentIntentFlowError? errorKey,
    bool clearError = false,
  }) {
    return PaymentIntentFlowState(
      receiverIdentifier: receiverIdentifier ?? this.receiverIdentifier,
      amountFiat: amountFiat ?? this.amountFiat,
      selectedRail: selectedRail ?? this.selectedRail,
      feeMode: feeMode ?? this.feeMode,
      onchainSpeed: onchainSpeed ?? this.onchainSpeed,
      capabilities:
          clearCapabilities ? null : capabilities ?? this.capabilities,
      quote: clearQuote ? null : quote ?? this.quote,
      status: clearStatus ? null : status ?? this.status,
      isLoadingCapabilities:
          isLoadingCapabilities ?? this.isLoadingCapabilities,
      isQuoting: isQuoting ?? this.isQuoting,
      isConfirming: isConfirming ?? this.isConfirming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorKey: clearError ? null : errorKey ?? this.errorKey,
    );
  }
}

class PaymentIntentFlowController extends Notifier<PaymentIntentFlowState> {
  late final PaymentIntentService _service;
  static const _uuid = Uuid();

  @override
  PaymentIntentFlowState build() {
    _service = ref.watch(paymentIntentServiceProvider);
    return const PaymentIntentFlowState();
  }

  void setRecipient(String value) {
    state = state.copyWith(
      receiverIdentifier: value,
      clearCapabilities: true,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );
  }

  void setAmountFiat(String value) {
    state = state.copyWith(
      amountFiat: value,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );
  }

  void setRail(PaymentRail rail) {
    state = state.copyWith(
      selectedRail: rail,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );
  }

  void setFeeMode(PaymentFeeMode mode) {
    state = state.copyWith(
      feeMode: mode,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );
  }

  void setOnchainSpeed(OnchainSpeed speed) {
    state = state.copyWith(
      onchainSpeed: speed,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );
  }

  Future<void> loadCapabilities() async {
    final receiver = state.receiverIdentifier.trim();
    if (receiver.isEmpty) {
      state = state.copyWith(
        errorKey: PaymentIntentFlowError.receiverRequired,
      );
      return;
    }

    state = state.copyWith(
      isLoadingCapabilities: true,
      clearCapabilities: true,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );

    try {
      final capabilities = await _service.receivingCapabilities(receiver);
      final preferred = capabilities.availableRails.contains(
        capabilities.preferredRail,
      )
          ? capabilities.preferredRail
          : capabilities.availableRails.isEmpty
              ? state.selectedRail
              : capabilities.availableRails.first;
      state = state.copyWith(
        capabilities: capabilities,
        selectedRail: preferred,
        isLoadingCapabilities: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCapabilities: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> requestQuote() async {
    final amount = state.amountFiat.trim().replaceAll(',', '.');
    if (amount.isEmpty) {
      state = state.copyWith(
        errorKey: PaymentIntentFlowError.amountRequired,
      );
      return;
    }

    state = state.copyWith(
      isQuoting: true,
      clearQuote: true,
      clearStatus: true,
      clearError: true,
    );

    try {
      final quote = await _service.quote(
        PaymentQuoteDraft(
          rail: state.selectedRail,
          feeMode: state.feeMode,
          amountFiat: amount,
          receiverIdentifier: state.receiverIdentifier.trim(),
          speed: state.selectedRail == PaymentRail.onchain
              ? state.onchainSpeed
              : null,
        ),
      );
      state = state.copyWith(quote: quote, isQuoting: false);
    } catch (error) {
      state = state.copyWith(
        isQuoting: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> confirmQuote() async {
    final quote = state.quote;
    if (quote == null) return;

    state = state.copyWith(isConfirming: true, clearError: true);

    try {
      final status = await _service.confirm(
        paymentIntentId: quote.paymentIntentId,
        idempotencyKey: _uuid.v4(),
        acceptedTotalDebitSats: quote.totalDebitSats,
        acceptedReceiverAmountSats: quote.receiverAmountSats,
      );
      state = state.copyWith(status: status, isConfirming: false);
    } catch (error) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refreshStatus() async {
    final intentId =
        state.quote?.paymentIntentId ?? state.status?.paymentIntentId;
    if (intentId == null || intentId.trim().isEmpty) return;

    try {
      final status = await _service.status(intentId);
      state = state.copyWith(status: status, clearError: true);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }
}

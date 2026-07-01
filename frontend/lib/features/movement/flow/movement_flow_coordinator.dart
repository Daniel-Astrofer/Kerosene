import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'package:kerosene/features/movement/screens/send_destination_models.dart';

enum MovementFlowSurface { activity, receive, send }

enum MovementRail { internal, onchain, lightning, paymentLink, nfc, onramp }

enum MovementReceiveWalletKind { internal, custodialOnchain, coldWallet }

enum MovementReceiveActionKind { gateway, p2p, qrCode, paymentLink, nfc }

class MovementReceiveAction {
  final MovementReceiveActionKind kind;
  final MovementRail rail;
  final ReceiveAmountMethod? receiveMethod;
  final bool opensGateway;

  const MovementReceiveAction({
    required this.kind,
    required this.rail,
    this.receiveMethod,
    this.opensGateway = false,
  });
}

class MovementFlowState {
  final MovementFlowSurface surface;
  final Wallet? selectedWallet;
  final MovementReceiveWalletKind? receiveWalletKind;
  final ReceiveAmountMethod? receiveMethod;
  final List<MovementReceiveAction> receiveActions;
  final String amountInput;
  final int paymentLinkExpiresInMinutes;
  final SendDestinationAnalysis? sendDestination;

  const MovementFlowState({
    this.surface = MovementFlowSurface.activity,
    this.selectedWallet,
    this.receiveWalletKind,
    this.receiveMethod,
    this.receiveActions = const [],
    this.amountInput = '0',
    this.paymentLinkExpiresInMinutes = 15,
    this.sendDestination,
  });

  double get amountBtc => MoneyDisplay.parseEditableInput(amountInput);

  MovementFlowState copyWith({
    MovementFlowSurface? surface,
    Wallet? selectedWallet,
    MovementReceiveWalletKind? receiveWalletKind,
    ReceiveAmountMethod? receiveMethod,
    List<MovementReceiveAction>? receiveActions,
    String? amountInput,
    int? paymentLinkExpiresInMinutes,
    SendDestinationAnalysis? sendDestination,
  }) {
    return MovementFlowState(
      surface: surface ?? this.surface,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      receiveWalletKind: receiveWalletKind ?? this.receiveWalletKind,
      receiveMethod: receiveMethod ?? this.receiveMethod,
      receiveActions: receiveActions ?? this.receiveActions,
      amountInput: amountInput ?? this.amountInput,
      paymentLinkExpiresInMinutes:
          paymentLinkExpiresInMinutes ?? this.paymentLinkExpiresInMinutes,
      sendDestination: sendDestination ?? this.sendDestination,
    );
  }
}

class MovementFlowCoordinator extends Notifier<MovementFlowState> {
  @override
  MovementFlowState build() => const MovementFlowState();

  void configureReceive({
    required Wallet wallet,
    required ReceiveAmountMethod method,
    required bool nfcCompatible,
  }) {
    state = state.copyWith(
      surface: MovementFlowSurface.receive,
      selectedWallet: wallet,
      receiveWalletKind: classifyReceiveWallet(wallet),
      receiveMethod: method,
      receiveActions: availableReceiveActions(
        wallet: wallet,
        nfcCompatible: nfcCompatible,
      ),
      amountInput: '0',
      paymentLinkExpiresInMinutes: 15,
    );
  }

  void applyAmountKey(String key) {
    final next = state.amountInput == '0' && key == '0'
        ? '0.'
        : MoneyDisplay.applyKeypadInput(
            currentValue: state.amountInput,
            key: key,
            currency: Currency.btc,
            maxLength: 16,
          );
    state = state.copyWith(amountInput: next);
  }

  void setAmountInput(String value) {
    state = state.copyWith(amountInput: value.trim().isEmpty ? '0' : value);
  }

  void selectPaymentLinkExpiration(int minutes) {
    state = state.copyWith(paymentLinkExpiresInMinutes: minutes);
  }

  void updateSendDestination(SendDestinationAnalysis destination) {
    state = state.copyWith(
      surface: MovementFlowSurface.send,
      sendDestination: destination,
    );
  }
}

final movementFlowCoordinatorProvider =
    NotifierProvider<MovementFlowCoordinator, MovementFlowState>(
  MovementFlowCoordinator.new,
);

MovementReceiveWalletKind classifyReceiveWallet(Wallet wallet) {
  final mode = wallet.walletMode.trim().toUpperCase();
  if (wallet.isSelfCustody ||
      mode.contains('COLD') ||
      mode.contains('WATCH_ONLY')) {
    return MovementReceiveWalletKind.coldWallet;
  }
  if (mode.contains('ONCHAIN') || mode.contains('ON_CHAIN')) {
    return MovementReceiveWalletKind.custodialOnchain;
  }
  return MovementReceiveWalletKind.internal;
}

bool isReceiveOnChainWallet(Wallet wallet) {
  return classifyReceiveWallet(wallet) != MovementReceiveWalletKind.internal;
}

List<MovementReceiveAction> availableReceiveActions({
  required Wallet? wallet,
  required bool nfcCompatible,
}) {
  final kind = wallet == null
      ? MovementReceiveWalletKind.internal
      : classifyReceiveWallet(wallet);
  final isInternal = kind == MovementReceiveWalletKind.internal;

  return [
    if (isInternal)
      const MovementReceiveAction(
        kind: MovementReceiveActionKind.gateway,
        rail: MovementRail.onramp,
        opensGateway: true,
      ),
    if (isInternal)
      const MovementReceiveAction(
        kind: MovementReceiveActionKind.p2p,
        rail: MovementRail.internal,
        receiveMethod: ReceiveAmountMethod.p2p,
      ),
    MovementReceiveAction(
      kind: MovementReceiveActionKind.qrCode,
      rail: isInternal ? MovementRail.internal : MovementRail.onchain,
      receiveMethod: ReceiveAmountMethod.qrCode,
    ),
    const MovementReceiveAction(
      kind: MovementReceiveActionKind.paymentLink,
      rail: MovementRail.paymentLink,
      receiveMethod: ReceiveAmountMethod.paymentLink,
    ),
    if (isInternal && nfcCompatible)
      const MovementReceiveAction(
        kind: MovementReceiveActionKind.nfc,
        rail: MovementRail.nfc,
        receiveMethod: ReceiveAmountMethod.nfc,
      ),
  ];
}

MovementRail railForReceiveMethod({
  required ReceiveAmountMethod method,
  required bool onChainWallet,
}) {
  return switch (method) {
    ReceiveAmountMethod.p2p => MovementRail.internal,
    ReceiveAmountMethod.nfc => MovementRail.nfc,
    ReceiveAmountMethod.paymentLink => MovementRail.paymentLink,
    ReceiveAmountMethod.qrCode =>
      onChainWallet ? MovementRail.onchain : MovementRail.internal,
  };
}

MovementRail railForSendDestination(SendDestinationAnalysis destination) {
  if (destination.isPaymentLink) return MovementRail.paymentLink;
  if (destination.isLightning) return MovementRail.lightning;
  if (destination.isOnChain) return MovementRail.onchain;
  return MovementRail.internal;
}

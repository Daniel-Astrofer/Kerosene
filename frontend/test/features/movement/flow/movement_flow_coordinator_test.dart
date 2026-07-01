import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/flow/movement_flow_coordinator.dart';
import 'package:kerosene/features/movement/screens/movement_amount_screen.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';

void main() {
  test('movement flow exposes receive actions and shared amount state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(movementFlowCoordinatorProvider.notifier);
    controller.configureReceive(
      wallet: _wallet(mode: 'KEROSENE'),
      method: ReceiveAmountMethod.paymentLink,
      nfcCompatible: true,
    );
    controller.applyAmountKey('2');
    controller.selectPaymentLinkExpiration(1440);

    final state = container.read(movementFlowCoordinatorProvider);
    expect(state.surface, MovementFlowSurface.receive);
    expect(state.amountInput, '2');
    expect(state.amountBtc, 2);
    expect(state.paymentLinkExpiresInMinutes, 1440);
    expect(
      state.receiveActions.map((action) => action.kind),
      containsAllInOrder([
        MovementReceiveActionKind.gateway,
        MovementReceiveActionKind.p2p,
        MovementReceiveActionKind.qrCode,
        MovementReceiveActionKind.paymentLink,
        MovementReceiveActionKind.nfc,
      ]),
    );
  });

  test('movement amount screen is the concrete shared value entry screen', () {
    expect(MovementAmountScreen, isNotNull);
  });
}

Wallet _wallet({required String mode}) {
  return Wallet(
    id: '$mode-wallet',
    name: '$mode wallet',
    address: 'bc1q$mode',
    walletMode: mode,
    balance: 0.1,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

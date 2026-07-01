import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/flow/movement_flow_coordinator.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';

void main() {
  test('classifies receive wallets and exposes available receive actions', () {
    final internalActions = availableReceiveActions(
      wallet: _wallet(mode: 'KEROSENE'),
      nfcCompatible: true,
    );

    expect(
      classifyReceiveWallet(_wallet(mode: 'KEROSENE')),
      MovementReceiveWalletKind.internal,
    );
    expect(
      classifyReceiveWallet(_wallet(mode: 'CUSTODIAL_ONCHAIN')),
      MovementReceiveWalletKind.custodialOnchain,
    );
    expect(
      classifyReceiveWallet(_wallet(mode: 'SELF_CUSTODY')),
      MovementReceiveWalletKind.coldWallet,
    );
    expect(
      internalActions.map((action) => action.kind),
      containsAllInOrder([
        MovementReceiveActionKind.gateway,
        MovementReceiveActionKind.p2p,
        MovementReceiveActionKind.qrCode,
        MovementReceiveActionKind.paymentLink,
        MovementReceiveActionKind.nfc,
      ]),
    );

    final onchainActions = availableReceiveActions(
      wallet: _wallet(mode: 'CUSTODIAL_ONCHAIN'),
      nfcCompatible: true,
    );

    expect(
      onchainActions.map((action) => action.kind),
      [
        MovementReceiveActionKind.qrCode,
        MovementReceiveActionKind.paymentLink,
      ],
    );
  });

  test('keeps receive amount and payment link expiration in reactive state',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(movementFlowCoordinatorProvider.notifier);
    controller.configureReceive(
      wallet: _wallet(mode: 'KEROSENE'),
      method: ReceiveAmountMethod.paymentLink,
      nfcCompatible: true,
    );
    controller.applyAmountKey('1');
    controller.selectPaymentLinkExpiration(15);

    final state = container.read(movementFlowCoordinatorProvider);

    expect(state.surface, MovementFlowSurface.receive);
    expect(state.receiveMethod, ReceiveAmountMethod.paymentLink);
    expect(state.amountInput, '1');
    expect(state.amountBtc, 1);
    expect(state.paymentLinkExpiresInMinutes, 15);
    expect(
        state.receiveActions.map((action) => action.kind),
        contains(
          MovementReceiveActionKind.nfc,
        ));
  });

  test('resets receive draft when a new receive flow starts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(movementFlowCoordinatorProvider.notifier);
    controller.configureReceive(
      wallet: _wallet(mode: 'KEROSENE'),
      method: ReceiveAmountMethod.paymentLink,
      nfcCompatible: true,
    );
    controller.applyAmountKey('1');
    controller.selectPaymentLinkExpiration(1440);

    controller.configureReceive(
      wallet: _wallet(mode: 'CUSTODIAL_ONCHAIN'),
      method: ReceiveAmountMethod.qrCode,
      nfcCompatible: false,
    );

    final state = container.read(movementFlowCoordinatorProvider);
    expect(state.amountInput, '0');
    expect(state.amountBtc, 0);
    expect(state.paymentLinkExpiresInMinutes, 15);
    expect(state.receiveMethod, ReceiveAmountMethod.qrCode);
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

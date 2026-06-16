import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/widgets/wallet_flow_selector.dart';

import '../storybook_mocks.dart';

enum WalletFlowSelectorStoryMode {
  send,
  receive,
  deposit,
  withdraw,
}

extension WalletFlowSelectorStoryModeX on WalletFlowSelectorStoryMode {
  String get label {
    return switch (this) {
      WalletFlowSelectorStoryMode.send => 'Send',
      WalletFlowSelectorStoryMode.receive => 'Receive',
      WalletFlowSelectorStoryMode.deposit => 'Deposit',
      WalletFlowSelectorStoryMode.withdraw => 'Withdraw',
    };
  }

  String title(BuildContext context) {
    return switch (this) {
      WalletFlowSelectorStoryMode.send => context.tr.send,
      WalletFlowSelectorStoryMode.receive => context.tr.receive,
      WalletFlowSelectorStoryMode.deposit => context.tr.depositFlowDepositTitle,
      WalletFlowSelectorStoryMode.withdraw => context.tr.withdrawExternalBtc,
    };
  }

  String subtitle(BuildContext context) {
    return switch (this) {
      WalletFlowSelectorStoryMode.send => context.tr.walletSelectorSendSubtitle,
      WalletFlowSelectorStoryMode.receive =>
        context.tr.walletSelectorReceiveSubtitle,
      WalletFlowSelectorStoryMode.deposit =>
        context.tr.walletSelectorDepositSubtitle,
      WalletFlowSelectorStoryMode.withdraw =>
        context.tr.walletSelectorWithdrawSubtitle,
    };
  }
}

List<Story> walletFlowStories() {
  return [
    Story(
      name: 'Wallet/Flow Selector',
      builder: (context) {
        final mode = context.knobs.options(
          label: 'Flow',
          initial: WalletFlowSelectorStoryMode.send,
          options: [
            for (final mode in WalletFlowSelectorStoryMode.values)
              Option(label: mode.label, value: mode),
          ],
        );
        final initialWalletId = context.knobs.options(
          label: 'Initial wallet',
          initial: mockWallets.first.id,
          options: [
            for (final wallet in mockWallets)
              Option(label: wallet.name, value: wallet.id),
          ],
        );
        final initialWallet = mockWallets.firstWhere(
          (wallet) => wallet.id == initialWalletId,
          orElse: () => mockWallets.first,
        );

        return WalletFlowSelectorStoryPreview(
          mode: mode,
          initialWallet: initialWallet,
        );
      },
    ),
  ];
}

class WalletFlowSelectorStoryPreview extends StatelessWidget {
  final WalletFlowSelectorStoryMode mode;
  final Wallet initialWallet;

  const WalletFlowSelectorStoryPreview({
    super.key,
    required this.mode,
    required this.initialWallet,
  });

  @override
  Widget build(BuildContext context) {
    return WalletFlowSelector(
      title: mode.title(context),
      subtitle: mode.subtitle(context),
      initialWallet: initialWallet,
      onContinue: (wallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${wallet.name} selecionada'),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      },
    );
  }
}

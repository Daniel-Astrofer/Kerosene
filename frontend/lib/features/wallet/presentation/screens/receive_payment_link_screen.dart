import 'package:flutter/material.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/screens/receive_method.dart';
import 'package:teste/features/wallet/presentation/screens/receive_request_flow_screen.dart';

class ReceivePaymentLinkScreen extends StatelessWidget {
  final PaymentLink initialLink;
  final String requestedAmountLabel;
  final String btcAmountLabel;
  final String? walletLabel;
  final String? cardTypeLabel;
  final String? depositFeeLabel;
  final String? netAmountLabel;

  const ReceivePaymentLinkScreen({
    super.key,
    required this.initialLink,
    required this.requestedAmountLabel,
    required this.btcAmountLabel,
    this.walletLabel,
    this.cardTypeLabel,
    this.depositFeeLabel,
    this.netAmountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final walletName = walletLabel?.trim().isNotEmpty == true
        ? walletLabel!.trim()
        : 'Kerosene';
    final address = initialLink.depositAddress.trim().isNotEmpty
        ? initialLink.depositAddress.trim()
        : 'kerosene-payment-${initialLink.id}';
    final isOnChain = !initialLink.isInternalPaymentRequest &&
        initialLink.paymentRail.trim().toUpperCase() != 'INTERNAL';

    return ReceiveRequestFlowScreen(
      wallet: Wallet(
        id: 'payment-link-${initialLink.id}',
        name: walletName,
        address: address,
        walletMode: isOnChain ? 'SELF_CUSTODY' : 'KEROSENE',
        balance: 0,
        derivationPath: "m/84'/0'/0'/0/0",
        type: WalletType.nativeSegwit,
        createdAt: initialLink.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      onChainWallet: isOnChain,
      amountBtc: initialLink.amountBtc,
      method: ReceiveAmountMethod.paymentLink,
      initialPaymentLink: initialLink,
      initialStage: _stageForLink(initialLink),
    );
  }
}

ReceiveRequestStage _stageForLink(PaymentLink link) {
  if (link.isPaid || link.isCompleted) {
    return ReceiveRequestStage.identified;
  }
  if (link.isVerifyingOnboarding || (link.txid?.trim().isNotEmpty ?? false)) {
    return ReceiveRequestStage.confirmations;
  }
  return ReceiveRequestStage.qr;
}

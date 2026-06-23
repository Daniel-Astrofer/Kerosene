import 'package:flutter/material.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_screen_review.dart';

String sendReviewNote(
  SendDestinationAnalysis destination, {
  required bool isPaymentLink,
}) {
  if (isPaymentLink) return 'Pagamento por link interno';
  if (destination.isLightning) return 'Pagamento Lightning';
  if (destination.isOnChain) return 'Envio on-chain';
  return 'Transferência interna Kerosene';
}

Future<dynamic> openSendPaymentReview({
  required BuildContext context,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double requestedAmount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required String recipientLabel,
  required double? btcUsd,
  required double? btcEur,
  required double? btcBrl,
  required bool isPaymentLink,
  required Future<dynamic> Function(BuildContext confirmationContext) onConfirm,
}) {
  final btcAmountLabel = MoneyDisplay.format(
    amount: requestedAmount,
    currency: Currency.btc,
  );
  final fiatAmountLabel = formatFiatReference(
    btcAmount: requestedAmount,
    btcUsd: btcUsd,
    btcEur: btcEur,
    btcBrl: btcBrl,
  );
  final feeLabel = destination.isExternal
      ? '${formatBtcValue(feeQuote.totalFeesBtc)} BTC'
      : 'Grátis';

  return Navigator.of(context).push<dynamic>(
    MaterialPageRoute(
      builder: (_) => InternalTransferReviewScreen<dynamic>(
        title:
            destination.isExternal ? 'Revisar envio' : 'Revisar transferência',
        confirmLabel:
            destination.isLightning ? 'Confirmar pagamento' : 'Confirmar envio',
        successTitle: destination.isExternal
            ? 'Envio iniciado'
            : 'Transferência concluída',
        successMessage: destination.isExternal
            ? 'A transação foi enviada para processamento.'
            : 'Os fundos foram enviados dentro da Kerosene.',
        recipientLabel: recipientLabel,
        recipientAddress: toAddress,
        amountBtcLabel: btcAmountLabel,
        fiatAmountLabel: fiatAmountLabel,
        feeLabel: feeLabel,
        note: sendReviewNote(destination, isPaymentLink: isPaymentLink),
        sourceWallet: wallet.name,
        onConfirm: onConfirm,
      ),
    ),
  );
}

Future<void> showSendSentTransactionNotification({
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double amount,
  required String toAddress,
  required String? recipientLabel,
}) async {
  final amountLabel = '${formatBtcValue(amount)} BTC';
  final recipient = recipientLabel ?? compactInternalValue(toAddress);
  final title = destination.isLightning
      ? 'Pagamento Lightning enviado'
      : destination.isOnChain
          ? 'Envio on-chain iniciado'
          : 'Transferência enviada';
  final body = destination.isExternal
      ? '$amountLabel enviado para $recipient. Acompanhe o status no histórico.'
      : '$amountLabel enviado para $recipient pela Kerosene.';

  await NotificationService().showTransactionNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    summary: wallet.name,
    payload: '/home',
    incoming: false,
    dedupeKey: 'sent:${wallet.id}:$toAddress:${amount.toStringAsFixed(8)}',
  );
}

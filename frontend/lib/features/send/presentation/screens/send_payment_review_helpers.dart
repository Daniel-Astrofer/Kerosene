import 'package:flutter/material.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/features/financial_activity/domain/entities/tx_status.dart';
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
  final btcAmountLabel = formatBtcValue(requestedAmount);
  final fiatAmountLabel = formatFiatReference(
    btcAmount: requestedAmount,
    btcUsd: btcUsd,
    btcEur: btcEur,
    btcBrl: btcBrl,
  );
  final networkLabel = _sendNetworkLabel(
    destination,
    isPaymentLink: isPaymentLink,
  );
  final reviewRows = _buildReviewRows(
    wallet: wallet,
    destination: destination,
    requestedAmount: requestedAmount,
    feeQuote: feeQuote,
    toAddress: toAddress,
    recipientLabel: recipientLabel,
    networkLabel: networkLabel,
    fiatAmountLabel: fiatAmountLabel,
  );

  return Navigator.of(context).push<dynamic>(
    MaterialPageRoute(
      builder: (_) => InternalTransferReviewScreen<dynamic>(
        amountBtcLabel: btcAmountLabel,
        fiatAmountLabel: _displayFiatLabel(fiatAmountLabel),
        confirmLabel: 'Autorizar',
        rows: reviewRows,
        onConfirm: onConfirm,
        receiptBuilder: (result) {
          if (result is! TxStatus) return null;
          return _buildReceiptData(
            status: result,
            wallet: wallet,
            destination: destination,
            requestedAmount: requestedAmount,
            feeQuote: feeQuote,
            toAddress: toAddress,
            recipientLabel: recipientLabel,
            networkLabel: networkLabel,
          );
        },
      ),
    ),
  );
}

List<SendPaymentReviewRowData> _buildReviewRows({
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double requestedAmount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required String recipientLabel,
  required String networkLabel,
  required String fiatAmountLabel,
}) {
  final rows = <SendPaymentReviewRowData>[
    SendPaymentReviewRowData(
      label: 'Cotação',
      value: _displayFiatLabel(fiatAmountLabel),
      numeric: true,
    ),
    SendPaymentReviewRowData(
      label: 'Destino',
      value: _displayParty(recipientLabel, toAddress),
      technical: recipientLabel.trim().isEmpty,
    ),
    SendPaymentReviewRowData(label: 'Rede', value: networkLabel),
    SendPaymentReviewRowData(label: 'Carteira', value: wallet.name),
    SendPaymentReviewRowData(
      label: 'Taxa de rede',
      value: _networkFeeLabel(destination, feeQuote),
      numeric: destination.isExternal,
    ),
  ];

  if (feeQuote.platformFeeBtc > 0) {
    rows.add(
      SendPaymentReviewRowData(
        label: 'Taxa Kerosene',
        value: '${formatBtcValue(feeQuote.platformFeeBtc)} BTC',
        numeric: true,
      ),
    );
  }

  rows.addAll([
    SendPaymentReviewRowData(
      label: 'Tempo estimado',
      value: estimatedSendTime(destination),
    ),
    SendPaymentReviewRowData(
      label: 'Valor de envio',
      value: '${formatBtcValue(requestedAmount)} BTC',
      numeric: true,
    ),
  ]);

  if (destination.isExternal &&
      (feeQuote.totalDebitedBtc - requestedAmount).abs() > 0.000000009) {
    rows.add(
      SendPaymentReviewRowData(
        label: 'Total debitado',
        value: '${formatBtcValue(feeQuote.totalDebitedBtc)} BTC',
        numeric: true,
      ),
    );
  }

  return rows;
}

SendPaymentReceiptData _buildReceiptData({
  required TxStatus status,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double requestedAmount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required String recipientLabel,
  required String networkLabel,
}) {
  final occurredAt = DateTime.now();
  final amountFallback =
      destination.isExternal ? feeQuote.receiverAmountBtc : requestedAmount;
  final amountLabel = receiptAmountLabelFromStatus(
    status: status,
    fallbackAmountBtc: amountFallback,
  );
  final sender = _firstNotEmpty(status.sender, wallet.address, wallet.name);
  final receiver = _firstNotEmpty(status.receiver, toAddress, recipientLabel);
  final networkFee =
      status.networkFeeBtc > 0 ? status.networkFeeBtc : feeQuote.networkFeeBtc;
  final platformFee = status.platformFeeBtc > 0
      ? status.platformFeeBtc
      : feeQuote.platformFeeBtc;
  final totalDebited = status.totalDebitedBtc > 0
      ? status.totalDebitedBtc
      : feeQuote.totalDebitedBtc;

  final rows = <SendPaymentReceiptRowData>[
    SendPaymentReceiptRowData(
      label: 'Remetente',
      value: compactSendReceiptValue(sender, head: 14, tail: 8),
      technical: sender.length > 24,
    ),
    SendPaymentReceiptRowData(label: 'Carteira', value: wallet.name),
    SendPaymentReceiptRowData(label: 'Rede', value: networkLabel),
    SendPaymentReceiptRowData(
      label: 'Destino',
      value: compactSendReceiptValue(receiver, head: 14, tail: 8),
      technical: receiver.length > 24,
    ),
  ];

  if (networkFee > 0) {
    rows.add(
      SendPaymentReceiptRowData(
        label: 'Taxa de rede',
        value: '${formatBtcValue(networkFee)} BTC',
        numeric: true,
      ),
    );
  }

  if (platformFee > 0) {
    rows.add(
      SendPaymentReceiptRowData(
        label: 'Taxa Kerosene',
        value: '${formatBtcValue(platformFee)} BTC',
        numeric: true,
      ),
    );
  }

  if (totalDebited > 0 && (totalDebited - amountFallback).abs() > 0.000000009) {
    rows.add(
      SendPaymentReceiptRowData(
        label: 'Total debitado',
        value: '${formatBtcValue(totalDebited)} BTC',
        numeric: true,
      ),
    );
  }

  if (status.status.trim().isNotEmpty) {
    rows.add(
      SendPaymentReceiptRowData(
        label: 'Status',
        value: _statusLabel(status.status),
      ),
    );
  }

  if (status.txid.trim().isNotEmpty) {
    rows.add(
      SendPaymentReceiptRowData(
        label: 'ID da transação',
        value: compactSendReceiptValue(status.txid, head: 10, tail: 8),
        numeric: true,
        technical: true,
      ),
    );
  }

  final title =
      status.isConfirmed ? 'Transação Confirmada' : 'Transação Enviada';

  return SendPaymentReceiptData(
    title: title,
    amountLabel: amountLabel,
    occurredAt: occurredAt,
    rows: rows,
    shareText: _receiptShareText(
      title: title,
      amountLabel: amountLabel,
      occurredAt: occurredAt,
      rows: rows,
    ),
  );
}

String _sendNetworkLabel(
  SendDestinationAnalysis destination, {
  required bool isPaymentLink,
}) {
  if (isPaymentLink || destination.isPaymentLink) return 'Link interno';
  if (destination.isLightning) return 'Lightning';
  if (destination.isOnChain) return 'On-chain';
  return 'Kerosene';
}

String _networkFeeLabel(
  SendDestinationAnalysis destination,
  SendFeeQuote feeQuote,
) {
  if (!destination.isExternal) return 'Grátis';
  return '${formatBtcValue(feeQuote.networkFeeBtc)} BTC';
}

String _displayFiatLabel(String value) {
  final trimmed = value.trim();
  return trimmed.startsWith('≈ ') ? trimmed.substring(2).trim() : trimmed;
}

String _displayParty(String label, String value) {
  final cleanLabel = label.trim();
  if (cleanLabel.isNotEmpty) return cleanLabel;
  return compactSendReceiptValue(value, head: 14, tail: 8);
}

String _firstNotEmpty(String first, String second, String third) {
  for (final value in [first, second, third]) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return 'Kerosene';
}

String _statusLabel(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return 'CONFIRMADO';
  return normalized;
}

String _receiptShareText({
  required String title,
  required String amountLabel,
  required DateTime occurredAt,
  required List<SendPaymentReceiptRowData> rows,
}) {
  final lines = <String>[
    title,
    'Valor: $amountLabel BTC',
    'Data: ${_shareDate(occurredAt)}',
    for (final row in rows) '${row.label}: ${row.value}',
  ];
  return lines.join('\n');
}

String _shareDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
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

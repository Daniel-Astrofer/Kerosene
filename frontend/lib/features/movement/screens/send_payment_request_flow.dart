import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/screens/send_destination_analyzer.dart';
import 'package:kerosene/features/movement/screens/send_money_formatters.dart';

Future<void> parseSendPaymentRequest({
  required BuildContext context,
  required WidgetRef ref,
  required String data,
  required bool Function() isMounted,
  required void Function(String value) setReceiverText,
  required void Function(String value) setLockedRecipientAddress,
  required void Function(double value) setLockedAmountBtc,
  required void Function(String value) setAmountText,
  required void Function(String? value) setLockedRecipientLabel,
  required void Function() incrementDestinationEditVersion,
  required Future<bool> Function(String linkId) fetchPaymentLinkDetails,
}) async {
  final linkId = QrPaymentParser.extractPaymentLinkId(data);
  if (linkId != null) {
    if (isMounted()) {
      incrementDestinationEditVersion();
      setReceiverText(data.trim());
    }
    await fetchPaymentLinkDetails(linkId);
    return;
  }

  final parsed = QrPaymentParser.decode(data);
  if (parsed != null && parsed.isComplete) {
    final analysis = analyzeSendDestination(data);
    final normalized = analysis.normalizedValue.isNotEmpty
        ? analysis.normalizedValue
        : parsed.address;
    incrementDestinationEditVersion();
    setReceiverText(normalized);
    setLockedRecipientAddress(normalized);
    if (parsed.amountBtc != null && parsed.amountBtc! > 0) {
      setLockedAmountBtc(parsed.amountBtc!);
      setAmountText(_amountText(parsed.amountBtc!));
    }
    if (parsed.label != null && parsed.label!.isNotEmpty) {
      setLockedRecipientLabel(parsed.label);
    }
    HapticFeedback.lightImpact();
    SnackbarHelper.showSuccess(context.tr.sendMoneyRequestDataLoaded);
    return;
  }

  final candidate = data.trim();
  if (isValidInternalDestination(candidate)) {
    incrementDestinationEditVersion();
    setReceiverText(candidate);
    HapticFeedback.lightImpact();
    return;
  }
  SnackbarHelper.showError(context.tr.sendMoneyInvalidQrRequest);
}

Future<bool> fetchSendPaymentLinkDetails({
  required BuildContext context,
  required WidgetRef ref,
  required String linkId,
  required int? destinationEditVersion,
  required int Function() currentDestinationEditVersion,
  required bool Function() isMounted,
  required void Function() incrementDestinationEditVersion,
  required void Function(String? value) setPendingPaymentLinkId,
  required void Function(String? value) setLockedRecipientLabel,
  required void Function(String value) setLockedRecipientAddress,
  required void Function(double value) setLockedAmountBtc,
  required void Function(String value) setAmountText,
}) async {
  final tr = context.tr;
  try {
    final payload =
        await ref.read(transactionRepositoryProvider).getPaymentLink(linkId);
    final amount = payload.amountBtc;
    final status = payload.status.toUpperCase();
    final destinationHash = payload.destinationHash ?? '';

    if (!isMounted() ||
        (destinationEditVersion != null &&
            destinationEditVersion != currentDestinationEditVersion())) {
      return false;
    }

    if (_paymentLinkBelongsToAuthenticatedUser(ref, payload)) {
      SnackbarHelper.showError(tr.errLedgerPaymentRequestSelfPay);
      return false;
    }

    if (status == 'PAID') {
      SnackbarHelper.showError(tr.sendMoneyRequestAlreadyPaid);
      return false;
    }
    if (status == 'CANCELED' || status == 'EXPIRED') {
      SnackbarHelper.showError(tr.sendMoneyRequestExpired);
      return false;
    }

    if (destinationEditVersion == null) {
      incrementDestinationEditVersion();
    }
    setPendingPaymentLinkId(linkId);
    setLockedRecipientLabel(
      destinationHash.isNotEmpty
          ? sendShortHash(destinationHash)
          : payload.referenceLabel?.trim().isNotEmpty == true
              ? payload.referenceLabel!.trim()
              : tr.sendMoneyLockedDestination,
    );
    setLockedRecipientAddress(
      destinationHash.isNotEmpty ? destinationHash : payload.depositAddress,
    );
    if (amount > 0) {
      setLockedAmountBtc(amount);
      setAmountText(_amountText(amount));
    }
    SnackbarHelper.showSuccess(tr.sendMoneyPaymentRequestLoaded);
    return true;
  } catch (error) {
    if (!isMounted()) return false;
    SnackbarHelper.showError(
      ErrorTranslator.translate(tr, error.toString()),
    );
    return false;
  }
}

String _amountText(double amount) {
  return amount
      .toStringAsFixed(8)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

bool _paymentLinkBelongsToAuthenticatedUser(WidgetRef ref, dynamic payload) {
  final authState = ref.read(authControllerProvider);
  if (authState is! AuthAuthenticated) {
    return false;
  }
  final currentUserId = int.tryParse(authState.user.id.trim());
  return currentUserId != null && currentUserId == payload.userId;
}

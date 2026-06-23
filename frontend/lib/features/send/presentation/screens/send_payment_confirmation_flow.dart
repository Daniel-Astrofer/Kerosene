import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/services/audio_service.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/presentation/widgets/transaction_auth_gate.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/send/send_money_copy.dart';

const defaultLightningRoutingFeeBtc = 0.000001;

Future<dynamic> confirmSendPayment({
  required BuildContext context,
  required BuildContext confirmationContext,
  required WidgetRef ref,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double amount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required String? pendingPaymentLinkId,
  required Future<AccountSecurityProfile> Function(Wallet wallet)
      resolveSecurityProfile,
  required Future<void> Function({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) showSentTransactionNotification,
  required String? Function(String toAddress) resolveRecentDestinationLabel,
  required String Function(String toAddress) resolveRecentDestinationAddress,
  required bool Function() isMounted,
}) async {
  final l10n = context.tr;
  final profile = await resolveSecurityProfile(wallet);
  if (!isMounted() || !confirmationContext.mounted) return null;

  final authResult = await TransactionAuthGate.show(
    confirmationContext,
    profile: profile,
    allowDeviceAuthUnavailable: true,
  );

  if (!authResult.isAuthenticated ||
      !isMounted() ||
      !confirmationContext.mounted) {
    SnackbarHelper.showError(l10n.sendMoneyAuthFailed);
    return null;
  }

  if (pendingPaymentLinkId != null) {
    return _confirmPaymentLink(
      confirmationContext: confirmationContext,
      ref: ref,
      wallet: wallet,
      destination: destination,
      amount: amount,
      toAddress: toAddress,
      linkId: pendingPaymentLinkId,
      authResult: authResult,
      showSentTransactionNotification: showSentTransactionNotification,
      isMounted: isMounted,
    );
  }

  if (destination.isExternal) {
    return _confirmExternalSend(
      context: context,
      confirmationContext: confirmationContext,
      ref: ref,
      wallet: wallet,
      destination: destination,
      amount: amount,
      feeQuote: feeQuote,
      toAddress: toAddress,
      authResult: authResult,
      showSentTransactionNotification: showSentTransactionNotification,
      resolveRecentDestinationLabel: resolveRecentDestinationLabel,
      isMounted: isMounted,
    );
  }

  return _confirmInternalSend(
    confirmationContext: confirmationContext,
    ref: ref,
    wallet: wallet,
    destination: destination,
    amount: amount,
    feeQuote: feeQuote,
    toAddress: toAddress,
    authResult: authResult,
    showSentTransactionNotification: showSentTransactionNotification,
    resolveRecentDestinationLabel: resolveRecentDestinationLabel,
    resolveRecentDestinationAddress: resolveRecentDestinationAddress,
    isMounted: isMounted,
  );
}

Future<dynamic> _confirmPaymentLink({
  required BuildContext confirmationContext,
  required WidgetRef ref,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double amount,
  required String toAddress,
  required String linkId,
  required TransactionAuthResult authResult,
  required Future<void> Function({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) showSentTransactionNotification,
  required bool Function() isMounted,
}) async {
  final result = await ref.read(paymentLinkNotifierProvider.notifier).pay(
        linkId: linkId,
        payerWalletName: wallet.name,
        totpCode: authResult.totpCode,
        confirmationPassphrase: authResult.confirmationPassphrase,
        passkeyAssertionJson: authResult.passkeyAssertionJson,
        appPin: authResult.appPin,
      );

  if (result != null) {
    await showSentTransactionNotification(
      wallet: wallet,
      destination: destination,
      amount: amount,
      toAddress: toAddress,
    );
    AudioService.instance.playTransaction();
    HapticFeedback.vibrate();
    ref.read(paymentLinkNotifierProvider.notifier).reset();
    return result;
  }

  AudioService.instance.playError();
  HapticFeedback.heavyImpact();
  final error = ref.read(paymentLinkNotifierProvider).error;
  if (error != null) {
    if (!isMounted() || !confirmationContext.mounted) return null;
    SnackbarHelper.showError(
      ErrorTranslator.translate(confirmationContext.l10n, error),
    );
  }
  ref.read(paymentLinkNotifierProvider.notifier).reset();
  return null;
}

Future<dynamic> _confirmExternalSend({
  required BuildContext context,
  required BuildContext confirmationContext,
  required WidgetRef ref,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double amount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required TransactionAuthResult authResult,
  required Future<void> Function({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) showSentTransactionNotification,
  required String? Function(String toAddress) resolveRecentDestinationLabel,
  required bool Function() isMounted,
}) async {
  final result = await ref.read(withdrawProvider.notifier).withdraw(
        fromWalletName: wallet.id,
        toAddress: destination.isOnChain ? toAddress : null,
        paymentRequest: destination.isLightning ? toAddress : null,
        amount: amount,
        totpCode: authResult.totpCode,
        isLightning: destination.isLightning,
        networkFeeBtc: feeQuote.networkFeeBtc,
        maxRoutingFeeBtc: defaultLightningRoutingFeeBtc,
        description: destination.isLightning
            ? 'Pagamento Lightning'
            : SendMoneyCopy.onchainSendDescription(context),
        confirmationPassphrase: authResult.confirmationPassphrase,
        passkeyAssertionJson: authResult.passkeyAssertionJson,
        appPin: authResult.appPin,
      );

  if (result != null) {
    await ref
        .read(recentTransactionDestinationsProvider.notifier)
        .saveDestination(
          address: toAddress,
          kind: destination.isLightning
              ? RecentTransactionDestinationKind.lightning
              : RecentTransactionDestinationKind.onChain,
          label: resolveRecentDestinationLabel(toAddress),
        );
    await showSentTransactionNotification(
      wallet: wallet,
      destination: destination,
      amount: amount,
      toAddress: toAddress,
    );
    AudioService.instance.playTransaction();
    HapticFeedback.vibrate();
    ref.read(withdrawProvider.notifier).reset();
    return result;
  }

  AudioService.instance.playError();
  HapticFeedback.heavyImpact();
  final error = ref.read(withdrawProvider).error;
  if (error != null) {
    if (!isMounted() || !confirmationContext.mounted) return null;
    SnackbarHelper.showError(
      ErrorTranslator.translate(confirmationContext.l10n, error),
    );
  }
  ref.read(withdrawProvider.notifier).reset();
  return null;
}

Future<dynamic> _confirmInternalSend({
  required BuildContext confirmationContext,
  required WidgetRef ref,
  required Wallet wallet,
  required SendDestinationAnalysis destination,
  required double amount,
  required SendFeeQuote feeQuote,
  required String toAddress,
  required TransactionAuthResult authResult,
  required Future<void> Function({
    required Wallet wallet,
    required SendDestinationAnalysis destination,
    required double amount,
    required String toAddress,
  }) showSentTransactionNotification,
  required String? Function(String toAddress) resolveRecentDestinationLabel,
  required String Function(String toAddress) resolveRecentDestinationAddress,
  required bool Function() isMounted,
}) async {
  final idempotencyKey = const Uuid().v4();
  final result = await ref.read(sendTransactionProvider.notifier).send(
        fromWalletId: wallet.id,
        fromAddress:
            wallet.address.trim().isEmpty ? null : wallet.address.trim(),
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: (feeQuote.networkFeeBtc * 100000000).toInt(),
        context: null,
        passkeyAssertionJson: authResult.passkeyAssertionJson,
        confirmationPassphrase: authResult.confirmationPassphrase,
        totpCode: authResult.totpCode,
        idempotencyKey: idempotencyKey,
        requestTimestamp: DateTime.now().millisecondsSinceEpoch,
        appPin: authResult.appPin,
      );

  if (result != null) {
    await ref
        .read(recentTransactionDestinationsProvider.notifier)
        .saveDestination(
          address: resolveRecentDestinationAddress(toAddress),
          kind: RecentTransactionDestinationKind.internal,
          label: resolveRecentDestinationLabel(toAddress),
        );
    await showSentTransactionNotification(
      wallet: wallet,
      destination: destination,
      amount: amount,
      toAddress: toAddress,
    );
    AudioService.instance.playTransaction();
    HapticFeedback.vibrate();
    ref.read(sendTransactionProvider.notifier).reset();
    return result;
  }

  AudioService.instance.playError();
  HapticFeedback.heavyImpact();
  final error = ref.read(sendTransactionProvider).error;
  if (error != null) {
    if (!isMounted() || !confirmationContext.mounted) return null;
    SnackbarHelper.showError(
      ErrorTranslator.translate(confirmationContext.l10n, error),
    );
  }
  ref.read(sendTransactionProvider.notifier).reset();
  return null;
}

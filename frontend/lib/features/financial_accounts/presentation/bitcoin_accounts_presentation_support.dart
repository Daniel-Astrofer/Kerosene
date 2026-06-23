import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';

import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

const kKeroseneBrandLabel = 'Kerosene';

String bitcoinAccountCardIdentifier(
  BitcoinAccount account, {
  ReceivingRequestView? receiveRequest,
}) {
  final candidates = [
    if (!account.isWatchOnly) receiveRequest?.address,
    if (account.isWatchOnly) account.xpubFingerprint,
    if (account.isWatchOnly) account.coldWalletId,
    account.cardId,
    account.xpubFingerprint,
    account.coldWalletId,
    account.id,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String bitcoinAccountCustodyLabel(
    BuildContext context, BitcoinAccount account) {
  if (account.isWatchOnly) return context.tr.bitcoinAccountsColdWalletBadge;
  if (account.isCustodialOnchain) {
    return context.tr.bitcoinAccountsCustodyOnchainTitle;
  }
  return context.tr.bitcoinAccountsKeroseneCardBadge;
}

String bitcoinAccountCardNetworkLabel(BitcoinAccount account) {
  if (account.isWatchOnly) return 'Cold Wallet';
  if (account.isCustodialOnchain) return 'Onchain';
  return 'Assegurada pela Kerosene';
}

String bitcoinAccountTypeLabel(BuildContext context, BitcoinAccount account) {
  final description = account.walletTypeDescription.trim();
  if (description.isNotEmpty) return description;
  if (account.isWatchOnly) {
    return context.tr.bitcoinAccountsCustodyWatchOnlyTitle;
  }
  if (account.isCustodialOnchain) {
    return context.tr.bitcoinAccountsCustodyOnchainTitle;
  }
  return context.tr.bitcoinAccountsCustodyInternalTitle;
}

int bitcoinAccountVisibleBalance(BitcoinAccount account) {
  if (account.isWatchOnly) return account.observedBalanceSats;
  return account.totalSats;
}

ReceivingRequestView? firstBitcoinReceiveRequest(
  AsyncValue<List<ReceivingRequestView>> requestsAsync,
) {
  final requests = requestsAsync.asData?.value;
  if (requests == null || requests.isEmpty) return null;
  return requests.first;
}

bool bitcoinAccountHasPublicMaterial(BitcoinAccount account) {
  return account.isWatchOnly ||
      account.isCustodialOnchain ||
      (account.xpubFingerprint ?? '').trim().isNotEmpty ||
      (account.derivationPath ?? '').trim().isNotEmpty ||
      (account.scriptPolicy ?? '').trim().isNotEmpty;
}

String bitcoinAccountDisplayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Não informado' : trimmed;
}

String bitcoinAccountsShortText(String value) {
  if (value.length <= 18) return value;
  return '${value.substring(0, 8)}…${value.substring(value.length - 6)}';
}

String bitcoinAccountHistoryDetail(Transaction transaction) {
  final candidates = [
    transaction.blockchainTxid,
    transaction.externalReference,
    transaction.isDebit ? transaction.toAddress : transaction.fromAddress,
    transaction.invoiceId,
    transaction.paymentHash,
    transaction.id,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return bitcoinAccountsShortText(value);
  }
  return 'Movimento Bitcoin';
}

String bitcoinAccountHistoryTimestampLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year}\n$hour:$minute';
}

String bitcoinAccountTransactionStatusLabel(
  BuildContext context,
  TransactionStatus status,
) {
  return switch (status) {
    TransactionStatus.pending => context.tr.bitcoinReceiveStatusWaiting,
    TransactionStatus.confirming => context.tr.bitcoinReceiveStatusConfirming,
    TransactionStatus.confirmed => context.tr.bitcoinReceiveStatusPaid,
    TransactionStatus.failed => context.tr.bitcoinReceiveStatusProtected,
  };
}

class BitcoinAccountsColors {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color text;
  final Color mutedText;
  final Color faintText;

  const BitcoinAccountsColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.text,
    required this.mutedText,
    required this.faintText,
  });

  factory BitcoinAccountsColors.of(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return const BitcoinAccountsColors(
        isLight: true,
        background: AppColors.hexFFF7F7F5,
        surface: AppColors.hexFFFFFFFF,
        surfaceAlt: AppColors.hexFFF0F1EE,
        surfaceRaised: AppColors.hexFFE5E7E3,
        border: AppColors.hexFFDDE0D8,
        borderStrong: AppColors.hexFFC8CDC3,
        divider: AppColors.hexFFE2E4DE,
        text: AppColors.hexFF181A17,
        mutedText: AppColors.hexFF62675F,
        faintText: AppColors.hexFF8B9087,
      );
    }

    return const BitcoinAccountsColors(
      isLight: false,
      background: AppColors.hexFF000000,
      surface: AppColors.hexFF1A1A1A,
      surfaceAlt: AppColors.hexFF111111,
      surfaceRaised: AppColors.hexFF222222,
      border: AppColors.hex14FFFFFF,
      borderStrong: AppColors.hexFF383838,
      divider: AppColors.hexFF1A1A1A,
      text: AppColors.hexFFFFFFFF,
      mutedText: AppColors.hexFF8A8A8E,
      faintText: AppColors.hexFF6B6B66,
    );
  }

  Color get filledButtonForeground => isLight ? Colors.white : Colors.black;
  Color get headerButtonBackground =>
      text.withValues(alpha: isLight ? 0.08 : 0.10);
  Color get selectedDot => text;
  Color get idleDot => text.withValues(alpha: isLight ? 0.24 : 0.30);
  Color get rowDivider => text.withValues(alpha: isLight ? 0.08 : 0.05);
  Color get skeleton => text.withValues(alpha: isLight ? 0.08 : 0.05);
  Color get cardShadow => Colors.black.withValues(alpha: isLight ? 0.10 : 0.50);
  Color get panelShadow =>
      Colors.black.withValues(alpha: isLight ? 0.08 : 0.28);
  BorderRadius get panelRadius =>
      isLight ? BorderRadius.circular(18) : monoRadius;
  BorderRadius get controlRadius =>
      isLight ? BorderRadius.circular(14) : monoRadius;
  BorderRadius get pillRadius =>
      isLight ? BorderRadius.circular(999) : monoRadius;
  BorderRadius get iconRadius =>
      isLight ? BorderRadius.circular(12) : monoRadius;

  BoxDecoration panelDecoration({
    Color? color,
    Color? borderColor,
    bool showShadow = true,
    BorderRadius? borderRadius,
  }) {
    if (!isLight) {
      return monochromePanelDecoration(
        color: color ?? surface,
        borderColor: borderColor ?? border,
        showShadow: showShadow,
      );
    }

    return BoxDecoration(
      color: color ?? surface,
      borderRadius: borderRadius ?? panelRadius,
      border: Border.all(color: borderColor ?? border),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: panelShadow,
                blurRadius: 24,
                spreadRadius: -18,
                offset: const Offset(0, 14),
              ),
            ]
          : null,
    );
  }

  InputDecoration inputDecoration({
    required String label,
    String? hintText,
    String? counterText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    if (!isLight) {
      return monochromeInputDecoration(
        label: label,
        hintText: hintText,
        counterText: counterText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      );
    }

    final radius = controlRadius;
    final borderSide = BorderSide(color: borderStrong);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: borderSide,
    );

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      counterText: counterText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(color: mutedText),
      hintStyle: AppTypography.bodySmall.copyWith(color: faintText),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
    );
  }

  ButtonStyle filledButtonStyle({
    bool emphasis = true,
    bool destructive = false,
    double minHeight = 52,
  }) {
    if (!isLight) {
      return monochromeFilledButtonStyle(
        emphasis: emphasis,
        destructive: destructive,
        minHeight: minHeight,
      );
    }

    final background = destructive
        ? surfaceAlt
        : emphasis
            ? text
            : surfaceAlt;
    final foreground = destructive
        ? text
        : emphasis
            ? filledButtonForeground
            : text;
    final outline = destructive || emphasis ? borderStrong : border;

    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: surfaceRaised,
      disabledForegroundColor: faintText,
      minimumSize: Size.fromHeight(minHeight),
      textStyle: AppTypography.buttonText.copyWith(
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
      side: BorderSide(color: outline),
    );
  }

  ButtonStyle outlinedButtonStyle({
    double minHeight = 48,
    Color? foregroundColor,
  }) {
    if (!isLight) {
      return monochromeOutlinedButtonStyle(
        minHeight: minHeight,
        foregroundColor: foregroundColor ?? monoTextColor,
      );
    }

    return OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(minHeight),
      foregroundColor: foregroundColor ?? text,
      disabledForegroundColor: faintText,
      side: BorderSide(color: borderStrong),
      backgroundColor: surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
      textStyle: AppTypography.buttonText.copyWith(
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  ButtonStyle textButtonStyle() {
    if (!isLight) {
      return monochromeTextButtonStyle();
    }

    return TextButton.styleFrom(
      foregroundColor: mutedText,
      disabledForegroundColor: faintText,
      textStyle: AppTypography.caption.copyWith(
        color: mutedText,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

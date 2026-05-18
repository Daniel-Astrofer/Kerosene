import 'package:flutter/material.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/l10n/l10n_extension.dart';

enum TransactionVisualFamily {
  onChain,
  lightning,
  internalTransfer,
  paymentLink,
  qrCode,
  nfc,
  deposit,
  withdrawal,
  mining,
  refund,
  swap,
  fee,
  failed,
  cancelled,
  unknown,
}

enum TransactionVisualDirection {
  incoming,
  outgoing,
  neutral,
}

enum TransactionVisualLabel {
  cancelled,
  refund,
  failed,
  mining,
  swap,
  fee,
  lightningDeposit,
  lightningPayment,
  lightningReceive,
  deposit,
  withdrawal,
  nfcReceive,
  nfcPayment,
  qrReceive,
  qrPayment,
  paymentLinkReceive,
  paymentLinkPayment,
  internalReceive,
  internalSend,
  event,
  onChainReceive,
  onChainSend,
}

class TransactionVisualSpec {
  static const Color _creditColor = Color(0xFFA8C7B1);
  static const Color _debitColor = Color(0xFFD59A9A);
  static const Color _neutralAmountColor = Color(0xFF8FA7C2);

  final TransactionVisualFamily family;
  final TransactionVisualDirection direction;
  final TransactionVisualLabel labelKey;
  final String prefix;
  final IconData icon;
  final Color iconColor;
  final Color amountColor;

  const TransactionVisualSpec({
    required this.family,
    required this.direction,
    required this.labelKey,
    required this.prefix,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
  });

  bool get isIncoming => direction == TransactionVisualDirection.incoming;
  bool get isOutgoing => direction == TransactionVisualDirection.outgoing;

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (labelKey) {
      TransactionVisualLabel.cancelled => l10n.transactionVisualCancelled,
      TransactionVisualLabel.refund => l10n.transactionVisualRefund,
      TransactionVisualLabel.failed => l10n.transactionVisualFailed,
      TransactionVisualLabel.mining => l10n.transactionVisualMining,
      TransactionVisualLabel.swap => l10n.transactionVisualSwap,
      TransactionVisualLabel.fee => l10n.transactionVisualFee,
      TransactionVisualLabel.lightningDeposit =>
        l10n.transactionVisualLightningDeposit,
      TransactionVisualLabel.lightningPayment =>
        l10n.transactionVisualLightningPayment,
      TransactionVisualLabel.lightningReceive =>
        l10n.transactionVisualLightningReceive,
      TransactionVisualLabel.deposit => l10n.transactionVisualDeposit,
      TransactionVisualLabel.withdrawal => l10n.transactionVisualWithdrawal,
      TransactionVisualLabel.nfcReceive => l10n.transactionVisualNfcReceive,
      TransactionVisualLabel.nfcPayment => l10n.transactionVisualNfcPayment,
      TransactionVisualLabel.qrReceive => l10n.transactionVisualQrReceive,
      TransactionVisualLabel.qrPayment => l10n.transactionVisualQrPayment,
      TransactionVisualLabel.paymentLinkReceive =>
        l10n.transactionVisualPaymentLinkReceive,
      TransactionVisualLabel.paymentLinkPayment =>
        l10n.transactionVisualPaymentLinkPayment,
      TransactionVisualLabel.internalReceive =>
        l10n.transactionVisualInternalReceive,
      TransactionVisualLabel.internalSend => l10n.transactionVisualInternalSend,
      TransactionVisualLabel.event => l10n.transactionVisualEvent,
      TransactionVisualLabel.onChainReceive =>
        l10n.transactionVisualOnChainReceive,
      TransactionVisualLabel.onChainSend => l10n.transactionVisualOnChainSend,
    };
  }

  static TransactionVisualSpec fromTransaction(Transaction transaction) {
    final isOutgoing = transaction.type == TransactionType.send ||
        transaction.type == TransactionType.withdrawal;
    final description = (transaction.description ?? '').toLowerCase();

    if (_looksCancelled(transaction)) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.cancelled,
        direction: TransactionVisualDirection.neutral,
        labelKey: TransactionVisualLabel.cancelled,
        prefix: '',
        icon: Icons.block_rounded,
        iconColor: Color(0xFFB38A8A),
        amountColor: _neutralAmountColor,
      );
    }

    if (_looksRefund(transaction)) {
      return _pair(
        family: TransactionVisualFamily.refund,
        isOutgoing: false,
        incomingLabelKey: TransactionVisualLabel.refund,
        outgoingLabelKey: TransactionVisualLabel.refund,
        icon: Icons.undo_rounded,
        iconColor: const Color(0xFFA9B3C3),
      );
    }

    if (transaction.status == TransactionStatus.failed) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.failed,
        direction: TransactionVisualDirection.neutral,
        labelKey: TransactionVisualLabel.failed,
        prefix: '',
        icon: Icons.error_outline_rounded,
        iconColor: Color(0xFFD59A9A),
        amountColor: _debitColor,
      );
    }

    if (_looksLikeMining(transaction)) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.mining,
        direction: TransactionVisualDirection.incoming,
        labelKey: TransactionVisualLabel.mining,
        prefix: '+',
        icon: Icons.auto_awesome_rounded,
        iconColor: Color(0xFFE3B85A),
        amountColor: _creditColor,
      );
    }

    switch (transaction.type) {
      case TransactionType.swap:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.swap,
          direction: TransactionVisualDirection.neutral,
          labelKey: TransactionVisualLabel.swap,
          prefix: '',
          icon: Icons.swap_horiz_rounded,
          iconColor: Color(0xFF8FA7C2),
          amountColor: _neutralAmountColor,
        );
      case TransactionType.fee:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.fee,
          direction: TransactionVisualDirection.neutral,
          labelKey: TransactionVisualLabel.fee,
          prefix: '-',
          icon: Icons.receipt_long_rounded,
          iconColor: Color(0xFF9AA3AE),
          amountColor: _debitColor,
        );
      case TransactionType.deposit:
        if (_looksLikeLightning(transaction)) {
          return _pair(
            family: TransactionVisualFamily.lightning,
            isOutgoing: false,
            incomingLabelKey: TransactionVisualLabel.lightningDeposit,
            outgoingLabelKey: TransactionVisualLabel.lightningPayment,
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFFE3B85A),
          );
        }
        return _pair(
          family: TransactionVisualFamily.deposit,
          isOutgoing: false,
          incomingLabelKey: TransactionVisualLabel.deposit,
          outgoingLabelKey: TransactionVisualLabel.deposit,
          icon: Icons.download_for_offline_rounded,
          iconColor: const Color(0xFF9EB3A4),
        );
      case TransactionType.withdrawal:
        if (_looksLikeLightning(transaction)) {
          return _pair(
            family: TransactionVisualFamily.lightning,
            isOutgoing: true,
            incomingLabelKey: TransactionVisualLabel.lightningReceive,
            outgoingLabelKey: TransactionVisualLabel.lightningPayment,
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFFE3B85A),
          );
        }
        if (_looksLikeCashWithdrawal(transaction)) {
          return _pair(
            family: TransactionVisualFamily.withdrawal,
            isOutgoing: true,
            incomingLabelKey: TransactionVisualLabel.withdrawal,
            outgoingLabelKey: TransactionVisualLabel.withdrawal,
            icon: Icons.upload_rounded,
            iconColor: const Color(0xFFB9A08A),
          );
        }
        break;
      case TransactionType.send:
      case TransactionType.receive:
        break;
    }

    if (_looksLikeNfc(transaction)) {
      return _pair(
        family: TransactionVisualFamily.nfc,
        isOutgoing: isOutgoing,
        incomingLabelKey: TransactionVisualLabel.nfcReceive,
        outgoingLabelKey: TransactionVisualLabel.nfcPayment,
        icon: Icons.nfc_rounded,
        iconColor: const Color(0xFF93A5B5),
      );
    }

    if (_looksLikeQr(transaction)) {
      return _pair(
        family: TransactionVisualFamily.qrCode,
        isOutgoing: isOutgoing,
        incomingLabelKey: TransactionVisualLabel.qrReceive,
        outgoingLabelKey: TransactionVisualLabel.qrPayment,
        icon: Icons.qr_code_2_rounded,
        iconColor: const Color(0xFF9AA6B2),
      );
    }

    if (_looksLikePaymentLink(transaction)) {
      return _pair(
        family: TransactionVisualFamily.paymentLink,
        isOutgoing: isOutgoing,
        incomingLabelKey: TransactionVisualLabel.paymentLinkReceive,
        outgoingLabelKey: TransactionVisualLabel.paymentLinkPayment,
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF9FA8B3),
      );
    }

    if (_looksLikeInternal(transaction)) {
      return _pair(
        family: TransactionVisualFamily.internalTransfer,
        isOutgoing: isOutgoing,
        incomingLabelKey: TransactionVisualLabel.internalReceive,
        outgoingLabelKey: TransactionVisualLabel.internalSend,
        icon: Icons.compare_arrows_rounded,
        iconColor: const Color(0xFF8794A3),
      );
    }

    if (_looksLikeLightning(transaction)) {
      return _pair(
        family: TransactionVisualFamily.lightning,
        isOutgoing: isOutgoing,
        incomingLabelKey: TransactionVisualLabel.lightningReceive,
        outgoingLabelKey: TransactionVisualLabel.lightningPayment,
        icon: Icons.flash_on_rounded,
        iconColor: const Color(0xFFB89B64),
      );
    }

    if (description.trim().isEmpty &&
        transaction.fromAddress.trim().isEmpty &&
        transaction.toAddress.trim().isEmpty) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.unknown,
        direction: TransactionVisualDirection.neutral,
        labelKey: TransactionVisualLabel.event,
        prefix: '',
        icon: Icons.help_outline_rounded,
        iconColor: Color(0xFF9CA8B4),
        amountColor: _neutralAmountColor,
      );
    }

    return _pair(
      family: TransactionVisualFamily.onChain,
      isOutgoing: isOutgoing,
      incomingLabelKey: TransactionVisualLabel.onChainReceive,
      outgoingLabelKey: TransactionVisualLabel.onChainSend,
      icon: Icons.hub_rounded,
      iconColor: const Color(0xFF9CA8B4),
    );
  }

  static TransactionVisualSpec _pair({
    required TransactionVisualFamily family,
    required bool isOutgoing,
    required TransactionVisualLabel incomingLabelKey,
    required TransactionVisualLabel outgoingLabelKey,
    required IconData icon,
    required Color iconColor,
  }) {
    return TransactionVisualSpec(
      family: family,
      direction: isOutgoing
          ? TransactionVisualDirection.outgoing
          : TransactionVisualDirection.incoming,
      labelKey: isOutgoing ? outgoingLabelKey : incomingLabelKey,
      prefix: isOutgoing ? '-' : '+',
      icon: icon,
      iconColor: iconColor,
      amountColor: isOutgoing ? _debitColor : _creditColor,
    );
  }

  static bool _looksLikePaymentLink(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return transaction.id.startsWith('pl_') ||
        description.contains('link de pagamento') ||
        description.contains('payment link') ||
        description.contains('pagamento por link') ||
        (description.contains('link') &&
            (description.contains('pag') || description.contains('payment')));
  }

  static bool _looksLikeQr(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('qr') ||
        description.contains('qr code') ||
        description.contains('qrcode');
  }

  static bool _looksLikeNfc(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('nfc') || description.contains('aproximacao');
  }

  static bool _looksLikeInternal(Transaction transaction) {
    if (transaction.isInternal) {
      return true;
    }

    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('transferencia interna') ||
        description.contains('transferência interna') ||
        description.contains('intra') ||
        description.contains('internal transfer');
  }

  static bool _looksLikeLightning(Transaction transaction) {
    if (transaction.isLightning) {
      return true;
    }

    final candidates = <String>[
      transaction.description ?? '',
      transaction.id,
      transaction.fromAddress,
      transaction.toAddress,
      transaction.blockchainTxid ?? '',
    ].map((value) => value.trim().toLowerCase());

    return candidates.any((value) {
      if (value.isEmpty) {
        return false;
      }

      return value.startsWith('lightning:') ||
          value.startsWith('lnbc') ||
          value.startsWith('lntb') ||
          value.startsWith('lnbcrt') ||
          value.startsWith('lnurl') ||
          value.contains('lightning') ||
          value.contains('bolt11') ||
          value.contains('@');
    });
  }

  static bool _looksLikeMining(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('mining') ||
        description.contains('mineracao') ||
        description.contains('mineração') ||
        description.contains('hashrate') ||
        description.contains('block reward');
  }

  static bool _looksRefund(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('estorno') ||
        description.contains('refund') ||
        description.contains('reversal') ||
        description.contains('chargeback');
  }

  static bool _looksCancelled(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('cancelado') ||
        description.contains('cancelled') ||
        description.contains('canceled') ||
        description.contains('expirado') ||
        description.contains('expired');
  }

  static bool _looksLikeCashWithdrawal(Transaction transaction) {
    final description = (transaction.description ?? '').toLowerCase();
    return description.contains('saque') ||
        description.contains('cashout') ||
        description.contains('cash out') ||
        description.contains('atm') ||
        description.contains('retirada');
  }
}

class TransactionTypeIconBadge extends StatelessWidget {
  final TransactionVisualSpec spec;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  const TransactionTypeIconBadge({
    super.key,
    required this.spec,
    this.size = 34,
    this.iconSize = 18,
    this.borderRadius = 8,
    this.backgroundColor = const Color(0xFF171B20),
    this.borderColor = const Color(0xFF262B31),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Icon(
        spec.icon,
        size: iconSize,
        color: spec.iconColor,
      ),
    );
  }
}

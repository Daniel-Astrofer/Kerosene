import 'package:flutter/material.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

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

class TransactionVisualSpec {
  static const Color _creditColor = Color(0xFFA8C7B1);
  static const Color _debitColor = Color(0xFFD59A9A);
  static const Color _neutralAmountColor = Color(0xFF8FA7C2);

  final TransactionVisualFamily family;
  final TransactionVisualDirection direction;
  final String label;
  final String prefix;
  final IconData icon;
  final Color iconColor;
  final Color amountColor;

  const TransactionVisualSpec({
    required this.family,
    required this.direction,
    required this.label,
    required this.prefix,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
  });

  bool get isIncoming => direction == TransactionVisualDirection.incoming;
  bool get isOutgoing => direction == TransactionVisualDirection.outgoing;

  static TransactionVisualSpec fromTransaction(Transaction transaction) {
    final isOutgoing = transaction.type == TransactionType.send ||
        transaction.type == TransactionType.withdrawal;
    final description = (transaction.description ?? '').toLowerCase();

    if (_looksCancelled(transaction)) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.cancelled,
        direction: TransactionVisualDirection.neutral,
        label: 'Cancelado',
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
        incomingLabel: 'Estorno',
        outgoingLabel: 'Estorno',
        icon: Icons.undo_rounded,
        iconColor: const Color(0xFFA9B3C3),
      );
    }

    if (transaction.status == TransactionStatus.failed) {
      return const TransactionVisualSpec(
        family: TransactionVisualFamily.failed,
        direction: TransactionVisualDirection.neutral,
        label: 'Falha',
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
        label: 'Mineração',
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
          label: 'Swap',
          prefix: '',
          icon: Icons.swap_horiz_rounded,
          iconColor: Color(0xFF8FA7C2),
          amountColor: _neutralAmountColor,
        );
      case TransactionType.fee:
        return const TransactionVisualSpec(
          family: TransactionVisualFamily.fee,
          direction: TransactionVisualDirection.neutral,
          label: 'Taxa',
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
            incomingLabel: 'Depósito Lightning',
            outgoingLabel: 'Pagamento Lightning',
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFFE3B85A),
          );
        }
        return _pair(
          family: TransactionVisualFamily.deposit,
          isOutgoing: false,
          incomingLabel: 'Depósito',
          outgoingLabel: 'Depósito',
          icon: Icons.download_for_offline_rounded,
          iconColor: const Color(0xFF9EB3A4),
        );
      case TransactionType.withdrawal:
        if (_looksLikeLightning(transaction)) {
          return _pair(
            family: TransactionVisualFamily.lightning,
            isOutgoing: true,
            incomingLabel: 'Recebimento Lightning',
            outgoingLabel: 'Pagamento Lightning',
            icon: Icons.flash_on_rounded,
            iconColor: const Color(0xFFE3B85A),
          );
        }
        if (_looksLikeCashWithdrawal(transaction)) {
          return _pair(
            family: TransactionVisualFamily.withdrawal,
            isOutgoing: true,
            incomingLabel: 'Saque',
            outgoingLabel: 'Saque',
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
        incomingLabel: 'Recebimento por NFC',
        outgoingLabel: 'Pagamento por NFC',
        icon: Icons.nfc_rounded,
        iconColor: const Color(0xFF93A5B5),
      );
    }

    if (_looksLikeQr(transaction)) {
      return _pair(
        family: TransactionVisualFamily.qrCode,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento via QR',
        outgoingLabel: 'Pagamento via QR',
        icon: Icons.qr_code_2_rounded,
        iconColor: const Color(0xFF9AA6B2),
      );
    }

    if (_looksLikePaymentLink(transaction)) {
      return _pair(
        family: TransactionVisualFamily.paymentLink,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento por link',
        outgoingLabel: 'Pagamento por link',
        icon: Icons.link_rounded,
        iconColor: const Color(0xFF9FA8B3),
      );
    }

    if (_looksLikeInternal(transaction)) {
      return _pair(
        family: TransactionVisualFamily.internalTransfer,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento interno',
        outgoingLabel: 'Envio interno',
        icon: Icons.compare_arrows_rounded,
        iconColor: const Color(0xFF8794A3),
      );
    }

    if (_looksLikeLightning(transaction)) {
      return _pair(
        family: TransactionVisualFamily.lightning,
        isOutgoing: isOutgoing,
        incomingLabel: 'Recebimento Lightning',
        outgoingLabel: 'Pagamento Lightning',
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
        label: 'Evento',
        prefix: '',
        icon: Icons.help_outline_rounded,
        iconColor: Color(0xFF9CA8B4),
        amountColor: _neutralAmountColor,
      );
    }

    return _pair(
      family: TransactionVisualFamily.onChain,
      isOutgoing: isOutgoing,
      incomingLabel: 'Recebimento on-chain',
      outgoingLabel: 'Envio on-chain',
      icon: Icons.hub_rounded,
      iconColor: const Color(0xFF9CA8B4),
    );
  }

  static TransactionVisualSpec _pair({
    required TransactionVisualFamily family,
    required bool isOutgoing,
    required String incomingLabel,
    required String outgoingLabel,
    required IconData icon,
    required Color iconColor,
  }) {
    return TransactionVisualSpec(
      family: family,
      direction: isOutgoing
          ? TransactionVisualDirection.outgoing
          : TransactionVisualDirection.incoming,
      label: isOutgoing ? outgoingLabel : incomingLabel,
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

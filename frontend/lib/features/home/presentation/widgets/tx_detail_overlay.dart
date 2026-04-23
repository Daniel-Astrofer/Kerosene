import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/mining/presentation/mining_explorer.dart';
import 'package:teste/features/mining/presentation/screens/mining_screen.dart';

import '../../../wallet/domain/entities/transaction.dart';

class TxDetailOverlay extends ConsumerWidget {
  final Transaction tx;
  final VoidCallback onClose;

  const TxDetailOverlay({
    super.key,
    required this.tx,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final explorer = MiningExplorerDescriptor.fromTransaction(tx);
    final amountSign = _isOutgoing(tx) ? '-' : '+';
    final primaryAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: tx.amountBTC,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final feeAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: tx.feeBTC,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final cryptoAmount = MoneyDisplay.format(
      amount: tx.amountBTC,
      currency: Currency.btc,
    );
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.76),
      body: GestureDetector(
        onTap: onClose,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 340,
                  maxHeight: size.height * 0.52,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: authenticatedSurfaceBackgroundColor,
                    border: Border.all(color: const Color(0xFF2A3037)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: _OverlayIconButton(
                            icon: LucideIcons.x,
                            onTap: onClose,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111418),
                              border: Border.all(
                                color: const Color(0xFF2A3037),
                              ),
                            ),
                            child: Icon(
                              _iconForTransaction(tx, explorer),
                              color: Colors.white.withValues(alpha: 0.84),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _typeLabel(tx),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$amountSign$primaryAmount',
                          textAlign: TextAlign.center,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        if (selectedCurrency != Currency.btc) ...[
                          const SizedBox(height: 4),
                          Text(
                            cryptoAmount,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontFamily: 'JetBrainsMono',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: LucideIcons.clock3,
                          label: 'Status',
                          value: tx.status.displayName,
                          valueColor: _statusColor(tx.status),
                        ),
                        _DetailRow(
                          icon: LucideIcons.calendarClock,
                          label: 'Data e hora',
                          value: _formatTimestamp(tx.timestamp),
                        ),
                        _DetailRow(
                          icon: _counterpartyIcon(tx),
                          label: _counterpartyLabel(tx),
                          value: _abbrevValue(_counterpartyValue(tx)),
                        ),
                        _DetailRow(
                          icon: _railIcon(explorer),
                          label: 'Rede',
                          value: explorer.badgeLabel,
                        ),
                        _DetailRow(
                          icon: LucideIcons.network,
                          label: 'Referência',
                          value: _abbrevValue(_primaryReference(tx, explorer)),
                        ),
                        if ((tx.description ?? '').trim().isNotEmpty)
                          _DetailRow(
                            icon: LucideIcons.fileText,
                            label: 'Descrição',
                            value: tx.description!.trim(),
                          ),
                        if (tx.feeSatoshis > 0)
                          _DetailRow(
                            icon: LucideIcons.receipt,
                            label: 'Taxa',
                            value: feeAmount,
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _OverlayActionButton(
                                label: 'Copiar dados',
                                icon: LucideIcons.copy,
                                onTap: () => _copyTransactionSummary(
                                  context,
                                  tx: tx,
                                  explorer: explorer,
                                  primaryAmount: primaryAmount,
                                  cryptoAmount: cryptoAmount,
                                  feeAmount: feeAmount,
                                  amountSign: amountSign,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _OverlayActionButton(
                                label: explorer.buttonLabel,
                                icon: _railIcon(explorer),
                                emphasis: true,
                                onTap: () {
                                  final navigator = Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  );
                                  final route = MaterialPageRoute<void>(
                                    builder: (_) => MiningScreen(
                                      initialTransaction: tx,
                                    ),
                                  );

                                  navigator.pop();
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (navigator.mounted) {
                                      navigator.push(route);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyTransactionSummary(
    BuildContext context, {
    required Transaction tx,
    required MiningExplorerDescriptor explorer,
    required String primaryAmount,
    required String cryptoAmount,
    required String feeAmount,
    required String amountSign,
  }) async {
    final summary = <String>[
      'Tipo: ${_typeLabel(tx)}',
      'Status: ${tx.status.displayName}',
      'Valor: $amountSign$primaryAmount',
      'BTC: $cryptoAmount',
      'Data: ${_formatTimestamp(tx.timestamp)}',
      '${_counterpartyLabel(tx)}: ${_counterpartyValue(tx)}',
      'Rede: ${explorer.badgeLabel}',
      'Referência: ${_primaryReference(tx, explorer)}',
      if ((tx.description ?? '').trim().isNotEmpty)
        'Descrição: ${tx.description!.trim()}',
      if (tx.feeSatoshis > 0) 'Taxa: $feeAmount',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: summary));

    if (!context.mounted) {
      return;
    }

    AppNotice.showSuccess(
      context,
      title: 'Dados copiados',
      message: 'Resumo da transação copiado para a área de transferência.',
    );
  }

  static bool _isOutgoing(Transaction tx) {
    return tx.type == TransactionType.send ||
        tx.type == TransactionType.withdrawal;
  }

  static String _typeLabel(Transaction tx) {
    if (tx.isLightning) {
      return 'LIGHTNING';
    }

    if (tx.isInternal) {
      return _isOutgoing(tx) ? 'CHEQUE ENVIADO' : 'CHEQUE RECEBIDO';
    }

    switch (tx.type) {
      case TransactionType.send:
        return 'ENVIO';
      case TransactionType.receive:
        return 'RECEBIMENTO';
      case TransactionType.deposit:
        return 'DEPÓSITO';
      case TransactionType.withdrawal:
        return 'SAQUE';
      case TransactionType.swap:
        return 'SWAP';
      case TransactionType.fee:
        return 'TAXA';
    }
  }

  static IconData _iconForTransaction(
    Transaction tx,
    MiningExplorerDescriptor explorer,
  ) {
    if (tx.isLightning || explorer.rail == MiningExplorerRail.lightning) {
      return LucideIcons.zap;
    }

    if (tx.isInternal || explorer.rail == MiningExplorerRail.internal) {
      return LucideIcons.receipt;
    }

    switch (tx.type) {
      case TransactionType.send:
      case TransactionType.withdrawal:
        return LucideIcons.arrowUpFromLine;
      case TransactionType.receive:
      case TransactionType.deposit:
        return LucideIcons.arrowDownToLine;
      case TransactionType.swap:
        return LucideIcons.arrowLeftRight;
      case TransactionType.fee:
        return LucideIcons.receipt;
    }
  }

  static IconData _counterpartyIcon(Transaction tx) {
    return _isOutgoing(tx)
        ? LucideIcons.arrowUpRight
        : LucideIcons.arrowDownLeft;
  }

  static String _counterpartyLabel(Transaction tx) {
    return _isOutgoing(tx) ? 'Destinatário' : 'Remetente';
  }

  static String _counterpartyValue(Transaction tx) {
    return _isOutgoing(tx) ? tx.toAddress : tx.fromAddress;
  }

  static IconData _railIcon(MiningExplorerDescriptor explorer) {
    switch (explorer.rail) {
      case MiningExplorerRail.blockchain:
        return LucideIcons.network;
      case MiningExplorerRail.lightning:
        return LucideIcons.zap;
      case MiningExplorerRail.internal:
        return LucideIcons.receipt;
    }
  }

  static String _primaryReference(
    Transaction tx,
    MiningExplorerDescriptor explorer,
  ) {
    return explorer.reference.trim().isNotEmpty
        ? explorer.reference
        : (tx.blockchainTxid ?? tx.id);
  }

  static String _abbrevValue(String value) {
    final normalized = value.trim();
    if (normalized.length <= 24) {
      return normalized;
    }
    return '${normalized.substring(0, 12)}...${normalized.substring(normalized.length - 10)}';
  }

  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  static Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return const Color(0xFFFF9F0A);
      case TransactionStatus.confirming:
        return const Color(0xFFFFCC00);
      case TransactionStatus.confirmed:
        return const Color(0xFFD4D8DD);
      case TransactionStatus.failed:
        return const Color(0xFFFF453A);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111418),
          border: Border.all(color: const Color(0xFF2A3037)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1014),
                border: Border.all(color: const Color(0xFF2A3037)),
              ),
              child: Icon(
                icon,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: valueColor ?? Colors.white.withValues(alpha: 0.86),
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool emphasis;
  final VoidCallback onTap;

  const _OverlayActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.04),
        ),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: emphasis ? const Color(0xFF111418) : const Color(0xFF0D1014),
            border: Border.all(color: const Color(0xFF2A3037)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.04),
        ),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF111418),
            border: Border.all(color: const Color(0xFF2A3037)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(alpha: 0.76),
          ),
        ),
      ),
    );
  }
}

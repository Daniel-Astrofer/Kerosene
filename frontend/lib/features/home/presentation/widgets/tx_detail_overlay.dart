import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/utils/transaction_address_display.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/mining/presentation/mining_explorer.dart';
import 'package:teste/features/mining/presentation/screens/mining_screen.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';

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
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final explorer = MiningExplorerDescriptor.fromTransaction(tx);
    final visual = TransactionVisualSpec.fromTransaction(tx);
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
    final amountPrefix = visual.prefix.isEmpty ? '' : visual.prefix;

    final detailItems = <_DetailItem>[
      _DetailItem(
        label: 'Data',
        value: _formatTimestamp(tx.timestamp),
      ),
      _DetailItem(
        label: _counterpartyLabel(tx),
        value: _abbrevValue(_counterpartyValue(tx)),
      ),
      _DetailItem(
        label: 'Rede',
        value: explorer.badgeLabel,
      ),
      _DetailItem(
        label: 'Referência',
        value: _abbrevValue(_primaryReference(tx, explorer)),
      ),
      if ((tx.invoiceId ?? '').trim().isNotEmpty)
        _DetailItem(
          label: 'Invoice ID',
          value: _abbrevValue(tx.invoiceId!.trim()),
        ),
      if ((tx.paymentHash ?? '').trim().isNotEmpty)
        _DetailItem(
          label: 'Payment hash',
          value: _abbrevValue(tx.paymentHash!.trim()),
        ),
      if ((tx.lightningInvoice ?? '').trim().isNotEmpty)
        _DetailItem(
          label: 'Invoice Lightning',
          value: tx.lightningInvoice!.trim(),
          fullWidth: true,
          maxLines: 2,
        ),
      if ((tx.description ?? '').trim().isNotEmpty)
        _DetailItem(
          label: 'Descrição',
          value: tx.description!.trim(),
          fullWidth: true,
          maxLines: 3,
        ),
      if (tx.feeSatoshis > 0)
        _DetailItem(
          label: 'Taxa',
          value: feeAmount,
        ),
      _DetailItem(
        label: 'Confirmações',
        value: tx.confirmations.toString(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.84),
      body: GestureDetector(
        onTap: onClose,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: monochromePanelDecoration(
                      color: monoSurfaceColor,
                      borderColor: monoBorderStrongColor,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = (constraints.maxWidth - 10) / 2;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'DETALHES DA TRANSACAO',
                                    style: AppTypography.caption.copyWith(
                                      color: monoMutedTextColor,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ),
                                _OverlayIconButton(
                                  icon: LucideIcons.x,
                                  onTap: onClose,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _SemanticBadge(
                                  icon: visual.icon,
                                  label: _familyLabel(visual.family),
                                ),
                                _SemanticBadge(
                                  icon: _railIcon(explorer),
                                  label: explorer.badgeLabel,
                                ),
                                _SemanticBadge(
                                  icon: _statusIcon(tx.status),
                                  label: tx.status.displayName,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: monochromePanelDecoration(
                                color: monoSurfaceAltColor,
                                borderColor: monoBorderStrongColor,
                                showShadow: false,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: monochromePanelDecoration(
                                      color: monoSurfaceRaisedColor,
                                      borderColor: monoBorderStrongColor,
                                      showShadow: false,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      visual.icon,
                                      color: monoTextColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    visual.label.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: monoMutedTextColor,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$amountPrefix$primaryAmount',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.h2.copyWith(
                                      color: monoTextColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  if (selectedCurrency != Currency.btc) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      cryptoAmount,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: monoMutedTextColor,
                                            fontFamily: 'JetBrainsMono',
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: detailItems.map((item) {
                                return SizedBox(
                                  width: item.fullWidth
                                      ? constraints.maxWidth
                                      : tileWidth,
                                  child: _DetailTile(item: item),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
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
                                      amountSign: amountPrefix,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                        );
                      },
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
      'Tipo: ${TransactionVisualSpec.fromTransaction(tx).label}',
      'Status: ${tx.status.displayName}',
      'Valor: $amountSign$primaryAmount',
      'BTC: $cryptoAmount',
      'Data: ${_formatTimestamp(tx.timestamp)}',
      '${_counterpartyLabel(tx)}: ${_counterpartyValue(tx)}',
      'Rede: ${explorer.badgeLabel}',
      'Referência: ${_primaryReference(tx, explorer)}',
      if ((tx.invoiceId ?? '').trim().isNotEmpty)
        'Invoice ID: ${tx.invoiceId!.trim()}',
      if ((tx.paymentHash ?? '').trim().isNotEmpty)
        'Payment hash: ${tx.paymentHash!.trim()}',
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

  static String _counterpartyLabel(Transaction tx) {
    return resolvePrimaryTransactionAddressLabel(tx);
  }

  static String _counterpartyValue(Transaction tx) {
    final value = resolvePrimaryTransactionAddress(tx).trim();
    return value.isEmpty ? 'Endereço indisponível' : value;
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

  static IconData _statusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return LucideIcons.clock3;
      case TransactionStatus.confirming:
        return LucideIcons.scanLine;
      case TransactionStatus.confirmed:
        return LucideIcons.check;
      case TransactionStatus.failed:
        return LucideIcons.alertCircle;
    }
  }

  static String _familyLabel(TransactionVisualFamily family) {
    switch (family) {
      case TransactionVisualFamily.paymentLink:
        return 'Link';
      case TransactionVisualFamily.qrCode:
        return 'QR Code';
      case TransactionVisualFamily.nfc:
        return 'NFC';
      case TransactionVisualFamily.lightning:
        return 'Lightning';
      case TransactionVisualFamily.internalTransfer:
        return 'Cheque';
      case TransactionVisualFamily.deposit:
        return 'Depósito';
      case TransactionVisualFamily.withdrawal:
        return 'Saque';
      case TransactionVisualFamily.onChain:
        return 'On-chain';
      case TransactionVisualFamily.swap:
        return 'Swap';
      case TransactionVisualFamily.fee:
        return 'Taxa';
      case TransactionVisualFamily.failed:
        return 'Falha';
      case TransactionVisualFamily.cancelled:
        return 'Cancelado';
      case TransactionVisualFamily.mining:
        return 'Mineração';
      case TransactionVisualFamily.refund:
        return 'Estorno';
      case TransactionVisualFamily.unknown:
        return 'Evento';
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
    if (normalized.length <= 28) {
      return normalized;
    }
    return '${normalized.substring(0, 12)}...${normalized.substring(normalized.length - 10)}';
  }

  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailItem {
  final String label;
  final String value;
  final bool fullWidth;
  final int maxLines;

  const _DetailItem({
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.maxLines = 2,
  });
}

class _DetailTile extends StatelessWidget {
  final _DetailItem item;

  const _DetailTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderColor,
        showShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoMutedTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: item.maxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoTextColor,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _SemanticBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SemanticBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderStrongColor,
        showShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: monoTextColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
        ],
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
        child: Ink(
          height: 48,
          decoration: monochromePanelDecoration(
            color: emphasis ? monoTextColor : monoSurfaceAltColor,
            borderColor: monoBorderStrongColor,
            showShadow: false,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: emphasis ? Colors.black : monoTextColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: emphasis ? Colors.black : monoTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
        child: Ink(
          width: 36,
          height: 36,
          decoration: monochromePanelDecoration(
            color: monoSurfaceAltColor,
            borderColor: monoBorderStrongColor,
            showShadow: false,
          ),
          child: Icon(
            icon,
            size: 16,
            color: monoTextColor,
          ),
        ),
      ),
    );
  }
}

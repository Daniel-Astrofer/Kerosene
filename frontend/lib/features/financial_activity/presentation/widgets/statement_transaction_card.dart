import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/currency_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_activity/presentation/utils/transaction_address_display.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_visuals.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

import 'package:kerosene/core/theme/app_typography.dart';

enum StatementTransactionCardMode { stacked, separated }

class StatementTransactionScrollStack extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double expandedItemExtent;
  final double itemGap;
  final double stackGap;
  final double topAnchorOffset;
  final double collapseStartFraction;
  final int? expandedIndex;

  const StatementTransactionScrollStack({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 172,
    this.expandedItemExtent = 360,
    this.itemGap = 12,
    this.stackGap = 112,
    this.topAnchorOffset = 10,
    this.collapseStartFraction = 0.75,
    this.expandedIndex,
  });

  @override
  State<StatementTransactionScrollStack> createState() =>
      _StatementTransactionScrollStackState();
}

class _StatementTransactionScrollStackState
    extends State<StatementTransactionScrollStack> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindScrollPosition();
  }

  @override
  void dispose() {
    _position?.removeListener(_handleScroll);
    super.dispose();
  }

  void _bindScrollPosition() {
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(_position, nextPosition)) return;
    _position?.removeListener(_handleScroll);
    _position = nextPosition;
    _position?.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _bindScrollPosition();

    if (widget.itemCount <= 0) return const SizedBox.shrink();

    final expandedIndex = _validExpandedIndex();
    final expandedExtra = expandedIndex == null
        ? 0.0
        : math.max(0.0, widget.expandedItemExtent - widget.itemExtent);
    final step = widget.itemExtent + widget.itemGap;
    final totalHeight = widget.itemExtent +
        math.max(0, widget.itemCount - 1) * step +
        expandedExtra;
    final listTop = _globalTopOfList();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeTop = MediaQuery.viewPaddingOf(context).top;
    final collapseStartTop = screenHeight * widget.collapseStartFraction;
    final collapseEndTop = safeTop + widget.topAnchorOffset;
    final paintOrder = _paintOrder(expandedIndex);

    return AnimatedSize(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final index in paintOrder)
              _positionedItem(
                context,
                index: index,
                naturalTop: index * step,
                listTop: listTop,
                collapseStartTop: collapseStartTop,
                collapseEndTop: collapseEndTop,
              ),
          ],
        ),
      ),
    );
  }

  int? _validExpandedIndex() {
    final index = widget.expandedIndex;
    if (index == null || index < 0 || index >= widget.itemCount) return null;
    return index;
  }

  List<int> _paintOrder(int? expandedIndex) {
    final indexes = List<int>.generate(widget.itemCount, (index) => index);
    if (expandedIndex == null) return indexes;
    indexes.remove(expandedIndex);
    indexes.add(expandedIndex);
    return indexes;
  }

  Widget _positionedItem(
    BuildContext context, {
    required int index,
    required double naturalTop,
    required double listTop,
    required double collapseStartTop,
    required double collapseEndTop,
  }) {
    final collapseRange = math.max(1.0, collapseStartTop - collapseEndTop);
    final collapseProgress =
        ((collapseStartTop - listTop) / collapseRange).clamp(0.0, 1.0);
    final stackedTop = index * widget.stackGap;
    final top = naturalTop + (stackedTop - naturalTop) * collapseProgress;
    return AnimatedPositioned(
      duration: KeroseneMotion.fast,
      curve: KeroseneMotion.standard,
      left: 0,
      right: 0,
      top: top,
      child: widget.itemBuilder(context, index),
    );
  }

  double _globalTopOfList() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return double.infinity;
    }
    return renderObject.localToGlobal(Offset.zero).dy;
  }
}

class StatementTransactionCard extends ConsumerWidget {
  final Transaction transaction;
  final bool expanded;
  final VoidCallback? onTap;
  final StatementTransactionCardMode mode;

  const StatementTransactionCard({
    super.key,
    required this.transaction,
    this.expanded = false,
    this.onTap,
    this.mode = StatementTransactionCardMode.stacked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = TransactionVisualSpec.fromTransaction(transaction);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final style = _StatementCardStyle.fromTransaction(transaction);
    final amountLabel = _amountLabel(
      transaction: transaction,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final title = _title(context, transaction, visual);
    final counterparty = _counterparty(context, transaction);
    final date = transaction.timestamp.toLocal();
    final timestampLabel =
        '${_dateFormat.format(date)}\n${_timeFormat.format(date)}';
    final compact = mode == StatementTransactionCardMode.stacked && !expanded;
    final cardPadding = compact ? 16.0 : 20.0;
    final iconSize = compact ? 42.0 : 48.0;
    final titleFontSize = compact ? 15.0 : 17.0;
    final counterpartyFontSize = compact ? 12.0 : 13.0;
    final amountFontSize = compact ? 24.0 : 30.0;
    final headerAmountGap = compact ? 12.0 : 22.0;
    final amountStatusGap = compact ? 10.0 : 16.0;
    final pillScale = compact ? 0.92 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: KeroseneMotion.medium,
          curve: KeroseneMotion.standard,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: style.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(transaction, visual),
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: AppTypography.bodyFontFamily,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          counterparty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.secondaryText,
                            fontFamily: AppTypography.bodyFontFamily,
                            fontSize: counterpartyFontSize,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    timestampLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: style.timeText,
                      fontFamily: AppTypography.bodyFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: headerAmountGap),
              Text(
                amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: AppTypography.bodyFontFamily,
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: amountStatusGap),
              Transform.scale(
                scale: pillScale,
                alignment: Alignment.centerLeft,
                child: _StatusPill(status: transaction.status),
              ),
              AnimatedSize(
                duration: KeroseneMotion.medium,
                curve: KeroseneMotion.standard,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: _TransactionDetailsTable(
                          transaction: transaction,
                          style: style,
                          btcAmount: MoneyDisplay.formatAmountFromBtc(
                            btcAmount: transaction.signedAmountBTC,
                            currency: Currency.btc,
                            btcUsd: btcUsd,
                            btcEur: btcEur,
                            btcBrl: btcBrl,
                            signed: true,
                          ),
                          feeAmount: transaction.hasNetworkFee &&
                                  transaction.feeSatoshis > 0
                              ? MoneyDisplay.format(
                                  amount: transaction.feeBTC,
                                  currency: Currency.btc,
                                )
                              : null,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String _amountLabel({
    required Transaction transaction,
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    final signedAmount = transaction.signedAmountBTC;
    return MoneyDisplay.formatFrozenAmountFromBtc(
      btcAmount: signedAmount,
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      displayAmountUsd: transaction.displayAmountUsd,
      displayAmountEur: transaction.displayAmountEur,
      displayAmountBrl: transaction.displayAmountBrl,
      displayBtcUsd: transaction.displayBtcUsd,
      displayBtcEur: transaction.displayBtcEur,
      displayBtcBrl: transaction.displayBtcBrl,
      signed: true,
    );
  }

  static bool _isDebit(Transaction transaction) {
    return transaction.isDebit;
  }

  static String _title(
    BuildContext context,
    Transaction tx,
    TransactionVisualSpec visual,
  ) {
    if (tx.isInternal) return 'Transação Interna';
    if (tx.isLightning) return 'Lightning';
    if (visual.family == TransactionVisualFamily.onChain ||
        visual.family == TransactionVisualFamily.deposit ||
        visual.family == TransactionVisualFamily.withdrawal) {
      return 'Onchain';
    }
    return visual.localizedLabel(context);
  }

  static String _counterparty(BuildContext context, Transaction tx) {
    final sent = _isDebit(tx);
    final label = sent ? 'Para' : 'De';
    final value = resolvePrimaryTransactionAddress(tx).trim();
    final fallback = tx.description?.trim() ?? '';
    final display = value.isNotEmpty
        ? _shorten(value, head: tx.isInternal ? 18 : 16, tail: 6)
        : fallback.isNotEmpty
            ? _shorten(fallback, head: 18, tail: 6)
            : 'Carteira Kerosene';
    return '$label: $display';
  }

  static IconData _iconFor(Transaction tx, TransactionVisualSpec visual) {
    if (tx.isInternal) return KeroseneIcons.group;
    if (tx.isLightning) return KeroseneIcons.lightning;
    if (tx.status == TransactionStatus.failed) return KeroseneIcons.warning;
    return KeroseneIcons.archive;
  }

  static String _shorten(String value, {int head = 12, int tail = 6}) {
    final normalized = value.trim();
    if (normalized.length <= head + tail + 3) return normalized;
    return '${normalized.substring(0, head)}...${normalized.substring(normalized.length - tail)}';
  }
}

class _TransactionDetailsTable extends StatelessWidget {
  final Transaction transaction;
  final _StatementCardStyle style;
  final String btcAmount;
  final String? feeAmount;

  const _TransactionDetailsTable({
    required this.transaction,
    required this.style,
    required this.btcAmount,
    this.feeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final reference = _firstNonEmpty([
      transaction.blockchainTxid,
      transaction.paymentHash,
      transaction.invoiceId,
      transaction.externalReference,
    ]);
    final senderValue = resolveTransactionSender(transaction);
    final recipientValue = resolveTransactionRecipient(transaction);
    final rows = [
      _TransactionDetailRow(
        key: 'from',
        label: _titleCase(context.tr.homeCounterpartyFrom),
        displayValue: _detailValue(context, senderValue),
        copyValue: _copyValue(transaction.fromAddress),
      ),
      _TransactionDetailRow(
        key: 'to',
        label: _titleCase(context.tr.homeCounterpartyTo),
        displayValue: _detailValue(context, recipientValue),
        copyValue: _copyValue(transaction.toAddress),
      ),
      _TransactionDetailRow(
        key: 'amount',
        label: context.tr.amount,
        displayValue: btcAmount,
      ),
      if (feeAmount != null)
        _TransactionDetailRow(
          key: 'network-fee',
          label: context.tr.networkFee,
          displayValue: feeAmount!,
        ),
      _TransactionDetailRow(
        key: 'id',
        label: _localizedCopy(
          context,
          pt: 'ID da transação',
          en: 'Transaction ID',
          es: 'ID de transacción',
        ),
        displayValue: StatementTransactionCard._shorten(transaction.id),
        copyValue: _copyValue(transaction.id),
      ),
      if (reference != null && reference != transaction.id)
        _TransactionDetailRow(
          key: 'reference',
          label: _localizedCopy(
            context,
            pt: 'Referência',
            en: 'Reference',
            es: 'Referencia',
          ),
          displayValue: StatementTransactionCard._shorten(reference),
          copyValue: reference,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: style.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Divider(height: 1, color: style.divider),
                ),
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                child: _TransactionDetailsRow(row: rows[index], style: style),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _detailValue(BuildContext context, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return _localizedCopy(
        context,
        pt: '—',
        en: '—',
        es: '—',
      );
    }
    return StatementTransactionCard._shorten(trimmed, head: 18, tail: 8);
  }
}

class _TransactionDetailsRow extends StatelessWidget {
  final _TransactionDetailRow row;
  final _StatementCardStyle style;

  const _TransactionDetailsRow({required this.row, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.label,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: AppTypography.bodyFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            row.displayValue,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.secondaryText,
              fontFamily: row.displayValue.length > 20
                  ? AppTypography.financialFontFamily
                  : AppTypography.bodyFontFamily,
              fontSize: row.displayValue.length > 20 ? 12 : 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        if (row.copyValue != null) ...[
          const SizedBox(width: 8),
          _TransactionDetailCopyButton(row: row, style: style),
        ],
      ],
    );
  }
}

class _TransactionDetailCopyButton extends StatelessWidget {
  final _TransactionDetailRow row;
  final _StatementCardStyle style;

  const _TransactionDetailCopyButton({required this.row, required this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr.copy,
      child: IconButton(
        key: ValueKey('statement-detail-copy-${row.key}'),
        onPressed: () => _copyDetail(context, row),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        icon: Icon(KeroseneIcons.copy, size: 15, color: style.secondaryText),
      ),
    );
  }

  Future<void> _copyDetail(
    BuildContext context,
    _TransactionDetailRow row,
  ) async {
    final value = row.copyValue;
    if (value == null) return;

    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _localizedCopy(
              context,
              pt: 'Detalhe copiado.',
              en: 'Transaction detail copied.',
              es: 'Detalle copiado.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: KeroseneMotion.loop,
        ),
      );
  }
}

class _TransactionDetailRow {
  final String key;
  final String label;
  final String displayValue;
  final String? copyValue;

  const _TransactionDetailRow({
    required this.key,
    required this.label,
    required this.displayValue,
    this.copyValue,
  });
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _copyValue(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return value;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

String _localizedCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}

class _StatusPill extends StatelessWidget {
  final TransactionStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      TransactionStatus.confirmed => (
          bg: AppColors.hexFFDCFCE7,
          fg: AppColors.hexFF166534,
          icon: KeroseneIcons.success,
          label: 'Concluída',
        ),
      TransactionStatus.confirming => (
          bg: AppColors.hexFFFFEDD5,
          fg: AppColors.hexFF9A3412,
          icon: KeroseneIcons.pending,
          label: 'Confirmando',
        ),
      TransactionStatus.pending => (
          bg: AppColors.hexFFFFEDD5,
          fg: AppColors.hexFF9A3412,
          icon: KeroseneIcons.pending,
          label: 'Pendente',
        ),
      TransactionStatus.failed => (
          bg: AppColors.hexFFFEE2E2,
          fg: AppColors.hexFF991B1B,
          icon: KeroseneIcons.warning,
          label: 'Falhou',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(colors.icon, size: 13, color: colors.fg),
          const SizedBox(width: 5),
          Text(
            colors.label,
            style: TextStyle(
              color: colors.fg,
              fontFamily: AppTypography.bodyFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementCardStyle {
  final Color background;
  final Color border;
  final Color secondaryText;
  final Color timeText;
  final Color divider;

  const _StatementCardStyle({
    required this.background,
    required this.border,
    required this.secondaryText,
    required this.timeText,
    required this.divider,
  });

  factory _StatementCardStyle.fromTransaction(Transaction tx) {
    if (tx.isLightning) {
      return const _StatementCardStyle(
        background: AppColors.hexFFFCE353,
        border: AppColors.hexFFE7CA32,
        secondaryText: AppColors.hexB3000000,
        timeText: AppColors.hex80000000,
        divider: AppColors.hex22000000,
      );
    }
    if (!tx.isInternal) {
      return const _StatementCardStyle(
        background: AppColors.hexFFFBBD75,
        border: AppColors.hexFFECA75D,
        secondaryText: AppColors.hexB3000000,
        timeText: AppColors.hex80000000,
        divider: AppColors.hex22000000,
      );
    }
    return const _StatementCardStyle(
      background: Colors.white,
      border: AppColors.hexFFE8E8EA,
      secondaryText: AppColors.hexFF6B7280,
      timeText: AppColors.hexFF9CA3AF,
      divider: AppColors.hexFFE5E7EB,
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/transaction_address_display.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

enum StatementTransactionCardMode { stacked, separated }

class StatementTransactionScrollStack extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double itemGap;
  final double stackGap;
  final double topAnchorOffset;
  final double collapseStartFraction;

  const StatementTransactionScrollStack({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 172,
    this.itemGap = 12,
    this.stackGap = 112,
    this.topAnchorOffset = 10,
    this.collapseStartFraction = 0.75,
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

    final step = widget.itemExtent + widget.itemGap;
    final totalHeight =
        widget.itemExtent + math.max(0, widget.itemCount - 1) * step;
    final listTop = _globalTopOfList();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeTop = MediaQuery.viewPaddingOf(context).top;
    final collapseStartTop = screenHeight * widget.collapseStartFraction;
    final collapseEndTop = safeTop + widget.topAnchorOffset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < widget.itemCount; index++)
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
    );
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
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
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
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
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
                            fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
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
                    '${_dateFormat.format(date)}\n${_timeFormat.format(date)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: style.timeText,
                      fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
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
                          feeAmount: MoneyDisplay.format(
                            amount: transaction.feeBTC,
                            currency: Currency.btc,
                          ),
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
    return MoneyDisplay.formatAmountFromBtc(
      btcAmount: signedAmount,
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
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
    if (tx.isInternal) return LucideIcons.users;
    if (tx.isLightning) return LucideIcons.zap;
    if (tx.status == TransactionStatus.failed) return LucideIcons.alertCircle;
    return LucideIcons.box;
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
  final String feeAmount;

  const _TransactionDetailsTable({
    required this.transaction,
    required this.style,
    required this.btcAmount,
    required this.feeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final reference = transaction.blockchainTxid ??
        transaction.paymentHash ??
        transaction.invoiceId ??
        transaction.externalReference ??
        transaction.id;
    final rows = [
      ('De', _detailValue(transaction.fromAddress, fallback: 'Carteira')),
      ('Para', _detailValue(transaction.toAddress, fallback: 'Carteira')),
      ('Valor', btcAmount),
      ('Taxa de rede', feeAmount),
      if (reference.trim().isNotEmpty)
        ('Referência', StatementTransactionCard._shorten(reference)),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rows[index].$1,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        rows[index].$2,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: style.secondaryText,
                          fontFamily: rows[index].$2.length > 20
                              ? 'monospace'
                              : 'Inter',
                          fontSize: rows[index].$2.length > 20 ? 12 : 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _detailValue(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return StatementTransactionCard._shorten(trimmed, head: 18, tail: 8);
  }
}

class _StatusPill extends StatelessWidget {
  final TransactionStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      TransactionStatus.confirmed => (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF166534),
          icon: LucideIcons.checkCircle2,
          label: 'Concluída',
        ),
      TransactionStatus.confirming => (
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFF9A3412),
          icon: LucideIcons.clock3,
          label: 'Confirmando',
        ),
      TransactionStatus.pending => (
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFF9A3412),
          icon: LucideIcons.clock3,
          label: 'Pendente',
        ),
      TransactionStatus.failed => (
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFF991B1B),
          icon: LucideIcons.alertCircle,
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
              fontFamily: 'Inter',
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
        background: Color(0xFFFCE353),
        border: Color(0xFFE7CA32),
        secondaryText: Color(0xB3000000),
        timeText: Color(0x80000000),
        divider: Color(0x22000000),
      );
    }
    if (!tx.isInternal) {
      return const _StatementCardStyle(
        background: Color(0xFFFBBD75),
        border: Color(0xFFECA75D),
        secondaryText: Color(0xB3000000),
        timeText: Color(0x80000000),
        divider: Color(0x22000000),
      );
    }
    return const _StatementCardStyle(
      background: Colors.white,
      border: Color(0xFFE8E8EA),
      secondaryText: Color(0xFF6B7280),
      timeText: Color(0xFF9CA3AF),
      divider: Color(0xFFE5E7EB),
    );
  }
}

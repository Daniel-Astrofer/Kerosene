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
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/movement/utils/transaction_address_display.dart';
import 'package:kerosene/features/movement/widgets/transaction_visuals.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';

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
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
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
                expandedIndex: expandedIndex,
                expandedExtra: expandedExtra,
                naturalTop: _naturalTop(
                  index: index,
                  step: step,
                  expandedIndex: expandedIndex,
                  expandedExtra: expandedExtra,
                ),
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
    final order = List<int>.generate(widget.itemCount, (index) => index);
    if (expandedIndex != null) {
      order
        ..remove(expandedIndex)
        ..add(expandedIndex);
    }
    return order;
  }

  Widget _positionedItem(
    BuildContext context, {
    required int index,
    required int? expandedIndex,
    required double expandedExtra,
    required double naturalTop,
    required double listTop,
    required double collapseStartTop,
    required double collapseEndTop,
  }) {
    final collapseRange = math.max(1.0, collapseStartTop - collapseEndTop);
    final collapseProgress =
        ((collapseStartTop - listTop) / collapseRange).clamp(0.0, 1.0);
    final stackedTop = _stackedTop(
      index: index,
      expandedIndex: expandedIndex,
      expandedExtra: expandedExtra,
    );
    final top = naturalTop + (stackedTop - naturalTop) * collapseProgress;
    return AnimatedPositioned(
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
      curve: KeroseneMotion.entrance,
      left: 0,
      right: 0,
      top: top,
      child: widget.itemBuilder(context, index),
    );
  }

  double _naturalTop({
    required int index,
    required double step,
    required int? expandedIndex,
    required double expandedExtra,
  }) {
    return index * step +
        (expandedIndex != null && index > expandedIndex ? expandedExtra : 0.0);
  }

  double _stackedTop({
    required int index,
    required int? expandedIndex,
    required double expandedExtra,
  }) {
    if (expandedIndex == null || index <= expandedIndex) {
      return index * widget.stackGap;
    }

    return expandedIndex * widget.stackGap +
        widget.expandedItemExtent +
        widget.itemGap +
        (index - expandedIndex - 1) * widget.stackGap;
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
    final amountLabel = _amountLabel(
      transaction: transaction,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final btcAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: transaction.signedAmountBTC,
      currency: Currency.btc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      signed: true,
    );
    final feeAmount = transaction.hasNetworkFee && transaction.feeSatoshis > 0
        ? MoneyDisplay.format(
            amount: transaction.feeBTC,
            currency: Currency.btc,
          )
        : null;
    final rail = _TransactionRailPresentation.resolve(
      context,
      transaction: transaction,
      visual: visual,
    );
    final date = transaction.timestamp.toLocal();
    final timestampLabel =
        '${_dateFormat.format(date)}\n${_timeFormat.format(date)}';

    if (mode == StatementTransactionCardMode.separated) {
      return _BankStatementTransactionRow(
        transaction: transaction,
        amountLabel: amountLabel,
        btcAmount: btcAmount,
        feeAmount: feeAmount,
        expanded: expanded,
        onTap: onTap,
      );
    }

    return _StackedTransactionCard(
      transaction: transaction,
      rail: rail,
      amountLabel: amountLabel,
      btcAmount: btcAmount,
      feeAmount: feeAmount,
      timestampLabel: timestampLabel,
      expanded: expanded,
      onTap: onTap,
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

  static String _shorten(String value, {int head = 12, int tail = 6}) {
    final normalized = value.trim();
    if (normalized.length <= head + tail + 3) return normalized;
    return '${normalized.substring(0, head)}...${normalized.substring(normalized.length - tail)}';
  }
}

enum _TransactionRail { onChain, lightning, internalTransfer }

class _TransactionRailPresentation {
  final _TransactionRail rail;
  final _StatementCardStyle style;
  final IconData icon;
  final String railLabel;
  final String title;
  final String subtitle;
  final String statusContext;
  final Color amountColor;

  const _TransactionRailPresentation({
    required this.rail,
    required this.style,
    required this.icon,
    required this.railLabel,
    required this.title,
    required this.subtitle,
    required this.statusContext,
    required this.amountColor,
  });

  factory _TransactionRailPresentation.resolve(
    BuildContext context, {
    required Transaction transaction,
    required TransactionVisualSpec visual,
  }) {
    final rail = _resolveRail(transaction, visual);
    final style = _StatementCardStyle.fromRail(rail);
    final statusContext = switch (rail) {
      _TransactionRail.onChain => _onChainStatusContext(context, transaction),
      _TransactionRail.lightning =>
        _lightningStatusContext(context, transaction),
      _TransactionRail.internalTransfer =>
        _internalStatusContext(context, transaction),
    };
    final title = _railTitle(context, transaction, visual, rail);
    final subtitle = _railSubtitle(context, transaction, rail);
    final failed = transaction.status == TransactionStatus.failed;

    return _TransactionRailPresentation(
      rail: rail,
      style: style,
      icon: _railIcon(transaction, visual, rail),
      railLabel: _railLabel(context, rail),
      title: title,
      subtitle: subtitle,
      statusContext: statusContext,
      amountColor: failed
          ? AppColors.error
          : transaction.isCredit
              ? style.accent
              : style.primaryText,
    );
  }

  static _TransactionRail _resolveRail(
    Transaction transaction,
    TransactionVisualSpec visual,
  ) {
    if (transaction.isLightning ||
        visual.family == TransactionVisualFamily.lightning) {
      return _TransactionRail.lightning;
    }
    if (transaction.isInternal ||
        visual.family == TransactionVisualFamily.internalTransfer) {
      return _TransactionRail.internalTransfer;
    }
    return _TransactionRail.onChain;
  }

  static IconData _railIcon(
    Transaction transaction,
    TransactionVisualSpec visual,
    _TransactionRail rail,
  ) {
    if (transaction.status == TransactionStatus.failed) {
      return KeroseneIcons.warning;
    }
    return switch (rail) {
      _TransactionRail.onChain => KeroseneIcons.onchain,
      _TransactionRail.lightning => KeroseneIcons.lightning,
      _TransactionRail.internalTransfer => KeroseneIcons.internalTransfer,
    };
  }

  static String _railTitle(
    BuildContext context,
    Transaction transaction,
    TransactionVisualSpec visual,
    _TransactionRail rail,
  ) {
    final visualLabel = visual.localizedLabel(context).trim();
    if (visualLabel.isNotEmpty) return visualLabel;

    final outgoing = transaction.isDebit;
    return switch (rail) {
      _TransactionRail.onChain => _localizedCopy(
          context,
          pt: outgoing ? 'Envio on-chain' : 'Recebimento on-chain',
          en: outgoing ? 'On-chain send' : 'On-chain receive',
          es: outgoing ? 'Envio on-chain' : 'Recepción on-chain',
        ),
      _TransactionRail.lightning => _localizedCopy(
          context,
          pt: outgoing ? 'Pagamento Lightning' : 'Recebimento Lightning',
          en: outgoing ? 'Lightning payment' : 'Lightning receive',
          es: outgoing ? 'Pago Lightning' : 'Recepción Lightning',
        ),
      _TransactionRail.internalTransfer => _localizedCopy(
          context,
          pt: outgoing ? 'Transferência interna' : 'Recebimento interno',
          en: outgoing ? 'Internal transfer' : 'Internal receive',
          es: outgoing ? 'Transferencia interna' : 'Recepción interna',
        ),
    };
  }

  static String _railSubtitle(
    BuildContext context,
    Transaction transaction,
    _TransactionRail rail,
  ) {
    if (rail == _TransactionRail.internalTransfer) {
      final source = _firstNonEmpty([
        transaction.sourceWalletId,
        transaction.senderDisplayName,
        transaction.fromAddress,
      ]);
      final destination = _firstNonEmpty([
        transaction.destinationWalletId,
        transaction.receiverDisplayName,
        transaction.toAddress,
      ]);
      if (source != null && destination != null) {
        return '${StatementTransactionCard._shorten(source, head: 12, tail: 5)} -> ${StatementTransactionCard._shorten(destination, head: 12, tail: 5)}';
      }
    }

    final label = transaction.isDebit
        ? _titleCase(context.tr.homeCounterpartyTo)
        : _titleCase(context.tr.homeCounterpartyFrom);
    final value = resolvePrimaryTransactionAddress(transaction).trim();
    final fallback = transaction.description?.trim() ?? '';
    final display = value.isNotEmpty
        ? StatementTransactionCard._shorten(value, head: 16, tail: 6)
        : fallback.isNotEmpty
            ? StatementTransactionCard._shorten(fallback, head: 18, tail: 6)
            : _localizedCopy(
                context,
                pt: 'Carteira Kerosene',
                en: 'Kerosene wallet',
                es: 'Billetera Kerosene',
              );
    return '$label $display';
  }
}

class _StackedTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final _TransactionRailPresentation rail;
  final String amountLabel;
  final String btcAmount;
  final String? feeAmount;
  final String timestampLabel;
  final bool expanded;
  final VoidCallback? onTap;

  const _StackedTransactionCard({
    required this.transaction,
    required this.rail,
    required this.amountLabel,
    required this.btcAmount,
    required this.feeAmount,
    required this.timestampLabel,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = rail.style;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
          curve: KeroseneMotion.standard,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: style.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 18,
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
                  _RailIconBadge(rail: rail),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StackedTransactionIdentity(rail: rail),
                  ),
                  const SizedBox(width: 10),
                  _StackedAmountBlock(
                    amountLabel: amountLabel,
                    timestampLabel: timestampLabel,
                    amountColor: rail.amountColor,
                    style: style,
                    expanded: expanded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RailStatusLine(transaction: transaction, rail: rail),
              _AnimatedExpandedTransactionDetails(
                expanded: expanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _TransactionDetailsTable(
                    transaction: transaction,
                    rail: rail.rail,
                    style: style,
                    btcAmount: btcAmount,
                    feeAmount: feeAmount,
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

class _RailIconBadge extends StatelessWidget {
  final _TransactionRailPresentation rail;

  const _RailIconBadge({required this.rail});

  @override
  Widget build(BuildContext context) {
    final style = rail.style;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: style.iconBackground,
        shape: BoxShape.circle,
        border: Border.all(color: style.accent.withValues(alpha: 0.42)),
      ),
      child: Icon(rail.icon, color: style.iconForeground, size: 20),
    );
  }
}

class _StackedTransactionIdentity extends StatelessWidget {
  final _TransactionRailPresentation rail;

  const _StackedTransactionIdentity({required this.rail});

  @override
  Widget build(BuildContext context) {
    final style = rail.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                rail.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: style.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.16,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: _RailLabelPill(rail: rail),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          rail.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: style.secondaryText,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.22,
          ),
        ),
      ],
    );
  }
}

class _RailLabelPill extends StatelessWidget {
  final _TransactionRailPresentation rail;

  const _RailLabelPill({required this.rail});

  @override
  Widget build(BuildContext context) {
    final style = rail.style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: style.accentSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        rail.railLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label.copyWith(
          color: style.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

class _StackedAmountBlock extends StatelessWidget {
  final String amountLabel;
  final String timestampLabel;
  final Color amountColor;
  final _StatementCardStyle style;
  final bool expanded;

  const _StackedAmountBlock({
    required this.amountLabel,
    required this.timestampLabel,
    required this.amountColor,
    required this.style,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timestampLabel,
            textAlign: TextAlign.right,
            style: AppTypography.caption.copyWith(
              color: style.timeText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              amountLabel,
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTypography.financial(
                color: amountColor,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
            curve: KeroseneMotion.standard,
            child: Icon(
              KeroseneIcons.chevronDown,
              size: 18,
              color: style.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailStatusLine extends StatelessWidget {
  final Transaction transaction;
  final _TransactionRailPresentation rail;

  const _RailStatusLine({
    required this.transaction,
    required this.rail,
  });

  @override
  Widget build(BuildContext context) {
    final style = rail.style;
    final statusVisual = _TransactionStatusVisual.resolve(
      context,
      transaction.status,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: style.detailBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusVisual.darkForeground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusVisual.label,
            style: AppTypography.label.copyWith(
              color: statusVisual.darkForeground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rail.statusContext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: style.secondaryText,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailDetailHeader extends StatelessWidget {
  final Transaction transaction;
  final _TransactionRail rail;
  final _StatementCardStyle style;

  const _RailDetailHeader({
    required this.transaction,
    required this.rail,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final primary = switch (rail) {
      _TransactionRail.onChain => _onChainStatusContext(context, transaction),
      _TransactionRail.lightning =>
        _lightningStatusContext(context, transaction),
      _TransactionRail.internalTransfer =>
        _internalStatusContext(context, transaction),
    };
    final secondary = switch (rail) {
      _TransactionRail.onChain => _blockchainVisibilityLabel(
          context,
          transaction,
        ),
      _TransactionRail.lightning => _firstNonEmpty([
            transaction.externalTransferStatus,
            transaction.externalTransferType,
            transaction.invoiceId,
          ]) ??
          _localizedCopy(
            context,
            pt: 'Sem referência externa',
            en: 'No external reference',
            es: 'Sin referencia externa',
          ),
      _TransactionRail.internalTransfer => _localizedCopy(
          context,
          pt: 'Movimento interno da plataforma',
          en: 'Internal platform movement',
          es: 'Movimiento interno de la plataforma',
        ),
    };

    return Row(
      children: [
        Expanded(
          child: _RailMetricChip(
            label: _localizedCopy(
              context,
              pt: 'Estado',
              en: 'State',
              es: 'Estado',
            ),
            value: primary,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RailMetricChip(
            label: _railMetricLabel(context, rail),
            value: secondary,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _RailMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final _StatementCardStyle style;

  const _RailMetricChip({
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: style.detailBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: style.timeText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: style.primaryText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

String _railLabel(BuildContext context, _TransactionRail rail) {
  return switch (rail) {
    _TransactionRail.onChain => _localizedCopy(
        context,
        pt: 'On-chain',
        en: 'On-chain',
        es: 'On-chain',
      ),
    _TransactionRail.lightning => 'Lightning',
    _TransactionRail.internalTransfer => _localizedCopy(
        context,
        pt: 'Interna',
        en: 'Internal',
        es: 'Interna',
      ),
  };
}

String _railMetricLabel(BuildContext context, _TransactionRail rail) {
  return switch (rail) {
    _TransactionRail.onChain => _localizedCopy(
        context,
        pt: 'Blockchain',
        en: 'Blockchain',
        es: 'Blockchain',
      ),
    _TransactionRail.lightning => _localizedCopy(
        context,
        pt: 'Referência',
        en: 'Reference',
        es: 'Referencia',
      ),
    _TransactionRail.internalTransfer => _localizedCopy(
        context,
        pt: 'Escopo',
        en: 'Scope',
        es: 'Alcance',
      ),
  };
}

String _onChainStatusContext(BuildContext context, Transaction transaction) {
  if (transaction.status == TransactionStatus.failed) {
    return _localizedCopy(
      context,
      pt: 'Falha antes da confirmação',
      en: 'Failed before confirmation',
      es: 'Falló antes de confirmar',
    );
  }
  if (transaction.confirmations > 0) {
    return _confirmationsLabel(context, transaction.confirmations);
  }
  if (_hasBlockchainEvidence(transaction)) {
    return _localizedCopy(
      context,
      pt: 'Vista na blockchain',
      en: 'Seen on blockchain',
      es: 'Vista en blockchain',
    );
  }
  return _localizedCopy(
    context,
    pt: 'Aguardando publicação',
    en: 'Waiting for broadcast',
    es: 'Esperando publicación',
  );
}

String _lightningStatusContext(BuildContext context, Transaction transaction) {
  if (transaction.status == TransactionStatus.failed) {
    return _localizedCopy(
      context,
      pt: 'Pagamento não liquidado',
      en: 'Payment not settled',
      es: 'Pago no liquidado',
    );
  }
  if (transaction.status == TransactionStatus.confirmed) {
    return _localizedCopy(
      context,
      pt: 'Liquidada',
      en: 'Settled',
      es: 'Liquidada',
    );
  }
  if (_firstNonEmpty([transaction.paymentHash, transaction.invoiceId]) !=
      null) {
    return _localizedCopy(
      context,
      pt: 'Aguardando liquidação',
      en: 'Awaiting settlement',
      es: 'Esperando liquidación',
    );
  }
  return _localizedCopy(
    context,
    pt: 'Solicitação Lightning',
    en: 'Lightning request',
    es: 'Solicitud Lightning',
  );
}

String _internalStatusContext(BuildContext context, Transaction transaction) {
  if (transaction.status == TransactionStatus.failed) {
    return _localizedCopy(
      context,
      pt: 'Transferência não concluída',
      en: 'Transfer not completed',
      es: 'Transferencia no completada',
    );
  }
  if (transaction.status == TransactionStatus.confirmed) {
    return _localizedCopy(
      context,
      pt: 'Lançada no saldo',
      en: 'Posted to balance',
      es: 'Registrada en saldo',
    );
  }
  return _localizedCopy(
    context,
    pt: 'Processando internamente',
    en: 'Processing internally',
    es: 'Procesando internamente',
  );
}

String _confirmationsLabel(BuildContext context, int confirmations) {
  if (confirmations == 1) {
    return _localizedCopy(
      context,
      pt: '1 confirmação',
      en: '1 confirmation',
      es: '1 confirmación',
    );
  }

  final suffix = _localizedCopy(
    context,
    pt: 'confirmações',
    en: 'confirmations',
    es: 'confirmaciones',
  );
  return '$confirmations $suffix';
}

String _blockchainVisibilityLabel(
  BuildContext context,
  Transaction transaction,
) {
  if (_hasBlockchainEvidence(transaction)) {
    return _localizedCopy(
      context,
      pt: 'Vista na blockchain',
      en: 'Seen on blockchain',
      es: 'Vista en blockchain',
    );
  }
  if (transaction.status == TransactionStatus.failed) {
    return _localizedCopy(
      context,
      pt: 'Não publicada',
      en: 'Not broadcast',
      es: 'No publicada',
    );
  }
  return _localizedCopy(
    context,
    pt: 'Ainda não publicada',
    en: 'Not broadcast yet',
    es: 'Aún no publicada',
  );
}

bool _hasBlockchainEvidence(Transaction transaction) {
  return transaction.confirmations > 0 ||
      (transaction.blockchainTxid?.trim().isNotEmpty ?? false) ||
      transaction.blockHeight != null ||
      (transaction.blockHash?.trim().isNotEmpty ?? false);
}

String _bankTitle(Transaction tx) {
  if (tx.isInternal) return 'Transferência interna';
  if (tx.isLightning) return 'Pagamento Lightning';
  if (tx.type == TransactionType.deposit ||
      tx.type == TransactionType.receive) {
    return 'Recebido';
  }
  if (tx.type == TransactionType.withdrawal) return 'Saque on-chain';
  if (tx.type == TransactionType.send) return 'Enviado';
  if (tx.type == TransactionType.fee) return 'Taxa de rede';
  return 'Transação';
}

String _bankRailLabel(Transaction tx) {
  if (tx.isInternal) return 'Transferência interna';
  if (tx.isLightning) return 'Lightning';
  if (tx.type == TransactionType.deposit) return 'Depósito on-chain';
  if (tx.type == TransactionType.withdrawal) return 'Saque on-chain';
  return 'On-chain';
}

String _bankStatusLabel(Transaction tx) {
  return switch (tx.status) {
    TransactionStatus.confirmed => 'Confirmado',
    TransactionStatus.confirming => '${tx.confirmations} confirmações',
    TransactionStatus.pending => 'Pendente',
    TransactionStatus.failed => 'Falhou',
  };
}

String _bankSubtitle(Transaction tx) {
  final local = tx.timestamp.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute · ${_bankRailLabel(tx)} · ${_bankStatusLabel(tx)}';
}

String _bankCounterparty(Transaction tx) {
  final displayName =
      tx.isDebit ? tx.receiverDisplayName : tx.senderDisplayName;
  final address = resolvePrimaryTransactionAddress(tx);
  final fallback = tx.description?.trim() ?? '';
  final value = [
    displayName,
    address,
    fallback,
    'Carteira Kerosene',
  ].firstWhere((value) => (value ?? '').trim().isNotEmpty)!;
  final label = tx.isDebit ? 'Para' : 'De';
  return '$label ${StatementTransactionCard._shorten(value, head: 18, tail: 8)}';
}

String _darkDetailValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '—';
  return StatementTransactionCard._shorten(trimmed, head: 18, tail: 8);
}

class _BankStatementTransactionRow extends StatelessWidget {
  final Transaction transaction;
  final String amountLabel;
  final String btcAmount;
  final String? feeAmount;
  final bool expanded;
  final VoidCallback? onTap;

  const _BankStatementTransactionRow({
    required this.transaction,
    required this.amountLabel,
    required this.btcAmount,
    required this.feeAmount,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = _bankTitle(transaction);
    final counterparty = _bankCounterparty(transaction);
    final subtitle = _bankSubtitle(transaction);
    final amountColor = transaction.status == TransactionStatus.failed
        ? AppColors.hexFFF4C7C7
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: KeroseneMotion.duration(context, KeroseneMotion.short),
          curve: KeroseneMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 15,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.hexFF222222),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _BankDirectionIcon(transaction: transaction),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          counterparty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.hexFFB8BCC2,
                            letterSpacing: 0,
                            height: 1.22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.hexFF8A8A8E,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 132),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountLabel,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.financial(
                            color: amountColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _DarkStatusPill(status: transaction.status),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _AnimatedExpandedTransactionDetails(
                expanded: expanded,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.base),
                  child: _BankTransactionDetailsTable(
                    transaction: transaction,
                    btcAmount: btcAmount,
                    feeAmount: feeAmount,
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

class _BankDirectionIcon extends StatelessWidget {
  final Transaction transaction;

  const _BankDirectionIcon({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final icon = _icon();
    final color = transaction.status == TransactionStatus.failed
        ? AppColors.hexFFF4C7C7
        : transaction.isLightning
            ? AppColors.hexFFD9B66A
            : transaction.isInternal
                ? AppColors.hexFFB8BCC2
                : transaction.isCredit
                    ? AppColors.hexFFA8C7B1
                    : AppColors.hexFFD4D4D8;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.hexFF111111,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hexFF2A2A2A),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  IconData _icon() {
    if (transaction.status == TransactionStatus.failed) {
      return KeroseneIcons.warning;
    }
    if (transaction.isLightning) {
      return KeroseneIcons.lightning;
    }
    if (transaction.isInternal) {
      return KeroseneIcons.moveHorizontal;
    }
    return transaction.isCredit ? KeroseneIcons.receive : KeroseneIcons.send;
  }
}

class _DarkStatusPill extends StatelessWidget {
  final TransactionStatus status;

  const _DarkStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final visual = _TransactionStatusVisual.resolve(context, status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: visual.darkForeground,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          visual.label,
          style: AppTypography.caption.copyWith(
            color: visual.darkForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _AnimatedExpandedTransactionDetails extends StatelessWidget {
  final bool expanded;
  final Widget child;

  const _AnimatedExpandedTransactionDetails({
    required this.expanded,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final duration = KeroseneMotion.duration(context, KeroseneMotion.medium);

    return AnimatedSize(
      duration: duration,
      curve: KeroseneMotion.standard,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: KeroseneMotion.entrance,
        switchOutCurve: KeroseneMotion.standard,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: expanded
            ? KeyedSubtree(
                key: const ValueKey('transaction-details-expanded'),
                child: child,
              )
            : const SizedBox(
                key: ValueKey('transaction-details-collapsed'),
                width: double.infinity,
              ),
      ),
    );
  }
}

class _BankTransactionDetailsTable extends StatelessWidget {
  final Transaction transaction;
  final String btcAmount;
  final String? feeAmount;

  const _BankTransactionDetailsTable({
    required this.transaction,
    required this.btcAmount,
    required this.feeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final reference = _firstNonEmpty([
      transaction.blockchainTxid,
      transaction.paymentHash,
      transaction.invoiceId,
      transaction.externalReference,
    ]);
    final rows = [
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
        key: 'from',
        label: _titleCase(context.tr.homeCounterpartyFrom),
        displayValue: _darkDetailValue(resolveTransactionSender(transaction)),
        copyValue: _copyValue(transaction.fromAddress),
      ),
      _TransactionDetailRow(
        key: 'to',
        label: _titleCase(context.tr.homeCounterpartyTo),
        displayValue:
            _darkDetailValue(resolveTransactionRecipient(transaction)),
        copyValue: _copyValue(transaction.toAddress),
      ),
      _TransactionDetailRow(
        key: 'id',
        label: _localizedCopy(
          context,
          pt: 'ID interno',
          en: 'Internal ID',
          es: 'ID interno',
        ),
        displayValue: StatementTransactionCard._shorten(transaction.id),
        copyValue: _copyValue(transaction.id),
      ),
      if (reference != null && reference != transaction.id)
        _TransactionDetailRow(
          key: 'reference',
          label: _localizedCopy(
            context,
            pt: 'Hash ou referência',
            en: 'Hash or reference',
            es: 'Hash o referencia',
          ),
          displayValue: StatementTransactionCard._shorten(reference),
          copyValue: reference,
        ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hexFF222222)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Divider(height: 1, color: AppColors.hexFF222222),
                ),
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                child: _BankTransactionDetailsRow(row: rows[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BankTransactionDetailsRow extends StatelessWidget {
  final _TransactionDetailRow row;

  const _BankTransactionDetailsRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          row.label,
          style: AppTypography.label.copyWith(
            color: AppColors.hexFF8A8A8E,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.25,
          ),
        ),
        if (row.copyValue != null) ...[
          const SizedBox(width: 6),
          _DarkTransactionDetailCopyButton(row: row),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.displayValue,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.hexFFE4E4E7,
              fontFamily: row.displayValue.length > 20
                  ? AppTypography.financialFontFamily
                  : AppTypography.bodyFontFamily,
              letterSpacing: 0,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkTransactionDetailCopyButton extends StatelessWidget {
  final _TransactionDetailRow row;

  const _DarkTransactionDetailCopyButton({required this.row});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr.copy,
      child: IconButton(
        key: ValueKey('statement-detail-copy-${row.key}'),
        onPressed: () => _copyDetail(context, row),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(
          KeroseneIcons.copy,
          size: 15,
          color: AppColors.hexFFB8BCC2,
        ),
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

class _TransactionDetailsTable extends StatelessWidget {
  final Transaction transaction;
  final _TransactionRail rail;
  final _StatementCardStyle style;
  final String btcAmount;
  final String? feeAmount;

  const _TransactionDetailsTable({
    required this.transaction,
    required this.rail,
    required this.style,
    required this.btcAmount,
    this.feeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _railDetailRows(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: style.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RailDetailHeader(
              transaction: transaction,
              rail: rail,
              style: style,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Divider(height: 1, color: style.divider),
                ),
              _TransactionDetailsRow(row: rows[index], style: style),
            ],
          ],
        ),
      ),
    );
  }

  List<_TransactionDetailRow> _railDetailRows(BuildContext context) {
    return switch (rail) {
      _TransactionRail.onChain => _onChainRows(context),
      _TransactionRail.lightning => _lightningRows(context),
      _TransactionRail.internalTransfer => _internalRows(context),
    };
  }

  List<_TransactionDetailRow> _onChainRows(BuildContext context) {
    final txid = _firstNonEmpty([transaction.blockchainTxid]);
    final blockHash = _firstNonEmpty([transaction.blockHash]);
    final rows = <_TransactionDetailRow>[
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
        key: 'confirmations',
        label: _localizedCopy(
          context,
          pt: 'Confirmações',
          en: 'Confirmations',
          es: 'Confirmaciones',
        ),
        displayValue: _confirmationsLabel(context, transaction.confirmations),
      ),
      _TransactionDetailRow(
        key: txid == null ? 'blockchain-state' : 'txid',
        label: txid == null
            ? _localizedCopy(
                context,
                pt: 'Blockchain',
                en: 'Blockchain',
                es: 'Blockchain',
              )
            : 'TXID',
        displayValue: txid == null
            ? _blockchainVisibilityLabel(context, transaction)
            : _detailValue(context, txid),
        copyValue: txid,
      ),
      if (transaction.blockHeight != null)
        _TransactionDetailRow(
          key: 'block-height',
          label: _localizedCopy(
            context,
            pt: 'Bloco',
            en: 'Block',
            es: 'Bloque',
          ),
          displayValue: '#${transaction.blockHeight}',
        ),
      if (blockHash != null)
        _TransactionDetailRow(
          key: 'block-hash',
          label: _localizedCopy(
            context,
            pt: 'Hash do bloco',
            en: 'Block hash',
            es: 'Hash del bloque',
          ),
          displayValue: _detailValue(context, blockHash),
          copyValue: blockHash,
        ),
      _TransactionDetailRow(
        key: 'from',
        label: _titleCase(context.tr.homeCounterpartyFrom),
        displayValue: _detailValue(
          context,
          resolveTransactionSender(transaction),
        ),
        copyValue: _copyValue(transaction.fromAddress),
      ),
      _TransactionDetailRow(
        key: 'to',
        label: _titleCase(context.tr.homeCounterpartyTo),
        displayValue: _detailValue(
          context,
          resolveTransactionRecipient(transaction),
        ),
        copyValue: _copyValue(transaction.toAddress),
      ),
      _TransactionDetailRow(
        key: 'id',
        label: _localizedCopy(
          context,
          pt: 'ID interno',
          en: 'Internal ID',
          es: 'ID interno',
        ),
        displayValue: _detailValue(context, transaction.id),
        copyValue: _copyValue(transaction.id),
      ),
    ];

    return rows;
  }

  List<_TransactionDetailRow> _lightningRows(BuildContext context) {
    final paymentHash = _firstNonEmpty([transaction.paymentHash]);
    final invoiceId = _firstNonEmpty([transaction.invoiceId]);
    final bolt11 = _firstNonEmpty([transaction.lightningInvoice]);
    final externalStatus = _firstNonEmpty([transaction.externalTransferStatus]);
    final externalType = _firstNonEmpty([transaction.externalTransferType]);

    return [
      _TransactionDetailRow(
        key: 'amount',
        label: context.tr.amount,
        displayValue: btcAmount,
      ),
      if (feeAmount != null)
        _TransactionDetailRow(
          key: 'lightning-fee',
          label: _localizedCopy(
            context,
            pt: 'Taxa Lightning',
            en: 'Lightning fee',
            es: 'Comisión Lightning',
          ),
          displayValue: feeAmount!,
        ),
      _TransactionDetailRow(
        key: 'lightning-status',
        label: _localizedCopy(
          context,
          pt: 'Liquidação',
          en: 'Settlement',
          es: 'Liquidación',
        ),
        displayValue: _lightningStatusContext(context, transaction),
      ),
      if (paymentHash != null)
        _TransactionDetailRow(
          key: 'payment-hash',
          label: 'Payment hash',
          displayValue: _detailValue(context, paymentHash),
          copyValue: paymentHash,
        ),
      if (invoiceId != null)
        _TransactionDetailRow(
          key: 'invoice-id',
          label: _localizedCopy(
            context,
            pt: 'Invoice',
            en: 'Invoice',
            es: 'Invoice',
          ),
          displayValue: _detailValue(context, invoiceId),
          copyValue: invoiceId,
        ),
      if (bolt11 != null)
        _TransactionDetailRow(
          key: 'bolt11',
          label: 'BOLT11',
          displayValue: _detailValue(context, bolt11),
          copyValue: bolt11,
        ),
      if (externalStatus != null)
        _TransactionDetailRow(
          key: 'external-status',
          label: _localizedCopy(
            context,
            pt: 'Status externo',
            en: 'External status',
            es: 'Estado externo',
          ),
          displayValue: externalStatus,
        ),
      if (externalType != null)
        _TransactionDetailRow(
          key: 'external-type',
          label: _localizedCopy(
            context,
            pt: 'Tipo externo',
            en: 'External type',
            es: 'Tipo externo',
          ),
          displayValue: externalType,
        ),
      _TransactionDetailRow(
        key: 'from',
        label: _titleCase(context.tr.homeCounterpartyFrom),
        displayValue: _detailValue(
          context,
          resolveTransactionSender(transaction),
        ),
        copyValue: _copyValue(transaction.fromAddress),
      ),
      _TransactionDetailRow(
        key: 'to',
        label: _titleCase(context.tr.homeCounterpartyTo),
        displayValue: _detailValue(
          context,
          resolveTransactionRecipient(transaction),
        ),
        copyValue: _copyValue(transaction.toAddress),
      ),
      _TransactionDetailRow(
        key: 'id',
        label: _localizedCopy(
          context,
          pt: 'ID interno',
          en: 'Internal ID',
          es: 'ID interno',
        ),
        displayValue: _detailValue(context, transaction.id),
        copyValue: _copyValue(transaction.id),
      ),
    ];
  }

  List<_TransactionDetailRow> _internalRows(BuildContext context) {
    final source = _firstNonEmpty([
      transaction.sourceWalletId,
      transaction.senderDisplayName,
      transaction.fromAddress,
    ]);
    final destination = _firstNonEmpty([
      transaction.destinationWalletId,
      transaction.receiverDisplayName,
      transaction.toAddress,
    ]);
    final walletId = _firstNonEmpty([transaction.walletId]);

    return [
      _TransactionDetailRow(
        key: 'amount',
        label: context.tr.amount,
        displayValue: btcAmount,
      ),
      _TransactionDetailRow(
        key: 'internal-status',
        label: _localizedCopy(
          context,
          pt: 'Status interno',
          en: 'Internal status',
          es: 'Estado interno',
        ),
        displayValue: _internalStatusContext(context, transaction),
      ),
      _TransactionDetailRow(
        key: 'source-wallet',
        label: _localizedCopy(
          context,
          pt: 'Carteira origem',
          en: 'Source wallet',
          es: 'Billetera origen',
        ),
        displayValue: _detailValue(context, source),
        copyValue: source,
      ),
      _TransactionDetailRow(
        key: 'destination-wallet',
        label: _localizedCopy(
          context,
          pt: 'Carteira destino',
          en: 'Destination wallet',
          es: 'Billetera destino',
        ),
        displayValue: _detailValue(context, destination),
        copyValue: destination,
      ),
      if (walletId != null)
        _TransactionDetailRow(
          key: 'wallet-id',
          label: _localizedCopy(
            context,
            pt: 'Carteira',
            en: 'Wallet',
            es: 'Billetera',
          ),
          displayValue: _detailValue(context, walletId),
          copyValue: walletId,
        ),
      _TransactionDetailRow(
        key: 'id',
        label: _localizedCopy(
          context,
          pt: 'ID interno',
          en: 'Internal ID',
          es: 'ID interno',
        ),
        displayValue: _detailValue(context, transaction.id),
        copyValue: _copyValue(transaction.id),
      ),
    ];
  }

  String _detailValue(BuildContext context, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _localizedCopy(
        context,
        pt: 'Não informado',
        en: 'Not available',
        es: 'No informado',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          row.label,
          style: AppTypography.label.copyWith(
            color: style.primaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.25,
          ),
        ),
        if (row.copyValue != null) ...[
          const SizedBox(width: 6),
          _TransactionDetailCopyButton(row: row, style: style),
        ],
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            row.displayValue,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.primaryText,
              fontFamily: row.displayValue.length > 20
                  ? AppTypography.financialFontFamily
                  : AppTypography.bodyFontFamily,
              fontSize: row.displayValue.length > 20 ? 12 : 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
        ),
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
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(KeroseneIcons.copy, size: 15, color: style.primaryText),
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

class _TransactionStatusVisual {
  final String label;
  final Color darkForeground;

  const _TransactionStatusVisual({
    required this.label,
    required this.darkForeground,
  });

  static _TransactionStatusVisual resolve(
    BuildContext context,
    TransactionStatus status,
  ) {
    return switch (status) {
      TransactionStatus.confirmed => _TransactionStatusVisual(
          label: context.tr.confirmed,
          darkForeground: AppColors.success,
        ),
      TransactionStatus.confirming => _TransactionStatusVisual(
          label: context.tr.confirming,
          darkForeground: AppColors.warning,
        ),
      TransactionStatus.pending => _TransactionStatusVisual(
          label: context.tr.pending,
          darkForeground: AppColors.warning,
        ),
      TransactionStatus.failed => _TransactionStatusVisual(
          label: context.tr.failed,
          darkForeground: AppColors.error,
        ),
    };
  }
}

class _StatementCardStyle {
  final Color background;
  final Color border;
  final Color accent;
  final Color accentSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color timeText;
  final Color divider;
  final Color detailBackground;
  final Color iconBackground;
  final Color iconForeground;

  const _StatementCardStyle({
    required this.background,
    required this.border,
    required this.accent,
    required this.accentSurface,
    required this.primaryText,
    required this.secondaryText,
    required this.timeText,
    required this.divider,
    required this.detailBackground,
    required this.iconBackground,
    required this.iconForeground,
  });

  factory _StatementCardStyle.fromRail(_TransactionRail rail) {
    return switch (rail) {
      _TransactionRail.onChain => const _StatementCardStyle(
          background: Color(0xFF14110D),
          border: Color(0xFF3E3325),
          accent: Color(0xFFD9B66A),
          accentSurface: Color(0x2ED9B66A),
          primaryText: Color(0xFFF5E9D3),
          secondaryText: Color(0xFFCDBA98),
          timeText: Color(0xFF978A75),
          divider: Color(0xFF302719),
          detailBackground: Color(0xFF19140E),
          iconBackground: Color(0xFF241A0D),
          iconForeground: Color(0xFFF4CE87),
        ),
      _TransactionRail.lightning => const _StatementCardStyle(
          background: Color(0xFF13121D),
          border: Color(0xFF39304F),
          accent: Color(0xFFF0CF5A),
          accentSurface: Color(0x2EF0CF5A),
          primaryText: Color(0xFFF4EFFC),
          secondaryText: Color(0xFFCFC4E6),
          timeText: Color(0xFF9F95B8),
          divider: Color(0xFF2A243A),
          detailBackground: Color(0xFF181527),
          iconBackground: Color(0xFF251F38),
          iconForeground: Color(0xFFF0CF5A),
        ),
      _TransactionRail.internalTransfer => const _StatementCardStyle(
          background: Color(0xFF0E1715),
          border: Color(0xFF24483E),
          accent: Color(0xFF7DD3B0),
          accentSurface: Color(0x2E7DD3B0),
          primaryText: Color(0xFFEAF7F2),
          secondaryText: Color(0xFFB7D5CC),
          timeText: Color(0xFF8BAAA1),
          divider: Color(0xFF1D332D),
          detailBackground: Color(0xFF111F1B),
          iconBackground: Color(0xFF142B25),
          iconForeground: Color(0xFF7DD3B0),
        ),
    };
  }
}

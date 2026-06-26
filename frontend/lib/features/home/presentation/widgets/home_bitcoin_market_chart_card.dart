import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;
import 'package:kerosene/core/services/bitcoin_market_chart_service.dart';
import 'package:kerosene/features/home/presentation/providers/home_bitcoin_market_chart_provider.dart';
import 'home_bitcoin_market_chart_motion.dart';
import '../screens/home_screen_dependencies.dart';
import '../screens/home_screen.dart';

class HomeBitcoinMarketChartCard extends ConsumerStatefulWidget {
  const HomeBitcoinMarketChartCard({super.key});
  @override
  ConsumerState<HomeBitcoinMarketChartCard> createState() =>
      _HomeBitcoinMarketChartCardState();
}
class _HomeBitcoinMarketChartCardState
    extends ConsumerState<HomeBitcoinMarketChartCard> {
  static const EdgeInsets _chartPadding = EdgeInsets.fromLTRB(46, 10, 8, 24);
  int? _selectedIndex;
  DateTime? _lastSelectionHapticAt;
  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(homeBitcoinMarketChartProvider);
    final selectedRange = ref.watch(homeBitcoinMarketChartRangeProvider);
    ref.listen<BitcoinMarketChartRequest>(homeBitcoinMarketChartRequestProvider, (
      previous,
      next,
    ) {
      if (previous != null && previous != next && mounted) {
        setState(() => _selectedIndex = null);
      }
    });
    return RepaintBoundary(
      child: HomeBitcoinChartStateTransition(
        child: chartAsync.when(
        data: (snapshot) => _buildLoadedCard(
          context,
          snapshot: snapshot,
          selectedRange: selectedRange,
        ),
        loading: () => _buildLoadingCard(context, selectedRange: selectedRange),
        error: (_, __) => _buildErrorCard(context, selectedRange: selectedRange),
      ),
    ),
    );
  }
  Widget _buildLoadedCard(
    BuildContext context, {
    required BitcoinMarketChartSnapshot snapshot,
    required BitcoinMarketChartRange selectedRange,
  }) {
    final points = snapshot.points;
    final selectedPoint = _selectedPoint(snapshot);
    final displayPoint = selectedPoint ?? (points.isNotEmpty ? points.last : null);
    final changePercent = snapshot.changePercent;
    final isPositive = (changePercent ?? 0) >= 0;
    final changeLabel = changePercent == null
        ? '—'
        : '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
    final changeColor = isPositive ? homePositiveColor : AppColors.hexFFFF5A67;
    final priceLabel = displayPoint == null
        ? '—'
        : MoneyDisplay.format(
            amount: displayPoint.price,
            currency: snapshot.request.quoteCurrency,
            decimalPlaces: 2,
          );
    return _ChartCardShell(
      key: ValueKey('btc-chart-${snapshot.request.symbol}-${snapshot.request.range.label}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bitcoin',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontFamily: AppTypography.fontFamily,
                        fontSize: homeFontSize(12),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: homeSize(6)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        priceLabel,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.financialFontFamily,
                          fontSize: homeFontSize(28),
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: homeSize(12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(homeSize(8)),
                      border: Border.all(
                        color: changeColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: homeSize(8),
                        vertical: homeSize(5),
                      ),
                      child: Text(
                        '$changeLabel ${selectedRange.label}',
                        style: TextStyle(
                          color: changeColor,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: homeFontSize(11),
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: homeSize(6)),
                  Text(
                    snapshot.request.pairLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontFamily: AppTypography.financialFontFamily,
                      fontSize: homeFontSize(10),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: homeSize(18)),
          SizedBox(
            height: homeBitcoinChartHeight(context),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final selectedX = _selectedX(snapshot, size);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _selectPoint(
                    details.localPosition,
                    size,
                    snapshot,
                  ),
                  onHorizontalDragStart: (details) => _selectPoint(
                    details.localPosition,
                    size,
                    snapshot,
                  ),
                  onHorizontalDragUpdate: (details) => _selectPoint(
                    details.localPosition,
                    size,
                    snapshot,
                  ),
                  onLongPressStart: (details) => _selectPoint(
                    details.localPosition,
                    size,
                    snapshot,
                  ),
                  onLongPressMoveUpdate: (details) => _selectPoint(
                    details.localPosition,
                    size,
                    snapshot,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: HomeBitcoinChartReveal(
                          key: ValueKey(snapshot.request),
                          child: CustomPaint(
                          painter: _BitcoinMarketChartPainter(
                            snapshot: snapshot,
                            selectedIndex: _safeSelectedIndex(snapshot),
                            padding: _chartPadding,
                            lineColor: AppColors.hexFF60A5FA,
                            lineSecondaryColor: AppColors.hexFF38BDF8,
                            gridColor: AppColors.hexFF2A2A2A,
                            labelColor: Colors.white.withValues(alpha: 0.42),
                            priceLabelFormatter: (value) => _compactPrice(
                              value,
                              snapshot.request.quoteCurrency,
                            ),
                            timeLabelFormatter: (time) => _timeLabel(
                              time,
                              snapshot.request.range,
                            ),
                          ),
                        ),
                        ),
                      ),
                      if (selectedPoint != null && selectedX != null)
                        Positioned(
                          left: _tooltipLeft(selectedX, size.width),
                          top: 0,
                          child: _ChartTooltip(
                            price: MoneyDisplay.format(
                              amount: selectedPoint.price,
                              currency: snapshot.request.quoteCurrency,
                              decimalPlaces: 2,
                            ),
                            time: _tooltipTime(
                              selectedPoint.time,
                              snapshot.request.range,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: homeSize(14)),
          _RangeSelector(selectedRange: selectedRange),
        ],
      ),
    );
  }
  Widget _buildLoadingCard(
    BuildContext context, {
    required BitcoinMarketChartRange selectedRange,
  }) {
    return _ChartCardShell(
      key: ValueKey('btc-chart-loading-${selectedRange.label}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(width: homeSize(82), height: homeSize(12)),
                    SizedBox(height: homeSize(10)),
                    _SkeletonBlock(width: homeSize(188), height: homeSize(28)),
                  ],
                ),
              ),
              _SkeletonBlock(width: homeSize(74), height: homeSize(24)),
            ],
          ),
          SizedBox(height: homeSize(18)),
          SizedBox(
            height: homeBitcoinChartHeight(context),
            child: HomeBitcoinChartAmbientPulse(
              child: CustomPaint(
              painter: _BitcoinLoadingChartPainter(
                padding: _chartPadding,
                lineColor: AppColors.hexFF60A5FA.withValues(alpha: 0.44),
                gridColor: AppColors.hexFF2A2A2A,
              ),
            ),
            ),
          ),
          SizedBox(height: homeSize(14)),
          _RangeSelector(selectedRange: selectedRange),
        ],
      ),
    );
  }
  Widget _buildErrorCard(
    BuildContext context, {
    required BitcoinMarketChartRange selectedRange,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        ref.invalidate(homeBitcoinMarketChartProvider);
      },
      child: _ChartCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bitcoin',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.fontFamily,
                      fontSize: homeFontSize(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: homeSize(22)),
            Container(
              height: homeBitcoinChartHeight(context),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(homeSize(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mercado BTC indisponivel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontFamily: AppTypography.fontFamily,
                      fontSize: homeFontSize(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: homeSize(6)),
                  Text(
                    'Toque para tentar novamente',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.46),
                      fontFamily: AppTypography.fontFamily,
                      fontSize: homeFontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: homeSize(14)),
            _RangeSelector(selectedRange: selectedRange),
          ],
        ),
      ),
    );
  }
  BitcoinMarketChartPoint? _selectedPoint(BitcoinMarketChartSnapshot snapshot) {
    final index = _safeSelectedIndex(snapshot);
    if (index == null) {
      return null;
    }
    return snapshot.points[index];
  }
  int? _safeSelectedIndex(BitcoinMarketChartSnapshot snapshot) {
    final selected = _selectedIndex;
    if (selected == null || snapshot.points.isEmpty) {
      return null;
    }
    return selected.clamp(0, snapshot.points.length - 1).toInt();
  }
  void _selectPoint(
    Offset localPosition,
    Size size,
    BitcoinMarketChartSnapshot snapshot,
  ) {
    if (snapshot.points.isEmpty) {
      return;
    }
    final plotWidth = size.width - _chartPadding.left - _chartPadding.right;
    if (plotWidth <= 0) {
      return;
    }
    final normalized = ((localPosition.dx - _chartPadding.left) / plotWidth)
        .clamp(0.0, 1.0)
        .toDouble();
    final nextIndex = (normalized * (snapshot.points.length - 1)).round();
    if (_selectedIndex != nextIndex) {
      _selectionHaptic();
      setState(() => _selectedIndex = nextIndex);
    }
  }

  void _selectionHaptic() {
    final now = DateTime.now();
    final last = _lastSelectionHapticAt;
    if (last != null && now.difference(last).inMilliseconds < 48) {
      return;
    }
    _lastSelectionHapticAt = now;
    HapticFeedback.selectionClick();
  }
  double? _selectedX(BitcoinMarketChartSnapshot snapshot, Size size) {
    final index = _safeSelectedIndex(snapshot);
    if (index == null || snapshot.points.length < 2) {
      return null;
    }
    final plotWidth = size.width - _chartPadding.left - _chartPadding.right;
    if (plotWidth <= 0) {
      return null;
    }
    return _chartPadding.left +
        (index / (snapshot.points.length - 1)) * plotWidth;
  }
  double _tooltipLeft(double selectedX, double width) {
    const tooltipWidth = 132.0;
    return (selectedX - tooltipWidth / 2)
        .clamp(_chartPadding.left, math.max(_chartPadding.left, width - tooltipWidth))
        .toDouble();
  }
}
class _ChartCardShell extends StatelessWidget {
  final Widget child;
  const _ChartCardShell({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(homeSize(18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(homeSize(20)),
        child: child,
      ),
    );
  }
}
class _RangeSelector extends ConsumerWidget {
  final BitcoinMarketChartRange selectedRange;
  const _RangeSelector({required this.selectedRange});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (final range in BitcoinMarketChartRange.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: homeSize(2)),
              child: _RangeButton(
                range: range,
                selected: range == selectedRange,
                onTap: () {
                  if (range == selectedRange) {
                    return;
                  }
                  HapticFeedback.selectionClick();
                  ref.read(homeBitcoinMarketChartRangeProvider.notifier).state =
                      range;
                },
              ),
            ),
          ),
      ],
    );
  }
}
class _RangeButton extends StatelessWidget {
  final BitcoinMarketChartRange range;
  final bool selected;
  final VoidCallback onTap;
  const _RangeButton({
    required this.range,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: homeSize(9)),
          child: AnimatedDefaultTextStyle(
            duration: KeroseneMotion.fast,
            curve: KeroseneMotion.standard,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.42),
              fontFamily: AppTypography.fontFamily,
              fontSize: homeFontSize(11),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.4,
            ),
            child: Text(range.label),
          ),
        ),
      ),
    );
  }
}
class _ChartTooltip extends StatelessWidget {
  final String price;
  final String time;
  const _ChartTooltip({required this.price, required this.time});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.hexFF0E0E0E.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(homeSize(10)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: homeSize(14),
            offset: Offset(0, homeSize(8)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: homeSize(9),
          vertical: homeSize(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppTypography.financialFontFamily,
                fontSize: homeFontSize(11),
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            SizedBox(height: homeSize(4)),
            Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.52),
                fontFamily: AppTypography.financialFontFamily,
                fontSize: homeFontSize(9),
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBlock({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(homeSize(8)),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
class _BitcoinMarketChartPainter extends CustomPainter {
  final BitcoinMarketChartSnapshot snapshot;
  final int? selectedIndex;
  final EdgeInsets padding;
  final Color lineColor;
  final Color lineSecondaryColor;
  final Color gridColor;
  final Color labelColor;
  final String Function(double value) priceLabelFormatter;
  final String Function(DateTime time) timeLabelFormatter;
  const _BitcoinMarketChartPainter({
    required this.snapshot,
    required this.selectedIndex,
    required this.padding,
    required this.lineColor,
    required this.lineSecondaryColor,
    required this.gridColor,
    required this.labelColor,
    required this.priceLabelFormatter,
    required this.timeLabelFormatter,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final points = snapshot.points;
    final plotRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      math.max(0, size.width - padding.left - padding.right),
      math.max(0, size.height - padding.top - padding.bottom),
    );
    if (plotRect.width <= 0 || plotRect.height <= 0) {
      return;
    }
    final minPrice = snapshot.lowPrice;
    final maxPrice = snapshot.highPrice;
    final spread = math.max(0.01, maxPrice - minPrice);
    final top = maxPrice + spread * 0.06;
    final bottom = minPrice - spread * 0.06;
    final adjustedSpread = math.max(0.01, top - bottom);
    _drawAxes(canvas, size, plotRect, bottom, top);
    if (points.length < 2) {
      return;
    }
    final offsets = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          plotRect.left + (index / (points.length - 1)) * plotRect.width,
          plotRect.top +
              ((top - points[index].price) / adjustedSpread) * plotRect.height,
        ),
    ];
    final path = _straightPath(offsets);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [lineSecondaryColor, lineColor, AppColors.hexFF283849],
        ).createShader(plotRect),
    );
    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < offsets.length) {
      _drawSelection(canvas, plotRect, offsets[selected]);
    }
  }
  void _drawAxes(
    Canvas canvas,
    Size size,
    Rect plotRect,
    double bottom,
    double top,
  ) {
    final spread = math.max(0.01, top - bottom);
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: labelColor,
      fontFamily: AppTypography.financialFontFamily,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    for (final value in _priceLabelValues(bottom, top, plotRect.height)) {
      final y = plotRect.bottom - ((value - bottom) / spread) * plotRect.height;
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      final painter = TextPainter(
        text: TextSpan(text: priceLabelFormatter(value), style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: padding.left - 6);
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }
    final timeStyle = labelStyle.copyWith(color: labelColor.withValues(alpha: 0.82));
    final labels = _timeLabels(plotRect.width);
    for (final item in labels) {
      final painter = TextPainter(
        text: TextSpan(text: timeLabelFormatter(item.time), style: timeStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 72);
      final x = plotRect.left + item.position * plotRect.width;
      painter.paint(
        canvas,
        Offset(
          (x - painter.width / 2)
              .clamp(plotRect.left, plotRect.right - painter.width)
              .toDouble(),
          size.height - painter.height,
        ),
      );
    }
  }
  List<double> _priceLabelValues(double bottom, double top, double height) {
    final targetCount = (height / 42).clamp(3, 6).round();
    final spread = math.max(0.01, top - bottom);
    final step = _nicePriceStep(spread / math.max(1, targetCount - 1));
    final values = <double>[];
    var value = (bottom / step).ceil() * step;
    while (value <= top && values.length < 8) {
      values.add(value);
      value += step;
    }
    return values.length < 2 ? [bottom, top] : values;
  }
  double _nicePriceStep(double rawStep) {
    if (rawStep <= 0) {
      return 1;
    }
    final exponent = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final fraction = rawStep / exponent;
    final niceFraction = fraction <= 1
        ? 1
        : fraction <= 2
            ? 2
            : fraction <= 5
                ? 5
                : 10;
    return niceFraction * exponent;
  }
  List<_ChartTimeLabel> _timeLabels(double width) {
    final points = snapshot.points;
    if (points.isEmpty) {
      return const [];
    }
    if (points.length == 1) {
      return [_ChartTimeLabel(position: 0, time: points.first.time)];
    }
    final count = (width / 92).clamp(2, 6).round();
    return [
      for (var index = 0; index < count; index++)
        _ChartTimeLabel(
          position: index / math.max(1, count - 1),
          time: points[((index / math.max(1, count - 1)) * (points.length - 1)).round()].time,
        ),
    ];
  }
  void _drawSelection(Canvas canvas, Rect plotRect, Offset offset) {
    final selectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(offset.dx, plotRect.top),
      Offset(offset.dx, plotRect.bottom),
      selectionPaint,
    );
    canvas.drawCircle(
      offset,
      5.5,
      Paint()..color = AppColors.hexFF0E0E0E,
    );
    canvas.drawCircle(
      offset,
      4.0,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      offset,
      2.6,
      Paint()..color = lineColor,
    );
  }
  Path _straightPath(List<Offset> offsets) {
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      path.lineTo(offsets[index].dx, offsets[index].dy);
    }
    return path;
  }
  @override
  bool shouldRepaint(covariant _BitcoinMarketChartPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.labelColor != labelColor;
  }
}
class _BitcoinLoadingChartPainter extends CustomPainter {
  final EdgeInsets padding;
  final Color lineColor;
  final Color gridColor;
  const _BitcoinLoadingChartPainter({
    required this.padding,
    required this.lineColor,
    required this.gridColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final plotRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      math.max(0, size.width - padding.left - padding.right),
      math.max(0, size.height - padding.top - padding.bottom),
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = plotRect.top + (index / 3.0) * plotRect.height;
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
    }
    final path = Path()
      ..moveTo(plotRect.left, plotRect.bottom - plotRect.height * 0.24)
      ..cubicTo(
        plotRect.left + plotRect.width * 0.18,
        plotRect.bottom - plotRect.height * 0.10,
        plotRect.left + plotRect.width * 0.30,
        plotRect.top + plotRect.height * 0.68,
        plotRect.left + plotRect.width * 0.44,
        plotRect.top + plotRect.height * 0.48,
      )
      ..cubicTo(
        plotRect.left + plotRect.width * 0.58,
        plotRect.top + plotRect.height * 0.28,
        plotRect.left + plotRect.width * 0.70,
        plotRect.top + plotRect.height * 0.34,
        plotRect.left + plotRect.width * 0.82,
        plotRect.top + plotRect.height * 0.22,
      )
      ..cubicTo(
        plotRect.left + plotRect.width * 0.92,
        plotRect.top + plotRect.height * 0.12,
        plotRect.left + plotRect.width,
        plotRect.top + plotRect.height * 0.18,
        plotRect.right,
        plotRect.top + plotRect.height * 0.16,
      );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }
  @override
  bool shouldRepaint(covariant _BitcoinLoadingChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.gridColor != gridColor;
  }
}
class _ChartTimeLabel {
  final double position;
  final DateTime time;
  const _ChartTimeLabel({required this.position, required this.time});
}
String _compactPrice(double value, Currency currency) {
  final symbol = MoneyDisplay.tickerSymbolFor(currency);
  final absValue = value.abs();
  if (absValue >= 1000000) {
    return '$symbol ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (absValue >= 1000) {
    return '$symbol ${(value / 1000).toStringAsFixed(0)}k';
  }
  return '$symbol ${value.toStringAsFixed(0)}';
}
String _timeLabel(DateTime time, BitcoinMarketChartRange range) {
  switch (range) {
    case BitcoinMarketChartRange.oneDay:
      return intl.DateFormat('HH:mm').format(time);
    case BitcoinMarketChartRange.oneWeek:
    case BitcoinMarketChartRange.oneMonth:
      return intl.DateFormat('dd/MM').format(time);
    case BitcoinMarketChartRange.oneYear:
      return intl.DateFormat('MMM').format(time);
    case BitcoinMarketChartRange.all:
      return intl.DateFormat('yyyy').format(time);
  }
}
String _tooltipTime(DateTime time, BitcoinMarketChartRange range) {
  switch (range) {
    case BitcoinMarketChartRange.oneDay:
      return intl.DateFormat('dd/MM HH:mm').format(time);
    case BitcoinMarketChartRange.oneWeek:
    case BitcoinMarketChartRange.oneMonth:
      return intl.DateFormat('dd/MM HH:mm').format(time);
    case BitcoinMarketChartRange.oneYear:
      return intl.DateFormat('dd/MM/yyyy').format(time);
    case BitcoinMarketChartRange.all:
      return intl.DateFormat('MM/yyyy').format(time);
  }
}

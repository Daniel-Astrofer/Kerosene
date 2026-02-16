import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../providers/market_provider.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen>
    with TickerProviderStateMixin {
  final List<String> _timeframes = ["1H", "1D", "1W", "1M", "3M", "1Y"];
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int? _touchedCandleIndex;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketProvider);
    final isPositive = marketState.priceChange24h >= 0;
    final trendColor = isPositive
        ? const Color(0xFF00FF94)
        : const Color(0xFFFF0055);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by parent/AppTheme
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _fadeController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header using GlassContainer
                    _buildHeader(marketState, isPositive, trendColor),
                    const SizedBox(height: 24),

                    // Currency Selector
                    _buildCurrencySelector(marketState),
                    const SizedBox(height: 20),

                    // Candlestick Chart (Glass Effect)
                    _buildCandlestickChart(marketState, trendColor),
                    const SizedBox(height: 16),

                    // Advanced Volume Chart (Glass Effect)
                    _buildAdvancedVolumeChart(marketState, trendColor),
                    const SizedBox(height: 20),

                    // Chart Statistics
                    _buildChartStatistics(marketState, trendColor),
                    const SizedBox(height: 20),

                    // Timeframe Selector
                    _buildTimeframeButtons(marketState),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _buildStats(marketState, trendColor),
                    const SizedBox(height: 100), // Bottom padding for dock
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MarketState state, bool isPositive, Color trendColor) {
    return GlassContainer(
      opacity: 0.1,
      blur: 15,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.currency_bitcoin,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Bitcoin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.currency.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.btcCurrentPrice),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Text(
                    "\$${value.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: trendColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: trendColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: trendColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${state.priceChange24h.toStringAsFixed(2)}%",
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.isConnected
                            ? const Color(0xFF00FF94)
                            : Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: state.isConnected
                                ? const Color(0xFF00FF94).withValues(alpha: 0.4)
                                : Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isConnected ? "LIVE" : "OFFLINE",
                      style: TextStyle(
                        color: state.isConnected
                            ? const Color(0xFF00FF94)
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(MarketState state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.availableCurrencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final currency = state.availableCurrencies[index];
          final isSelected = state.currency == currency;

          return GestureDetector(
            onTap: () =>
                ref.read(marketProvider.notifier).changeCurrency(currency),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  currency.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandlestickChart(MarketState state, Color trendColor) {
    if (state.isLoading) {
      return SizedBox(
        height: 380,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00D4FF),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (state.candles.isEmpty) {
      return const SizedBox(
        height: 380,
        child: Center(
          child: Text(
            "Sem dados disponíveis",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < state.candles.length; i++) {
      spots.add(FlSpot(i.toDouble(), state.candles[i].close));
    }

    // Calcular min e max para melhor visualização
    final minPrice = state.candles
        .map((c) => c.low)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = state.candles
        .map((c) => c.high)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final yAxisMin = minPrice - (priceRange * 0.1);
    final yAxisMax = maxPrice + (priceRange * 0.1);

    return GlassContainer(
      opacity: 0.05,
      blur: 10,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header Info
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          color: trendColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Gráfico de Preço",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (_touchedCandleIndex != null &&
                        _touchedCandleIndex! < state.candles.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildTouchedCandleInfo(state),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: trendColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "${spots.length} velas",
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Chart
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.isEmpty ? 1 : (spots.length - 1).toDouble(),
                minY: yAxisMin,
                maxY: yAxisMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: priceRange / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: math.max(
                        1,
                        (spots.length / 4).ceil().toDouble(),
                      ),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= state.candles.length)
                          return const SizedBox.shrink();

                        final candle = state.candles[index];
                        final label = _formatTimeLabel(
                          candle.time,
                          state.timeframe,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: priceRange / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatPrice(value),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? response) {
                        if (event is FlTapUpEvent ||
                            event is FlPanUpdateEvent) {
                          if (response != null &&
                              response.lineBarSpots != null &&
                              response.lineBarSpots!.isNotEmpty) {
                            setState(() {
                              _touchedCandleIndex = response
                                  .lineBarSpots!
                                  .first
                                  .x
                                  .toInt();
                            });
                          }
                        }
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF1A1F3C).withValues(alpha: 0.95),
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    tooltipBorderRadius: BorderRadius.circular(12),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot spot) {
                        final index = spot.x.toInt();
                        if (index >= state.candles.length) {
                          return LineTooltipItem('', const TextStyle());
                        }

                        final candle = state.candles[index];
                        final tooltipText =
                            'Fechamento: ${_formatPrice(spot.y)}\n'
                            'Abertura: ${_formatPrice(candle.open)}\n'
                            'Alta: ${_formatPrice(candle.high)}\n'
                            'Baixa: ${_formatPrice(candle.low)}\n'
                            'Data/Hora: ${_formatDateTime(candle.time, state.timeframe)}';

                        return LineTooltipItem(
                          tooltipText,
                          TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: trendColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (_touchedCandleIndex == index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: trendColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 2,
                          color: trendColor.withValues(alpha: 0.3),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          trendColor.withValues(alpha: 0.25),
                          trendColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchedCandleInfo(MarketState state) {
    if (_touchedCandleIndex == null ||
        _touchedCandleIndex! >= state.candles.length) {
      return const SizedBox.shrink();
    }

    final candle = state.candles[_touchedCandleIndex!];
    final isPositive = candle.close >= candle.open;
    final color = isPositive
        ? const Color(0xFF00FF94)
        : const Color(0xFFFF0055);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDateTime(candle.time, state.timeframe),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatPrice(candle.close),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            "${((candle.close - candle.open) / candle.open * 100).toStringAsFixed(2)}%",
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedVolumeChart(MarketState state, Color trendColor) {
    if (state.volumeSpots.isEmpty) return const SizedBox.shrink();

    // Calcular estatísticas de volume
    final maxVolume = state.candles
        .map((c) => c.volume)
        .reduce((a, b) => a > b ? a : b);
    final minVolume = state.candles
        .map((c) => c.volume)
        .reduce((a, b) => a < b ? a : b);
    final avgVolume =
        state.candles.fold<double>(0, (a, b) => a + b.volume) /
        state.candles.length;

    return Column(
      children: [
        // Volume Chart Container
        GlassContainer(
          opacity: 0.05,
          blur: 10,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Volume (24h)",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: trendColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      "${state.candles.length} períodos",
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Volume Chart
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.02),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: math.max(
                            1,
                            (state.volumeSpots.length / 6).ceil().toDouble(),
                          ),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= state.candles.length)
                              return const SizedBox.shrink();

                            final candle = state.candles[index];
                            final label = _formatTimeLabel(
                              candle.time,
                              state.timeframe,
                            );

                            return Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      math.min(state.volumeSpots.length, 40),
                      (index) {
                        final dataIndex =
                            (index *
                                    (state.volumeSpots.length /
                                        math.min(state.volumeSpots.length, 40)))
                                .floor();
                        if (dataIndex >= state.volumeSpots.length) return null;

                        final spot = state.volumeSpots[dataIndex];
                        final candle = state.candles[dataIndex];
                        final isGrowing = candle.close >= candle.open;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: spot.y,
                              color: isGrowing
                                  ? const Color(
                                      0xFF00FF94,
                                    ).withValues(alpha: 0.7)
                                  : const Color(
                                      0xFFFF0055,
                                    ).withValues(alpha: 0.7),
                              width: 3,
                              borderRadius: BorderRadius.circular(2),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: Colors.white.withValues(alpha: 0.02),
                              ),
                            ),
                          ],
                        );
                      },
                    ).whereType<BarChartGroupData>().toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Volume Statistics Grid
        Row(
          children: [
            Expanded(
              child: _buildVolumeStatCard(
                "Máximo",
                _formatLargeNumber(maxVolume),
                Icons.trending_up_rounded,
                const Color(0xFF00FF94),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVolumeStatCard(
                "Médio",
                _formatLargeNumber(avgVolume),
                Icons.equalizer_rounded,
                trendColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVolumeStatCard(
                "Mínimo",
                _formatLargeNumber(minVolume),
                Icons.trending_down_rounded,
                const Color(0xFFFF0055),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildVolumeStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      opacity: 0.08,
      blur: 8,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.7), size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStatistics(MarketState state, Color trendColor) {
    if (state.candles.isEmpty) return const SizedBox.shrink();

    // Calcular estatísticas
    final opens = state.candles.map((c) => c.open).toList();
    final closes = state.candles.map((c) => c.close).toList();
    final highestHigh = state.candles
        .map((c) => c.high)
        .reduce((a, b) => a > b ? a : b);
    final lowestLow = state.candles
        .map((c) => c.low)
        .reduce((a, b) => a < b ? a : b);

    final bullishCandles = state.candles.where((c) => c.close >= c.open).length;
    final bullishPercent = (bullishCandles / state.candles.length * 100)
        .toStringAsFixed(1);

    final firstOpen = opens.first;
    final lastClose = closes.last;
    final periodChange = ((lastClose - firstOpen) / firstOpen * 100);

    return GlassContainer(
      opacity: 0.05,
      blur: 10,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "Estatísticas do Período",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatChip(
                "Máxima",
                _formatPrice(highestHigh),
                const Color(0xFF00FF94),
              ),
              _buildStatChip(
                "Mínima",
                _formatPrice(lowestLow),
                const Color(0xFFFF0055),
              ),
              _buildStatChip(
                "Variação",
                "${periodChange.toStringAsFixed(2)}%",
                periodChange >= 0
                    ? const Color(0xFF00FF94)
                    : const Color(0xFFFF0055),
              ),
              _buildStatChip("Touros", "$bullishPercent%", trendColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeButtons(MarketState state) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tf = _timeframes[index];
          final isSelected = state.timeframe == tf;
          return GestureDetector(
            onTap: () => ref
                .read(marketProvider.notifier)
                .fetchMarketData(tf),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats(MarketState state, Color trendColor) {
    final highPrice = state.candles.isNotEmpty
        ? state.candles.map((c) => c.high).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final lowPrice = state.candles.isNotEmpty
        ? state.candles.map((c) => c.low).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          "High (24h)",
          "\$${highPrice.toStringAsFixed(0)}",
          Icons.arrow_upward_rounded,
          const Color(0xFF00FF94),
        ),
        _buildStatCard(
          "Low (24h)",
          "\$${lowPrice.toStringAsFixed(0)}",
          Icons.arrow_downward_rounded,
          const Color(0xFFFF0055),
        ),
        _buildStatCard(
          "Change",
          "${state.priceChange24h.toStringAsFixed(2)}%",
          Icons.ssid_chart_rounded,
          trendColor,
        ),
        _buildStatCard("Volume", "High", Icons.bar_chart_rounded, Colors.white),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      opacity: 0.05,
      blur: 10,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for formatting
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(2)}M';
    } else if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(2)}K';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatTimeLabel(DateTime time, String timeframe) {
    switch (timeframe) {
      case "1H":
        return DateFormat('HH:mm').format(time);
      case "1D":
        return DateFormat('MMM dd').format(time);
      case "1W":
        return DateFormat('MMM dd').format(time);
      case "1M":
        return DateFormat('MMM dd').format(time);
      case "3M":
        return DateFormat('MMM').format(time);
      case "1Y":
        return DateFormat('MMM').format(time);
      default:
        return DateFormat('dd/MM').format(time);
    }
  }

  String _formatDateTime(DateTime time, String timeframe) {
    switch (timeframe) {
      case "1H":
        return DateFormat('dd/MM HH:mm').format(time);
      case "1D":
        return DateFormat('dd/MM/yyyy').format(time);
      case "1W":
        return DateFormat('dd/MM/yyyy').format(time);
      case "1M":
        return DateFormat('dd/MM/yyyy').format(time);
      case "3M":
        return DateFormat('dd/MM/yyyy').format(time);
      case "1Y":
        return DateFormat('dd/MM/yyyy').format(time);
      default:
        return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}

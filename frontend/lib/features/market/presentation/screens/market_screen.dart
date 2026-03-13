import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/price_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/fear_and_greed_widget.dart';
import '../widgets/order_book_widget.dart';
import '../../../home/presentation/widgets/animated_balance_display.dart';
import '../../../../core/presentation/widgets/animated_number_display.dart';

// ─── Price Alert Model ─────────────────────────────────────────────────────────
class PriceAlert {
  final String id;
  final double targetPrice;
  final String direction; // 'above' or 'below'
  final bool active;

  PriceAlert({
    required this.id,
    required this.targetPrice,
    required this.direction,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetPrice': targetPrice,
    'direction': direction,
    'active': active,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
    id: json['id'],
    targetPrice: (json['targetPrice'] as num).toDouble(),
    direction: json['direction'],
    active: json['active'] ?? true,
  );
}

// ─── Price Alert Provider ──────────────────────────────────────────────────────
final priceAlertProvider =
    StateNotifierProvider<PriceAlertNotifier, List<PriceAlert>>((ref) {
      return PriceAlertNotifier();
    });

class PriceAlertNotifier extends StateNotifier<List<PriceAlert>> {
  PriceAlertNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('price_alerts') ?? [];
    final alerts = <PriceAlert>[];
    for (final s in raw) {
      try {
        final parts = s.split('|');
        alerts.add(
          PriceAlert(
            id: parts[0],
            targetPrice: double.parse(parts[1]),
            direction: parts[2],
            active: parts[3] == 'true',
          ),
        );
      } catch (_) {}
    }
    state = alerts;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state
        .map((a) => '${a.id}|${a.targetPrice}|${a.direction}|${a.active}')
        .toList();
    await prefs.setStringList('price_alerts', raw);
  }

  Future<void> addAlert(double price, String direction) async {
    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetPrice: price,
      direction: direction,
    );
    state = [...state, alert];
    await _save();
  }

  Future<void> removeAlert(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _save();
  }
}

// ─── Technical Indicator Helpers ───────────────────────────────────────────────
List<FlSpot> computeSMA(List<FlSpot> data, int period) {
  if (data.length < period) return [];
  final result = <FlSpot>[];
  for (int i = period - 1; i < data.length; i++) {
    double sum = 0;
    for (int j = i - period + 1; j <= i; j++) {
      sum += data[j].y;
    }
    result.add(FlSpot(data[i].x, sum / period));
  }
  return result;
}

List<FlSpot> computeEMA(List<FlSpot> data, int period) {
  if (data.length < period) return [];
  final k = 2.0 / (period + 1);
  double sum = 0;
  for (int i = 0; i < period; i++) {
    sum += data[i].y;
  }
  double ema = sum / period;
  final result = <FlSpot>[FlSpot(data[period - 1].x, ema)];
  for (int i = period; i < data.length; i++) {
    ema = (data[i].y - ema) * k + ema;
    result.add(FlSpot(data[i].x, ema));
  }
  return result;
}

List<FlSpot> computeRSI(List<FlSpot> data, int period) {
  if (data.length < period + 1) return [];
  final result = <FlSpot>[];

  double avgGain = 0, avgLoss = 0;
  for (int i = 1; i <= period; i++) {
    final change = data[i].y - data[i - 1].y;
    if (change > 0) {
      avgGain += change;
    } else {
      avgLoss += change.abs();
    }
  }
  avgGain /= period;
  avgLoss /= period;

  double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
  double rsi = 100 - (100 / (1 + rs));
  result.add(FlSpot(data[period].x, rsi));

  for (int i = period + 1; i < data.length; i++) {
    final change = data[i].y - data[i - 1].y;
    if (change > 0) {
      avgGain = (avgGain * (period - 1) + change) / period;
      avgLoss = (avgLoss * (period - 1)) / period;
    } else {
      avgGain = (avgGain * (period - 1)) / period;
      avgLoss = (avgLoss * (period - 1) + change.abs()) / period;
    }
    rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
    rsi = 100 - (100 / (1 + rs));
    result.add(FlSpot(data[i].x, rsi));
  }
  return result;
}

// ─── Market Screen ─────────────────────────────────────────────────────────────
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _livePulseController;
  late Animation<double> _livePulseAnimation;
  bool _showMA = false;
  bool _showRSI = false;

  @override
  void initState() {
    super.initState();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _livePulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _livePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _livePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketProvider);
    final alerts = ref.watch(priceAlertProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(marketProvider.notifier)
                .fetchMarketData(marketState.timeframe);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Bitcoin",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Price Header
                _buildPriceHeader(marketState),
                const SizedBox(height: 24),

                // Main Chart
                GestureDetector(
                  onLongPressStart: (details) {
                    _showPriceAlertDialog(context, marketState);
                  },
                  child: SizedBox(
                    height: 300,
                    child: _buildMainChart(marketState, alerts),
                  ),
                ),

                // RSI Sub-Chart
                if (_showRSI && marketState.spots.isNotEmpty)
                  _buildRSIChart(marketState),

                const SizedBox(height: 16),

                // Indicator Toggles + Timeframe Selector
                _buildIndicatorToggles(),
                const SizedBox(height: 12),

                // Timeframe Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["LIVE", "1H", "1D", "1W", "1M", "1Y", "ALL"].map(
                      (tf) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildTimeframeButton(
                            tf,
                            marketState.timeframe == tf,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Active Alerts
                if (alerts.isNotEmpty) ...[
                  _buildAlertsSection(alerts),
                  const SizedBox(height: 24),
                ],

                // Stats Grid
                Text(
                  "Market Stats",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "24h High",
                        _formatPrice(
                          context,
                          marketState.high24h * _getConversionFactor(ref),
                          ref.watch(currencyProvider),
                        ),
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "24h Low",
                        _formatPrice(
                          context,
                          marketState.low24h * _getConversionFactor(ref),
                          ref.watch(currencyProvider),
                        ),
                        isPositive: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  "Volume (24h)",
                  _formatMarketCap(
                    context,
                    marketState.totalVolume * _getConversionFactor(ref),
                    ref.watch(currencyProvider),
                  ),
                  subtitle: "USDT",
                ),
                const SizedBox(height: 24),

                // Fear & Greed
                if (marketState.fearAndGreed != null)
                  FearAndGreedWidget(data: marketState.fearAndGreed!),

                const SizedBox(height: 24),

                // Order Book
                OrderBookWidget(bids: marketState.bids, asks: marketState.asks),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Indicator Toggle Chips ────────────────────────────────────────────────
  Widget _buildIndicatorToggles() {
    return Row(
      children: [
        _buildChip(
          label: "MA",
          active: _showMA,
          color: const Color(0xFFFFD700),
          onTap: () => setState(() => _showMA = !_showMA),
        ),
        const SizedBox(width: 8),
        _buildChip(
          label: "RSI",
          active: _showRSI,
          color: const Color(0xFF7B61FF),
          onTap: () => setState(() => _showRSI = !_showRSI),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 12, color: color),
              ),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Alerts Section ────────────────────────────────────────────────────────
  Widget _buildAlertsSection(List<PriceAlert> alerts) {
    final currency = ref.watch(currencyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Price Alerts",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${alerts.length} active",
              style: TextStyle(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alerts.map((alert) {
          final icon = alert.direction == 'above'
              ? Icons.arrow_upward
              : Icons.arrow_downward;
          final color = alert.direction == 'above'
              ? const Color(0xFF00FF94)
              : const Color(0xFFFF0055);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GlassContainer(
              enableBlur: false, // Performance optimization for list items
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: BorderRadius.circular(12),
              opacity: 0.05,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${alert.direction == 'above' ? 'Above' : 'Below'} ${_formatPrice(context, alert.targetPrice, currency)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(priceAlertProvider.notifier)
                        .removeAlert(alert.id),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Price Alert Dialog ────────────────────────────────────────────────────
  void _showPriceAlertDialog(BuildContext context, MarketState state) {
    final currency = ref.read(currencyProvider);
    final factor = _getConversionFactor(ref);
    final currentConverted = state.currentPrice * factor;
    final controller = TextEditingController(
      text: currentConverted.toStringAsFixed(2),
    );
    String direction = 'above';

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF00D4FF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Set Price Alert",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Direction toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => direction = 'above'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: direction == 'above'
                                  ? const Color(
                                      0xFF00FF94,
                                    ).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: direction == 'above'
                                    ? const Color(
                                        0xFF00FF94,
                                      ).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: direction == 'above'
                                      ? const Color(0xFF00FF94)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Above",
                                  style: TextStyle(
                                    color: direction == 'above'
                                        ? const Color(0xFF00FF94)
                                        : Colors.white38,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => direction = 'below'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: direction == 'below'
                                  ? const Color(
                                      0xFFFF0055,
                                    ).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: direction == 'below'
                                    ? const Color(
                                        0xFFFF0055,
                                      ).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: direction == 'below'
                                      ? const Color(0xFFFF0055)
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Below",
                                  style: TextStyle(
                                    color: direction == 'below'
                                        ? const Color(0xFFFF0055)
                                        : Colors.white38,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Price input
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: currency == Currency.brl
                          ? 'R\$ '
                          : currency == Currency.eur
                          ? '€ '
                          : '\$ ',
                      prefixStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final price = double.tryParse(controller.text) ?? 0;
                        if (price > 0) {
                          ref
                              .read(priceAlertProvider.notifier)
                              .addAlert(price, direction);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Alert set: ${direction == 'above' ? '↑' : '↓'} ${controller.text}",
                              ),
                              backgroundColor: const Color(0xFF00D4FF),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Set Alert",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Conversion Helpers ────────────────────────────────────────────────────
  double _getConversionFactor(WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    if (currency == Currency.usd) return 1.0;

    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    if (btcUsd == null || btcUsd == 0) return 0.0;

    switch (currency) {
      case Currency.btc:
        return 1.0 / btcUsd;
      case Currency.eur:
        return (btcEur ?? 0) / btcUsd;
      case Currency.brl:
        return (btcBrl ?? 0) / btcUsd;
      default:
        return 1.0;
    }
  }

  String _formatPrice(BuildContext context, double price, Currency currency) {
    if (price == 0) return "---";
    final appLocale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.currency(
      locale: appLocale,
      symbol: currency == Currency.brl
          ? 'R\$'
          : currency == Currency.eur
          ? '€'
          : currency == Currency.btc
          ? '₿'
          : '\$',
      decimalDigits: currency == Currency.btc ? 8 : 2,
    );
    return formatter.format(price);
  }

  String _formatMarketCap(
    BuildContext context,
    double value,
    Currency currency,
  ) {
    if (value == 0) return "---";
    final symbol = currency == Currency.brl
        ? 'R\$'
        : currency == Currency.eur
        ? '€'
        : currency == Currency.btc
        ? '₿'
        : '\$';
    if (value >= 1e12) {
      return '$symbol${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value >= 1e9) {
      return '$symbol${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '$symbol${(value / 1e6).toStringAsFixed(2)}M';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }

  // ─── Price Header ──────────────────────────────────────────────────────────
  Widget _buildPriceHeader(MarketState state) {
    final currency = ref.watch(currencyProvider);
    final factor = _getConversionFactor(ref);
    final convertedPrice = state.currentPrice * factor;
    final isPositive = state.priceChange24h >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedBalanceDisplay(
              balance: convertedPrice,
              decimalPlaces: currency == Currency.btc ? 8 : 2,
              prefix: currency == Currency.brl
                  ? 'R\$ '
                  : currency == Currency.eur
                  ? '€ '
                  : currency == Currency.btc
                  ? '₿ '
                  : '\$ ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currency.code,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                (isPositive ? const Color(0xFF00FF94) : const Color(0xFFFF0055))
                    .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${isPositive ? '+' : ''}${state.priceChange24h.toStringAsFixed(2)}% (24h)",
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFF00FF94)
                  : const Color(0xFFFF0055),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Timeframe Button ──────────────────────────────────────────────────────
  Widget _buildTimeframeButton(String label, bool isActive) {
    final isLive = label == 'LIVE';
    return GestureDetector(
      onTap: () {
        ref.read(marketProvider.notifier).fetchMarketData(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isLive
                    ? const Color(0xFFFF0055).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isLive && isActive
              ? Border.all(
                  color: const Color(0xFFFF0055).withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive) ...[
              AnimatedBuilder(
                animation: _livePulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF0055,
                      ).withValues(alpha: _livePulseAnimation.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF0055,
                          ).withValues(alpha: _livePulseAnimation.value * 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? (isLive ? const Color(0xFFFF0055) : Colors.white)
                    : Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stat Card ─────────────────────────────────────────────────────────────
  Widget _buildStatCard(
    String title,
    String value, {
    String? subtitle,
    bool isPositive = true,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedNumberDisplay(
            value:
                double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0,
            prefix: value.contains(r'$') ? r'$' : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decimalPlaces: 2,
            enableFlash: false, // Less distraction for stats
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── RSI Sub-Chart ─────────────────────────────────────────────────────────
  Widget _buildRSIChart(MarketState state) {
    final factor = _getConversionFactor(ref);
    if (factor == 0) return const SizedBox();

    final convertedSpots = state.spots
        .map((s) => FlSpot(s.x, s.y * factor))
        .toList();
    final rsiData = computeRSI(convertedSpots, 14);
    if (rsiData.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RSI (14)",
            style: TextStyle(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 70,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) {
                    final isKey = value == 30 || value == 70;
                    return FlLine(
                      color: isKey
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      strokeWidth: isKey ? 1 : 0.5,
                      dashArray: isKey ? [4, 4] : null,
                    );
                  },
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: rsiData,
                    isCurved: true,
                    color: const Color(0xFF7B61FF),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7B61FF).withValues(alpha: 0.1),
                          const Color(0xFF7B61FF).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: Colors.white.withValues(alpha: 0.2),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF00D4FF),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipColor: (touchedSpot) =>
                        const Color(0xFF1A1A24).withValues(alpha: 0.9),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          barSpot.x.toInt(),
                        );
                        final formattedDate =
                            state.timeframe == 'LIVE' || state.timeframe == '1H'
                            ? DateFormat('HH:mm:ss').format(date)
                            : DateFormat('MMM dd, HH:mm').format(date);

                        final currency = ref.read(currencyProvider);
                        final factor = _getConversionFactor(ref);
                        final price = _formatPrice(
                          context,
                          barSpot.y * factor,
                          currency,
                        );

                        return LineTooltipItem(
                          '$formattedDate\n',
                          const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Chart ────────────────────────────────────────────────────────────
  Widget _buildMainChart(MarketState state, List<PriceAlert> alerts) {
    // Force black background immediately
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
      height: 350,
      width: double.infinity,
      child: state.spots.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF94),
                strokeWidth: 2,
              ),
            )
          : LineChart(
              LineChartData(
                minY: state.spots.isNotEmpty
                    ? state.spots.map((e) => e.y).reduce(math.min) * 0.999
                    : 0,
                maxY: state.spots.isNotEmpty
                    ? state.spots.map((e) => e.y).reduce(math.max) * 1.001
                    : 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: state.spots,
                    isCurved: true,
                    curveSmoothness: 0.1,
                    color: const Color(0xFF00FF94),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00FF94).withValues(alpha: 0.15),
                          const Color(0xFF00FF94).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: Colors.white.withValues(alpha: 0.1),
                              strokeWidth: 1,
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFF00FF94),
                                  strokeWidth: 2,
                                  strokeColor: Colors.black,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A24),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '\$${barSpot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

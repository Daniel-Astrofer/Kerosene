import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../../../shared/widgets/navigation/shared_bottom_nav_bar.dart';

enum ChartRange {
  oneDay('1D', '1'),
  oneWeek('1W', '7'),
  oneMonth('1M', '30'),
  oneYear('1Y', '365');

  final String label;
  final String apiDays;
  const ChartRange(this.label, this.apiDays);
}

enum Currency {
  usd('USD', '\$', 'usd'),
  brl('BRL', 'R\$', 'brl'),
  eur('EUR', '€', 'eur');

  final String label;
  final String symbol;
  final String apiId;
  const Currency(this.label, this.symbol, this.apiId);
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Chart Data
  List<FlSpot> _spots = [];
  Timer? _timer;

  // State
  double _currentPrice = 0.0;
  double _priceChange24h = 0.0;
  double _marketCap = 0.0;
  double _volume24h = 0.0;

  bool _isLoading = true;
  ChartRange _selectedRange = ChartRange.oneDay;
  Currency _selectedCurrency = Currency.usd;
  double _minY = 0;
  double _maxY = 0;
  double _minX = 0;
  double _maxX = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRealtimeUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchTickerData();
      if (_selectedRange == ChartRange.oneDay) {
        _fetchChartData(silent: true);
      }
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchTickerData(), _fetchChartData()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchTickerData() async {
    try {
      // If BRL, try Mercado Bitcoin first for the "Last Price"
      if (_selectedCurrency == Currency.brl) {
        try {
          final response = await http.get(
            Uri.parse('https://www.mercadobitcoin.net/api/BTC/ticker/'),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final ticker = data['ticker'];
            final price = double.tryParse(ticker['last'].toString()) ?? 0.0;
            // MB sends Volume in BTC amount, not BRL usually. We'll rely on CG for global stats.
            if (mounted) {
              setState(() {
                _currentPrice = price;
              });
            }
          }
        } catch (e) {
          debugPrint("MB API Error: $e");
          // Fallback to CoinGecko will happen below if _currentPrice is 0
        }
      }

      // Fetch Global Stats (Cap, Vol, Change) from CoinGecko
      // We also use this for Price if NOT BRL (or if MB failed/we want to ensure consistency)
      final currency = _selectedCurrency.apiId;
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$currency&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final btcData = data['bitcoin'];

        if (mounted) {
          setState(() {
            // Only update price from CG if not BRL (or if currentPrice is still 0)
            if (_selectedCurrency != Currency.brl || _currentPrice == 0) {
              try {
                _currentPrice = (btcData[currency] as num).toDouble();
              } catch (_) {}
            }
            try {
              _priceChange24h = (btcData['${currency}_24h_change'] as num)
                  .toDouble();
              _marketCap = (btcData['${currency}_market_cap'] as num)
                  .toDouble();
              _volume24h = (btcData['${currency}_24h_vol'] as num).toDouble();
            } catch (_) {}
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ticker: $e");
    }
  }

  Future<void> _fetchChartData({bool silent = false}) async {
    if (!mounted) return;

    try {
      final currency = _selectedCurrency.apiId;
      final days = _selectedRange.apiDays;

      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=$currency&days=$days',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = data['prices'] as List;

        final List<FlSpot> spots = [];
        double minPrice = double.infinity;
        double maxPrice = double.negativeInfinity;
        double minTime = double.infinity;
        double maxTime = double.negativeInfinity;

        // Optimization: Cap at maximum 100 points for smooth rendering
        const maxPoints = 100;
        final skip = (prices.length / maxPoints).ceil().clamp(1, prices.length);

        for (int i = 0; i < prices.length; i += skip) {
          final entry = prices[i];
          final timestamp = (entry[0] as num).toDouble();
          final price = (entry[1] as num).toDouble();

          if (price < minPrice) minPrice = price;
          if (price > maxPrice) maxPrice = price;
          if (timestamp < minTime) minTime = timestamp;
          if (timestamp > maxTime) maxTime = timestamp;

          spots.add(FlSpot(timestamp, price));
        }

        if (mounted) {
          setState(() {
            _spots = spots;
            _minY = minPrice * 0.99;
            _maxY = maxPrice * 1.01;
            _minX = minTime;
            _maxX = maxTime;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching market chart: $e");
    }
  }

  void _onRangeSelected(ChartRange range) {
    if (_selectedRange != range) {
      setState(() {
        _selectedRange = range;
      });
      _fetchChartData();
    }
  }

  void _onCurrencySelected(Currency? currency) {
    if (currency != null && _selectedCurrency != currency) {
      setState(() {
        _selectedCurrency = currency;
        // Reset data to avoid confusing visual
        _currentPrice = 0;
        _isLoading = true;
      });
      _fetchData();
    }
  }

  String _formatDate(double timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    switch (_selectedRange) {
      case ChartRange.oneDay:
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      case ChartRange.oneWeek:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case ChartRange.oneMonth:
        return "${date.day}/${date.month}";
      case ChartRange.oneYear:
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[date.month - 1];
    }
  }

  String _formatFullDate(double timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatKmb(double value) {
    if (value >= 1e9) {
      return "${(value / 1e9).toStringAsFixed(2)}B";
    }
    if (value >= 1e6) {
      return "${(value / 1e6).toStringAsFixed(2)}M";
    }
    if (value >= 1e3) {
      return "${(value / 1e3).toStringAsFixed(2)}K";
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    double totalBalanceBtc = 0;

    if (walletState is WalletLoaded) {
      for (var w in walletState.wallets) {
        totalBalanceBtc += w.balanceSatoshis / 100000000.0;
      }
    }

    final totalBalanceFiat = totalBalanceBtc * _currentPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF050511),
      appBar: AppBar(
        title: const Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Total Balance Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F3C), Color(0xFF131525)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _isLoading && _currentPrice == 0
                          ? const CircularProgressIndicator(
                              color: Color(0xFF00D4FF),
                            )
                          : Text(
                              "${_selectedCurrency.symbol}${totalBalanceFiat.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${totalBalanceBtc.toStringAsFixed(8)} BTC",
                          style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Chart Header & Interval Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bitcoin / ${_selectedCurrency.label}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 8,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "LIVE MARKET",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Interval Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ChartRange.values.map((range) {
                            final isSelected = _selectedRange == range;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _onRangeSelected(range),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF7B61FF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    range.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Chart Area
                SizedBox(
                  height: 300,
                  child: _isLoading && _spots.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B61FF),
                          ),
                        )
                      : _spots.isEmpty
                      ? const Center(
                          child: Text(
                            "No data available",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 20, left: 10),
                          child: LineChart(
                            LineChartData(
                              minY: _minY,
                              maxY: _maxY,
                              minX: _minX,
                              maxX: _maxX,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      // Only show specific intervals to avoid clutter
                                      final totalDuration = _maxX - _minX;
                                      if (totalDuration <= 0)
                                        return const SizedBox.shrink();

                                      String text = _formatDate(value);
                                      if (text.isEmpty)
                                        return const SizedBox.shrink();

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                    interval: (_maxX - _minX) / 5,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _spots,
                                  isCurved: true,
                                  color: const Color(0xFF7B61FF),
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF7B61FF,
                                        ).withOpacity(0.3),
                                        const Color(
                                          0xFF7B61FF,
                                        ).withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) =>
                                      const Color(0xFF1A1F3C),
                                  fitInsideHorizontally: true,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((
                                      LineBarSpot touchedSpot,
                                    ) {
                                      final dateStr = _formatFullDate(
                                        touchedSpot.x,
                                      );
                                      return LineTooltipItem(
                                        "${_selectedCurrency.symbol}${touchedSpot.y.toStringAsFixed(2)}\n",
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: dateStr,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
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
                ),

                const SizedBox(height: 32),

                // Analytics Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape =
                          MediaQuery.of(context).orientation ==
                          Orientation.landscape;
                      final aspectRatio = isLandscape ? 2.5 : 1.4;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                        children: [
                          _buildStatCard(
                            "Current Price",
                            "${_selectedCurrency.symbol}${_currentPrice.toStringAsFixed(2)}",
                            Icons.currency_bitcoin,
                          ),
                          _buildStatCard(
                            "24h Change",
                            "${_priceChange24h > 0 ? '+' : ''}${_priceChange24h.toStringAsFixed(2)}%",
                            Icons.trending_up,
                            isPositive: _priceChange24h >= 0,
                          ),
                          _buildStatCard(
                            "Market Cap",
                            "${_selectedCurrency.symbol}${_formatKmb(_marketCap)}",
                            Icons.pie_chart,
                          ),
                          _buildStatCard(
                            "Volume (24h)",
                            "${_selectedCurrency.symbol}${_formatKmb(_volume24h)}",
                            Icons.bar_chart,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 180), // Bottom padding for Nav Bar
              ],
            ),
          ),
          const SharedBottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: isPositive == null
                    ? Colors.white
                    : (isPositive ? Colors.green : Colors.red),
                fontSize: 23,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:fl_chart/fl_chart.dart';
import '../../data/datasources/binance_socket_service.dart';

class OrderBookEntry {
  final double price;
  final double amount;

  OrderBookEntry({required this.price, required this.amount});
}

class MarketState {
  final double currentPrice;
  final double priceChange24h;
  final double high24h;
  final double low24h;
  final double totalVolume;
  final double marketCap;
  final List<FlSpot> spots;
  final bool isLoading;
  final String? error;
  final String timeframe;
  final Map<String, dynamic>? fearAndGreed;
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;

  MarketState({
    this.currentPrice = 0.0,
    this.priceChange24h = 0.0,
    this.high24h = 0.0,
    this.low24h = 0.0,
    this.totalVolume = 0.0,
    this.marketCap = 0.0,
    this.spots = const [],
    this.isLoading = false,
    this.error,
    this.timeframe = "LIVE",
    this.fearAndGreed,
    this.bids = const [],
    this.asks = const [],
  });

  MarketState copyWith({
    double? currentPrice,
    double? priceChange24h,
    double? high24h,
    double? low24h,
    double? totalVolume,
    double? marketCap,
    List<FlSpot>? spots,
    bool? isLoading,
    String? error,
    String? timeframe,
    Map<String, dynamic>? fearAndGreed,
    List<OrderBookEntry>? bids,
    List<OrderBookEntry>? asks,
  }) {
    return MarketState(
      currentPrice: currentPrice ?? this.currentPrice,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      totalVolume: totalVolume ?? this.totalVolume,
      marketCap: marketCap ?? this.marketCap,
      spots: spots ?? this.spots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      timeframe: timeframe ?? this.timeframe,
      fearAndGreed: fearAndGreed ?? this.fearAndGreed,
      bids: bids ?? this.bids,
      asks: asks ?? this.asks,
    );
  }
}

final binanceSocketProvider = Provider((ref) => BinanceSocketService());

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((
  ref,
) {
  final socketService = ref.watch(binanceSocketProvider);
  return MarketNotifier(socketService);
});

class MarketNotifier extends StateNotifier<MarketState> {
  final BinanceSocketService _socketService;

  MarketNotifier(this._socketService) : super(MarketState()) {
    _socketService.connect();
    _listenToSocket();
    fetchMarketData("1D");
  }

  void _listenToSocket() {
    _socketService.dataStream.listen((event) {
      final stream = event['stream'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (data == null) return;

      if (stream == 'btcusdt@ticker') {
        _handleTickerData(data);
      } else if (stream?.contains('@kline_') ?? false) {
        _handleKlineData(data);
      } else if (stream == 'btcusdt@depth20') {
        _handleDepthData(data);
      }
    });
  }

  void _handleTickerData(Map<String, dynamic> data) {
    final price = double.tryParse(data['c']?.toString() ?? '') ?? 0.0;
    final change = double.tryParse(data['P']?.toString() ?? '') ?? 0.0;
    final high = double.tryParse(data['h']?.toString() ?? '') ?? 0.0;
    final low = double.tryParse(data['l']?.toString() ?? '') ?? 0.0;
    final volume = double.tryParse(data['v']?.toString() ?? '') ?? 0.0;

    state = state.copyWith(
      currentPrice: price,
      priceChange24h: change,
      high24h: high,
      low24h: low,
      totalVolume: volume,
    );
  }

  void _handleKlineData(Map<String, dynamic> klineData) {
    final k = klineData['k'] as Map<String, dynamic>?;
    if (k == null) return;

    final closePrice = double.tryParse(k['c']?.toString() ?? '') ?? 0.0;
    final isFinal = k['x'] == true;

    // Safety check: ensure we have spots to update
    if (state.spots.isEmpty) return;

    final newSpots = List<FlSpot>.from(state.spots);

    // Update the last spot with the latest close price (Real-time tick)
    final lastSpot = newSpots.last;
    if (lastSpot.y != closePrice) {
      debugPrint('Chart Update: ${lastSpot.y} -> $closePrice');
    }
    newSpots[newSpots.length - 1] = FlSpot(lastSpot.x, closePrice);

    // If candle is closed, append a new spot for the NEXT candle
    if (isFinal) {
      debugPrint('Candle Closed. Adding new spot.');
      // The x-axis index simply increments
      newSpots.add(FlSpot(lastSpot.x + 1, closePrice));

      // Keep list size manageable
      if (newSpots.length > 500) {
        newSpots.removeAt(0);
        // Re-index x-axis to avoid huge numbers?
        // Or just let it grow. For detailed charts, re-indexing might be smoother but
        // fl_chart handles large X values fine.
      }
    }

    state = state.copyWith(spots: newSpots, currentPrice: closePrice);
  }

  void _handleDepthData(Map<String, dynamic> data) {
    final rawBids = data['bids'] as List? ?? [];
    final rawAsks = data['asks'] as List? ?? [];

    final bids = rawBids
        .take(10)
        .map(
          (e) => OrderBookEntry(
            price: double.tryParse(e[0].toString()) ?? 0.0,
            amount: double.tryParse(e[1].toString()) ?? 0.0,
          ),
        )
        .toList();

    final asks = rawAsks
        .take(10)
        .map(
          (e) => OrderBookEntry(
            price: double.tryParse(e[0].toString()) ?? 0.0,
            amount: double.tryParse(e[1].toString()) ?? 0.0,
          ),
        )
        .toList();

    state = state.copyWith(bids: bids, asks: asks);
  }

  Future<void> fetchMarketData(String timeframe) async {
    state = state.copyWith(
      isLoading: state.spots.isEmpty,
      timeframe: timeframe,
      error: null,
    );

    try {
      String interval = '1h';
      int limit = 200;

      switch (timeframe) {
        case "LIVE": // Real-time view
          interval = '1m';
          limit = 30; // Focus on immediate action
          break;
        case "1H":
          interval = '1m';
          limit = 60;
          break;
        case "1D":
          interval = '15m';
          limit = 96;
          break;
        case "1W":
          interval = '1h';
          limit = 168;
          break;
        case "1M":
          interval = '4h';
          limit = 180;
          break;
        case "1Y":
          interval = '1d';
          limit = 365;
          break;
        case "ALL":
          interval = '1w';
          limit = 500;
          break;
      }

      // Reconnect WebSocket with new interval
      _socketService.connect(interval: interval);

      final candles = await _socketService.fetchHistoricalCandles(
        'BTCUSDT',
        interval,
        limit: limit,
      );

      if (candles.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final spots = <FlSpot>[];
      for (int i = 0; i < candles.length; i++) {
        final closePrice = double.tryParse(candles[i][4].toString()) ?? 0.0;
        spots.add(FlSpot(i.toDouble(), closePrice));
      }

      state = state.copyWith(isLoading: false, spots: spots);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';

class CandleSpot {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleSpot({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class MarketState {
  final double currentPrice;
  final double btcCurrentPrice;
  final double priceChange24h;
  final double high24h;
  final double low24h;
  final double totalVolume;
  final double marketCap;
  final List<FlSpot> spots;
  final List<FlSpot> volumeSpots;
  final List<CandleSpot> candles;
  final List<DateTime> timestamps;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final String timeframe;
  final String currency;
  final List<String> availableCurrencies;

  MarketState({
    this.currentPrice = 0.0,
    this.btcCurrentPrice = 0.0,
    this.priceChange24h = 0.0,
    this.high24h = 0.0,
    this.low24h = 0.0,
    this.totalVolume = 0.0,
    this.marketCap = 0.0,
    this.spots = const [],
    this.volumeSpots = const [],
    this.candles = const [],
    this.timestamps = const [],
    this.isLoading = false,
    this.isConnected = true,
    this.error,
    this.timeframe = "1D",
    this.currency = "USD",
    this.availableCurrencies = const ["USD", "BRL", "EUR", "BTC"],
  });

  MarketState copyWith({
    double? currentPrice,
    double? btcCurrentPrice,
    double? priceChange24h,
    double? high24h,
    double? low24h,
    double? totalVolume,
    double? marketCap,
    List<FlSpot>? spots,
    List<FlSpot>? volumeSpots,
    List<CandleSpot>? candles,
    List<DateTime>? timestamps,
    bool? isLoading,
    bool? isConnected,
    String? error,
    String? timeframe,
    String? currency,
    List<String>? availableCurrencies,
  }) {
    return MarketState(
      currentPrice: currentPrice ?? this.currentPrice,
      btcCurrentPrice: btcCurrentPrice ?? this.btcCurrentPrice,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      totalVolume: totalVolume ?? this.totalVolume,
      marketCap: marketCap ?? this.marketCap,
      spots: spots ?? this.spots,
      volumeSpots: volumeSpots ?? this.volumeSpots,
      candles: candles ?? this.candles,
      timestamps: timestamps ?? this.timestamps,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      timeframe: timeframe ?? this.timeframe,
      currency: currency ?? this.currency,
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
    );
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier();
});

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier() : super(MarketState()) {
    fetchMarketData("1D");
  }

  int _lastRequestId = 0;

  Future<void> changeCurrency(String newCurrency) async {
    if (state.currency == newCurrency) return;
    state = state.copyWith(currency: newCurrency);
    await fetchMarketData(state.timeframe);
  }

  Future<void> fetchMarketData(String timeframe) async {
    final requestId = ++_lastRequestId;
    state = state.copyWith(isLoading: true, timeframe: timeframe, error: null);

    try {
      String days = '1';
      switch (timeframe) {
        case "1H": days = '0.0416'; break;
        case "1D": days = '1'; break;
        case "1W": days = '7'; break;
        case "1M": days = '30'; break;
        case "3M": days = '90'; break;
        case "1Y": days = '365'; break;
        case "ALL": days = 'max'; break;
      }

      final chartUrl = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=${state.currency.toLowerCase()}&days=$days',
      );

      final chartResponse = await http.get(chartUrl);
      if (requestId != _lastRequestId) return;

      if (chartResponse.statusCode != 200) {
         state = state.copyWith(isLoading: false, error: "API limit. Try again later.");
         return;
      }

      final chartData = jsonDecode(chartResponse.body);
      final List<dynamic> prices = chartData['prices'] ?? [];
      final List<dynamic> volumes = chartData['total_volumes'] ?? [];

      List<FlSpot> rawSpots = [];
      List<FlSpot> volumeSpots = [];
      List<DateTime> timestamps = [];
      List<CandleSpot> candles = [];

      for (var i = 0; i < prices.length; i++) {
        final ms = (prices[i][0] as num).toInt();
        final price = (prices[i][1] as num).toDouble();
        final volume = (volumes.length > i) ? (volumes[i][1] as num).toDouble() : 0.0;
        
        rawSpots.add(FlSpot(i.toDouble(), price));
        volumeSpots.add(FlSpot(i.toDouble(), volume));
        timestamps.add(DateTime.fromMillisecondsSinceEpoch(ms));
        
        // Mocking candles from line data since CoinGecko free API doesn't provide OHLC for free in all timeframes easily
        // In a real app, we would use /ohlc endpoint or aggregate this data
        candles.add(CandleSpot(
          time: DateTime.fromMillisecondsSinceEpoch(ms),
          open: price * 0.999,
          high: price * 1.002,
          low: price * 0.998,
          close: price,
          volume: volume,
        ));
      }

      // Suavização por Média Móvel (SMA) para uma trilha mais fluida
      List<FlSpot> finalSpots = [];
      int windowSize = (rawSpots.length / 60).clamp(1, 12).toInt();
      
      for (int i = 0; i < rawSpots.length; i++) {
        double sum = 0;
        int count = 0;
        for (int j = math.max(0, i - windowSize); j <= math.min(rawSpots.length - 1, i + windowSize); j++) {
          sum += rawSpots[j].y;
          count++;
        }
        finalSpots.add(FlSpot(i.toDouble(), sum / count));
      }

      final marketUrl = Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=${state.currency.toLowerCase()}&ids=bitcoin');
      final marketResponse = await http.get(marketUrl);
      
      if (requestId == _lastRequestId && marketResponse.statusCode == 200) {
        final List<dynamic> marketList = jsonDecode(marketResponse.body);
        if (marketList.isNotEmpty) {
          final data = marketList[0];
          state = state.copyWith(
            isLoading: false,
            spots: finalSpots,
            volumeSpots: volumeSpots,
            candles: candles,
            timestamps: timestamps,
            currentPrice: (data['current_price'] as num).toDouble(),
            btcCurrentPrice: (data['current_price'] as num).toDouble(), // Simplificado
            priceChange24h: (data['price_change_percentage_24h'] as num).toDouble(),
            high24h: (data['high_24h'] as num? ?? 0.0).toDouble(),
            low24h: (data['low_24h'] as num? ?? 0.0).toDouble(),
            totalVolume: (data['total_volume'] as num).toDouble(),
            marketCap: (data['market_cap'] as num).toDouble(),
          );
        }
      } else {
         state = state.copyWith(
           isLoading: false, 
           spots: finalSpots, 
           volumeSpots: volumeSpots,
           candles: candles,
           timestamps: timestamps,
         );
      }
    } catch (e) {
      if (requestId == _lastRequestId) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

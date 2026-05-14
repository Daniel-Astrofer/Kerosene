import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/price_websocket_service.dart';

/// Provider for WebSocket price service
final priceWebSocketServiceProvider = Provider<PriceWebSocketService>((ref) {
  final service = PriceWebSocketService();
  service.connect();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream provider for BTC price in USD
final btcPriceProvider = StreamProvider<double>((ref) {
  final service = ref.watch(priceWebSocketServiceProvider);
  return service.priceStream;
});

/// Provider for latest BTC price (synchronous access)
final latestBtcPriceProvider = Provider<double?>((ref) {
  final priceAsync = ref.watch(btcPriceProvider);
  return priceAsync.when(
    data: (price) => price,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for BTC/EUR exchange rate
final btcEurPriceProvider = Provider<double?>((ref) {
  final btcUsdPrice = ref.watch(latestBtcPriceProvider);
  if (btcUsdPrice == null) return null;
  const eurUsdRate = 0.92;
  return btcUsdPrice * eurUsdRate;
});

/// Provider for BTC/BRL exchange rate
final btcBrlPriceProvider = Provider<double?>((ref) {
  final btcUsdPrice = ref.watch(latestBtcPriceProvider);
  if (btcUsdPrice == null) return null;
  const brlUsdRate = 5.0; // Approximation for now
  return btcUsdPrice * brlUsdRate;
});

/// Currency enum for multi-currency support
enum Currency {
  btc('BTC', 'Bitcoin', 8),
  usd('USD', 'US Dollar', 2),
  eur('EUR', 'Euro', 2),
  brl('BRL', 'Real', 2);

  final String code;
  final String name;
  final int decimals;

  const Currency(this.code, this.name, this.decimals);
}

/// Helper to convert any currency to BTC
double convertToBtc(
  double amount,
  Currency from,
  double? btcUsdPrice,
  double? btcEurPrice, [
  double? btcBrlPrice,
]) {
  switch (from) {
    case Currency.btc:
      return amount;
    case Currency.usd:
      if (btcUsdPrice == null || btcUsdPrice == 0) return 0;
      return amount / btcUsdPrice;
    case Currency.eur:
      if (btcEurPrice == null || btcEurPrice == 0) return 0;
      return amount / btcEurPrice;
    case Currency.brl:
      if (btcBrlPrice == null || btcBrlPrice == 0) return 0;
      return amount / btcBrlPrice;
  }
}

/// Helper to convert BTC to any currency
double convertFromBtc(
  double btcAmount,
  Currency to,
  double? btcUsdPrice,
  double? btcEurPrice, [
  double? btcBrlPrice,
]) {
  switch (to) {
    case Currency.btc:
      return btcAmount;
    case Currency.usd:
      if (btcUsdPrice == null) return 0;
      return btcAmount * btcUsdPrice;
    case Currency.eur:
      if (btcEurPrice == null) return 0;
      return btcAmount * btcEurPrice;
    case Currency.brl:
      if (btcBrlPrice == null) return 0;
      return btcAmount * btcBrlPrice;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client_provider.dart';
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

final btcTickerProvider = StreamProvider<PriceTickerSnapshot>((ref) {
  final service = ref.watch(priceWebSocketServiceProvider);
  return service.tickerStream;
});

final btcDailyChangePercentProvider = Provider<double?>((ref) {
  final tickerAsync = ref.watch(btcTickerProvider);
  return tickerAsync.whenOrNull(
    data: (ticker) => ticker.dailyChangePercent,
  );
});

/// Provider for latest BTC price (synchronous access).
/// Falls back to backend HTTP price when the external WebSocket feed is unavailable.
final latestBtcPriceProvider = Provider<double?>((ref) {
  final priceAsync = ref.watch(btcPriceProvider);
  final wsPrice = priceAsync.whenOrNull(data: (price) => price);

  if (wsPrice != null && wsPrice > 0) {
    return wsPrice;
  }

  // Fallback: use the backend's cached BTC price
  final backendRates = ref.watch(backendBtcRatesProvider);
  final backendPrice = backendRates.asData?.value?.btcUsd;
  if (backendPrice != null && backendPrice > 0) {
    return backendPrice;
  }

  return null;
});

class BackendBtcRates {
  final double btcUsd;
  final double btcBrl;
  final double usdBrl;

  const BackendBtcRates({
    required this.btcUsd,
    required this.btcBrl,
    required this.usdBrl,
  });

  factory BackendBtcRates.fromJson(Map<String, dynamic> json) {
    final btcUsd = (json['btcUsd'] as num?)?.toDouble() ?? 0;
    final btcBrl = (json['btcBrl'] as num?)?.toDouble() ?? 0;
    final usdBrl = (json['usdBrl'] as num?)?.toDouble() ??
        (btcUsd > 0 ? btcBrl / btcUsd : 0);

    return BackendBtcRates(
      btcUsd: btcUsd,
      btcBrl: btcBrl,
      usdBrl: usdBrl,
    );
  }
}

final backendBtcRatesProvider = FutureProvider<BackendBtcRates?>((ref) async {
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/api/economy/btc-price');
    final payload = Map<String, dynamic>.from(response.data as Map);
    return BackendBtcRates.fromJson(payload);
  } catch (_) {
    return null;
  }
});

final usdBrlRateProvider = Provider<double?>((ref) {
  final backendRates = ref.watch(backendBtcRatesProvider);
  return backendRates.asData?.value?.usdBrl;
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
  final brlUsdRate = ref.watch(usdBrlRateProvider) ?? 5.0;
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

final currencyQuoteProvider =
    Provider.family<double?, Currency>((ref, currency) {
  switch (currency) {
    case Currency.btc:
      return 1;
    case Currency.usd:
      return ref.watch(latestBtcPriceProvider);
    case Currency.eur:
      return ref.watch(btcEurPriceProvider);
    case Currency.brl:
      return ref.watch(btcBrlPriceProvider);
  }
});

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

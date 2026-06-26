import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kerosene/core/providers/currency_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/services/bitcoin_market_chart_service.dart';

final homeBitcoinMarketChartRangeProvider =
    StateProvider.autoDispose<BitcoinMarketChartRange>((ref) {
  return BitcoinMarketChartRange.oneDay;
});

final homeBitcoinMarketChartServiceProvider =
    Provider.autoDispose<BitcoinMarketChartService>((ref) {
  final service = BitcoinMarketChartService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final homeBitcoinMarketChartRequestProvider =
    Provider.autoDispose<BitcoinMarketChartRequest>((ref) {
  final selectedCurrency = ref.watch(currencyProvider);
  final quoteCurrency = _chartQuoteCurrencyFor(selectedCurrency);
  final range = ref.watch(homeBitcoinMarketChartRangeProvider);

  return BitcoinMarketChartRequest(
    symbol: _binanceSymbolFor(quoteCurrency),
    quoteCurrency: quoteCurrency,
    range: range,
  );
});

final homeBitcoinMarketChartProvider =
    StreamProvider.autoDispose<BitcoinMarketChartSnapshot>((ref) {
  final request = ref.watch(homeBitcoinMarketChartRequestProvider);
  final service = ref.watch(homeBitcoinMarketChartServiceProvider);
  unawaited(service.setRequest(request));
  return service.snapshots;
});

Currency _chartQuoteCurrencyFor(Currency selectedCurrency) {
  if (selectedCurrency == Currency.btc) {
    return Currency.brl;
  }
  return selectedCurrency;
}

String _binanceSymbolFor(Currency quoteCurrency) {
  switch (quoteCurrency) {
    case Currency.brl:
      return 'BTCBRL';
    case Currency.eur:
      return 'BTCEUR';
    case Currency.usd:
      return 'BTCUSDT';
    case Currency.btc:
      return 'BTCBRL';
  }
}

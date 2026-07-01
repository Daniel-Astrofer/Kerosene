import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/logging/app_log.dart';

/// Market notifications are backend-authored. The provider is kept as a
/// compatibility hook for older bootstrap code and intentionally does not
/// author local notification text.
final priceAlertProvider = Provider.autoDispose<_PriceAlertController>((ref) {
  appLog('PriceAlerts: backend notification source enabled.');
  return const _PriceAlertController();
});

class _PriceAlertController {
  const _PriceAlertController();

  void dispose() {}
}

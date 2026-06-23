import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/logging/app_log.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/core/services/price_websocket_service.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';

/// Thresholds (in absolute %) that must be crossed for a price notification to fire.
/// Alerts fire at most once per threshold per session.
const List<double> _alertThresholds = [3.0, 5.0, 8.0, 10.0, 12.0, 15.0, 20.0];

/// Provider that subscribes to the BTC ticker and fires market-alert
/// notifications whenever the 24h change crosses a meaningful threshold.
///
/// Wire this provider in bootstrap widgets (similar to balanceWebSocketServiceProvider)
/// so it is always active while the user is logged in.
final priceAlertProvider = Provider.autoDispose<_PriceAlertController>((ref) {
  final controller = _PriceAlertController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class _PriceAlertController {
  final Ref _ref;
  StreamSubscription<PriceTickerSnapshot>? _sub;
  final Set<String> _firedAlerts = {};
  double? _lastNotifiedChangePercent;

  _PriceAlertController(this._ref) {
    _start();
  }

  void _start() {
    final service = _ref.read(priceWebSocketServiceProvider);
    _sub = service.tickerStream.listen(_onTicker);
    appLog('PriceAlerts: monitoring market movements.');
  }

  void _onTicker(PriceTickerSnapshot ticker) {
    final alertPrefs = _ref.read(alertPreferencesProvider);
    if (!alertPrefs.marketAlertsEnabled) return;

    final change = ticker.dailyChangePercent;
    if (change == null) return;

    final abs = change.abs();
    final isPositive = change >= 0;

    // Find the highest threshold that was crossed but not yet notified
    double? crossedThreshold;
    for (final threshold in _alertThresholds.reversed) {
      if (abs >= threshold) {
        crossedThreshold = threshold;
        break;
      }
    }
    if (crossedThreshold == null) return;

    final alertKey =
        '${isPositive ? "up" : "down"}_${crossedThreshold.toStringAsFixed(0)}';
    if (_firedAlerts.contains(alertKey)) return;

    // Also deduplicate: only fire if the magnitude has changed meaningfully
    // from the last notification (prevents repeat fires on same threshold level)
    final last = _lastNotifiedChangePercent;
    if (last != null && (change - last).abs() < 1.0) return;

    _firedAlerts.add(alertKey);
    _lastNotifiedChangePercent = change;

    final sign = isPositive ? '▲' : '▼';
    final direction = isPositive ? 'subiu' : 'caiu';
    final title = 'Bitcoin $sign ${abs.toStringAsFixed(1)}% (24h)';
    final body =
        'O Bitcoin $direction ${abs.toStringAsFixed(1)}% nas últimas 24 horas.'
        ' Preço atual: \$${ticker.priceUsd.toStringAsFixed(0)}.';

    final notification = SessionNotificationItem(
      id: 'market_alert_$alertKey',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      kind: SessionNotificationItem.kindMarketAlert,
      severity: isPositive
          ? SessionNotificationItem.severitySuccess
          : SessionNotificationItem.severityWarning,
      deeplink: '/home',
    );

    appLog(
        'PriceAlerts: firing alert – $alertKey (${change.toStringAsFixed(2)}%).');

    _ref.read(sessionNotificationFeedProvider.notifier).add(notification);

    // Push a system notification (only if background alerts are on)
    if (alertPrefs.backgroundAlertsEnabled) {
      unawaited(
        NotificationService().showTransactionNotification(
          id: notification.id.hashCode & 0x7fffffff,
          title: title,
          body: body,
          summary: 'Kerosene',
          payload: '/home',
          incoming: isPositive,
        ),
      );
    } else {
      // Show as in-app banner regardless
      _ref.read(notificationBannerProvider.notifier).show(notification);
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    appLog('PriceAlerts: disposed.');
  }
}

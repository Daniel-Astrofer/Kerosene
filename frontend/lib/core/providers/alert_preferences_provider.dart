import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertPreferencesState {
  final bool backgroundAlertsEnabled;
  final bool inAppBannersEnabled;
  final bool transactionAlertsEnabled;
  final bool securityAlertsEnabled;
  final bool marketAlertsEnabled;

  const AlertPreferencesState({
    this.backgroundAlertsEnabled = false,
    this.inAppBannersEnabled = true,
    this.transactionAlertsEnabled = true,
    this.securityAlertsEnabled = true,
    this.marketAlertsEnabled = true,
  });

  AlertPreferencesState copyWith({
    bool? backgroundAlertsEnabled,
    bool? inAppBannersEnabled,
    bool? transactionAlertsEnabled,
    bool? securityAlertsEnabled,
    bool? marketAlertsEnabled,
  }) {
    return AlertPreferencesState(
      backgroundAlertsEnabled:
          backgroundAlertsEnabled ?? this.backgroundAlertsEnabled,
      inAppBannersEnabled: inAppBannersEnabled ?? this.inAppBannersEnabled,
      transactionAlertsEnabled:
          transactionAlertsEnabled ?? this.transactionAlertsEnabled,
      securityAlertsEnabled:
          securityAlertsEnabled ?? this.securityAlertsEnabled,
      marketAlertsEnabled: marketAlertsEnabled ?? this.marketAlertsEnabled,
    );
  }
}

class AlertPreferencesNotifier extends Notifier<AlertPreferencesState> {
  static const String backgroundAlertsKey = 'background_alerts_enabled';
  static const String inAppBannersKey = 'in_app_banners_enabled';
  static const String transactionAlertsKey = 'transaction_alerts_enabled';
  static const String securityAlertsKey = 'security_alerts_enabled';
  static const String marketAlertsKey = 'market_alerts_enabled';

  @override
  AlertPreferencesState build() {
    _load();
    return const AlertPreferencesState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      backgroundAlertsEnabled: prefs.getBool(backgroundAlertsKey) ?? false,
      inAppBannersEnabled: prefs.getBool(inAppBannersKey) ?? true,
      transactionAlertsEnabled: prefs.getBool(transactionAlertsKey) ?? true,
      securityAlertsEnabled: prefs.getBool(securityAlertsKey) ?? true,
      marketAlertsEnabled: prefs.getBool(marketAlertsKey) ?? true,
    );
  }

  Future<void> setBackgroundAlertsEnabled(bool enabled) async {
    state = state.copyWith(backgroundAlertsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundAlertsKey, enabled);
  }

  Future<void> setInAppBannersEnabled(bool enabled) async {
    state = state.copyWith(inAppBannersEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(inAppBannersKey, enabled);
  }

  Future<void> setTransactionAlertsEnabled(bool enabled) async {
    state = state.copyWith(transactionAlertsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(transactionAlertsKey, enabled);
  }

  Future<void> setSecurityAlertsEnabled(bool enabled) async {
    state = state.copyWith(securityAlertsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(securityAlertsKey, enabled);
  }

  Future<void> setMarketAlertsEnabled(bool enabled) async {
    state = state.copyWith(marketAlertsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(marketAlertsKey, enabled);
  }
}

Future<bool> loadBackgroundAlertsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(AlertPreferencesNotifier.backgroundAlertsKey) ?? false;
}

final alertPreferencesProvider =
    NotifierProvider<AlertPreferencesNotifier, AlertPreferencesState>(
  AlertPreferencesNotifier.new,
);

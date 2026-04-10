import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertPreferencesState {
  final bool backgroundAlertsEnabled;

  const AlertPreferencesState({
    this.backgroundAlertsEnabled = false,
  });

  AlertPreferencesState copyWith({
    bool? backgroundAlertsEnabled,
  }) {
    return AlertPreferencesState(
      backgroundAlertsEnabled:
          backgroundAlertsEnabled ?? this.backgroundAlertsEnabled,
    );
  }
}

class AlertPreferencesNotifier extends Notifier<AlertPreferencesState> {
  static const String backgroundAlertsKey = 'background_alerts_enabled';

  @override
  AlertPreferencesState build() {
    _load();
    return const AlertPreferencesState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      backgroundAlertsEnabled: prefs.getBool(backgroundAlertsKey) ?? false,
    );
  }

  Future<void> setBackgroundAlertsEnabled(bool enabled) async {
    state = state.copyWith(backgroundAlertsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundAlertsKey, enabled);
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

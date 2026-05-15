import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceSettings {
  final bool isHidden;
  final int decimalPlaces;

  const BalanceSettings({
    this.isHidden = false,
    this.decimalPlaces = 8,
  });

  BalanceSettings copyWith({
    bool? isHidden,
    int? decimalPlaces,
  }) {
    return BalanceSettings(
      isHidden: isHidden ?? this.isHidden,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }

  String formatBalance(double balance, {String suffix = ' BTC'}) {
    if (isHidden) return '••••••••$suffix';
    return '${balance.toStringAsFixed(decimalPlaces)}$suffix';
  }
}

class BalanceSettingsNotifier extends Notifier<BalanceSettings> {
  static const _hideKey = 'balance_hidden';
  static const _decimalsKey = 'balance_decimals';
  late SharedPreferences _prefs;

  @override
  BalanceSettings build() {
    // We'll initialize from prefs asynchronously if possible,
    // but for now let's use a simpler approach or just return default and load later.
    _loadPrefs();
    return const BalanceSettings();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final isHidden = _prefs.getBool(_hideKey) ?? false;
    final decimalPlaces = _prefs.getInt(_decimalsKey) ?? 8;
    state = BalanceSettings(isHidden: isHidden, decimalPlaces: decimalPlaces);
  }

  void toggleVisibility() {
    state = state.copyWith(isHidden: !state.isHidden);
    _prefs.setBool(_hideKey, state.isHidden);
  }

  void setDecimalPlaces(int value) {
    state = state.copyWith(decimalPlaces: value);
    _prefs.setInt(_decimalsKey, value);
  }

  void cycleDecimals() {
    // Cycle between 8, 4, 2, 0
    final current = state.decimalPlaces;
    int next;
    if (current == 8) {
      next = 4;
    } else if (current == 4) {
      next = 2;
    } else if (current == 2) {
      next = 0;
    } else {
      next = 8;
    }

    setDecimalPlaces(next);
  }
}

final balanceSettingsProvider =
    NotifierProvider<BalanceSettingsNotifier, BalanceSettings>(
        BalanceSettingsNotifier.new);

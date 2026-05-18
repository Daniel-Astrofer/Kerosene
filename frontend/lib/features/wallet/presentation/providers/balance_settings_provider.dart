import 'dart:async';

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
  static const List<int> supportedDecimalPlaces = [8, 4, 2];
  static const int minDecimalPlaces = 2;
  static const int maxDecimalPlaces = 8;
  SharedPreferences? _prefs;

  @override
  BalanceSettings build() {
    _loadPrefs();
    return const BalanceSettings();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _loadPrefs() async {
    final prefs = await _ensurePrefs();
    final isHidden = prefs.getBool(_hideKey) ?? false;
    final decimalPlaces = _normalizeDecimalPlaces(prefs.getInt(_decimalsKey));
    state = BalanceSettings(isHidden: isHidden, decimalPlaces: decimalPlaces);
  }

  void toggleVisibility() {
    state = state.copyWith(isHidden: !state.isHidden);
    final isHidden = state.isHidden;
    unawaited(
        _ensurePrefs().then((prefs) => prefs.setBool(_hideKey, isHidden)));
  }

  void setDecimalPlaces(int value) {
    final nextValue = _normalizeDecimalPlaces(value);
    state = state.copyWith(decimalPlaces: nextValue);
    unawaited(
        _ensurePrefs().then((prefs) => prefs.setInt(_decimalsKey, nextValue)));
  }

  void increaseDecimals() {
    _moveAcrossSupported(increase: true);
  }

  void decreaseDecimals() {
    _moveAcrossSupported(increase: false);
  }

  void cycleDecimals() {
    _moveAcrossSupported(increase: false);
  }

  int _normalizeDecimalPlaces(int? value) {
    final rawValue = value ?? supportedDecimalPlaces.first;
    if (rawValue >= 6) {
      return 8;
    }
    if (rawValue >= 3) {
      return 4;
    }
    return 2;
  }

  void _moveAcrossSupported({required bool increase}) {
    final current = _normalizeDecimalPlaces(state.decimalPlaces);
    final values = increase
        ? supportedDecimalPlaces.reversed.toList(growable: false)
        : supportedDecimalPlaces;
    final currentIndex = values.indexOf(current);
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = (safeIndex + 1) % values.length;
    setDecimalPlaces(values[nextIndex]);
  }
}

final balanceSettingsProvider =
    NotifierProvider<BalanceSettingsNotifier, BalanceSettings>(
        BalanceSettingsNotifier.new);

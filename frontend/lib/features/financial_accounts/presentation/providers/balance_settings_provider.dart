import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart'
    show sessionStorageScopeProvider;
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
  static const _legacyHideKey = 'balance_hidden';
  static const _legacyDecimalsKey = 'balance_decimals';
  static const _hideKeyPrefix = 'balance_hidden';
  static const _decimalsKeyPrefix = 'balance_decimals';
  static const List<int> supportedDecimalPlaces = [8, 4, 2];
  static const int minDecimalPlaces = 2;
  static const int maxDecimalPlaces = 8;
  SharedPreferences? _prefs;
  String? _sessionScope;

  @override
  BalanceSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _sessionScope = ref.watch(sessionStorageScopeProvider);
    if (_sessionScope == null) {
      return const BalanceSettings();
    }
    unawaited(_loadPrefsForScope(_sessionScope!));
    return const BalanceSettings();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _hideKey(String scope) => '${_hideKeyPrefix}_$scope';
  String _decimalsKey(String scope) => '${_decimalsKeyPrefix}_$scope';

  Future<void> _loadPrefsForScope(String scope) async {
    final prefs = await _ensurePrefs();
    final hideKey = _hideKey(scope);
    final decimalsKey = _decimalsKey(scope);
    await _migrateLegacyKeysIfNeeded(prefs, hideKey, decimalsKey);
    if (_sessionScope != scope) {
      return;
    }
    final isHidden = prefs.getBool(hideKey) ?? false;
    final decimalPlaces = _normalizeDecimalPlaces(prefs.getInt(decimalsKey));
    state = BalanceSettings(isHidden: isHidden, decimalPlaces: decimalPlaces);
  }

  Future<void> _migrateLegacyKeysIfNeeded(
    SharedPreferences prefs,
    String hideKey,
    String decimalsKey,
  ) async {
    if (!prefs.containsKey(hideKey) && prefs.containsKey(_legacyHideKey)) {
      final legacyHidden = prefs.getBool(_legacyHideKey);
      if (legacyHidden != null) {
        await prefs.setBool(hideKey, legacyHidden);
      }
    }

    if (!prefs.containsKey(decimalsKey) &&
        prefs.containsKey(_legacyDecimalsKey)) {
      final legacyDecimals = prefs.getInt(_legacyDecimalsKey);
      if (legacyDecimals != null) {
        await prefs.setInt(decimalsKey, _normalizeDecimalPlaces(legacyDecimals));
      }
    }

    await prefs.remove(_legacyHideKey);
    await prefs.remove(_legacyDecimalsKey);
  }

  void toggleVisibility() {
    state = state.copyWith(isHidden: !state.isHidden);
    final scope = _sessionScope;
    if (scope == null) {
      return;
    }
    final isHidden = state.isHidden;
    unawaited(
      _ensurePrefs().then((prefs) => prefs.setBool(_hideKey(scope), isHidden)),
    );
  }

  void setDecimalPlaces(int value) {
    final nextValue = _normalizeDecimalPlaces(value);
    state = state.copyWith(decimalPlaces: nextValue);
    final scope = _sessionScope;
    if (scope == null) {
      return;
    }
    unawaited(
      _ensurePrefs()
          .then((prefs) => prefs.setInt(_decimalsKey(scope), nextValue)),
    );
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

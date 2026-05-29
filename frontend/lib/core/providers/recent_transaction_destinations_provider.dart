import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';

enum RecentTransactionDestinationKind {
  internal,
  onChain,
  lightning,
}

final class RecentTransactionDestination {
  final String address;
  final String? label;
  final RecentTransactionDestinationKind kind;
  final DateTime lastUsedAt;

  const RecentTransactionDestination({
    required this.address,
    this.label,
    required this.kind,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'label': label,
        'kind': kind.name,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory RecentTransactionDestination.fromJson(Map<String, dynamic> json) {
    return RecentTransactionDestination(
      address: (json['address']?.toString() ?? '').trim(),
      label: _normalizeLabel(json['label']?.toString()),
      kind: _parseKind(json['kind']?.toString()),
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  static RecentTransactionDestinationKind _parseKind(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'onChain':
      case 'onchain':
      case 'on_chain':
        return RecentTransactionDestinationKind.onChain;
      case 'lightning':
        return RecentTransactionDestinationKind.lightning;
      default:
        return RecentTransactionDestinationKind.internal;
    }
  }

  static String? _normalizeLabel(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class RecentTransactionDestinationsNotifier
    extends Notifier<List<RecentTransactionDestination>> {
  static const String _storageKey = 'recent_transaction_destinations_v1';
  static const int _maxItems = 12;

  late final SharedPreferences _prefs;

  @override
  List<RecentTransactionDestination> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _readFromPrefs();
  }

  Future<void> saveDestination({
    required String address,
    required RecentTransactionDestinationKind kind,
    String? label,
  }) async {
    final normalizedAddress = address.trim();
    if (normalizedAddress.isEmpty) {
      return;
    }

    final normalizedLabel = _normalizeLabel(label);
    final existing = _findExisting(
      address: normalizedAddress,
      kind: kind,
    );

    final nextEntry = RecentTransactionDestination(
      address: normalizedAddress,
      label: normalizedLabel ?? existing?.label,
      kind: kind,
      lastUsedAt: DateTime.now(),
    );

    final next = <RecentTransactionDestination>[
      nextEntry,
      for (final item in state)
        if (_entryKey(item.address, item.kind) !=
            _entryKey(normalizedAddress, kind))
          item,
    ];

    if (next.length > _maxItems) {
      next.removeRange(_maxItems, next.length);
    }

    state = next;
    await _persist(next);
  }

  RecentTransactionDestination? _findExisting({
    required String address,
    required RecentTransactionDestinationKind kind,
  }) {
    final key = _entryKey(address, kind);
    for (final item in state) {
      if (_entryKey(item.address, item.kind) == key) {
        return item;
      }
    }
    return null;
  }

  List<RecentTransactionDestination> _readFromPrefs() {
    final rawList = _prefs.getStringList(_storageKey) ?? const <String>[];
    final entries = <RecentTransactionDestination>[];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final entry = RecentTransactionDestination.fromJson(decoded);
        if (entry.address.isEmpty) {
          continue;
        }
        entries.add(entry);
      } catch (_) {
        continue;
      }
    }

    entries.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return entries.take(_maxItems).toList(growable: false);
  }

  Future<void> _persist(List<RecentTransactionDestination> entries) {
    final jsonList =
        entries.map((entry) => jsonEncode(entry.toJson())).toList();
    return _prefs.setStringList(_storageKey, jsonList);
  }

  String _entryKey(
    String address,
    RecentTransactionDestinationKind kind,
  ) {
    final trimmed = address.trim();
    final normalized = switch (kind) {
      RecentTransactionDestinationKind.internal => trimmed,
      RecentTransactionDestinationKind.onChain ||
      RecentTransactionDestinationKind.lightning =>
        trimmed.toLowerCase(),
    };
    return '${kind.name}:$normalized';
  }

  String? _normalizeLabel(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

final recentTransactionDestinationsProvider = NotifierProvider<
    RecentTransactionDestinationsNotifier, List<RecentTransactionDestination>>(
  RecentTransactionDestinationsNotifier.new,
);

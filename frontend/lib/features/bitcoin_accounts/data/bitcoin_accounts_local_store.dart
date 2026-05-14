import 'dart:convert';

import 'package:teste/core/security/secure_storage_service.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';

class BitcoinAccountsLocalStore {
  static const _taxEventsKey = 'bitcoin_accounts_tax_events_v1';

  final SecureStorageService _storage;

  BitcoinAccountsLocalStore({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  Future<List<TaxEventView>> mergeTaxEvents(List<TaxEventView> remote) async {
    final current = await readTaxEvents();
    final byId = <String, TaxEventView>{
      for (final event in current) event.id: event,
      for (final event in remote) event.id: event,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    final capped = merged.take(750).toList();
    await _storage.write(
      key: _taxEventsKey,
      value: jsonEncode(capped.map((event) => event.toJson()).toList()),
    );
    return capped;
  }

  Future<List<TaxEventView>> readTaxEvents() async {
    final payload = await _storage.read(key: _taxEventsKey);
    if (payload == null || payload.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => TaxEventView.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveTaxEvents(List<TaxEventView> events) async {
    await _storage.write(
      key: _taxEventsKey,
      value: jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }

  String csvFor(List<TaxEventView> events) {
    final buffer = StringBuffer()
      ..writeln(
        'created_at,event_type,asset,quantity_sats,classification,source_ref,account_id,card_id,wallet_id',
      );
    for (final event in events) {
      buffer.writeln([
        event.createdAt ?? '',
        event.eventType,
        event.asset,
        event.quantitySats.toString(),
        event.classification,
        event.sourceRef ?? '',
        event.accountId ?? '',
        event.cardId ?? '',
        event.walletId ?? '',
      ].map(_csv).join(','));
    }
    return buffer.toString();
  }

  String jsonFor(List<TaxEventView> events) {
    return const JsonEncoder.withIndent('  ').convert(
      events.map((event) => event.toJson()).toList(),
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return escaped.contains(',') ||
            escaped.contains('\n') ||
            escaped.contains('"')
        ? '"$escaped"'
        : escaped;
  }
}

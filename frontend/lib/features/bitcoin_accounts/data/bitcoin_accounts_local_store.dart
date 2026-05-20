import 'dart:convert';

import 'package:teste/core/security/secure_storage_service.dart';

import 'bitcoin_account_models.dart';

class BitcoinAccountsLocalStore {
  BitcoinAccountsLocalStore({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  static const _accountsKey = 'bitcoin_accounts.v1';
  static const _receiveRequestsKey = 'bitcoin_receive_requests.v1';
  static const _taxEventsKey = 'bitcoin_tax_events.v1';

  final SecureStorageService _storage;

  Future<List<BitcoinAccount>> loadAccounts() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BitcoinAccount.fromJson)
        .where((account) => account.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveAccounts(List<BitcoinAccount> accounts) async {
    await _storage.write(
      key: _accountsKey,
      value: jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  Future<void> upsertAccount(BitcoinAccount account) async {
    final accounts = await loadAccounts();
    final next = [
      account,
      ...accounts.where((existing) => existing.id != account.id),
    ];
    await saveAccounts(next);
  }

  Future<void> upsertReceiveRequest(ReceivingRequestView request) async {
    final requests = await _loadReceiveRequests();
    final next = [
      request,
      ...requests.where((existing) => existing.id != request.id),
    ];
    await _saveReceiveRequests(next);
  }

  Future<ReceivingRequestView?> findReceiveRequest(String requestId) async {
    final requests = await _loadReceiveRequests();
    for (final request in requests) {
      if (request.id == requestId) {
        return request;
      }
    }
    return null;
  }

  Future<List<ReceivingRequestView>> loadReceiveRequestsForAccount(
    String accountId,
  ) async {
    final requests = await _loadReceiveRequests();
    return requests
        .where((request) => request.accountId == accountId)
        .toList(growable: false);
  }

  Future<List<TaxEventView>> mergeTaxEvents(List<TaxEventView> incoming) async {
    final existing = await _loadTaxEvents();
    final byId = <String, TaxEventView>{
      for (final event in existing) event.id: event,
      for (final event in incoming) event.id: event,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveTaxEvents(merged);
    return merged;
  }

  String csvFor(List<TaxEventView> events) {
    final rows = [
      'id,eventType,asset,quantitySats,classification,sourceRef,createdAt',
      for (final event in events)
        [
          event.id,
          event.eventType,
          event.asset,
          event.quantitySats,
          event.classification,
          event.sourceRef,
          event.createdAt,
        ].map(_csvEscape).join(','),
    ];
    return rows.join('\n');
  }

  String jsonFor(List<TaxEventView> events) {
    return jsonEncode(events.map((event) => event.toJson()).toList());
  }

  Future<List<ReceivingRequestView>> _loadReceiveRequests() async {
    final raw = await _storage.read(key: _receiveRequestsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ReceivingRequestView.fromJson)
        .toList(growable: false);
  }

  Future<void> _saveReceiveRequests(List<ReceivingRequestView> requests) async {
    await _storage.write(
      key: _receiveRequestsKey,
      value: jsonEncode(requests.map((request) => request.toJson()).toList()),
    );
  }

  Future<List<TaxEventView>> _loadTaxEvents() async {
    final raw = await _storage.read(key: _taxEventsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TaxEventView.fromJson)
        .toList(growable: false);
  }

  Future<void> _saveTaxEvents(List<TaxEventView> events) async {
    await _storage.write(
      key: _taxEventsKey,
      value: jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }

  String _csvEscape(Object? value) {
    final string = '$value';
    if (!string.contains(',') &&
        !string.contains('"') &&
        !string.contains('\n')) {
      return string;
    }
    return '"${string.replaceAll('"', '""')}"';
  }
}

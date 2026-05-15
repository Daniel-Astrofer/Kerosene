import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/security/secure_storage_service.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_local_store.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return values[key];
  }
}

void main() {
  test('mergeTaxEvents keeps a durable local copy without duplicating ids',
      () async {
    final storage = FakeSecureStorageService();
    final store = BitcoinAccountsLocalStore(storage: storage);
    final event = TaxEventView(
      id: 'event-1',
      eventType: 'DEPOSIT_INTERNAL',
      asset: 'BTC',
      quantitySats: 12000,
      classification: 'USER_CLASSIFICATION_PENDING',
      sourceRef: 'txref:0',
      createdAt: '2026-04-30T12:00:00',
    );

    await store.mergeTaxEvents([event]);
    final merged = await store.mergeTaxEvents([event]);

    expect(merged, hasLength(1));
    expect(merged.single.quantitySats, 12000);
    expect(store.csvFor(merged), contains('DEPOSIT_INTERNAL'));
    expect(store.jsonFor(merged), contains('event-1'));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences sharedPreferences;
  late ProviderContainer container;

  Future<ProviderContainer> createContainer() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    container = await createContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('stores newest destinations first and deduplicates by address and kind',
      () async {
    final notifier = container.read(
      recentTransactionDestinationsProvider.notifier,
    );

    await notifier.saveDestination(
      address: 'bc1qvaultdestino',
      kind: RecentTransactionDestinationKind.onChain,
      label: 'Cold wallet',
    );
    await notifier.saveDestination(
      address: 'wallet-interna-01',
      kind: RecentTransactionDestinationKind.internal,
    );
    await notifier.saveDestination(
      address: 'bc1qvaultdestino',
      kind: RecentTransactionDestinationKind.onChain,
      label: 'Hardware wallet',
    );

    final destinations = container.read(recentTransactionDestinationsProvider);

    expect(destinations, hasLength(2));
    expect(destinations.first.address, 'bc1qvaultdestino');
    expect(destinations.first.kind, RecentTransactionDestinationKind.onChain);
    expect(destinations.first.label, 'Hardware wallet');
    expect(destinations.last.address, 'wallet-interna-01');
  });

  test('persists destinations and enforces the storage limit', () async {
    final notifier = container.read(
      recentTransactionDestinationsProvider.notifier,
    );

    for (var index = 0; index < 14; index++) {
      await notifier.saveDestination(
        address: 'wallet-$index',
        kind: RecentTransactionDestinationKind.internal,
      );
    }

    final current = container.read(recentTransactionDestinationsProvider);
    expect(current, hasLength(12));
    expect(current.first.address, 'wallet-13');
    expect(current.last.address, 'wallet-2');

    final reloaded = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(reloaded.dispose);

    final persisted = reloaded.read(recentTransactionDestinationsProvider);
    expect(persisted, hasLength(12));
    expect(persisted.first.address, 'wallet-13');
    expect(persisted.last.address, 'wallet-2');
  });
}

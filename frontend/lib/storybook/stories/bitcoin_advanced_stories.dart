import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';

import '../storybook_mocks.dart';

List<Story> bitcoinAdvancedStories() {
  return [
    Story(
      name: 'Bitcoin/Advanced',
      builder: (_) => ProviderScope(
        overrides: [
          bitcoinAccountsServiceProvider.overrideWithValue(
            MockBitcoinAccountsService(),
          ),
          bitcoinAccountsProvider.overrideWith(BitcoinAccountsNotifier.new),
        ],
        child: const BitcoinAccountsScreen(),
      ),
    ),
    Story(
      name: 'Bitcoin/Cards Surface',
      builder: (_) => const BitcoinCardsSurfaceStoryPreview(),
    ),
    Story(
      name: 'Bitcoin/Cold Wallet/Create Flow',
      builder: (_) => const ColdWalletCreationStoryPreview(),
    ),
  ];
}

class BitcoinCardsSurfaceStoryPreview extends StatelessWidget {
  const BitcoinCardsSurfaceStoryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        bitcoinAccountsServiceProvider.overrideWithValue(
          MockBitcoinAccountsService(),
        ),
        bitcoinAccountsProvider.overrideWith(BitcoinAccountsNotifier.new),
      ],
      child: const BitcoinAccountsScreen(),
    );
  }
}

class ColdWalletCreationStoryPreview extends StatelessWidget {
  const ColdWalletCreationStoryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        bitcoinAccountsServiceProvider.overrideWithValue(
          MockBitcoinAccountsService(),
        ),
        bitcoinAccountsProvider.overrideWith(BitcoinAccountsNotifier.new),
      ],
      child: const ColdWalletCreationScreen(initialStepName: 'prepare'),
    );
  }
}

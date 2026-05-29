import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';

import '../storybook_mocks.dart';

enum ReceiveRequestStoryScenario {
  loading,
  empty,
  pending,
  paid,
  expired,
  error,
}

extension ReceiveRequestStoryScenarioX on ReceiveRequestStoryScenario {
  String get label {
    return switch (this) {
      ReceiveRequestStoryScenario.loading => 'Loading',
      ReceiveRequestStoryScenario.empty => 'Empty',
      ReceiveRequestStoryScenario.pending => 'Pending',
      ReceiveRequestStoryScenario.paid => 'Paid',
      ReceiveRequestStoryScenario.expired => 'Expired',
      ReceiveRequestStoryScenario.error => 'Error',
    };
  }
}

List<Story> receiveStories() {
  return [
    for (final scenario in ReceiveRequestStoryScenario.values)
      Story(
        name: 'Receive/Requests/${scenario.label}',
        builder: (_) => ReceiveRequestsScenarioPreview(
          scenario: scenario,
        ),
      ),
  ];
}

class ReceiveRequestsScenarioPreview extends StatelessWidget {
  final ReceiveRequestStoryScenario scenario;

  const ReceiveRequestsScenarioPreview({
    super.key,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        bitcoinAccountsServiceProvider.overrideWithValue(
          _ReceiveRequestsScenarioService(scenario),
        ),
        bitcoinAccountsProvider.overrideWith(BitcoinAccountsNotifier.new),
      ],
      child: const BitcoinAccountsScreen(),
    );
  }
}

class _ReceiveRequestsScenarioService extends MockBitcoinAccountsService {
  final ReceiveRequestStoryScenario scenario;

  _ReceiveRequestsScenarioService(this.scenario)
      : super(
          receiveRequests: _requestsForScenario(scenario),
          listRequestsError: scenario == ReceiveRequestStoryScenario.error
              ? Exception('Storybook receive requests failure')
              : null,
        );

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) {
    if (scenario == ReceiveRequestStoryScenario.loading) {
      return Completer<List<ReceivingRequestView>>().future;
    }

    return super.listReceiveRequestsForAccount(accountId);
  }
}

List<ReceivingRequestView>? _requestsForScenario(
  ReceiveRequestStoryScenario scenario,
) {
  return switch (scenario) {
    ReceiveRequestStoryScenario.loading => const <ReceivingRequestView>[],
    ReceiveRequestStoryScenario.empty => const <ReceivingRequestView>[],
    ReceiveRequestStoryScenario.pending => mockReceiveRequests
        .where((request) => request.status == 'ACTIVE')
        .toList(),
    ReceiveRequestStoryScenario.paid =>
      mockReceiveRequests.where((request) => request.status == 'PAID').toList(),
    ReceiveRequestStoryScenario.expired => mockReceiveRequests
        .where((request) => request.status == 'EXPIRED')
        .toList(),
    ReceiveRequestStoryScenario.error => const <ReceivingRequestView>[],
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:kerosene/features/payments/data/payment_intent_service.dart';
import 'package:kerosene/features/payments/domain/payment_intent_models.dart';
import 'package:kerosene/features/payments/presentation/providers/payment_intent_provider.dart';
import 'package:kerosene/features/payments/presentation/screens/payment_intent_flow_screen.dart';

enum PaymentIntentStoryScenario {
  start,
  capabilities,
  quote,
  settled,
  failed,
  missingCapability,
}

extension PaymentIntentStoryScenarioX on PaymentIntentStoryScenario {
  String get label {
    return switch (this) {
      PaymentIntentStoryScenario.start => 'Intent Start',
      PaymentIntentStoryScenario.capabilities => 'Intent Capabilities',
      PaymentIntentStoryScenario.quote => 'Intent Quote',
      PaymentIntentStoryScenario.settled => 'Intent Settled',
      PaymentIntentStoryScenario.failed => 'Intent Failed',
      PaymentIntentStoryScenario.missingCapability => 'Intent Missing Rail',
    };
  }
}

List<Story> paymentStories() {
  return [
    for (final scenario in PaymentIntentStoryScenario.values)
      Story(
        name: 'Payments/${scenario.label}',
        builder: (_) => PaymentIntentScenarioPreview(scenario: scenario),
      ),
  ];
}

class PaymentIntentScenarioPreview extends StatelessWidget {
  final PaymentIntentStoryScenario scenario;

  const PaymentIntentScenarioPreview({
    super.key,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        paymentIntentServiceProvider.overrideWithValue(
          _StoryPaymentIntentService(scenario),
        ),
        paymentIntentFlowProvider.overrideWith(PaymentIntentFlowController.new),
      ],
      child: _PaymentIntentScenarioBootstrap(scenario: scenario),
    );
  }
}

class _PaymentIntentScenarioBootstrap extends ConsumerStatefulWidget {
  final PaymentIntentStoryScenario scenario;

  const _PaymentIntentScenarioBootstrap({required this.scenario});

  @override
  ConsumerState<_PaymentIntentScenarioBootstrap> createState() =>
      _PaymentIntentScenarioBootstrapState();
}

class _PaymentIntentScenarioBootstrapState
    extends ConsumerState<_PaymentIntentScenarioBootstrap> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _seed());
  }

  Future<void> _seed() async {
    if (!mounted) return;
    final controller = ref.read(paymentIntentFlowProvider.notifier);
    controller.setRecipient('ops@kerosene.local');
    controller.setAmountFiat('250.00');

    if (widget.scenario == PaymentIntentStoryScenario.start) return;

    await controller.loadCapabilities();
    if (!mounted) return;

    if (widget.scenario == PaymentIntentStoryScenario.capabilities ||
        widget.scenario == PaymentIntentStoryScenario.missingCapability) {
      return;
    }

    await controller.requestQuote();
    if (!mounted) return;

    if (widget.scenario == PaymentIntentStoryScenario.settled ||
        widget.scenario == PaymentIntentStoryScenario.failed) {
      await controller.confirmQuote();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PaymentIntentFlowScreen(
      initialRecipient: 'ops@kerosene.local',
      initialAmountFiat: '250.00',
    );
  }
}

class _StoryPaymentIntentService implements PaymentIntentService {
  final PaymentIntentStoryScenario scenario;

  const _StoryPaymentIntentService(this.scenario);

  @override
  Future<ReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  ) async {
    if (scenario == PaymentIntentStoryScenario.missingCapability) {
      return const ReceivingCapabilities(
        canReceiveInternal: false,
        canReceiveLightning: false,
        canReceiveOnchain: false,
        preferredRail: PaymentRail.internal,
        missingRequirements: ['Receiver has no active receiving method.'],
        receiverDisplayName: 'Operations Desk',
        availableRails: [],
        limits: PaymentLimits(
          asset: 'BTC',
          fiatCurrencies: ['BRL', 'USD'],
          minInternalSats: 1000,
          minLightningSats: 1000,
          minOnchainSats: 10000,
        ),
      );
    }

    return const ReceivingCapabilities(
      canReceiveInternal: true,
      canReceiveLightning: true,
      canReceiveOnchain: true,
      preferredRail: PaymentRail.internal,
      missingRequirements: [],
      receiverDisplayName: 'Operations Desk',
      availableRails: [
        PaymentRail.internal,
        PaymentRail.lightning,
        PaymentRail.onchain,
      ],
      limits: PaymentLimits(
        asset: 'BTC',
        fiatCurrencies: ['BRL', 'USD'],
        minInternalSats: 1000,
        minLightningSats: 1000,
        minOnchainSats: 10000,
      ),
    );
  }

  @override
  Future<PaymentQuote> quote(PaymentQuoteDraft draft) async {
    return PaymentQuote(
      paymentIntentId: '7b3e7c91-4fb5-40f4-a7b8-storybook001',
      quoteExpiresAt: DateTime.now().add(const Duration(minutes: 3)),
      rail: draft.rail,
      feeMode: draft.feeMode,
      receiverDisplayName: 'Operations Desk',
      receiverAmountFiat: '250.00',
      receiverAmountSats: 125000,
      totalDebitFiat: '251.20',
      totalDebitSats: 125600,
      networkFeeFiat: '0.70',
      networkFeeSats: 350,
      keroseneFeeFiat: '0.50',
      keroseneFeeSats: 250,
      warnings: draft.rail == PaymentRail.onchain
          ? const ['On-chain settlement depends on mempool conditions.']
          : const [],
      requiresConfirmation: true,
    );
  }

  @override
  Future<PaymentStatus> confirm({
    required String paymentIntentId,
    required String idempotencyKey,
    required int acceptedTotalDebitSats,
    required int acceptedReceiverAmountSats,
    String? userConfirmationToken,
  }) async {
    final failed = scenario == PaymentIntentStoryScenario.failed;
    return PaymentStatus(
      paymentIntentId: paymentIntentId,
      status: failed ? PaymentIntentStatus.failed : PaymentIntentStatus.settled,
      rail: PaymentRail.internal,
      feeMode: PaymentFeeMode.senderPays,
      receiverDisplayName: 'Operations Desk',
      receiverAmountSats: acceptedReceiverAmountSats,
      totalDebitSats: acceptedTotalDebitSats,
      networkFeeSats: 350,
      keroseneFeeSats: 250,
      quoteExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
      failureCode: failed ? 'PROVIDER_REJECTED' : null,
      failureMessage:
          failed ? 'The provider rejected the payment authorization.' : null,
      warnings: const [],
    );
  }

  @override
  Future<PaymentStatus> status(String paymentIntentId) async {
    return PaymentStatus(
      paymentIntentId: paymentIntentId,
      status: PaymentIntentStatus.processing,
      rail: PaymentRail.internal,
      feeMode: PaymentFeeMode.senderPays,
      receiverDisplayName: 'Operations Desk',
      receiverAmountSats: 125000,
      totalDebitSats: 125600,
      networkFeeSats: 350,
      keroseneFeeSats: 250,
      quoteExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
      failureCode: null,
      failureMessage: null,
      warnings: const [],
    );
  }
}

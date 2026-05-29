import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/features/payments/domain/payment_intent_models.dart';
import 'package:kerosene/features/payments/presentation/providers/payment_intent_provider.dart';
import 'package:kerosene/features/payments/presentation/widgets/payment_intent_widgets.dart';

class PaymentIntentFlowScreen extends ConsumerStatefulWidget {
  final String initialRecipient;
  final String initialAmountFiat;

  const PaymentIntentFlowScreen({
    super.key,
    this.initialRecipient = '',
    this.initialAmountFiat = '',
  });

  @override
  ConsumerState<PaymentIntentFlowScreen> createState() =>
      _PaymentIntentFlowScreenState();
}

class _PaymentIntentFlowScreenState
    extends ConsumerState<PaymentIntentFlowScreen> {
  late final TextEditingController _recipientController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.initialRecipient);
    _amountController = TextEditingController(text: widget.initialAmountFiat);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(paymentIntentFlowProvider.notifier);
      if (widget.initialRecipient.trim().isNotEmpty) {
        controller.setRecipient(widget.initialRecipient);
      }
      if (widget.initialAmountFiat.trim().isNotEmpty) {
        controller.setAmountFiat(widget.initialAmountFiat);
      }
    });
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentIntentFlowProvider);
    final controller = ref.read(paymentIntentFlowProvider.notifier);
    final capabilities = state.capabilities;
    final availableRails = capabilities?.availableRails.isEmpty == false
        ? capabilities!.availableRails
        : PaymentRail.values;
    final errorMessage = _paymentIntentErrorMessage(context, state);

    return Scaffold(
      backgroundColor: paymentIntentBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _Header(status: state.status?.status),
                const SizedBox(height: 18),
                PaymentRecipientPicker(
                  controller: _recipientController,
                  loading: state.isLoadingCapabilities,
                  onLookup: () {
                    controller.setRecipient(_recipientController.text);
                    controller.loadCapabilities();
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  PaymentErrorBanner(message: errorMessage),
                ],
                if (capabilities != null) ...[
                  const SizedBox(height: 14),
                  PaymentSectionPanel(
                    title: capabilities.receiverDisplayName,
                    icon: LucideIcons.badgeCheck,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            CapabilityBadge(
                              rail: PaymentRail.internal,
                              enabled: capabilities.canReceiveInternal,
                            ),
                            CapabilityBadge(
                              rail: PaymentRail.lightning,
                              enabled: capabilities.canReceiveLightning,
                            ),
                            CapabilityBadge(
                              rail: PaymentRail.onchain,
                              enabled: capabilities.canReceiveOnchain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RouteSelector(
                          availableRails: availableRails,
                          selectedRail: state.selectedRail,
                          onChanged: controller.setRail,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                PaymentSectionPanel(
                  title: context.tr.paymentIntentAmountFeeTitle,
                  icon: LucideIcons.coins,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PaymentAmountInput(
                        controller: _amountController,
                        onChanged: controller.setAmountFiat,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final mode in PaymentFeeMode.values)
                            ChoiceChip(
                              selected: state.feeMode == mode,
                              label: Text(
                                paymentIntentFeeModeLabel(context, mode),
                              ),
                              onSelected: (_) => controller.setFeeMode(mode),
                            ),
                        ],
                      ),
                      if (state.selectedRail == PaymentRail.onchain) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final speed in OnchainSpeed.values)
                              ChoiceChip(
                                selected: state.onchainSpeed == speed,
                                label: Text(
                                  paymentIntentOnchainSpeedLabel(
                                    context,
                                    speed,
                                  ),
                                ),
                                onSelected: (_) =>
                                    controller.setOnchainSpeed(speed),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: state.isQuoting
                            ? null
                            : () {
                                controller.setAmountFiat(
                                  _amountController.text,
                                );
                                controller.requestQuote();
                              },
                        icon: state.isQuoting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.router, size: 17),
                        label:
                            Text(context.tr.paymentIntentGenerateQuoteAction),
                      ),
                    ],
                  ),
                ),
                if (state.quote != null) ...[
                  const SizedBox(height: 14),
                  PaymentQuoteCard(
                    quote: state.quote!,
                    confirming: state.isConfirming,
                    onConfirm: () => _confirmQuote(context, state.quote!),
                  ),
                ],
                if (state.quote != null || state.status != null) ...[
                  const SizedBox(height: 14),
                  PaymentStatusTimeline(status: state.status),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmQuote(BuildContext context, PaymentQuote quote) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111113),
      builder: (sheetContext) {
        return PaymentConfirmationSheet(
          quote: quote,
          onConfirm: () {
            Navigator.of(sheetContext).pop();
            ref.read(paymentIntentFlowProvider.notifier).confirmQuote();
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final PaymentIntentStatus? status;

  const _Header({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF171719),
            border: Border.all(color: const Color(0xFF2A2A2E)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.paymentIntentScreenTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr.paymentIntentScreenSubtitle,
                style: const TextStyle(
                  color: Color(0xFF9A9AA0),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (status != null)
          Text(
            paymentIntentStatusLabel(context, status!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

String? _paymentIntentErrorMessage(
  BuildContext context,
  PaymentIntentFlowState state,
) {
  return switch (state.errorKey) {
    PaymentIntentFlowError.receiverRequired =>
      context.tr.paymentIntentValidationRecipientRequired,
    PaymentIntentFlowError.amountRequired =>
      context.tr.paymentIntentValidationAmountRequired,
    null => state.errorMessage,
  };
}

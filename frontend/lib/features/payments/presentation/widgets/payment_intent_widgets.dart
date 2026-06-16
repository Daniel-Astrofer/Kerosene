import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/features/payments/domain/payment_intent_models.dart';
import 'package:kerosene/core/theme/app_colors.dart';

class PaymentRecipientPicker extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLookup;

  const PaymentRecipientPicker({
    super.key,
    required this.controller,
    required this.loading,
    required this.onLookup,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(LucideIcons.userCheck, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.tr.paymentIntentRecipientHint,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onLookup(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 118,
              child: FilledButton.icon(
                onPressed: loading ? null : onLookup,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.search, size: 16),
                label: Text(context.tr.paymentIntentSearchAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapabilityBadge extends StatelessWidget {
  final PaymentRail rail;
  final bool enabled;

  const CapabilityBadge({
    super.key,
    required this.rail,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        border: Border.all(
          color: enabled
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? LucideIcons.checkCircle2 : LucideIcons.circleSlash,
              color: enabled ? AppColors.success : AppColors.textMuted,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              paymentIntentRailLabel(context, rail),
              style: TextStyle(
                color: enabled ? AppColors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteSelector extends StatelessWidget {
  final List<PaymentRail> availableRails;
  final PaymentRail selectedRail;
  final ValueChanged<PaymentRail> onChanged;

  const RouteSelector({
    super.key,
    required this.availableRails,
    required this.selectedRail,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final rail in PaymentRail.values)
          ChoiceChip(
            selected: selectedRail == rail,
            label: Text(paymentIntentRailLabel(context, rail)),
            avatar: Icon(
              _iconForRail(rail),
              size: 16,
              color: selectedRail == rail ? AppColors.black : AppColors.white,
            ),
            onSelected:
                availableRails.contains(rail) ? (_) => onChanged(rail) : null,
          ),
      ],
    );
  }
}

class PaymentQuoteCard extends StatelessWidget {
  final PaymentQuote quote;
  final bool confirming;
  final VoidCallback onConfirm;

  const PaymentQuoteCard({
    super.key,
    required this.quote,
    required this.confirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.tr.paymentIntentQuoteTitle,
      icon: LucideIcons.receipt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricLine(
            context.tr.paymentIntentMetricReceiver,
            quote.receiverDisplayName,
          ),
          _MetricLine(
            context.tr.paymentIntentMetricRoute,
            paymentIntentRailLabel(context, quote.rail),
          ),
          _MetricLine(
            context.tr.paymentIntentMetricReceives,
            _sats(quote.receiverAmountSats),
          ),
          _MetricLine(
            context.tr.paymentIntentMetricNetworkFee,
            _sats(quote.networkFeeSats),
          ),
          _MetricLine(
            context.tr.paymentIntentMetricKeroseneFee,
            _sats(quote.keroseneFeeSats),
          ),
          const Divider(color: AppColors.border, height: 22),
          _MetricLine(
            context.tr.paymentIntentMetricTotalDebit,
            _sats(quote.totalDebitSats),
          ),
          if (quote.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final warning in quote.warnings)
              _Notice(icon: LucideIcons.alertTriangle, text: warning),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: confirming ? null : onConfirm,
            icon: confirming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.shieldCheck, size: 17),
            label: Text(context.tr.paymentIntentConfirmPaymentAction),
          ),
        ],
      ),
    );
  }
}

class PaymentStatusTimeline extends StatelessWidget {
  final PaymentStatus? status;

  const PaymentStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final current = status?.status ?? PaymentIntentStatus.created;
    final steps = [
      PaymentIntentStatus.quoted,
      PaymentIntentStatus.confirmed,
      PaymentIntentStatus.processing,
      PaymentIntentStatus.settled,
    ];

    return _Panel(
      title: context.tr.paymentIntentStatusTitle,
      icon: LucideIcons.activity,
      child: Column(
        children: [
          for (final step in steps)
            _TimelineRow(
              label: paymentIntentStatusLabel(context, step),
              active: _statusRank(current) >= _statusRank(step),
              terminal: current.isTerminal && current == step,
            ),
          if (current == PaymentIntentStatus.failed ||
              current == PaymentIntentStatus.canceled ||
              current == PaymentIntentStatus.expired)
            _Notice(
              icon: LucideIcons.alertTriangle,
              text: status?.failureMessage ??
                  context.tr.paymentIntentNotCompleted,
            ),
        ],
      ),
    );
  }
}

class PaymentConfirmationSheet extends StatelessWidget {
  final PaymentQuote quote;
  final VoidCallback onConfirm;

  const PaymentConfirmationSheet({
    super.key,
    required this.quote,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.shieldAlert,
                color: AppColors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              context.tr.paymentIntentReviewTitle,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.paymentIntentReviewDebitMessage(
                _sats(quote.totalDebitSats),
                quote.receiverDisplayName,
              ),
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(context.tr.paymentIntentAuthorizeAction),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSectionPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const PaymentSectionPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(title: title, icon: icon, child: child);
  }
}

class PaymentAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const PaymentAmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      decoration: const InputDecoration(
        prefixText: 'R\$ ',
        prefixStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        hintText: '0,00',
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: InputBorder.none,
      ),
    );
  }
}

class PaymentErrorBanner extends StatelessWidget {
  final String message;

  const PaymentErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return _Notice(icon: LucideIcons.alertTriangle, text: message);
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetricLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child:
                Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool active;
  final bool terminal;

  const _TimelineRow({
    required this.label,
    required this.active,
    required this.terminal,
  });

  @override
  Widget build(BuildContext context) {
    final color = terminal
        ? AppColors.success
        : active
            ? AppColors.white
            : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            active ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.primary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForRail(PaymentRail rail) {
  return switch (rail) {
    PaymentRail.internal => LucideIcons.repeat2,
    PaymentRail.lightning => LucideIcons.zap,
    PaymentRail.onchain => LucideIcons.link,
  };
}

int _statusRank(PaymentIntentStatus status) {
  return switch (status) {
    PaymentIntentStatus.created => 0,
    PaymentIntentStatus.quoted => 1,
    PaymentIntentStatus.confirmed => 2,
    PaymentIntentStatus.processing ||
    PaymentIntentStatus.acceptedByProvider ||
    PaymentIntentStatus.requiresReconciliation =>
      3,
    PaymentIntentStatus.settled => 4,
    PaymentIntentStatus.failed ||
    PaymentIntentStatus.canceled ||
    PaymentIntentStatus.expired =>
      5,
  };
}

String paymentIntentRailLabel(BuildContext context, PaymentRail rail) {
  return switch (rail) {
    PaymentRail.internal => context.tr.paymentIntentRailInternal,
    PaymentRail.lightning => context.tr.paymentIntentRailLightning,
    PaymentRail.onchain => context.tr.paymentIntentRailOnchain,
  };
}

String paymentIntentFeeModeLabel(
  BuildContext context,
  PaymentFeeMode mode,
) {
  return switch (mode) {
    PaymentFeeMode.senderPays => context.tr.paymentIntentFeeSenderPays,
    PaymentFeeMode.recipientPays => context.tr.paymentIntentFeeRecipientPays,
  };
}

String paymentIntentOnchainSpeedLabel(
  BuildContext context,
  OnchainSpeed speed,
) {
  return switch (speed) {
    OnchainSpeed.economy => context.tr.paymentIntentSpeedEconomy,
    OnchainSpeed.normal => context.tr.paymentIntentSpeedNormal,
    OnchainSpeed.fast => context.tr.paymentIntentSpeedFast,
  };
}

String paymentIntentStatusLabel(
    BuildContext context, PaymentIntentStatus status) {
  return switch (status) {
    PaymentIntentStatus.created => context.tr.paymentIntentStatusCreated,
    PaymentIntentStatus.quoted => context.tr.paymentIntentStatusQuoted,
    PaymentIntentStatus.confirmed => context.tr.paymentIntentStatusConfirmed,
    PaymentIntentStatus.processing => context.tr.paymentIntentStatusProcessing,
    PaymentIntentStatus.acceptedByProvider =>
      context.tr.paymentIntentStatusAcceptedByProvider,
    PaymentIntentStatus.requiresReconciliation =>
      context.tr.paymentIntentStatusRequiresReconciliation,
    PaymentIntentStatus.settled => context.tr.paymentIntentStatusSettled,
    PaymentIntentStatus.failed => context.tr.paymentIntentStatusFailed,
    PaymentIntentStatus.canceled => context.tr.paymentIntentStatusCanceled,
    PaymentIntentStatus.expired => context.tr.paymentIntentStatusExpired,
  };
}

String _sats(int value) {
  return '${value.toString()} sats';
}

Color get paymentIntentBackgroundColor => AppColors.background;

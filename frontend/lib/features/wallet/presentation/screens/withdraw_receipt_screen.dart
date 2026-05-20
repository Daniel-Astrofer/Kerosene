import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

class WithdrawReceiptScreen extends StatelessWidget {
  final String amountBtc;
  final String toAddress;
  final String txId;
  final String feeBtc;
  final String walletName;
  final DateTime timestamp;
  final bool isLightning;

  const WithdrawReceiptScreen({
    super.key,
    required this.amountBtc,
    required this.toAddress,
    required this.txId,
    required this.feeBtc,
    required this.walletName,
    required this.timestamp,
    this.isLightning = false,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: context.tr.withdrawSuccess,
      subtitle: context.tr.withdrawReceiptSubtitle,
      onBack: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSuccessIcon(context),
          const SizedBox(height: AppSpacing.lg),
          _buildAmountSection(context),
          const SizedBox(height: AppSpacing.lg),
          _buildDetailsCard(context),
          const SizedBox(height: AppSpacing.xl),
          ReceiveFlowPrimaryButton(
            label: context.tr.done.toUpperCase(),
            icon: LucideIcons.check,
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: receiveFlowPanelRaisedColor,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: receiveFlowBorderStrongColor),
        ),
        child: const Icon(
          LucideIcons.check,
          color: receiveFlowTextColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr.withdrawSuccess.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: receiveFlowFaintTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: receiveFlowMutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              amountBtc,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: receiveFlowTextColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'JetBrainsMono',
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return ReceiveFlowPanel(
      child: Column(
        children: [
          _buildDetailRow(context, context.tr.walletName, walletName),
          const ReceiveFlowDivider(),
          _buildDetailRow(
              context,
              AppCopy.withdrawReceiptDestinationLabel(
                context,
                isLightning: isLightning,
              ),
              toAddress,
              isAddress: true),
          const ReceiveFlowDivider(),
          _buildDetailRow(
            context,
            AppCopy.withdrawReceiptTime.resolve(context),
            dateFormat.format(timestamp),
          ),
          const ReceiveFlowDivider(),
          _buildDetailRow(
            context,
            AppCopy.withdrawReceiptFee.resolve(context),
            "₿ $feeBtc",
          ),
          const ReceiveFlowDivider(),
          _buildDetailRow(
              context,
              AppCopy.withdrawReceiptStatus.resolve(context),
              AppCopy.withdrawReceiptConfirmed.resolve(context),
              color: receiveFlowTextColor),
          const ReceiveFlowDivider(),
          _buildDetailRow(
            context,
            AppCopy.withdrawReceiptTransactionId.resolve(context),
            txId,
            isAddress: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isAddress = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: receiveFlowFaintTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontFamily: 'JetBrainsMono',
                      color: color ?? receiveFlowTextColor,
                      fontSize: isAddress ? 12 : 14,
                      fontWeight:
                          color != null ? FontWeight.w700 : FontWeight.w500,
                    ),
                maxLines: isAddress ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAddress)
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  HapticFeedback.mediumImpact();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: receiveFlowMutedTextColor,
              ),
          ],
        ),
      ],
    );
  }
}

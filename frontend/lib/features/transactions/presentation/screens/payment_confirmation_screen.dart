import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

typedef PaymentConfirmationAction<T> = Future<T?> Function(
  BuildContext context,
  String? totpCode,
);

class PaymentConfirmationDetail {
  final String label;
  final String value;
  final IconData icon;
  final bool monospace;
  final bool emphasized;
  final Color? valueColor;
  final bool copyable;
  final String? copyValue;
  final String? copyMessage;

  const PaymentConfirmationDetail({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
    this.emphasized = false,
    this.valueColor,
    this.copyable = false,
    this.copyValue,
    this.copyMessage,
  });
}

class PaymentConfirmationScreen<T> extends StatefulWidget {
  final String title;
  final String eyebrow;
  final String amountPrimary;
  final String amountSecondary;
  final String sourceLabel;
  final String sourceValue;
  final String destinationLabel;
  final String destinationValue;
  final String? destinationSubtitle;
  final String networkLabel;
  final String notice;
  final String securityMessage;
  final String confirmText;
  final String cancelText;
  final List<PaymentConfirmationDetail> details;
  final bool requiresTotp;
  final String totpTitle;
  final String totpHint;
  final PaymentConfirmationAction<T> onConfirm;

  const PaymentConfirmationScreen({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.amountPrimary,
    required this.amountSecondary,
    required this.sourceLabel,
    required this.sourceValue,
    required this.destinationLabel,
    required this.destinationValue,
    this.destinationSubtitle,
    required this.networkLabel,
    required this.notice,
    required this.securityMessage,
    required this.confirmText,
    required this.cancelText,
    required this.details,
    required this.onConfirm,
    this.requiresTotp = false,
    this.totpTitle = 'Código do autenticador',
    this.totpHint = 'Digite os 6 dígitos do app autenticador.',
  });

  @override
  State<PaymentConfirmationScreen<T>> createState() =>
      _PaymentConfirmationScreenState<T>();
}

class _PaymentConfirmationScreenState<T>
    extends State<PaymentConfirmationScreen<T>> {
  final _totpController = TextEditingController();
  bool _isSubmitting = false;
  bool _totpError = false;
  int _totpErrorPulseKey = 0;

  @override
  void dispose() {
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;

    final totp = _totpController.text.trim();
    if (widget.requiresTotp && totp.length != 6) {
      setState(() {
        _totpError = true;
        _totpErrorPulseKey++;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _totpError = false;
    });

    try {
      final result = await widget.onConfirm(
        context,
        widget.requiresTotp ? totp : null,
      );
      if (!mounted) return;
      if (result != null) {
        Navigator.of(context).pop(result);
        return;
      }
    } catch (error) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Não foi possível confirmar',
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: widget.title,
      subtitle: 'Revise os dados e confirme com os fatores de segurança.',
      onBack: _isSubmitting ? () {} : () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AmountHero(
              eyebrow: widget.eyebrow,
              amountPrimary: widget.amountPrimary,
              amountSecondary: widget.amountSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReceiptCard(
              sourceLabel: widget.sourceLabel,
              sourceValue: widget.sourceValue,
              destinationLabel: widget.destinationLabel,
              destinationValue: widget.destinationValue,
              destinationSubtitle: widget.destinationSubtitle,
              networkLabel: widget.networkLabel,
              details: widget.details,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SecurityCard(
              message: widget.securityMessage,
              requiresTotp: widget.requiresTotp,
              totpTitle: widget.totpTitle,
              totpHint: widget.totpHint,
              totpController: _totpController,
              isSubmitting: _isSubmitting,
              totpError: _totpError,
              totpErrorPulseKey: _totpErrorPulseKey,
              onTotpChanged: (_) {
                if (_totpError) {
                  setState(() => _totpError = false);
                }
              },
            ),
            if (widget.notice.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _NoticeCard(text: widget.notice),
            ],
            const SizedBox(height: AppSpacing.xl),
            ReceiveFlowPrimaryButton(
              label: widget.confirmText,
              icon: LucideIcons.shieldCheck,
              isLoading: _isSubmitting,
              onTap: _confirm,
            ),
            const SizedBox(height: AppSpacing.md),
            ReceiveFlowSecondaryButton(
              label: widget.cancelText,
              icon: LucideIcons.x,
              onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountHero extends StatelessWidget {
  final String eyebrow;
  final String amountPrimary;
  final String amountSecondary;

  const _AmountHero({
    required this.eyebrow,
    required this.amountPrimary,
    required this.amountSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        children: [
          ReceiveFlowTag(
            label: eyebrow.toUpperCase(),
            icon: LucideIcons.shieldCheck,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            amountPrimary,
            textAlign: TextAlign.center,
            style: AppTypography.number.copyWith(
              color: receiveFlowTextColor,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountSecondary,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontFamily: 'JetBrainsMono',
                ),
          ),
        ],
      ),
    );
  }
}

class _FlowEndpointRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _FlowEndpointRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: receiveFlowPanelRaisedColor,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: receiveFlowBorderStrongColor),
          ),
          child: Icon(icon, color: receiveFlowTextColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReceiveFlowSectionLabel(label),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: receiveFlowTextColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrainsMono',
                      height: 1.25,
                    ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.3,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String sourceLabel;
  final String sourceValue;
  final String destinationLabel;
  final String destinationValue;
  final String? destinationSubtitle;
  final String networkLabel;
  final List<PaymentConfirmationDetail> details;

  const _ReceiptCard({
    required this.sourceLabel,
    required this.sourceValue,
    required this.destinationLabel,
    required this.destinationValue,
    this.destinationSubtitle,
    required this.networkLabel,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FlowEndpointRow(
            icon: LucideIcons.arrowUpRight,
            label: destinationLabel,
            value: destinationValue,
            subtitle: destinationSubtitle,
          ),
          const ReceiveFlowDivider(),
          _FlowEndpointRow(
            icon: LucideIcons.wallet,
            label: sourceLabel,
            value: sourceValue,
          ),
          const ReceiveFlowDivider(),
          _ReceiptDetailRow(
            detail: PaymentConfirmationDetail(
              label: 'Data e Hora',
              value: dateStr,
              icon: LucideIcons.calendarClock,
            ),
          ),
          _ReceiptDetailRow(
            detail: PaymentConfirmationDetail(
              label: 'Rede',
              value: networkLabel,
              icon: LucideIcons.network,
            ),
          ),
          ...details.map((d) => _ReceiptDetailRow(detail: d)),
        ],
      ),
    );
  }
}

class _ReceiptDetailRow extends StatelessWidget {
  final PaymentConfirmationDetail detail;

  const _ReceiptDetailRow({required this.detail});

  Future<void> _copy(BuildContext context) async {
    final value = detail.copyValue ?? detail.value;
    if (value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    if (!context.mounted) return;

    AppNotice.showSuccess(
      context,
      message: detail.copyMessage ?? '${detail.label} copiado.',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueColor = detail.valueColor ?? receiveFlowTextColor;
    final valueStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: valueColor,
          fontWeight: detail.emphasized ? FontWeight.w700 : FontWeight.w500,
          fontFamily: detail.monospace ? 'JetBrainsMono' : null,
          letterSpacing: 0,
          height: 1.35,
        );

    if (detail.copyable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  detail.icon,
                  size: 16,
                  color: receiveFlowFaintTextColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    detail.label,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: receiveFlowMutedTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: receiveFlowMutedTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _copy(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: receiveFlowPanelAltColor,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: receiveFlowBorderStrongColor),
                ),
                child: SelectableText(
                  detail.value,
                  style: valueStyle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            detail.icon,
            size: 16,
            color: receiveFlowFaintTextColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              detail.label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: receiveFlowMutedTextColor,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              detail.value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final String message;
  final bool requiresTotp;
  final String totpTitle;
  final String totpHint;
  final TextEditingController totpController;
  final bool isSubmitting;
  final bool totpError;
  final int totpErrorPulseKey;
  final ValueChanged<String> onTotpChanged;

  const _SecurityCard({
    required this.message,
    required this.requiresTotp,
    required this.totpTitle,
    required this.totpHint,
    required this.totpController,
    required this.isSubmitting,
    required this.totpError,
    required this.totpErrorPulseKey,
    required this.onTotpChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldAlert,
                  color: receiveFlowMutedTextColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          if (requiresTotp) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              totpTitle,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: receiveFlowFaintTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TotpInputContainer(
              controller: totpController,
              onChanged: onTotpChanged,
              onCompleted: (_) {},
              hasError: totpError,
              errorPulseKey: totpErrorPulseKey,
              enabled: !isSubmitting,
              accentColor: receiveFlowTextColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              totpHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String text;

  const _NoticeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: receiveFlowPanelAltColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: receiveFlowMutedTextColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

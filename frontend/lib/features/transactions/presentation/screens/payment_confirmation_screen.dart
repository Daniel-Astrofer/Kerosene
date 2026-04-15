import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';

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
    return CyberBackground(
      useScroll: true,
      resizeToAvoidBottomInset: true,
      showAmbientEffects: false,
      simpleGradient: true,
      backgroundColor: const Color(0xFF07111D),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: widget.title,
              onBack: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _AmountHero(
              eyebrow: widget.eyebrow,
              amountPrimary: widget.amountPrimary,
              amountSecondary: widget.amountSecondary,
            ),
            const SizedBox(height: AppSpacing.xxl),
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
            BouncingButton(
              text: widget.confirmText,
              icon: LucideIcons.shieldCheck,
              isLoading: _isSubmitting,
              onPressed: _confirm,
            ),
            const SizedBox(height: AppSpacing.md),
            BouncingButton(
              text: widget.cancelText,
              variant: BouncingButtonVariant.outlined,
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _Header({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(
            LucideIcons.chevronLeft,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        const Spacer(),
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.6,
              ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.send,
                  size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          amountPrimary,
          textAlign: TextAlign.center,
          style: AppTypography.number.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          amountSecondary,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontFamily: 'JetBrainsMono',
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Destination Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.arrowUpRight,
                    color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destinationLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(destinationValue,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                fontWeight: FontWeight.w800,
                                fontFamily: 'JetBrainsMono')),
                    if (destinationSubtitle != null &&
                        destinationSubtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(destinationSubtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                  color: Colors.white.withValues(alpha: 0.5))),
                    ]
                  ],
                ),
              )
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                    width: 44,
                    alignment: Alignment.center,
                    child: Container(
                        width: 2,
                        height: 24,
                        color: Colors.white.withValues(alpha: 0.1))),
                Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
          ),

          // Source Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.wallet,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sourceLabel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(sourceValue,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: AppSpacing.xl),

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(detail.copyMessage ?? '${detail.label} copiado.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueColor = detail.valueColor ??
        (detail.emphasized
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onPrimary);
    final valueStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: valueColor,
          fontWeight: detail.emphasized ? FontWeight.w900 : FontWeight.w700,
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
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    detail.label,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
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
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
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
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              detail.label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldAlert,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
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
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
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
              accentColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              totpHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: Colors.white.withValues(alpha: 0.62),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

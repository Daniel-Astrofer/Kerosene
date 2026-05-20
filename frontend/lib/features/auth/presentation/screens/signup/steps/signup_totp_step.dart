import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';

class SignupTotpStep extends ConsumerStatefulWidget {
  final String username;
  final String passphrase;
  final String totpSecret;
  final String qrCodeUri;
  final List<String> backupCodes;
  final VoidCallback onVerified;

  const SignupTotpStep({
    super.key,
    required this.username,
    required this.passphrase,
    required this.totpSecret,
    required this.qrCodeUri,
    this.backupCodes = const [],
    required this.onVerified,
  });

  @override
  ConsumerState<SignupTotpStep> createState() => _SignupTotpStepState();
}

class _SignupTotpStepState extends ConsumerState<SignupTotpStep> {
  String _currentCode = '';
  late bool _backupConfirmed;

  @override
  void initState() {
    super.initState();
    _backupConfirmed = widget.backupCodes.isEmpty;
  }

  @override
  void didUpdateWidget(covariant SignupTotpStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backupCodes != widget.backupCodes) {
      _backupConfirmed = widget.backupCodes.isEmpty;
    }
  }

  void _handleVerify(String code) {
    ref.read(authControllerProvider.notifier).verifyTotp(
          username: widget.username,
          passphrase: widget.passphrase,
          totpSecret: widget.totpSecret,
          totpCode: code,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final canSubmit = _currentCode.length == 6 && _backupConfirmed;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthTotpVerified) {
        widget.onVerified();
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.tr, next.toString()),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            if (_currentCode.length == 6) {
              _handleVerify(_currentCode);
            }
          },
        );
      }
    });

    return SignupStepLayout(
      eyebrow: AppCopy.signupTotpEyebrow.resolve(context),
      title: AppCopy.signupTotpTitle.resolve(context),
      subtitle: AppCopy.signupTotpSubtitle.resolve(context),
      icon: LucideIcons.shieldCheck,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupTotpHighlightLabel.resolve(context),
      highlightValue: canSubmit
          ? AppCopy.signupTotpHighlightReady.resolve(context)
          : AppCopy.signupTotpHighlightPending.resolve(context),
      highlightHint: AppCopy.signupTotpHighlightHint.resolve(context),
      chips: [
        AppCopy.signupTotpChipQr.resolve(context),
        AppCopy.signupTotpChipBackup.resolve(context),
        AppCopy.signupTotpChipCode.resolve(context),
      ],
      footer: SignupPrimaryFooter(
        text: context.tr.totpVerifyButton,
        isLoading: isLoading,
        onPressed: canSubmit ? () => _handleVerify(_currentCode) : null,
        icon: LucideIcons.badgeCheck,
      ),
      children: [
        _buildSection(
          context: context,
          step: '1',
          title: AppCopy.signupTotpStepScan.resolve(context),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrCodeUri,
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSection(
          context: context,
          step: '2',
          title: AppCopy.signupTotpStepStore.resolve(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.signupTotpSecretLabel.resolve(context),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.totpSecret,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.backupCodes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppCopy.signupTotpBackupCodesLabel.resolve(context),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.backupCodes
                        .map(
                          (code) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _backupConfirmed,
                        onChanged: (value) {
                          setState(() => _backupConfirmed = value ?? false);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            AppCopy.signupTotpBackupConfirm.resolve(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.backupCodes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildSection(
          context: context,
          step: '3',
          title: AppCopy.signupTotpStepEnter.resolve(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.totpEnter6Digits.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TotpInputContainer(
                onChanged: (code) {
                  setState(() => _currentCode = code);
                },
                onCompleted: (code) {
                  setState(() => _currentCode = code);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String step,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

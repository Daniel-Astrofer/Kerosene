import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';

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

  void _copySecret() {
    Clipboard.setData(ClipboardData(text: widget.totpSecret));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.totpSecretCopied),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
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

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthTotpVerified) {
        widget.onVerified();
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            if (_currentCode.length == 6) {
              _handleVerify(_currentCode);
            }
          },
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.totpSetupTitle,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 28,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.totpSetupSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
                  const SizedBox(height: AppSpacing.xl),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTP SECRET',
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
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
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
                            GestureDetector(
                              onTap: _copySecret,
                              child: Icon(
                                LucideIcons.copy,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.backupCodes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'BACKUP CODES (SAVE THESE NOW)',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.backupCodes
                            .map(
                              (code) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
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
                  ],
                  
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    context.l10n.totpEnter6Digits.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TotpInputContainer(
                    onCompleted: (code) {
                      setState(() => _currentCode = code);
                      _handleVerify(code);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          BouncingButton(
            text: context.l10n.totpVerifyButton,
            isLoading: isLoading,
            onPressed: _currentCode.length == 6 ? () => _handleVerify(_currentCode) : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

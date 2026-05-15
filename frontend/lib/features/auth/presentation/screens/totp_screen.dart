import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import '../widgets/totp_input_container.dart';
import '../../controller/auth_controller.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';

/// Unified TOTP Screen for both Setup (Signup) and Challenge (Login) flows.
/// Role: AI-Native Reactive UI for Two-Factor Authentication.
class TotpScreen extends ConsumerStatefulWidget {
  final String username;
  final String passphrase;
  final bool isSetup;
  final String? totpSecret;
  final String? qrCodeUri;
  final String? preAuthToken;

  const TotpScreen({
    super.key,
    required this.username,
    required this.passphrase,
    required this.isSetup,
    this.totpSecret,
    this.qrCodeUri,
    this.preAuthToken,
  });

  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  String _currentCode = '';

  void _copySecret() {
    if (widget.totpSecret != null) {
      Clipboard.setData(ClipboardData(text: widget.totpSecret!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.totpSecretCopied),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleVerify(String code) {
    if (widget.isSetup) {
      ref.read(authControllerProvider.notifier).verifyTotp(
            username: widget.username,
            passphrase: widget.passphrase,
            totpSecret: widget.totpSecret ?? '',
            totpCode: code,
          );
    } else {
      ref.read(authControllerProvider.notifier).verifyLoginTotp(
            username: widget.username,
            passphrase: widget.passphrase,
            totpCode: code,
            preAuthToken: widget.preAuthToken,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
      } else if (next is AuthTotpVerified) {
        // After TOTP is verified, go to Onboarding Payment if it's signup
        Navigator.of(context).pushReplacementNamed(
          '/onboarding_payment',
          arguments: {
            'sessionId': next.sessionId,
            'username': widget.username,
            'password': widget.passphrase,
          },
        );
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

    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    left: AppSpacing.sm,
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Heading
                      Text(
                        widget.isSetup
                            ? context.l10n.totpSetupTitle
                            : context.l10n.totpTitle,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontSize: 28,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.isSetup
                            ? context.l10n.totpSetupSubtitle
                            : context.l10n.totpSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      if (widget.isSetup) ...[
                        // QR Code Section
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.md),
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
                            child: widget.qrCodeUri != null
                                ? QrImageView(
                                    data: widget.qrCodeUri!,
                                    version: QrVersions.auto,
                                    size: 180.0,
                                  )
                                : Icon(
                                    LucideIcons.qrCode,
                                    size: 120,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Secret Key
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTP SECRET',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.md),
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
                                      widget.totpSecret ??
                                          '•••• •••• •••• ••••',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
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
                        const SizedBox(height: AppSpacing.xxl),
                      ] else ...[
                        // Login Mode Visual
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Icon(
                            LucideIcons.shieldCheck,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                      ],

                      // 6-Digit input
                      Text(
                        context.l10n.totpEnter6Digits.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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

                      const SizedBox(height: 120),

                      // Submit Button (Manual fallback)
                      BouncingButton(
                        text: widget.isSetup
                            ? context.l10n.totpVerifyButton
                            : context.l10n.totpVerifyContinue,
                        isLoading: isLoading,
                        onPressed: _currentCode.length == 6
                            ? () => _handleVerify(_currentCode)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupHardwareStep extends ConsumerWidget {
  final String sessionId;
  final VoidCallback onVerified;

  const SignupHardwareStep({
    super.key,
    required this.sessionId,
    required this.onVerified,
  });

  void _handleRegister(WidgetRef ref) {
    ref.read(authControllerProvider.notifier).registerPasskeyOnboarding(sessionId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthHardwareVerified) {
        onVerified();
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            _handleRegister(ref);
          },
        );
      }
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'SEGURANÇA BIOMÉTRICA',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Para sua proteção, vinculamos sua conta ao hardware deste dispositivo. Isso impede acessos não autorizados mesmo se sua semente for exposta.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      Icon(
                        LucideIcons.fingerprint,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                const SizedBox(height: AppSpacing.xxl),
                
                BouncingButton(
                  text: 'REGISTRAR DISPOSITIVO',
                  isLoading: isLoading,
                  onPressed: () => _handleRegister(ref),
                ),
                
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Proteção Nível Bancário ATIVA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

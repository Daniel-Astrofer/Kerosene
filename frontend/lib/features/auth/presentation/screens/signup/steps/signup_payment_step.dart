import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

/// Signup Step 5: Finalization / Payment
class SignupPaymentStep extends ConsumerWidget {
  final String username;
  final String mnemonic;

  const SignupPaymentStep({
    super.key,
    required this.username,
    required this.mnemonic,
  });

  void _createWallet(WidgetRef ref) {
    final flowState = ref.read(signupFlowProvider);
    ref.read(authControllerProvider.notifier).signup(
          username: username,
          password: mnemonic,
          accountSecurity: _mapAccountSecurity(flowState.seedSecurityOption),
        );
  }

  String _mapAccountSecurity(SeedSecurityOption option) {
    switch (option) {
      case SeedSecurityOption.slip39:
        return 'SHAMIR';
      case SeedSecurityOption.multisig2fa:
        return 'MULTISIG_2FA';
      case SeedSecurityOption.standard:
        return 'STANDARD';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onGoBack: () =>
              ref.read(authControllerProvider.notifier).clearError(),
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
                  'Ativação da Carteira',
                  style: Theme.of(context).textTheme.displayLarge!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A rede Kerosene exige uma pequena taxa de depósito inicial para validar sua conta no Vault de forma descentralizada.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.hammer,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'PRONTO PARA FORJAR',
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sua identidade criptográfica foi gerada. Clique abaixo para registrar sua conta e abrir seu canal na rede.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (authState is AuthLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  BouncingButton(
                    text: 'FORJAR CARTEIRA',
                    onPressed: () => _createWallet(ref),
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

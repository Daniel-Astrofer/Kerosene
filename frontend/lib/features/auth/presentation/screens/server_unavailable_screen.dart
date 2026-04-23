import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';

class ServerUnavailableScreen extends ConsumerWidget {
  final String message;
  final String? retryRouteName;

  const ServerUnavailableScreen({
    super.key,
    this.message =
        'Não foi possível alcançar o servidor ou estabelecer conexão com a internet no momento.',
    this.retryRouteName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated glowing icon container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.serverCrash,
                    size: 80,
                    color: AppColors.error,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Text(
                  'CONEXÃO INDISPONÍVEL',
                  style: AppTypography.h1.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  message,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                BouncingButton(
                  text: 'TENTAR NOVAMENTE',
                  icon: LucideIcons.refreshCw,
                  isLoading: retryRouteName == null && isLoading,
                  onPressed: () {
                    if (retryRouteName != null) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        retryRouteName!,
                        (_) => false,
                      );
                      return;
                    }

                    ref
                        .read(authControllerProvider.notifier)
                        .retrySessionCheck();
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                TextButton(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  child: Text(
                    'SAIR DA SESSÃO',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

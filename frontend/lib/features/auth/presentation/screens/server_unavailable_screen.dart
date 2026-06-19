import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';

class ServerAvailabilityGate extends ConsumerStatefulWidget {
  final Widget child;

  const ServerAvailabilityGate({super.key, required this.child});

  @override
  ConsumerState<ServerAvailabilityGate> createState() =>
      _ServerAvailabilityGateState();
}

class _ServerAvailabilityGateState
    extends ConsumerState<ServerAvailabilityGate> {
  bool _showingUnavailableScreen = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider);
    final authState = ref.watch(authControllerProvider);
    final isUnavailable = !isOnline || authState is AuthServerUnavailable;
    final isRetryingUnavailable =
        _showingUnavailableScreen && authState is AuthLoading;

    if (isUnavailable || isRetryingUnavailable) {
      _showingUnavailableScreen = true;
      return const ServerUnavailableScreen();
    }

    _showingUnavailableScreen = false;
    return widget.child;
  }
}

class ServerUnavailableScreen extends ConsumerWidget {
  final String message;
  final String? retryRouteName;
  final Future<void> Function()? onRetryOverride;

  const ServerUnavailableScreen({
    super.key,
    this.message = 'Servidor em manutenção',
    this.retryRouteName,
    this.onRetryOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    const title = 'Conexão indisponível';

    return Scaffold(
      backgroundColor: AppColors.hexFF000000,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    KeroseneIcons.serverUnavailable,
                    size: 76,
                    color: AppColors.hexFFFFFFFF,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    title,
                    style: AppTypography.newsreader(
                      color: AppColors.hexFFFFFFFF,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.hexFFA1A1AA,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.hexFFFFFFFF,
                        foregroundColor: AppColors.hexFF000000,
                        disabledBackgroundColor: AppColors.hexFFE4E4E7,
                        disabledForegroundColor: AppColors.hexFF52525B,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                      onPressed: isLoading ? null : () => _retry(context, ref),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.hexFF000000,
                              ),
                            )
                          : Text(context.tr.tryAgain),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    if (onRetryOverride != null) {
      await onRetryOverride!();
      return;
    }

    if (retryRouteName != null) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(retryRouteName!, (_) => false);
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState is AuthServerUnavailable ||
        authState is AuthAuthenticated ||
        authState is AuthLoading) {
      await ref.read(authControllerProvider.notifier).retrySessionCheck();
      return;
    }

    await ref.read(networkStatusProvider.notifier).checkConnection();
  }
}

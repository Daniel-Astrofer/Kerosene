import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_status_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bouncing_button.dart';
import '../../l10n/l10n_extension.dart';

class OfflineOverlay extends ConsumerWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          child,
          if (!isOnline)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: const BoxDecoration(gradient: AppColors.bgGradient),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(networkStatusProvider.notifier)
                                .checkConnection();
                          },
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          displacement: 28,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: AppSpacing.xxl),
                                    Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error.withValues(
                                          alpha: 0.12,
                                        ),
                                        border: Border.all(
                                          color: AppColors.error.withValues(
                                            alpha: 0.28,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.error.withValues(
                                              alpha: 0.16,
                                            ),
                                            blurRadius: 36,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.wifi_off_rounded,
                                        size: 52,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Text(
                                      context.l10n.errNoInternet,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.h2.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      context.l10n.waitingConnection,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xl,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withValues(
                                          alpha: 0.94,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: AppColors.white10,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 32,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            context.l10n.offlineRetryHint,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: AppColors.white70,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          BouncingButton(
                                            text: context.l10n.tryAgain,
                                            icon: Icons.refresh_rounded,
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    networkStatusProvider
                                                        .notifier,
                                                  )
                                                  .checkConnection();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

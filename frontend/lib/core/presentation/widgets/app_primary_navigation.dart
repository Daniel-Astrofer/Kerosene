import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/core/theme/app_colors.dart';

enum AppPrimaryDestination { home, history, mining, settings }

extension AppPrimaryDestinationX on AppPrimaryDestination {
  String get routeName {
    switch (this) {
      case AppPrimaryDestination.home:
        return '/home';
      case AppPrimaryDestination.history:
        return '/history';
      case AppPrimaryDestination.mining:
        return '/mining';
      case AppPrimaryDestination.settings:
        return '/settings';
    }
  }

  String get label {
    switch (this) {
      case AppPrimaryDestination.home:
        return 'Início';
      case AppPrimaryDestination.history:
        return 'Histórico';
      case AppPrimaryDestination.mining:
        return 'Minerar';
      case AppPrimaryDestination.settings:
        return 'Ajustes';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPrimaryDestination.home:
        return Icons.home_rounded;
      case AppPrimaryDestination.history:
        return Icons.receipt_long_rounded;
      case AppPrimaryDestination.mining:
        return Icons.bolt_rounded;
      case AppPrimaryDestination.settings:
        return Icons.settings_rounded;
    }
  }
}

class AppPrimaryNavigationBar extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const AppPrimaryNavigationBar({
    super.key,
    required this.currentDestination,
  });

  static void navigateTo(
    BuildContext context,
    AppPrimaryDestination destination,
  ) {
    HapticFeedback.selectionClick();

    if (ModalRoute.of(context)?.settings.name == destination.routeName) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(destination.routeName, (route) => false);
  }

  static void backOrHome(BuildContext context) {
    HapticFeedback.selectionClick();

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      AppPrimaryDestination.home.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF07111A).withValues(alpha: 0.96),
                      const Color(0xFF0A1724).withValues(alpha: 0.92),
                      const Color(0xFF05080C).withValues(alpha: 0.98),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      for (final destination in AppPrimaryDestination.values)
                        Expanded(
                          child: _PrimaryNavigationItem(
                            destination: destination,
                            selected: destination == currentDestination,
                            onTap: () {
                              if (destination == currentDestination) {
                                HapticFeedback.selectionClick();
                                return;
                              }
                              navigateTo(context, destination);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavigationItem extends StatelessWidget {
  final AppPrimaryDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _PrimaryNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.34)
                    : Colors.transparent,
              ),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.28),
                        AppColors.secondary.withValues(alpha: 0.18),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  destination.icon,
                  size: 22,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.70),
                ),
                const SizedBox(height: 6),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.68),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

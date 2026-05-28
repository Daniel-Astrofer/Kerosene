import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/l10n/l10n_extension.dart';

enum AppPrimaryDestination { home, card, history, mining, settings }

extension AppPrimaryDestinationX on AppPrimaryDestination {
  String get routeName {
    switch (this) {
      case AppPrimaryDestination.home:
        return '/home';
      case AppPrimaryDestination.card:
        return '/card';
      case AppPrimaryDestination.history:
        return '/history';
      case AppPrimaryDestination.mining:
        return '/mining';
      case AppPrimaryDestination.settings:
        return '/settings';
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case AppPrimaryDestination.home:
        return context.tr.primaryNavHome;
      case AppPrimaryDestination.card:
        return context.tr.primaryNavCard;
      case AppPrimaryDestination.history:
        return context.tr.primaryNavHistory;
      case AppPrimaryDestination.mining:
        return context.tr.primaryNavMining;
      case AppPrimaryDestination.settings:
        return context.tr.primaryNavSettings;
    }
  }

  IconData get icon {
    switch (this) {
      case AppPrimaryDestination.home:
        return LucideIcons.home;
      case AppPrimaryDestination.card:
        return LucideIcons.walletCards;
      case AppPrimaryDestination.history:
        return LucideIcons.receipt;
      case AppPrimaryDestination.mining:
        return LucideIcons.zap;
      case AppPrimaryDestination.settings:
        return LucideIcons.settings;
    }
  }
}

class AppPrimaryNavigationBar {
  static const double _buttonSize = 56;
  static const double _buttonRightSpacing = AppSpacing.xl2;
  static const double _buttonBottomSpacing = 32;
  static const double _contentBuffer = AppSpacing.xl2;
  static const double _gestureIndicatorWidth = 128;
  static const double _gestureIndicatorHeight = 4;

  const AppPrimaryNavigationBar._();

  static void navigateTo(
    BuildContext context,
    AppPrimaryDestination destination,
  ) {
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

  static double scaffoldBottomClearance(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom +
        _buttonSize +
        _buttonBottomSpacing +
        _contentBuffer;
  }

  static Widget overlay({
    Key? key,
    required AppPrimaryDestination currentDestination,
  }) {
    return _AppPrimaryCircularNavigationOverlay(
      key: key,
      currentDestination: currentDestination,
    );
  }
}

class _AppPrimaryCircularNavigationOverlay extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const _AppPrimaryCircularNavigationOverlay({
    super.key,
    required this.currentDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              0,
              0,
              AppPrimaryNavigationBar._buttonRightSpacing,
              AppPrimaryNavigationBar._buttonBottomSpacing,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: _AppPrimaryFloatingMenuButton(
                currentDestination: currentDestination,
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: AppPrimaryNavigationBar._gestureIndicatorWidth,
                height: AppPrimaryNavigationBar._gestureIndicatorHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppPrimaryFloatingMenuButton extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const _AppPrimaryFloatingMenuButton({required this.currentDestination});

  @override
  Widget build(BuildContext context) {
    final tooltip = MaterialLocalizations.of(context).showMenuTooltip;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              _showMenu(context);
            },
            child: Container(
              width: AppPrimaryNavigationBar._buttonSize,
              height: AppPrimaryNavigationBar._buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.menu,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _AppPrimaryMenuPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final destination in AppPrimaryDestination.values)
                    _AppPrimaryMenuDestinationTile(
                      destination: destination,
                      selected: destination == currentDestination,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppPrimaryMenuPanel extends StatelessWidget {
  final Widget child;

  const _AppPrimaryMenuPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: child,
      ),
    );
  }
}

class _AppPrimaryMenuDestinationTile extends StatelessWidget {
  final AppPrimaryDestination destination;
  final bool selected;

  const _AppPrimaryMenuDestinationTile({
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final label = destination.label(context);
    final color = selected ? AppColors.primary : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                AppPrimaryNavigationBar.navigateTo(context, destination);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(destination.icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.check,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

enum AppPrimaryDestination { home, card, history, settings }

extension AppPrimaryDestinationX on AppPrimaryDestination {
  String get routeName {
    switch (this) {
      case AppPrimaryDestination.home:
        return '/home';
      case AppPrimaryDestination.card:
        return '/accounts';
      case AppPrimaryDestination.history:
        return '/activity';
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
      case AppPrimaryDestination.settings:
        return context.tr.primaryNavSettings;
    }
  }

  String supportingLabel(BuildContext context) {
    switch (this) {
      case AppPrimaryDestination.home:
        return 'Visao geral da conta';
      case AppPrimaryDestination.card:
        return 'Carteiras e cartoes';
      case AppPrimaryDestination.history:
        return 'Extrato e comprovantes';
      case AppPrimaryDestination.settings:
        return 'Preferencias do app';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPrimaryDestination.home:
        return KeroseneIcons.home;
      case AppPrimaryDestination.card:
        return KeroseneIcons.wallet;
      case AppPrimaryDestination.history:
        return KeroseneIcons.history;
      case AppPrimaryDestination.settings:
        return KeroseneIcons.settings;
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
    final navigator = Navigator.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final targetRouteName = destination.routeName;

    if (currentRouteName == targetRouteName) {
      return;
    }

    HapticFeedback.selectionClick();

    if (destination == AppPrimaryDestination.home) {
      _returnToHome(navigator);
      return;
    }

    if (currentRouteName == AppPrimaryDestination.home.routeName ||
        currentRouteName == '/home_loading') {
      navigator.pushNamed(targetRouteName);
      return;
    }

    if (_isPrimaryRouteName(currentRouteName)) {
      navigator.pushReplacementNamed(targetRouteName);
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      targetRouteName,
      (route) => route.settings.name == AppPrimaryDestination.home.routeName,
    );
  }

  static void backOrHome(BuildContext context) {
    HapticFeedback.selectionClick();

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
      return;
    }

    navigator.pushReplacementNamed(AppPrimaryDestination.home.routeName);
  }

  static bool _isPrimaryRouteName(String? routeName) {
    return AppPrimaryDestination.values.any(
      (destination) => destination.routeName == routeName,
    );
  }

  static void _returnToHome(NavigatorState navigator) {
    var foundHome = false;
    if (navigator.canPop()) {
      navigator.popUntil((route) {
        foundHome = route.settings.name == AppPrimaryDestination.home.routeName;
        return foundHome || route.isFirst;
      });
    }

    if (!foundHome) {
      navigator.pushNamedAndRemoveUntil(
        AppPrimaryDestination.home.routeName,
        (route) => false,
      );
    }
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
                  color: KeroseneBrandTokens.textPrimary,
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

class _AppPrimaryFloatingMenuButton extends StatefulWidget {
  final AppPrimaryDestination currentDestination;

  const _AppPrimaryFloatingMenuButton({required this.currentDestination});

  @override
  State<_AppPrimaryFloatingMenuButton> createState() =>
      _AppPrimaryFloatingMenuButtonState();
}

class _AppPrimaryFloatingMenuButtonState
    extends State<_AppPrimaryFloatingMenuButton> with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _menuController;
  late final Animation<double> _scaleAnimation;
  OverlayEntry? _menuEntry;
  bool _menuOpen = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.fast,
    );
    _menuController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.long,
      reverseDuration: KeroseneMotion.short,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: KeroseneMotion.standard),
    );
  }

  @override
  void didUpdateWidget(covariant _AppPrimaryFloatingMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDestination != widget.currentDestination &&
        _menuOpen) {
      _closeMenu();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _pressController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = _menuOpen
        ? MaterialLocalizations.of(context).closeButtonTooltip
        : widget.currentDestination.label(context);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: _menuOpen,
        label: tooltip,
        child: GestureDetector(
          onTapDown: (_) => _pressController.forward(),
          onTapUp: (_) {
            _pressController.reverse();
            HapticFeedback.selectionClick();
            _toggleMenu();
          },
          onTapCancel: () => _pressController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: KeroseneMotion.duration(context, KeroseneMotion.short),
              curve: KeroseneMotion.standard,
              width: AppPrimaryNavigationBar._buttonSize,
              height: AppPrimaryNavigationBar._buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _menuOpen
                      ? const [
                          KeroseneBrandTokens.textPrimary,
                          AppColors.hexFFE2E2DC,
                        ]
                      : const [
                          AppColors.surface,
                          KeroseneBrandTokens.backgroundSoft,
                        ],
                ),
                border: Border.all(
                  color: _menuOpen
                      ? AppColors.white.withValues(alpha: 0.34)
                      : AppColors.white.withValues(alpha: 0.13),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.48),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: AppColors.white.withValues(alpha: 0.08),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration:
                    KeroseneMotion.duration(context, KeroseneMotion.short),
                switchInCurve: KeroseneMotion.entrance,
                switchOutCurve: KeroseneMotion.exit,
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns:
                        Tween<double>(begin: -0.06, end: 0).animate(animation),
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  _menuOpen
                      ? KeroseneIcons.close
                      : widget.currentDestination.icon,
                  key: ValueKey<String>(
                    _menuOpen
                        ? 'navigation-close'
                        : widget.currentDestination.name,
                  ),
                  color: _menuOpen
                      ? AppColors.background
                      : KeroseneBrandTokens.textPrimary,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleMenu() async {
    if (_menuOpen) {
      await _closeMenu();
      return;
    }

    _openMenu();
  }

  void _openMenu() {
    if (_menuEntry != null) return;

    _menuEntry = OverlayEntry(
      builder: (overlayContext) {
        return _AppPrimaryExpandingMenuOverlay(
          animation: _menuController,
          currentDestination: widget.currentDestination,
          onDismiss: _closeMenu,
          onDestinationSelected: (destination) async {
            if (destination != widget.currentDestination) {
              HapticFeedback.selectionClick();
            }

            await _closeMenu();
            if (!mounted || destination == widget.currentDestination) return;
            AppPrimaryNavigationBar.navigateTo(context, destination);
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_menuEntry!);
    setState(() => _menuOpen = true);
    _menuController.forward(from: 0);
  }

  Future<void> _closeMenu() async {
    if (_menuEntry == null || _closing) return;
    _closing = true;

    await _menuController.reverse();
    _removeOverlay();
    _closing = false;
    if (mounted) setState(() => _menuOpen = false);
  }

  void _removeOverlay() {
    _menuEntry?.remove();
    _menuEntry = null;
    if (_menuController.value != 0) {
      _menuController.value = 0;
    }
  }
}

class _AppPrimaryExpandingMenuOverlay extends StatelessWidget {
  final Animation<double> animation;
  final AppPrimaryDestination currentDestination;
  final Future<void> Function() onDismiss;
  final Future<void> Function(AppPrimaryDestination destination)
      onDestinationSelected;

  const _AppPrimaryExpandingMenuOverlay({
    required this.animation,
    required this.currentDestination,
    required this.onDismiss,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = (media.size.width - 32).clamp(252.0, 342.0).toDouble();
    final bottomInset = media.viewPadding.bottom +
        AppPrimaryNavigationBar._buttonBottomSpacing +
        AppPrimaryNavigationBar._buttonSize +
        AppSpacing.sm;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: KeroseneMotion.standard,
            ).value;
            final panelValue = CurvedAnimation(
              parent: animation,
              curve: KeroseneMotion.emphasized,
              reverseCurve: KeroseneMotion.exit,
            ).value;

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDismiss,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.18 * fade),
                    ),
                  ),
                ),
                Positioned(
                  right: AppPrimaryNavigationBar._buttonRightSpacing,
                  bottom: bottomInset,
                  width: width,
                  child: Transform.scale(
                    alignment: Alignment.bottomRight,
                    scale: 0.72 + (0.28 * panelValue),
                    child: Opacity(
                      opacity: fade,
                      child: _AppPrimaryMenuPanel(
                        animation: animation,
                        currentDestination: currentDestination,
                        onDestinationSelected: onDestinationSelected,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppPrimaryMenuPanel extends StatelessWidget {
  final Animation<double> animation;
  final AppPrimaryDestination currentDestination;
  final Future<void> Function(AppPrimaryDestination destination)
      onDestinationSelected;

  const _AppPrimaryMenuPanel({
    required this.animation,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KeroseneBrandTokens.backgroundSoft,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppPrimaryMenuHeader(
                icon: currentDestination.icon,
                title: currentDestination.label(context),
                subtitle: 'Navegacao principal',
              ),
              const SizedBox(height: 8),
              for (var index = 0;
                  index < AppPrimaryDestination.values.length;
                  index++)
                _AnimatedMenuEntry(
                  animation: animation,
                  index: index,
                  child: _AppPrimaryMenuDestinationTile(
                    destination: AppPrimaryDestination.values[index],
                    selected: AppPrimaryDestination.values[index] ==
                        currentDestination,
                    onTap: () => onDestinationSelected(
                      AppPrimaryDestination.values[index],
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

class _AppPrimaryMenuHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AppPrimaryMenuHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.white.withValues(alpha: 0.045),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.065),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              icon,
              color: KeroseneBrandTokens.textPrimary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KeroseneBrandTokens.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: KeroseneBrandTokens.textSecondary.withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMenuEntry extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _AnimatedMenuEntry({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.16 + index * 0.07).clamp(0.0, 0.72).toDouble();
    final entryAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(start, 1.0, curve: KeroseneMotion.entrance),
      reverseCurve: KeroseneMotion.exit,
    );

    return AnimatedBuilder(
      animation: entryAnimation,
      child: child,
      builder: (context, child) {
        final value = entryAnimation.value;
        return Transform.translate(
          offset: Offset(10 * (1 - value), 8 * (1 - value)),
          child: Transform.scale(
            alignment: Alignment.bottomRight,
            scale: 0.96 + (0.04 * value),
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
    );
  }
}

class _AppPrimaryMenuDestinationTile extends StatefulWidget {
  final AppPrimaryDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _AppPrimaryMenuDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_AppPrimaryMenuDestinationTile> createState() =>
      _AppPrimaryMenuDestinationTileState();
}

class _AppPrimaryMenuDestinationTileState
    extends State<_AppPrimaryMenuDestinationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.destination.label(context);
    final supporting = widget.destination.supportingLabel(context);
    final contentColor = widget.selected
        ? KeroseneBrandTokens.textPrimary
        : KeroseneBrandTokens.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
        curve: KeroseneMotion.standard,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.white.withValues(alpha: 0.06),
            highlightColor: AppColors.white.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: KeroseneMotion.duration(context, KeroseneMotion.short),
              curve: KeroseneMotion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: widget.selected
                    ? AppColors.white.withValues(alpha: 0.075)
                    : (_pressed
                        ? AppColors.white.withValues(alpha: 0.045)
                        : Colors.transparent),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration:
                        KeroseneMotion.duration(context, KeroseneMotion.short),
                    curve: KeroseneMotion.standard,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: widget.selected
                          ? AppColors.white.withValues(alpha: 0.12)
                          : AppColors.white.withValues(alpha: 0.055),
                      border: Border.all(
                        color: AppColors.white.withValues(
                          alpha: widget.selected ? 0.14 : 0.075,
                        ),
                      ),
                    ),
                    child: Icon(
                      widget.destination.icon,
                      color: contentColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 14.5,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          supporting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: KeroseneBrandTokens.textSecondary.withValues(
                              alpha: 0.66,
                            ),
                            fontSize: 11.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration:
                        KeroseneMotion.duration(context, KeroseneMotion.short),
                    child: widget.selected
                        ? const Icon(
                            KeroseneIcons.success,
                            key: ValueKey<String>('selected'),
                            color: KeroseneBrandTokens.textPrimary,
                            size: 17,
                          )
                        : Icon(
                            KeroseneIcons.chevronRight,
                            key: const ValueKey<String>('next'),
                            color: KeroseneBrandTokens.textSecondary.withValues(
                              alpha: 0.46,
                            ),
                            size: 16,
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
}

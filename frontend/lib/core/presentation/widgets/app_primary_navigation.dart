import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

enum AppPrimaryDestination { home, card, history, settings }

extension AppPrimaryDestinationX on AppPrimaryDestination {
  String get routeName {
    switch (this) {
      case AppPrimaryDestination.home:
        return '/home';
      case AppPrimaryDestination.card:
        return '/card';
      case AppPrimaryDestination.history:
        return '/history';
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

  IconData get icon {
    switch (this) {
      case AppPrimaryDestination.home:
        return LucideIcons.home;
      case AppPrimaryDestination.card:
        return LucideIcons.walletCards;
      case AppPrimaryDestination.history:
        return LucideIcons.receipt;
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

class _AppPrimaryFloatingMenuButton extends StatefulWidget {
  final AppPrimaryDestination currentDestination;

  const _AppPrimaryFloatingMenuButton({required this.currentDestination});

  @override
  State<_AppPrimaryFloatingMenuButton> createState() =>
      _AppPrimaryFloatingMenuButtonState();
}

class _AppPrimaryFloatingMenuButtonState
    extends State<_AppPrimaryFloatingMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = MaterialLocalizations.of(context).showMenuTooltip;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTapDown: (_) {
            _pressController.forward();
          },
          onTapUp: (_) {
            _pressController.reverse();
            HapticFeedback.selectionClick();
            _showMenu(context);
          },
          onTapCancel: () {
            _pressController.reverse();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: AppPrimaryNavigationBar._buttonSize,
              height: AppPrimaryNavigationBar._buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    Color(0xFF0C0E10),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
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
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _AppPrimaryMenuPanel(
              children: [
                for (final destination in AppPrimaryDestination.values)
                  _AppPrimaryMenuDestinationTile(
                    destination: destination,
                    selected: destination == widget.currentDestination,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppPrimaryMenuPanel extends StatefulWidget {
  final List<Widget> children;

  const _AppPrimaryMenuPanel({required this.children});

  @override
  State<_AppPrimaryMenuPanel> createState() => _AppPrimaryMenuPanelState();
}

class _AppPrimaryMenuPanelState extends State<_AppPrimaryMenuPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color:
                const Color(0xCC0A0D10), // Elegant dark translucent background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.children.length, (index) {
                final double start = (index * 0.08).clamp(0.0, 1.0);
                final double end = (start + 0.65).clamp(0.0, 1.0);

                final animation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: Curves.easeOutQuart),
                );

                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1.0 - animation.value)),
                      child: Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: widget.children[index],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppPrimaryMenuDestinationTile extends StatefulWidget {
  final AppPrimaryDestination destination;
  final bool selected;

  const _AppPrimaryMenuDestinationTile({
    required this.destination,
    required this.selected,
  });

  @override
  State<_AppPrimaryMenuDestinationTile> createState() =>
      _AppPrimaryMenuDestinationTileState();
}

class _AppPrimaryMenuDestinationTileState
    extends State<_AppPrimaryMenuDestinationTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.destination.label(context);
    final activeColor = AppColors.primary;

    // Determine colors based on selection and state
    final Color contentColor = widget.selected
        ? activeColor
        : (_isPressed ? Colors.white : Colors.white.withValues(alpha: 0.85));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTap: widget.selected
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    AppPrimaryNavigationBar.navigateTo(
                        context, widget.destination);
                  },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: widget.selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (_isPressed
                        ? AppColors.white.withValues(alpha: 0.05)
                        : Colors.transparent),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.destination.icon,
                    color: contentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 14.5,
                        fontWeight:
                            widget.selected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const Icon(
                            LucideIcons.check,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        );
                      },
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

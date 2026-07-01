import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons/kerosene_icons.dart';

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

  String get compactFallbackLabel {
    switch (this) {
      case AppPrimaryDestination.home:
        return 'Inicio';
      case AppPrimaryDestination.card:
        return 'Cartao';
      case AppPrimaryDestination.history:
        return 'Historico';
      case AppPrimaryDestination.settings:
        return 'Ajustes';
    }
  }

  IconData get _iconData {
    switch (this) {
      case AppPrimaryDestination.home:
        return KeroseneIcons.home;
      case AppPrimaryDestination.card:
        return KeroseneIcons.creditCard;
      case AppPrimaryDestination.history:
        return KeroseneIcons.history;
      case AppPrimaryDestination.settings:
        return KeroseneIcons.settings;
    }
  }
}

class AppPrimaryNavigationBar {
  static const double _buttonSize = 64;
  static const double _buttonSideSpacing = AppSpacing.base;
  static const double _buttonBottomSpacing = AppSpacing.xl2;
  static const double _contentBuffer = AppSpacing.xl2;
  static const double _gestureIndicatorWidth = 128;
  static const double _gestureIndicatorHeight = 4;

  const AppPrimaryNavigationBar._();

  static void navigateTo(
    BuildContext context,
    AppPrimaryDestination destination, {
    bool triggerFeedback = true,
  }) {
    final navigator = Navigator.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final targetRouteName = destination.routeName;

    if (currentRouteName == targetRouteName) {
      return;
    }

    if (triggerFeedback) {
      HapticFeedback.selectionClick();
    }

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
    return _KerosenePrimaryNavigationOverlay(
      key: key,
      currentDestination: currentDestination,
    );
  }
}

class _KerosenePrimaryNavigationOverlay extends StatefulWidget {
  final AppPrimaryDestination currentDestination;

  const _KerosenePrimaryNavigationOverlay({
    super.key,
    required this.currentDestination,
  });

  @override
  State<_KerosenePrimaryNavigationOverlay> createState() =>
      _KerosenePrimaryNavigationOverlayState();
}

class _KerosenePrimaryNavigationOverlayState
    extends State<_KerosenePrimaryNavigationOverlay> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _KerosenePrimaryNavigationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDestination != widget.currentDestination &&
        _expanded) {
      setState(() => _expanded = false);
    }
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  void _closeExpanded() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  Future<void> _selectDestination(AppPrimaryDestination destination) async {
    HapticFeedback.selectionClick();
    setState(() => _expanded = false);

    if (!mounted || destination == widget.currentDestination) return;

    await Future<void>.delayed(KeroseneMotion.fast);
    if (!mounted) return;
    AppPrimaryNavigationBar.navigateTo(
      context,
      destination,
      triggerFeedback: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_expanded,
              child: AnimatedOpacity(
                opacity: _expanded ? 1 : 0,
                duration: KeroseneMotion.duration(
                  context,
                  KeroseneMotion.short,
                ),
                curve: KeroseneMotion.standard,
                child: ExcludeSemantics(
                  excluding: !_expanded,
                  child: Semantics(
                    label: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeExpanded,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppPrimaryNavigationBar._buttonSideSpacing,
              0,
              AppPrimaryNavigationBar._buttonSideSpacing,
              AppPrimaryNavigationBar._buttonBottomSpacing,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _KeroseneExpandableNavigationButton(
                currentDestination: widget.currentDestination,
                expanded: _expanded,
                onToggle: _toggleExpanded,
                onDestinationSelected: _selectDestination,
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _expanded ? 0 : 1,
                  duration:
                      KeroseneMotion.duration(context, KeroseneMotion.short),
                  curve: KeroseneMotion.standard,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _KeroseneExpandableNavigationButton extends StatefulWidget {
  final AppPrimaryDestination currentDestination;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<AppPrimaryDestination> onDestinationSelected;

  const _KeroseneExpandableNavigationButton({
    required this.currentDestination,
    required this.expanded,
    required this.onToggle,
    required this.onDestinationSelected,
  });

  @override
  State<_KeroseneExpandableNavigationButton> createState() =>
      _KeroseneExpandableNavigationButtonState();
}

class _KeroseneExpandableNavigationButtonState
    extends State<_KeroseneExpandableNavigationButton>
    with TickerProviderStateMixin {
  static const double _closedSize = AppPrimaryNavigationBar._buttonSize;
  static const double _openHeight = 64;
  static const double _maxOpenWidth = 330;
  static const Color _navBackground = Color(0xFF1A1A1A);

  late final AnimationController _menuController;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.long,
      reverseDuration: KeroseneMotion.short,
      value: widget.expanded ? 1 : 0,
    );
    _pressController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.fast,
      reverseDuration: KeroseneMotion.fast,
    );
    _pressScale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: KeroseneMotion.standard),
    );
  }

  @override
  void didUpdateWidget(
      covariant _KeroseneExpandableNavigationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (KeroseneMotion.reduceMotion(context)) {
        _menuController.value = widget.expanded ? 1 : 0;
      } else if (widget.expanded) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reducedMotion = KeroseneMotion.reduceMotion(context);
    final availableWidth = media.size.width -
        media.viewPadding.left -
        media.viewPadding.right -
        AppPrimaryNavigationBar._buttonSideSpacing * 2;
    final openWidth =
        availableWidth.clamp(_closedSize, _maxOpenWidth).toDouble();
    final currentLabel = widget.currentDestination.label(context);
    final semanticsLabel = widget.expanded
        ? MaterialLocalizations.of(context).closeButtonTooltip
        : '${MaterialLocalizations.of(context).showMenuTooltip}: $currentLabel';

    return Semantics(
      button: true,
      toggled: widget.expanded,
      label: semanticsLabel,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_menuController, _pressController]),
          builder: (context, child) {
            final rawValue = reducedMotion
                ? (widget.expanded ? 1.0 : 0.0)
                : _menuController.value;
            final normalized = rawValue.clamp(0.0, 1.0).toDouble();
            final widthProgress = KeroseneMotion.standard.transform(normalized);
            final destinationsProgress = KeroseneMotion.standard.transform(
              ((normalized - 0.20) / 0.80).clamp(0.0, 1.0).toDouble(),
            );
            final closedProgress = KeroseneMotion.standard.transform(
              (normalized / 0.45).clamp(0.0, 1.0).toDouble(),
            );
            final width =
                _closedSize + (openWidth - _closedSize) * widthProgress;
            final scale = _pressScale.value;

            return Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                key: const ValueKey('appPrimaryNavigationSurface'),
                width: width,
                height: _openHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_openHeight / 2),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: _navBackground,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _navBackground,
                              borderRadius:
                                  BorderRadius.circular(_openHeight / 2),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.10 + widthProgress * 0.05,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.80),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: normalized < 0.98,
                            child: Opacity(
                              opacity: destinationsProgress,
                              child: Transform.scale(
                                scale: 0.96 + destinationsProgress * 0.04,
                                child: _KeroseneNavigationDestinations(
                                  progress: destinationsProgress,
                                  currentDestination: widget.currentDestination,
                                  onDestinationSelected:
                                      widget.onDestinationSelected,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: widget.expanded,
                            child: Opacity(
                              opacity: 1 - closedProgress,
                              child: _KeroseneClosedNavigationGlyph(
                                destination: widget.currentDestination,
                              ),
                            ),
                          ),
                        ),
                        if (!widget.expanded)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onToggle,
                              onTapDown: (_) => _pressController.forward(),
                              onTapCancel: _pressController.reverse,
                              onTapUp: (_) => _pressController.reverse(),
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
    );
  }
}

class _KeroseneClosedNavigationGlyph extends StatelessWidget {
  final AppPrimaryDestination destination;

  const _KeroseneClosedNavigationGlyph({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          destination._iconData,
          color: Colors.black,
          size: 22,
        ),
      ),
    );
  }
}

class _KeroseneNavigationDestinations extends StatelessWidget {
  final double progress;
  final AppPrimaryDestination currentDestination;
  final ValueChanged<AppPrimaryDestination> onDestinationSelected;

  const _KeroseneNavigationDestinations({
    required this.progress,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  static const double _contentPadding = 8;
  static const List<AppPrimaryDestination> _visualOrder = [
    AppPrimaryDestination.home,
    AppPrimaryDestination.card,
    AppPrimaryDestination.history,
    AppPrimaryDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final eased = KeroseneMotion.standard.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - _contentPadding * 2) / _visualOrder.length;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _contentPadding,
            vertical: 6,
          ),
          child: Row(
            children: [
              for (var index = 0; index < _visualOrder.length; index++)
                SizedBox(
                  key: ValueKey(
                    'appPrimaryNavigationDestination-${_visualOrder[index].name}',
                  ),
                  width: itemWidth,
                  height: double.infinity,
                  child: _KeroseneNavigationDestinationItem(
                    destination: _visualOrder[index],
                    selected: _visualOrder[index] == currentDestination,
                    progress: eased,
                    onTap: () => onDestinationSelected(_visualOrder[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KeroseneNavigationDestinationItem extends StatefulWidget {
  final AppPrimaryDestination destination;
  final bool selected;
  final double progress;
  final VoidCallback onTap;

  const _KeroseneNavigationDestinationItem({
    required this.destination,
    required this.selected,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_KeroseneNavigationDestinationItem> createState() =>
      _KeroseneNavigationDestinationItemState();
}

class _KeroseneNavigationDestinationItemState
    extends State<_KeroseneNavigationDestinationItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel(context);
    final progress = widget.progress.clamp(0.0, 1.0).toDouble();
    final iconColor = widget.selected
        ? Colors.black
        : Colors.white.withValues(alpha: 0.72 + progress * 0.28);
    final backgroundAlpha = widget.selected ? 1.0 : (_pressed ? 0.10 : 0.0);
    final borderAlpha = widget.selected ? 0.0 : 0.08 + progress * 0.08;

    return ExcludeSemantics(
      excluding: progress < 0.98,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: label,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
          curve: KeroseneMotion.standard,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(32),
              splashColor: Colors.white.withValues(alpha: 0.06),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: KeroseneMotion.duration(
                      context,
                      KeroseneMotion.fast,
                    ),
                    curve: KeroseneMotion.standard,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: backgroundAlpha),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: borderAlpha),
                      ),
                      boxShadow: widget.selected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.destination._iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 10,
                              fontWeight: widget.selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
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

  String _resolveLabel(BuildContext context) {
    final localized = widget.destination.label(context);
    if (localized.trim().isEmpty) {
      return widget.destination.compactFallbackLabel;
    }
    return localized;
  }
}

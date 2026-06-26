import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

enum AppPrimaryDestination { home, card, history, settings }

enum _KeroseneNavIconKind { home, wallet, history, settings }

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
        return 'Carteira';
      case AppPrimaryDestination.history:
        return 'Atividade';
      case AppPrimaryDestination.settings:
        return 'Ajustes';
    }
  }

  _KeroseneNavIconKind get _iconKind {
    switch (this) {
      case AppPrimaryDestination.home:
        return _KeroseneNavIconKind.home;
      case AppPrimaryDestination.card:
        return _KeroseneNavIconKind.wallet;
      case AppPrimaryDestination.history:
        return _KeroseneNavIconKind.history;
      case AppPrimaryDestination.settings:
        return _KeroseneNavIconKind.settings;
    }
  }
}

class AppPrimaryNavigationBar {
  static const double _buttonSize = 60;
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
    if (oldWidget.currentDestination != widget.currentDestination && _expanded) {
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
    AppPrimaryNavigationBar.navigateTo(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          if (_expanded)
            Positioned.fill(
              child: Semantics(
                label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
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
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppPrimaryNavigationBar._buttonRightSpacing,
              AppPrimaryNavigationBar._buttonBottomSpacing,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
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
                  duration: KeroseneMotion.duration(context, KeroseneMotion.short),
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
  static const double _itemGap = 4;

  late final AnimationController _menuController;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.medium,
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
  void didUpdateWidget(covariant _KeroseneExpandableNavigationButton oldWidget) {
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
    final openWidth = (media.size.width -
            AppPrimaryNavigationBar._buttonRightSpacing -
            AppSpacing.md)
        .clamp(292.0, 392.0)
        .toDouble();
    final label = widget.expanded
        ? MaterialLocalizations.of(context).closeButtonTooltip
        : widget.currentDestination.label(context);

    return Semantics(
      button: true,
      toggled: widget.expanded,
      label: label,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_menuController, _pressController]),
          builder: (context, child) {
            final rawValue = reducedMotion
                ? (widget.expanded ? 1.0 : 0.0)
                : _menuController.value;
            final panelValue = KeroseneMotion.standard.transform(rawValue);
            final radiusValue = KeroseneMotion.entrance.transform(rawValue);
            final width = _closedSize + (openWidth - _closedSize) * panelValue;
            final height = _closedSize + (_openHeight - _closedSize) * panelValue;
            final radius = _closedSize / 2 + (32 - _closedSize / 2) * radiusValue;
            final scale = _pressScale.value;

            return Transform.scale(
              scale: scale,
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.black,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.10 + panelValue * 0.08,
                                ),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.36),
                                  blurRadius: 22 + panelValue * 16,
                                  offset: Offset(0, 10 + panelValue * 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: openWidth,
                            height: _openHeight,
                            child: _KeroseneNavigationDestinations(
                              progress: rawValue,
                              currentDestination: widget.currentDestination,
                              onDestinationSelected: widget.onDestinationSelected,
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

class _KeroseneNavigationDestinations extends StatelessWidget {
  final double progress;
  final AppPrimaryDestination currentDestination;
  final ValueChanged<AppPrimaryDestination> onDestinationSelected;

  const _KeroseneNavigationDestinations({
    required this.progress,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  static const double _iconBoxSize = 40;
  static const double _contentPadding = 8;
  static const double _gap = _KeroseneExpandableNavigationButtonState._itemGap;

  @override
  Widget build(BuildContext context) {
    final destinations = AppPrimaryDestination.values;
    final eased = KeroseneMotion.standard.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = _gap * (destinations.length - 1);
        final itemWidth =
            (constraints.maxWidth - _contentPadding * 2 - totalGap) /
                destinations.length;
        final closeCenterX = constraints.maxWidth -
            AppPrimaryNavigationBar._buttonSize / 2;

        return Padding(
          padding: const EdgeInsets.all(_contentPadding),
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++) ...[
                SizedBox(
                  width: itemWidth,
                  child: _KeroseneNavigationDestinationPill(
                    destination: destinations[index],
                    selected: destinations[index] == currentDestination,
                    progress: eased,
                    flyOffset: _selectedFlyOffset(
                      selected: destinations[index] == currentDestination,
                      closeCenterX: closeCenterX,
                      index: index,
                      itemWidth: itemWidth,
                    ),
                    onTap: () => onDestinationSelected(destinations[index]),
                  ),
                ),
                if (index != destinations.length - 1) const SizedBox(width: _gap),
              ],
            ],
          ),
        );
      },
    );
  }

  Offset _selectedFlyOffset({
    required bool selected,
    required double closeCenterX,
    required int index,
    required double itemWidth,
  }) {
    if (!selected) return Offset.zero;

    final itemStart = _contentPadding + index * (itemWidth + _gap);
    final iconCenterX = itemStart + _iconBoxSize / 2;
    return Offset((closeCenterX - iconCenterX) * (1 - progress), 0);
  }
}

class _KeroseneNavigationDestinationPill extends StatefulWidget {
  final AppPrimaryDestination destination;
  final bool selected;
  final double progress;
  final Offset flyOffset;
  final VoidCallback onTap;

  const _KeroseneNavigationDestinationPill({
    required this.destination,
    required this.selected,
    required this.progress,
    required this.flyOffset,
    required this.onTap,
  });

  @override
  State<_KeroseneNavigationDestinationPill> createState() =>
      _KeroseneNavigationDestinationPillState();
}

class _KeroseneNavigationDestinationPillState
    extends State<_KeroseneNavigationDestinationPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel(context);
    final visibleTextAlpha = widget.progress.clamp(0.0, 1.0).toDouble();
    final inactiveAlpha = widget.progress.clamp(0.0, 1.0).toDouble();
    final iconAlpha = widget.selected ? 1.0 : inactiveAlpha;
    final itemBackgroundAlpha = widget.selected
        ? 0.12 * visibleTextAlpha
        : (_pressed ? 0.07 : 0.0) * visibleTextAlpha;
    final borderAlpha = widget.selected ? 0.16 * visibleTextAlpha : 0.0;

    return AnimatedScale(
      scale: _pressed ? 0.965 : 1,
      duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
      curve: KeroseneMotion.standard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.07),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
            curve: KeroseneMotion.standard,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: itemBackgroundAlpha),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderAlpha),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: widget.flyOffset,
                  child: Transform.rotate(
                    angle: widget.selected ? widget.progress * math.pi : 0,
                    child: _KeroseneNativeNavIcon(
                      kind: widget.destination._iconKind,
                      color: Colors.white.withValues(alpha: iconAlpha),
                      size: 40,
                      strokeWidth: widget.selected ? 1.75 : 1.55,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.progress.clamp(0.0, 1.0).toDouble(),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: visibleTextAlpha),
                          fontSize: 11.5,
                          fontWeight:
                              widget.selected ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: -0.18,
                          height: 1,
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
    );
  }

  String _resolveLabel(BuildContext context) {
    final localized = widget.destination.label(context);
    if (localized.trim().isEmpty) return widget.destination.compactFallbackLabel;
    return localized;
  }
}

class _KeroseneNativeNavIcon extends StatelessWidget {
  final _KeroseneNavIconKind kind;
  final Color color;
  final double size;
  final double strokeWidth;

  const _KeroseneNativeNavIcon({
    required this.kind,
    required this.color,
    this.size = 40,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _KeroseneNavIconPainter(
            kind: kind,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _KeroseneNavIconPainter extends CustomPainter {
  final _KeroseneNavIconKind kind;
  final Color color;
  final double strokeWidth;

  const _KeroseneNavIconPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case _KeroseneNavIconKind.home:
        _paintHome(canvas, stroke);
      case _KeroseneNavIconKind.wallet:
        _paintWallet(canvas, stroke);
      case _KeroseneNavIconKind.history:
        _paintHistory(canvas, stroke);
      case _KeroseneNavIconKind.settings:
        _paintSettings(canvas, stroke);
    }

    canvas.restore();
  }

  void _paintHome(Canvas canvas, Paint stroke) {
    final roof = Path()
      ..moveTo(4.4, 10.2)
      ..lineTo(12, 4.6)
      ..lineTo(19.6, 10.2);
    canvas.drawPath(roof, stroke);

    final body = Path()
      ..moveTo(6.1, 10.1)
      ..lineTo(6.1, 19.1)
      ..quadraticBezierTo(6.1, 20, 7, 20)
      ..lineTo(9.4, 20)
      ..lineTo(9.4, 14.8)
      ..quadraticBezierTo(9.4, 14.1, 10.1, 14.1)
      ..lineTo(13.9, 14.1)
      ..quadraticBezierTo(14.6, 14.1, 14.6, 14.8)
      ..lineTo(14.6, 20)
      ..lineTo(17, 20)
      ..quadraticBezierTo(17.9, 20, 17.9, 19.1)
      ..lineTo(17.9, 10.1);
    canvas.drawPath(body, stroke);
  }

  void _paintWallet(Canvas canvas, Paint stroke) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.8, 6.7, 16.4, 11.8),
      const Radius.circular(3.1),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawLine(const Offset(5.1, 9.5), const Offset(18.7, 9.5), stroke);

    final pocket = RRect.fromRectAndRadius(
      const Rect.fromLTWH(13.3, 11.0, 6.9, 4.2),
      const Radius.circular(2.1),
    );
    canvas.drawRRect(pocket, stroke);
    canvas.drawCircle(const Offset(15.4, 13.1), 0.45, stroke);
  }

  void _paintHistory(Canvas canvas, Paint stroke) {
    final arcRect = Rect.fromCircle(center: const Offset(12, 12), radius: 7.1);
    canvas.drawArc(arcRect, -math.pi * 1.03, math.pi * 1.72, false, stroke);

    final arrow = Path()
      ..moveTo(4.7, 8.4)
      ..lineTo(4.8, 13.1)
      ..lineTo(8.6, 10.4);
    canvas.drawPath(arrow, stroke);
    canvas.drawLine(const Offset(12, 8.1), const Offset(12, 12.3), stroke);
    canvas.drawLine(const Offset(12, 12.3), const Offset(15.4, 14.1), stroke);
  }

  void _paintSettings(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(12, 12), 3.1, stroke);

    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final inner = Offset(
        12 + math.cos(angle) * 6.0,
        12 + math.sin(angle) * 6.0,
      );
      final outer = Offset(
        12 + math.cos(angle) * 8.0,
        12 + math.sin(angle) * 8.0,
      );
      canvas.drawLine(inner, outer, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _KeroseneNavIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

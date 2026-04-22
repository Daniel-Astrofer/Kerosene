import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  String get label {
    switch (this) {
      case AppPrimaryDestination.home:
        return 'Início';
      case AppPrimaryDestination.card:
        return 'Cartão';
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
      case AppPrimaryDestination.card:
        return Icons.credit_card_rounded;
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
  static const double _floatingHeight = 78;
  static const double _topSpacing = 8;
  static const double _bottomSpacing = 18;
  static const double _contentBuffer = 20;

  final AppPrimaryDestination currentDestination;
  final AppPrimaryNavigationController? controller;

  const AppPrimaryNavigationBar({
    super.key,
    required this.currentDestination,
    this.controller,
  });

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
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final safeBottomInset = math.max(viewPadding, _bottomSpacing);
    return _floatingHeight + safeBottomInset + _contentBuffer;
  }

  static Widget overlay({
    Key? key,
    required AppPrimaryDestination currentDestination,
    AppPrimaryNavigationController? controller,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AppPrimaryNavigationBar(
        key: key,
        currentDestination: currentDestination,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PrimaryNavigationBarBody(
      currentDestination: currentDestination,
      controller: controller,
    );
  }
}

class AppPrimaryNavigationController extends ChangeNotifier {
  int _refreshVersion = 0;

  int get refreshVersion => _refreshVersion;

  void triggerRefreshAnimation() {
    _refreshVersion += 1;
    notifyListeners();
  }
}

class _PrimaryNavigationBarBody extends StatefulWidget {
  final AppPrimaryDestination currentDestination;
  final AppPrimaryNavigationController? controller;

  const _PrimaryNavigationBarBody({
    required this.currentDestination,
    required this.controller,
  });

  @override
  State<_PrimaryNavigationBarBody> createState() =>
      _PrimaryNavigationBarBodyState();
}

class _PrimaryNavigationBarBodyState extends State<_PrimaryNavigationBarBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _refreshSweepController;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _refreshSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller?.addListener(_handleRefreshTrigger);
  }

  @override
  void didUpdateWidget(covariant _PrimaryNavigationBarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?.removeListener(_handleRefreshTrigger);
    widget.controller?.addListener(_handleRefreshTrigger);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleRefreshTrigger);
    _refreshSweepController.dispose();
    super.dispose();
  }

  void _handleRefreshTrigger() {
    if (!mounted) {
      return;
    }
    setState(() {
      _refreshVersion =
          widget.controller?.refreshVersion ?? (_refreshVersion + 1);
    });
    _refreshSweepController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = screenWidth >= 1180;
    final isTablet = screenWidth >= 720;
    final horizontalMargin = isLargeScreen ? 28.0 : (isTablet ? 24.0 : 16.0);
    final maxWidth = isLargeScreen ? 520.0 : (isTablet ? 460.0 : 420.0);
    final borderRadius = BorderRadius.circular(isLargeScreen ? 18 : 14);

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        horizontalMargin,
        AppPrimaryNavigationBar._topSpacing,
        horizontalMargin,
        AppPrimaryNavigationBar._bottomSpacing,
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AnimatedBuilder(
            animation: _refreshSweepController,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: LayoutBuilder(
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: const Color(0xFF101317),
                          border: Border.all(
                            color: const Color(0xFF252B32),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101317),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  for (var index = 0;
                                      index <
                                          AppPrimaryDestination.values.length;
                                      index++)
                                    Expanded(
                                      child: _PrimaryNavigationItem(
                                        index: index,
                                        refreshVersion: _refreshVersion,
                                        destination:
                                            AppPrimaryDestination.values[index],
                                        selected: AppPrimaryDestination
                                                .values[index] ==
                                            widget.currentDestination,
                                        onTap: () {
                                          final destination =
                                              AppPrimaryDestination
                                                  .values[index];
                                          if (destination ==
                                              widget.currentDestination) {
                                            return;
                                          }
                                          AppPrimaryNavigationBar.navigateTo(
                                            context,
                                            destination,
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrimaryNavigationItem extends StatefulWidget {
  final int index;
  final AppPrimaryDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final int refreshVersion;

  const _PrimaryNavigationItem({
    required this.index,
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.refreshVersion,
  });

  @override
  State<_PrimaryNavigationItem> createState() => _PrimaryNavigationItemState();
}

class _PrimaryNavigationItemState extends State<_PrimaryNavigationItem>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pressController;
  late final AnimationController _tapController;
  late final AnimationController _refreshController;
  bool _tapLocked = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    Future<void>.delayed(
      Duration(milliseconds: 140 + (widget.index * 90)),
      () {
        if (!mounted) {
          return;
        }
        _introController.forward();
      },
    );
  }

  @override
  void didUpdateWidget(covariant _PrimaryNavigationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _refreshController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _pressController.dispose();
    _tapController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  Future<void> _handleTap() async {
    if (_tapLocked) {
      return;
    }
    _tapLocked = true;
    _pressController.reverse();
    _tapController.forward(from: 0);
    await HapticFeedback.selectionClick();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      widget.onTap();
    }
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      _tapLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _introController,
        _pressController,
        _tapController,
        _refreshController,
      ]),
      builder: (context, _) {
        final intro = Curves.easeOutCubic.transform(_introController.value);
        final press = Curves.easeOutCubic.transform(_pressController.value);
        final tap = Curves.easeOutBack.transform(_tapController.value);
        final refresh =
            Curves.easeInOutCubic.transform(_refreshController.value);
        final refreshLift = math.sin(refresh * math.pi) * 4;
        final refreshPulse = math.sin(refresh * math.pi) * 0.08;
        final introTurn = (1 - intro) * (widget.selected ? -0.22 : 0.18);
        final activeAccent = const Color(0xFF6F7D8C);
        final iconColor = widget.selected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.76);
        final shellColor = widget.selected
            ? activeAccent.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.045 + (press * 0.03));
        final shellBorder = widget.selected
            ? activeAccent.withValues(alpha: 0.44)
            : Colors.white.withValues(alpha: 0.05 + (refresh * 0.04));

        return Opacity(
          opacity: intro,
          child: Transform.translate(
            offset: Offset(0, (1 - intro) * 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: widget.destination.label,
                child: Semantics(
                  label: widget.destination.label,
                  button: true,
                  selected: widget.selected,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTapDown: _handleTapDown,
                      onTapCancel: _handleTapCancel,
                      onTapUp: (_) => _handleTapCancel(),
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 58,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: widget.selected ? 58 : 54,
                              height: widget.selected ? 58 : 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: shellColor,
                                border: Border.all(color: shellBorder),
                              ),
                            ),
                            Positioned(
                              bottom: widget.selected ? 5 : 8,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: widget.selected ? 20 : 6,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: widget.selected
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(0, -refreshLift + (press * 1.5)),
                              child: Transform.rotate(
                                angle: introTurn - (press * 0.04),
                                child: Transform.scale(
                                  scale: (0.88 + (intro * 0.12)) -
                                      (press * 0.10) +
                                      (widget.selected ? 0.08 : 0.0) +
                                      (tap * 0.14) +
                                      refreshPulse,
                                  child: Icon(
                                    widget.destination.icon,
                                    size: widget.selected ? 24 : 23,
                                    color: iconColor,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

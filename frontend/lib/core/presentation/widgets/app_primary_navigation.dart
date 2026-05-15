import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';

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
        return context.l10n.primaryNavHome;
      case AppPrimaryDestination.card:
        return context.l10n.primaryNavCard;
      case AppPrimaryDestination.history:
        return context.l10n.primaryNavHistory;
      case AppPrimaryDestination.mining:
        return context.l10n.primaryNavMining;
      case AppPrimaryDestination.settings:
        return context.l10n.primaryNavSettings;
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

class AppPrimaryNavigationBar extends StatelessWidget {
  static const double _floatingHeight = 80;
  static const double _topSpacing = AppSpacing.sm;
  static const double _bottomSpacing = AppSpacing.lg;
  static const double _contentBuffer = AppSpacing.lg;

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
    final isTinyPhone = screenWidth < 360;
    final horizontalMargin = isLargeScreen
        ? AppSpacing.xl
        : (isTablet
            ? AppSpacing.lg
            : (isTinyPhone ? AppSpacing.sm : AppSpacing.md));
    final maxWidth = isLargeScreen ? 520.0 : (isTablet ? 464.0 : 424.0);
    final borderRadius = BorderRadius.circular(AppSpacing.md);

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
                          color: AppColors.bgInput,
                          border: Border.all(
                            color: AppColors.white10,
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.bgInput,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.sm,
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

    Future<void>.delayed(Duration(milliseconds: 140 + (widget.index * 90)), () {
      if (!mounted) {
        return;
      }
      _introController.forward();
    });
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final shellMaxWidth = math.max(
          44.0,
          constraints.maxWidth - (AppSpacing.xs * 2),
        );
        final selectedShellSize = math.min(64.0, shellMaxWidth);
        final idleShellSize = math.min(56.0, shellMaxWidth);
        final itemHeight = math.max(56.0, selectedShellSize);
        final selectedIconSize = math.min(24.0, selectedShellSize * 0.44);
        final idleIconSize = math.min(23.0, idleShellSize * 0.44);

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
            final refresh = Curves.easeInOutCubic.transform(
              _refreshController.value,
            );
            final refreshLift = math.sin(refresh * math.pi) * 4;
            final refreshPulse = math.sin(refresh * math.pi) * 0.08;
            final introTurn = (1 - intro) * (widget.selected ? -0.22 : 0.18);
            final activeAccent = AppColors.white70;
            final iconColor = widget.selected
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.76);
            final shellColor = widget.selected
                ? activeAccent.withValues(alpha: 0.20)
                : AppColors.white.withValues(alpha: 0.045 + (press * 0.03));
            final shellBorder = widget.selected
                ? activeAccent.withValues(alpha: 0.44)
                : AppColors.white.withValues(alpha: 0.05 + (refresh * 0.04));
            final label = widget.destination.label(context);

            return Opacity(
              opacity: intro,
              child: Transform.translate(
                offset: Offset(0, (1 - intro) * 18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Tooltip(
                    message: label,
                    child: Semantics(
                      label: label,
                      button: true,
                      selected: widget.selected,
                      child: Material(
                        color: AppColors.black.withValues(alpha: 0),
                        child: InkWell(
                          onTapDown: _handleTapDown,
                          onTapCancel: _handleTapCancel,
                          onTapUp: (_) => _handleTapCancel(),
                          onTap: _handleTap,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          child: SizedBox(
                            height: itemHeight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: widget.selected
                                      ? selectedShellSize
                                      : idleShellSize,
                                  height: widget.selected
                                      ? selectedShellSize
                                      : idleShellSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.sm,
                                    ),
                                    color: shellColor,
                                    border: Border.all(color: shellBorder),
                                  ),
                                ),
                                Positioned(
                                  bottom: widget.selected
                                      ? AppSpacing.xs
                                      : AppSpacing.sm,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    width: widget.selected
                                        ? math.min(
                                            AppSpacing.lg,
                                            selectedShellSize * 0.38,
                                          )
                                        : AppSpacing.sm,
                                    height: AppSpacing.xs,
                                    decoration: BoxDecoration(
                                      color: widget.selected
                                          ? AppColors.white.withValues(
                                              alpha: 0.92,
                                            )
                                          : AppColors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.xxl,
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    -refreshLift + (press * 1.5),
                                  ),
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
                                        size: widget.selected
                                            ? selectedIconSize
                                            : idleIconSize,
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
      },
    );
  }
}

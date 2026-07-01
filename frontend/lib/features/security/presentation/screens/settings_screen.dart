import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_account_pane.dart';
import 'settings_appearance_pane.dart';
import 'settings_navigation.dart';
import 'settings_notifications_pane.dart';
import 'settings_display_pane.dart';
import 'settings_security_pane.dart';
import 'settings_wallets_pane.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;
  final bool openNotificationsPane;

  const SettingsScreen({
    super.key,
    this.showPrimaryNavigation = false,
    this.openNotificationsPane = false,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.openNotificationsPane) {
      return _SettingsPaneDetailScreen(
        pane: SettingsPane.notifications,
        showPrimaryNavigation: widget.showPrimaryNavigation,
      );
    }

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width <= 360 ? AppSpacing.lg : AppSpacing.xl2;
    final bottomPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettingsHeader(onClose: _close),
                            const SizedBox(height: AppSpacing.xxl),
                            const SettingsHero(),
                            const SizedBox(height: AppSpacing.xxl),
                            SettingsNavigationRail(
                              selected: null,
                              onSelected: _openPane,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showPrimaryNavigation)
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.settings,
            ),
        ],
      ),
    );
  }

  void _openPane(SettingsPane pane) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(_settingsPaneRoute(pane));
  }

  Route<void> _settingsPaneRoute(SettingsPane pane) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => _SettingsPaneDetailScreen(
        pane: pane,
        showPrimaryNavigation: widget.showPrimaryNavigation,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _close() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/home');
    }
  }
}

class _SettingsPaneDetailScreen extends StatelessWidget {
  final SettingsPane pane;
  final bool showPrimaryNavigation;

  const _SettingsPaneDetailScreen({
    required this.pane,
    this.showPrimaryNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width <= 360 ? AppSpacing.lg : AppSpacing.xl2;
    final bottomPadding = showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettingsHeader(
                              onClose: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).maybePop();
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            _AnimatedPaneSwitcher(pane),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showPrimaryNavigation)
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.settings,
            ),
        ],
      ),
    );
  }
}

class _AnimatedPaneSwitcher extends StatelessWidget {
  final SettingsPane pane;

  const _AnimatedPaneSwitcher(this.pane);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
      switchInCurve: KeroseneMotion.emphasized,
      switchOutCurve: KeroseneMotion.standard,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(pane),
        child: switch (pane) {
          SettingsPane.account => const SettingsAccountPane(),
          SettingsPane.security => const SettingsSecurityPane(),
          SettingsPane.notifications => const SettingsNotificationsPane(),
          SettingsPane.appearance => const SettingsAppearancePane(),
          SettingsPane.display => const SettingsDisplayPane(),
          SettingsPane.wallets => const SettingsWalletsPane(),
        },
      ),
    );
  }
}

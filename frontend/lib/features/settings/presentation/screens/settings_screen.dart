import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_account_pane.dart';
import 'settings_appearance_pane.dart';
import 'settings_navigation.dart';
import 'settings_notifications_pane.dart';
import 'settings_security_pane.dart';
import 'settings_wallets_pane.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const SettingsScreen({super.key, this.showPrimaryNavigation = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsPane _pane = SettingsPane.account;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width <= 360 ? AppSpacing.lg : AppSpacing.xl2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                viewPadding.bottom + AppSpacing.xxl,
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
                          selected: _pane,
                          onSelected: _selectPane,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _AnimatedPaneSwitcher(_pane),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPane(SettingsPane pane) {
    HapticFeedback.selectionClick();
    setState(() => _pane = pane);
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
          SettingsPane.wallets => const SettingsWalletsPane(),
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/presentation/widgets/app_notification_surface.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/core/presentation/widgets/app_screen_feedback_host.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/notifications/presentation/notification_navigation.dart';
import 'package:kerosene/features/notifications/presentation/notification_visuals.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/notifications/presentation/screens/notification_center_screen.dart';

import 'session_notification_sidebar.dart';

class GlobalNotificationHost extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalNotificationHost({super.key, required this.child});

  @override
  ConsumerState<GlobalNotificationHost> createState() =>
      _GlobalNotificationHostState();
}

class _GlobalNotificationHostState
    extends ConsumerState<GlobalNotificationHost> {
  bool _backgroundNudgeScheduled = false;
  bool _backgroundNudgeShownForSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleBackgroundAlertsNudge();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      _scheduleBackgroundAlertsNudge();
    });
    ref.listen<AlertPreferencesState>(alertPreferencesProvider, (_, __) {
      _scheduleBackgroundAlertsNudge();
    });

    final sidebarOpen = ref.watch(notificationSidebarProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: AppScreenFeedbackHost(child: widget.child)),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !sidebarOpen,
            child: GestureDetector(
              onTap: () =>
                  ref.read(notificationSidebarProvider.notifier).close(),
              child: AnimatedOpacity(
                opacity: sidebarOpen ? 1 : 0,
                duration: KeroseneMotion.medium,
                curve: KeroseneMotion.standard,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
              ),
            ),
          ),
        ),
        if (sidebarOpen)
          AnimatedPositioned(
            duration: KeroseneMotion.long,
            curve: KeroseneMotion.standard,
            top: 0,
            right: 0,
            bottom: 0,
            child: SessionNotificationSidebar(
              showCloseButton: true,
              onClose: () =>
                  ref.read(notificationSidebarProvider.notifier).close(),
            ),
          ),
        const _TopNotificationBanner(),
      ],
    );
  }

  void _scheduleBackgroundAlertsNudge() {
    if (_backgroundNudgeShownForSession || _backgroundNudgeScheduled) {
      return;
    }

    _backgroundNudgeScheduled = true;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () async {
        _backgroundNudgeScheduled = false;
        await _maybeShowBackgroundAlertsNudge();
      }),
    );
  }

  Future<void> _maybeShowBackgroundAlertsNudge() async {
    if (!mounted || _backgroundNudgeShownForSession) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) {
      return;
    }

    final preferences = ref.read(alertPreferencesProvider);
    if (!preferences.inAppBannersEnabled ||
        preferences.backgroundAlertsEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedEnabled =
        prefs.getBool(AlertPreferencesNotifier.backgroundAlertsKey) ?? false;
    if (persistedEnabled || !mounted) {
      return;
    }

    final userId = authState.user.id.trim();
    final now = DateTime.now();
    final notification = SessionNotificationItem(
      id: 'background-alerts-nudge-$userId-${now.millisecondsSinceEpoch}',
      title: 'Ative alertas em segundo plano',
      body:
          'Receba transações, depósitos e atualizações importantes mesmo fora do app. Toque para revisar as configurações.',
      timestamp: now,
      kind: SessionNotificationItem.kindBackgroundAlertsSetup,
      severity: SessionNotificationItem.severityInfo,
      deeplink: '/settings/notifications',
      entityType: 'device',
      entityId: userId,
      metadata: const {
        'dedupeKey': 'background-alerts-setup-nudge',
        'cta': 'Configurar agora',
      },
    );

    _backgroundNudgeShownForSession = true;
    ref.read(sessionNotificationFeedProvider.notifier).add(notification);
    ref.read(notificationBannerProvider.notifier).show(notification);
  }
}

class _TopNotificationBanner extends ConsumerWidget {
  const _TopNotificationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(notificationBannerProvider);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: notification == null,
          child: AnimatedSwitcher(
            duration: KeroseneMotion.medium,
            switchInCurve: KeroseneMotion.standard,
            switchOutCurve: KeroseneMotion.exit,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, -0.16),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: notification == null
                ? const SizedBox(key: ValueKey<String>('empty-banner'))
                : _DismissibleNotificationBanner(
                    key: ValueKey<String>(
                      '${notification.id}-${notification.timestamp.microsecondsSinceEpoch}',
                    ),
                    notification: notification,
                  ),
          ),
        ),
      ),
    );
  }
}

class _DismissibleNotificationBanner extends ConsumerStatefulWidget {
  final SessionNotificationItem notification;

  const _DismissibleNotificationBanner({super.key, required this.notification});

  @override
  ConsumerState<_DismissibleNotificationBanner> createState() =>
      _DismissibleNotificationBannerState();
}

class _DismissibleNotificationBannerState
    extends ConsumerState<_DismissibleNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  final GlobalKey _bannerOriginKey = GlobalKey();
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.short,
    );
    _offsetAnimation = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      final next = _dragOffset + details.delta;
      _dragOffset = Offset(next.dx, next.dy > 0 ? 0 : next.dy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final shouldDismiss = _dragOffset.dx.abs() > 96 ||
        _dragOffset.dy < -48 ||
        velocity.dx.abs() > 720 ||
        velocity.dy < -540;

    if (shouldDismiss) {
      ref.read(notificationBannerProvider.notifier).dismiss();
      return;
    }

    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: KeroseneMotion.standard));
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            _controller.isAnimating ? _offsetAnimation.value : _dragOffset;
        if (_controller.isCompleted && _dragOffset != Offset.zero) {
          _dragOffset = Offset.zero;
        }
        return Transform.translate(offset: offset, child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Center(
            child: _NotificationBannerCard(
              notification: widget.notification,
              originKey: _bannerOriginKey,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBannerCard extends ConsumerWidget {
  final SessionNotificationItem notification;
  final GlobalKey originKey;

  const _NotificationBannerCard({
    required this.notification,
    required this.originKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = resolveNotificationVisuals(context, notification);
    final footer = buildNotificationFooterLabel(
      context,
      notification,
      _localizedNow(context),
    );
    final accent = _accentFor(visuals.tone);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360 || size.height < 620;
    final shortViewport = size.height < 420;
    final maxBannerHeight = math.min(
      compact ? 144.0 : 168.0,
      math.max(96.0, size.height * (shortViewport ? 0.38 : 0.26)),
    );
    final titleStyle = AppTypography.bodyMedium.copyWith(
      color: Colors.white,
      fontSize: compact ? 14 : 15,
      fontWeight: FontWeight.w800,
      height: 1.18,
      letterSpacing: 0,
      decoration: TextDecoration.none,
    );
    final bodyStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.hexFFC4C4C4,
      fontSize: compact ? 12 : 13,
      height: 1.34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      decoration: TextDecoration.none,
    );
    final contentPadding = compact
        ? const EdgeInsets.fromLTRB(16, 14, 44, 14)
        : const EdgeInsets.fromLTRB(18, 16, 48, 16);

    return ConstrainedBox(
      key: originKey,
      constraints: BoxConstraints(maxWidth: 480, maxHeight: maxBannerHeight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await _handleBannerTap(context, ref);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.hexFF050505,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.hexFF1F2937.withValues(alpha: 0.50),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: contentPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(
                        64,
                        maxBannerHeight -
                            contentPadding.vertical -
                            (compact ? 2 : 0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              visuals.icon,
                              color: accent,
                              size: compact ? 18 : 20,
                            ),
                          ),
                          SizedBox(width: compact ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification.title.trim().isEmpty
                                      ? _fallbackTitle(context)
                                      : notification.title.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                if (notification.body.trim().isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    notification.body.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyStyle,
                                  ),
                                ],
                                SizedBox(height: compact ? 7 : 9),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        footer,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.42),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                          letterSpacing: 0,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    if (notification.isActionable) ...[
                                      const SizedBox(width: 8),
                                      _BannerActionPill(
                                        label: notification.metadata['cta'] ??
                                            _localizedAction(context),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: compact ? 10 : 14,
                  right: compact ? 10 : 14,
                  child: Semantics(
                    button: true,
                    label: 'Fechar notificação',
                    child: IconButton(
                      onPressed: () => ref
                          .read(notificationBannerProvider.notifier)
                          .dismiss(),
                      icon: const Icon(KeroseneIcons.close),
                      color: Colors.white.withValues(alpha: 0.48),
                      hoverColor: Colors.white.withValues(alpha: 0.08),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const RoundedRectangleBorder(),
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

  Future<void> _handleBannerTap(BuildContext context, WidgetRef ref) {
    ref.read(notificationBannerProvider.notifier).dismiss();
    unawaited(
      ref
          .read(sessionNotificationFeedProvider.notifier)
          .markRead(notification.id),
    );

    if (notification.isActionable) {
      return NotificationNavigation.openFromContext(context, notification);
    }

    return openNotificationCenter(
      context,
      originKey: originKey,
    );
  }

  static Color _accentFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.error => AppColors.hexFFF8312F,
      AppNotificationTone.warning => AppColors.hexFFF8312F,
      AppNotificationTone.success => AppColors.hexFFE5E7EB,
      AppNotificationTone.info => AppColors.hexFFD4D4D8,
      AppNotificationTone.neutral => AppColors.hexFFD4D4D8,
    };
  }

  static String _localizedNow(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Now';
      case 'es':
        return 'Ahora';
      default:
        return 'Agora';
    }
  }

  static String _localizedAction(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Open';
      case 'es':
        return 'Abrir';
      default:
        return 'Abrir';
    }
  }

  static String _fallbackTitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Notification';
      case 'es':
        return 'Notificación';
      default:
        return 'Notificação';
    }
  }
}

class _BannerActionPill extends StatelessWidget {
  final String label;

  const _BannerActionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            KeroseneIcons.chevronRight,
            size: 13,
            color: Colors.white.withValues(alpha: 0.66),
          ),
        ],
      ),
    );
  }
}

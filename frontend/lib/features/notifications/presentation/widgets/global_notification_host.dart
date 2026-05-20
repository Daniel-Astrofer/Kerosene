import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/presentation/widgets/app_screen_feedback_host.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';
import 'package:teste/features/notifications/presentation/notification_visuals.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:teste/features/notifications/presentation/screens/notification_center_screen.dart';

import 'session_notification_sidebar.dart';

class GlobalNotificationHost extends ConsumerWidget {
  final Widget child;

  const GlobalNotificationHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarOpen = ref.watch(notificationSidebarProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: AppScreenFeedbackHost(child: child)),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !sidebarOpen,
            child: GestureDetector(
              onTap: () =>
                  ref.read(notificationSidebarProvider.notifier).close(),
              child: AnimatedOpacity(
                opacity: sidebarOpen ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
              ),
            ),
          ),
        ),
        if (sidebarOpen)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
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
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
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
      duration: const Duration(milliseconds: 180),
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
      compact ? 184.0 : 228.0,
      math.max(112.0, size.height * (shortViewport ? 0.46 : 0.34)),
    );
    final titleStyle = GoogleFonts.ebGaramond(
      color: Colors.white,
      fontSize: compact ? 21 : 26,
      fontWeight: FontWeight.w400,
      height: compact ? 1.14 : 32 / 26,
      letterSpacing: 0.2,
    );
    final bodyStyle = AppTypography.bodySmall.copyWith(
      color: const Color(0xFFC4C4C4),
      fontSize: compact ? 13 : 15,
      height: compact ? 1.32 : 22 / 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
    final contentPadding = compact
        ? const EdgeInsets.fromLTRB(18, 16, 48, 16)
        : const EdgeInsets.fromLTRB(24, 22, 54, 22);

    return ConstrainedBox(
      key: originKey,
      constraints: BoxConstraints(maxWidth: 480, maxHeight: maxBannerHeight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final navigation = openNotificationCenter(
              context,
              originKey: originKey,
            );
            ref.read(notificationBannerProvider.notifier).dismiss();
            await navigation;
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1F2937).withValues(alpha: 0.50),
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
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              visuals.icon,
                              color: accent,
                              size: compact ? 21 : 24,
                            ),
                          ),
                          SizedBox(width: compact ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification.title.trim().isEmpty
                                      ? _fallbackTitle(context)
                                      : notification.title.trim(),
                                  maxLines: compact ? 2 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                if (notification.body.trim().isNotEmpty) ...[
                                  SizedBox(height: compact ? 6 : 8),
                                  Text(
                                    notification.body.trim(),
                                    maxLines: compact ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: bodyStyle,
                                  ),
                                ],
                                SizedBox(height: compact ? 9 : 12),
                                Text(
                                  footer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.42),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                    letterSpacing: 0,
                                  ),
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
                      icon: const Icon(LucideIcons.x),
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

  static Color _accentFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.error => const Color(0xFFF8312F),
      AppNotificationTone.warning => const Color(0xFFF8312F),
      AppNotificationTone.success => const Color(0xFFE5E7EB),
      AppNotificationTone.info => const Color(0xFFD4D4D8),
      AppNotificationTone.neutral => const Color(0xFFD4D4D8),
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

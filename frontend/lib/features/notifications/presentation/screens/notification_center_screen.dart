import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/motion/app_motion.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';
import 'package:teste/features/notifications/presentation/notification_navigation.dart';
import 'package:teste/features/notifications/presentation/notification_visuals.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:teste/features/profile/presentation/screens/notification_settings_screen.dart';

Future<void> openNotificationCenter(
  BuildContext context, {
  required GlobalKey originKey,
}) {
  final navigator = Navigator.of(context);
  final overlayObject = navigator.overlay?.context.findRenderObject();
  final overlayBox = overlayObject is RenderBox ? overlayObject : null;
  final originRect =
      _originRectForKey(originKey, overlayBox) ??
      _fallbackOriginRect(MediaQuery.sizeOf(context));

  return navigator.push<void>(_notificationCenterRoute(originRect));
}

Rect? _originRectForKey(GlobalKey key, RenderBox? overlayBox) {
  if (overlayBox == null) {
    return null;
  }

  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }

  final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: overlayBox);
  return topLeft & renderObject.size;
}

Rect _fallbackOriginRect(Size size) {
  const fallbackSize = 42.0;
  return Rect.fromLTWH(
    size.width - fallbackSize - 20,
    48,
    fallbackSize,
    fallbackSize,
  );
}

Route<void> _notificationCenterRoute(Rect originRect) {
  return PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const NotificationCenterScreen();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion = KeroseneMotion.reduceMotion(context);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      if (reduceMotion) {
        return FadeTransition(opacity: curved, child: child);
      }

      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final center = originRect.center;
          final startRadius = math.max(originRect.width, originRect.height) / 2;
          final endRadius = _distanceToFarthestCorner(center, size);
          final radius = startRadius + (endRadius - startRadius) * curved.value;
          final opacity = const Interval(
            0.10,
            0.78,
            curve: Curves.easeOutCubic,
          ).transform(curved.value);

          return ClipPath(
            clipper: _CircularRevealClipper(center: center, radius: radius),
            child: Opacity(opacity: opacity, child: child),
          );
        },
      );
    },
  );
}

double _distanceToFarthestCorner(Offset center, Size size) {
  return [
    Offset.zero,
    Offset(size.width, 0),
    Offset(0, size.height),
    Offset(size.width, size.height),
  ].map((corner) => (corner - center).distance).reduce(math.max);
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _CircularRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  _NotificationCenterFilter _filter = _NotificationCenterFilter.all;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref
            .read(sessionNotificationFeedProvider.notifier)
            .reloadFromServer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final unreadCount = ref.watch(sessionNotificationUnreadCountProvider);
    final filtered = _filteredNotifications(notifications);
    final groups = _groupNotifications(context, filtered);
    final reduceMotion = KeroseneMotion.reduceMotion(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: _animated(
                      const _NotificationCenterHeader(),
                      reduceMotion: reduceMotion,
                      delay: 80,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  sliver: SliverToBoxAdapter(
                    child: _animated(
                      _NotificationFilterBar(
                        selected: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      reduceMotion: reduceMotion,
                      delay: 140,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  sliver: SliverToBoxAdapter(
                    child: _animated(
                      _NotificationCenterActions(
                        unreadCount: unreadCount,
                        totalCount: notifications.length,
                        onMarkAllRead: unreadCount == 0
                            ? null
                            : () => ref
                                  .read(
                                    sessionNotificationFeedProvider.notifier,
                                  )
                                  .markAllRead(),
                        onClear: notifications.isEmpty
                            ? null
                            : () => ref
                                  .read(
                                    sessionNotificationFeedProvider.notifier,
                                  )
                                  .clear(),
                      ),
                      reduceMotion: reduceMotion,
                      delay: 170,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _animated(
                      _NotificationEmptyState(filter: _filter),
                      reduceMotion: reduceMotion,
                      delay: 200,
                    ),
                  )
                else
                  for (final group in groups) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      sliver: SliverToBoxAdapter(
                        child: _animated(
                          Text(
                            group.label,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                          reduceMotion: reduceMotion,
                          delay: 190,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                      sliver: SliverList.separated(
                        itemBuilder: (context, index) {
                          final item = group.items[index];
                          return _animated(
                            _NotificationCenterCard(
                              item: item,
                              onTap: () => _openNotification(item),
                            ),
                            reduceMotion: reduceMotion,
                            delay: 220 + index * 45,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: group.items.length,
                      ),
                    ),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<SessionNotificationItem> _filteredNotifications(
    List<SessionNotificationItem> notifications,
  ) {
    final filtered = switch (_filter) {
      _NotificationCenterFilter.all => List.of(notifications),
      _NotificationCenterFilter.alerts =>
        notifications
            .where((item) => !_isSecurityNotification(context, item))
            .toList(),
      _NotificationCenterFilter.security =>
        notifications
            .where((item) => _isSecurityNotification(context, item))
            .toList(),
    };
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  List<_NotificationDateGroup> _groupNotifications(
    BuildContext context,
    List<SessionNotificationItem> notifications,
  ) {
    final grouped = <String, List<SessionNotificationItem>>{};

    for (final item in notifications) {
      final label = _dateLabel(context, item.timestamp);
      grouped.putIfAbsent(label, () => []).add(item);
    }

    return grouped.entries
        .map((entry) => _NotificationDateGroup(entry.key, entry.value))
        .toList();
  }

  Future<void> _openNotification(SessionNotificationItem item) async {
    await ref.read(sessionNotificationFeedProvider.notifier).markRead(item.id);

    if (!mounted || !item.isActionable) {
      return;
    }

    await NotificationNavigation.openFromContext(context, item);
  }

  Widget _animated(
    Widget child, {
    required bool reduceMotion,
    required int delay,
  }) {
    if (reduceMotion) {
      return child;
    }

    return child
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
          begin: 0.18,
        )
        .slideY(
          begin: 0.035,
          end: 0,
          duration: 360.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

enum _NotificationCenterFilter { all, alerts, security }

class _NotificationDateGroup {
  final String label;
  final List<SessionNotificationItem> items;

  const _NotificationDateGroup(this.label, this.items);
}

class _NotificationCenterHeader extends StatelessWidget {
  const _NotificationCenterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            _copy(
              context,
              pt: 'Notificações',
              en: 'Notifications',
              es: 'Notificaciones',
            ),
            style: GoogleFonts.ibmPlexSerif(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        IconButton(
          tooltip: _copy(
            context,
            pt: 'Configurações',
            en: 'Settings',
            es: 'Configuración',
          ),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          ),
          icon: const Icon(LucideIcons.settings),
          color: Colors.white.withValues(alpha: 0.78),
          iconSize: 18,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            fixedSize: const Size(34, 34),
          ),
        ),
      ],
    );
  }
}

class _NotificationFilterBar extends StatelessWidget {
  final _NotificationCenterFilter selected;
  final ValueChanged<_NotificationCenterFilter> onChanged;

  const _NotificationFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _NotificationFilterChip(
          label: _copy(context, pt: 'Todos', en: 'All', es: 'Todos'),
          icon: null,
          selected: selected == _NotificationCenterFilter.all,
          onTap: () => onChanged(_NotificationCenterFilter.all),
        ),
        _NotificationFilterChip(
          label: _copy(context, pt: 'Avisos', en: 'Alerts', es: 'Avisos'),
          icon: LucideIcons.bell,
          selected: selected == _NotificationCenterFilter.alerts,
          onTap: () => onChanged(_NotificationCenterFilter.alerts),
        ),
        _NotificationFilterChip(
          label: _copy(
            context,
            pt: 'Segurança',
            en: 'Security',
            es: 'Seguridad',
          ),
          icon: LucideIcons.shieldCheck,
          selected: selected == _NotificationCenterFilter.security,
          onTap: () => onChanged(_NotificationCenterFilter.security),
        ),
      ],
    );
  }
}

class _NotificationCenterActions extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onClear;

  const _NotificationCenterActions({
    required this.unreadCount,
    required this.totalCount,
    required this.onMarkAllRead,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = totalCount == 0
        ? _copy(
            context,
            pt: '0 notificações',
            en: '0 notifications',
            es: '0 notificaciones',
          )
        : _copy(
            context,
            pt: '$unreadCount não lidas',
            en: '$unreadCount unread',
            es: '$unreadCount sin leer',
          );

    return Row(
      children: [
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            statusLabel,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        const Spacer(),
        _NotificationActionTextButton(
          label: _copy(
            context,
            pt: 'Ler tudo',
            en: 'Read all',
            es: 'Leer todo',
          ),
          onPressed: onMarkAllRead,
        ),
        const SizedBox(width: 6),
        _NotificationActionTextButton(
          label: _copy(context, pt: 'Limpar', en: 'Clear', es: 'Limpiar'),
          onPressed: onClear,
        ),
      ],
    );
  }
}

class _NotificationActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _NotificationActionTextButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: enabled ? 0.72 : 0.22),
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : Colors.white;

    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: foreground.withValues(alpha: 0.74)),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCenterCard extends StatelessWidget {
  final SessionNotificationItem item;
  final VoidCallback onTap;

  const _NotificationCenterCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visuals = resolveNotificationVisuals(context, item);
    final accent = _accentFor(visuals.tone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(visuals.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _timeLabel(context, item.timestamp),
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.42,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!item.read)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  final _NotificationCenterFilter filter;

  const _NotificationEmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _NotificationCenterFilter.all => _copy(
        context,
        pt: 'Sem notificações',
        en: 'No notifications',
        es: 'Sin notificaciones',
      ),
      _NotificationCenterFilter.alerts => _copy(
        context,
        pt: 'Sem avisos',
        en: 'No alerts',
        es: 'Sin avisos',
      ),
      _NotificationCenterFilter.security => _copy(
        context,
        pt: 'Sem alertas de segurança',
        en: 'No security alerts',
        es: 'Sin alertas de seguridad',
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bellOff,
                color: Colors.white.withValues(alpha: 0.54),
                size: 26,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _copy(
                  context,
                  pt: 'Quando algo importante acontecer, aparece aqui.',
                  en: 'When something important happens, it appears here.',
                  es: 'Cuando ocurra algo importante, aparece aqui.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSecurityNotification(
  BuildContext context,
  SessionNotificationItem item,
) {
  if (item.kind.startsWith('security_')) {
    return true;
  }

  final category = resolveNotificationVisuals(
    context,
    item,
  ).categoryLabel.trim().toLowerCase();
  return category == 'segurança' ||
      category == 'security' ||
      category == 'seguridad';
}

Color _accentFor(AppNotificationTone tone) {
  return switch (tone) {
    AppNotificationTone.success => const Color(0xFF22C55E),
    AppNotificationTone.warning => const Color(0xFFAEB7C1),
    AppNotificationTone.error => const Color(0xFFFF5A67),
    AppNotificationTone.info => const Color(0xFFA7B0BA),
    AppNotificationTone.neutral => const Color(0xFF9CA3AF),
  };
}

String _dateLabel(BuildContext context, DateTime timestamp) {
  final now = DateTime.now();
  final today = DateUtils.dateOnly(now);
  final date = DateUtils.dateOnly(timestamp);

  if (date == today) {
    return _copy(context, pt: 'Hoje', en: 'Today', es: 'Hoy');
  }
  if (date == today.subtract(const Duration(days: 1))) {
    return _copy(context, pt: 'Ontem', en: 'Yesterday', es: 'Ayer');
  }
  return MaterialLocalizations.of(context).formatMediumDate(timestamp);
}

String _timeLabel(BuildContext context, DateTime timestamp) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(timestamp),
    alwaysUse24HourFormat:
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}

String _copy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}

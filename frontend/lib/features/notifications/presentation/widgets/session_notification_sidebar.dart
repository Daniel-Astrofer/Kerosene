import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/presentation/widgets/push_notification_card.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/notifications/presentation/notification_navigation.dart';
import 'package:teste/features/notifications/presentation/notification_visuals.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';

class SessionNotificationSidebar extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool showCloseButton;

  const SessionNotificationSidebar({
    super.key,
    this.onClose,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final unreadCount = ref.watch(sessionNotificationUnreadCountProvider);
    final headerTitle = _copy(
      context,
      pt: 'Notificações',
      en: 'Push notifications',
      es: 'Notificaciones',
    );
    final headerSubtitle = _copy(
      context,
      pt: 'Alertas recentes da sessão.',
      en: 'Recent session alerts.',
      es: 'Alertas recientes de la sesión.',
    );
    final clearLabel = _copy(
      context,
      pt: 'Limpar',
      en: 'Clear',
      es: 'Limpiar',
    );
    final emptyStateTitle = _copy(
      context,
      pt: 'Sem alertas',
      en: 'No alerts',
      es: 'Sin alertas',
    );
    final emptyStateMessage = _copy(
      context,
      pt: 'Quando algo importante acontecer, a notificação aparece aqui.',
      en: 'When something important happens, the notification appears here.',
      es: 'Cuando ocurra algo importante, la notificacion aparece aqui.',
    );
    final alertLabel = _copy(
      context,
      pt: unreadCount == 1 ? 'não lida' : 'não lidas',
      en: unreadCount == 1 ? 'unread' : 'unread',
      es: unreadCount == 1 ? 'sin leer' : 'sin leer',
    );

    return Container(
      width: 336,
      decoration: BoxDecoration(
        color: const Color(0xFF050607),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFFF2F4F5),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          headerSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.46),
                            fontSize: 12,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      color: Colors.white.withValues(alpha: 0.68),
                      iconSize: 17,
                      style: IconButton.styleFrom(
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1014),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      '$unreadCount $alertLabel',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: unreadCount == 0
                        ? null
                        : () => ref
                            .read(sessionNotificationFeedProvider.notifier)
                            .markAllRead(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(
                        alpha: unreadCount == 0 ? 0.22 : 0.7,
                      ),
                      shape: const RoundedRectangleBorder(),
                      textStyle: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(_copy(
                      context,
                      pt: 'Ler tudo',
                      en: 'Read all',
                      es: 'Leer todo',
                    )),
                  ),
                  TextButton(
                    onPressed: notifications.isEmpty
                        ? null
                        : () => ref
                            .read(sessionNotificationFeedProvider.notifier)
                            .clear(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(
                        alpha: notifications.isEmpty ? 0.22 : 0.7,
                      ),
                      shape: const RoundedRectangleBorder(),
                      textStyle: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(clearLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppNotificationSurface(
                          title: emptyStateTitle,
                          message: emptyStateMessage,
                          tone: AppNotificationTone.neutral,
                          showLeadingIcon: false,
                          borderRadius: 0,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          maxMessageLines: 2,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final visuals =
                            resolveNotificationVisuals(context, item);
                        return Container(
                          decoration: BoxDecoration(
                            border: item.read
                                ? null
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                          ),
                          child: Stack(
                            children: [
                              PushNotificationCard(
                                title: item.title,
                                message: item.body,
                                footerLabel: buildNotificationFooterLabel(
                                  context,
                                  item,
                                  _footerLabel(context, item.timestamp),
                                ),
                                tone: visuals.tone,
                                leadingIcon: visuals.icon,
                                padding:
                                    const EdgeInsets.fromLTRB(14, 13, 14, 13),
                                borderRadius: 0,
                                maxMessageLines: 3,
                                onTap: () {
                                  ref
                                      .read(
                                        sessionNotificationFeedProvider.notifier,
                                      )
                                      .markRead(item.id);

                                  if (item.isActionable) {
                                    onClose?.call();
                                    NotificationNavigation.openFromContext(
                                      context,
                                      item,
                                    );
                                  }
                                },
                              ),
                              if (!item.read)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4C430),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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

  String _footerLabel(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return _copy(context, pt: 'Agora', en: 'Now', es: 'Ahora');
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    }
    if (DateUtils.isSameDay(now, timestamp)) {
      return MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(timestamp),
        alwaysUse24HourFormat:
            MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
      );
    }

    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

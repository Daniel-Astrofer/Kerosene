import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/services/balance_websocket_service.dart';
import 'package:teste/core/services/notification_orchestrator.dart';
import 'package:teste/features/web_admin/theme/admin_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

final notificationsListProvider =
    FutureProvider.autoDispose<List<RealtimeNotificationEvent>>((ref) async {
  final orchestrator = ref.watch(notificationOrchestratorProvider);
  return orchestrator.getInbox();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications Inbox',
          style: TextStyle(
            fontFamily: 'IBMPlexSansHebrew',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AdminColors.textSecondary),
            onPressed: () {
              ref.invalidate(notificationsListProvider);
            },
          ),
        ],
      ),
      body: state.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications found.',
                style: TextStyle(color: AdminColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationCard(notification: n);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load notifications: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final RealtimeNotificationEvent notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color severityColor;
    IconData icon;

    switch (notification.severity) {
      case 'success':
        severityColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'warning':
        severityColor = Colors.orangeAccent;
        icon = Icons.warning_amber_outlined;
        break;
      case 'error':
        severityColor = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      default:
        severityColor = Colors.blueAccent;
        icon = Icons.info_outline;
    }

    return Card(
      color: AdminColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: severityColor.withValues(alpha: 0.1),
          child: Icon(icon, color: severityColor),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: const TextStyle(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  timeago.format(notification.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                ),
                if (notification.kind.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.kind,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'IBMPlexSansHebrew',
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check, color: AdminColors.textSecondary),
          tooltip: 'Mark as read',
          onPressed: () async {
            await ref
                .read(notificationOrchestratorProvider)
                .markAsRead(notification.id);
            ref.invalidate(notificationsListProvider);
          },
        ),
      ),
    );
  }
}

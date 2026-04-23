import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';

class SessionNotificationFeedNotifier
    extends Notifier<List<SessionNotificationItem>> {
  static const int _maxItems = 30;

  @override
  List<SessionNotificationItem> build() => const [];

  void add(SessionNotificationItem item) {
    state = [
      item,
      ...state.where(
        (existing) =>
            existing.id != item.id && existing.dedupeKey != item.dedupeKey,
      ),
    ].take(_maxItems).toList();
  }

  void clear() {
    state = const [];
  }
}

class NotificationSidebarNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void open() => state = true;

  void close() => state = false;
}

final sessionNotificationFeedProvider = NotifierProvider<
    SessionNotificationFeedNotifier, List<SessionNotificationItem>>(
  SessionNotificationFeedNotifier.new,
);

final notificationSidebarProvider =
    NotifierProvider<NotificationSidebarNotifier, bool>(
  NotificationSidebarNotifier.new,
);

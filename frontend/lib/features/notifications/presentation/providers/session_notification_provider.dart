import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:teste/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';
import 'package:teste/features/notifications/domain/repositories/notification_repository.dart';

class SessionNotificationFeedNotifier
    extends Notifier<List<SessionNotificationItem>> {
  static const int _maxItems = 50;
  static const String _storageKeyBase = 'session_notification_feed_v2';
  String? _activeStorageKey;

  @override
  List<SessionNotificationItem> build() {
    final authState = ref.watch(authControllerProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    if (userId == null || userId.trim().isEmpty) {
      _activeStorageKey = null;
      return const [];
    }

    final nextStorageKey = '$_storageKeyBase-$userId';
    if (_activeStorageKey != nextStorageKey) {
      _activeStorageKey = nextStorageKey;
      unawaited(_hydrate(nextStorageKey));
    }

    return state;
  }

  void add(SessionNotificationItem item) {
    _replaceState(_merge([item], state));
  }

  Future<void> reloadFromServer() async {
    final result =
        await ref.read(notificationRepositoryProvider).getNotifications();
    result.fold(
      (_) {},
      (items) => _replaceState(_merge(items, state)),
    );
  }

  Future<void> markRead(String notificationId) async {
    final current = state;
    final index = current.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      return;
    }

    final target = current[index];
    if (target.read) {
      return;
    }

    final updated = [...current];
    updated[index] = target.copyWith(read: true);
    _replaceState(updated);

    if (target.canSyncRead) {
      unawaited(
          ref.read(notificationRepositoryProvider).markAsRead(notificationId));
    }
  }

  Future<void> markAllRead() async {
    final unreadIds =
        state.where((item) => !item.read).map((item) => item.id).toList();
    if (unreadIds.isEmpty) {
      return;
    }

    _replaceState(
      state.map((item) => item.copyWith(read: true)).toList(),
    );

    unawaited(_syncMarkAllRead(unreadIds));
  }

  void clear() {
    _replaceState(const []);
  }

  Future<void> _hydrate(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getStringList(storageKey) ?? const <String>[];

    final localItems = persisted
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .map(SessionNotificationItem.fromJson)
        .toList();

    if (_activeStorageKey == storageKey) {
      _replaceState(_merge(localItems, const []), persist: false);
      await reloadFromServer();
    }
  }

  Future<void> _persist() async {
    final storageKey = _activeStorageKey;
    if (storageKey == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      storageKey,
      state.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _syncMarkAllRead(List<String> ids) async {
    for (final id in ids) {
      if (int.tryParse(id) == null) {
        continue;
      }
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    }
  }

  void _replaceState(
    List<SessionNotificationItem> nextState, {
    bool persist = true,
  }) {
    state = [...nextState]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (state.length > _maxItems) {
      state = state.take(_maxItems).toList();
    }

    if (persist) {
      unawaited(_persist());
    }
  }

  List<SessionNotificationItem> _merge(
    List<SessionNotificationItem> incoming,
    List<SessionNotificationItem> current,
  ) {
    final merged = <String, SessionNotificationItem>{};

    for (final item in [...incoming, ...current]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))) {
      final key = item.dedupeKey;
      final existing = merged[key];

      if (existing == null) {
        merged[key] = item;
        continue;
      }

      final latest =
          item.timestamp.isAfter(existing.timestamp) ? item : existing;
      merged[key] = latest.copyWith(
        read: item.read || existing.read,
        metadata: {
          ...existing.metadata,
          ...item.metadata,
        },
      );
    }

    return merged.values.toList();
  }
}

class NotificationSidebarNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void open() => state = true;

  void close() => state = false;
}

class NotificationBannerNotifier extends Notifier<SessionNotificationItem?> {
  Timer? _dismissTimer;

  @override
  SessionNotificationItem? build() {
    ref.onDispose(() => _dismissTimer?.cancel());
    return null;
  }

  void show(SessionNotificationItem notification) {
    _dismissTimer?.cancel();
    state = notification;
    _dismissTimer = Timer(const Duration(seconds: 6), dismiss);
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    state = null;
  }

  void openSidebar() {
    dismiss();
    ref.read(notificationSidebarProvider.notifier).open();
  }
}

final sessionNotificationFeedProvider = NotifierProvider<
    SessionNotificationFeedNotifier, List<SessionNotificationItem>>(
  SessionNotificationFeedNotifier.new,
);

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRemoteDataSourceImpl(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final sessionNotificationUnreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(sessionNotificationFeedProvider);
  return notifications.where((item) => !item.read).length;
});

final notificationSidebarProvider =
    NotifierProvider<NotificationSidebarNotifier, bool>(
  NotificationSidebarNotifier.new,
);

final notificationBannerProvider =
    NotifierProvider<NotificationBannerNotifier, SessionNotificationItem?>(
  NotificationBannerNotifier.new,
);

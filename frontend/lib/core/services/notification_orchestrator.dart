import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/network/api_client.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/core/services/balance_websocket_service.dart';

final notificationOrchestratorProvider =
    Provider<NotificationOrchestrator>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationOrchestrator(apiClient: apiClient);
});

class NotificationOrchestrator {
  final ApiClient apiClient;
  static const String _storageKey = 'local_notifications_inbox';

  NotificationOrchestrator({required this.apiClient});

  Future<List<RealtimeNotificationEvent>> getInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedStr = prefs.getString(_storageKey);
      List<RealtimeNotificationEvent> localList = [];

      if (storedStr != null && storedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storedStr);
        localList = decoded
            .map((e) =>
                RealtimeNotificationEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Sync with backend if possible
      try {
        final response = await apiClient.get(AppConfig.notificationsList);
        if (response.statusCode == 200 && response.data is List) {
          final backendList = (response.data as List)
              .map((e) =>
                  RealtimeNotificationEvent.fromJson(e as Map<String, dynamic>))
              .toList();

          // Merge lists keeping backend as truth, fallback to local
          localList = _mergeNotifications(localList, backendList);
          await _saveInbox(localList);
        }
      } catch (e) {
        debugPrint('Failed to sync notifications from backend: $e');
      }

      return localList..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading local notifications inbox: $e');
      return [];
    }
  }

  List<RealtimeNotificationEvent> _mergeNotifications(
      List<RealtimeNotificationEvent> local,
      List<RealtimeNotificationEvent> backend) {
    final map = <String, RealtimeNotificationEvent>{};
    for (var n in local) {
      map[n.id] = n;
    }
    for (var n in backend) {
      map[n.id] = n;
    }
    return map.values.toList();
  }

  Future<void> _saveInbox(List<RealtimeNotificationEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list
        .map((n) => {
              'id': n.id,
              'kind': n.kind,
              'severity': n.severity,
              'title': n.title,
              'body': n.body,
              'timestamp': n.timestamp.toIso8601String(),
              'deeplink': n.deeplink,
              'entityType': n.entityType,
              'entityId': n.entityId,
              'metadata': n.metadata,
            })
        .toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> saveRealtimeNotification(RealtimeNotificationEvent event) async {
    final list = await getInbox();
    if (!list.any((e) => e.id == event.id)) {
      list.add(event);
      await _saveInbox(list);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await apiClient.put(AppConfig.notificationsRead.replaceAll('{id}', id));
    } catch (e) {
      debugPrint('Failed to mark notification as read on backend: $e');
    }
  }
}

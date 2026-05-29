import 'package:flutter/material.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';

class NotificationNavigation {
  static Future<void> openFromContext(
    BuildContext context,
    SessionNotificationItem notification,
  ) {
    return openWithNavigator(notification, Navigator.of(context));
  }

  static Future<void> openWithNavigator(
    SessionNotificationItem notification,
    NavigatorState navigator,
  ) async {
    final route = notification.deeplink?.trim();
    if (route == null || route.isEmpty) {
      return;
    }

    try {
      await navigator.pushNamed(route);
    } catch (error) {
      debugPrint('Could not open notification deeplink "$route": $error');
    }
  }
}

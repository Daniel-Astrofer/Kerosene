import 'package:flutter/material.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';
import '../presentation/widgets/app_notice.dart';

class SnackbarHelper {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showError(String message, {String? title}) {
    _showNotice(
      message: message,
      title: title,
      type: AppNoticeType.error,
    );
  }

  static void showSuccess(String message, {String? title}) {
    _showNotice(
      message: message,
      title: title,
      type: AppNoticeType.success,
    );
  }

  static void showInfo(String message, {String? title}) {
    _showNotice(
      message: message,
      title: title,
      type: AppNoticeType.info,
    );
  }

  static void showPushNotification(SessionNotificationItem notification) {
    debugPrint(
      'SnackbarHelper.showPushNotification is deprecated. '
      'Use notificationBannerProvider instead. Message: ${notification.body}',
    );
  }

  static void showWarning(String message, {String? title}) {
    _showNotice(
      message: message,
      title: title,
      type: AppNoticeType.warning,
    );
  }

  static void _showNotice({
    required String message,
    required AppNoticeType type,
    String? title,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint(
        'Cannot show notice: ScaffoldMessenger is null. Message: $message',
      );
      return;
    }

    AppNotice.showOn(
      messenger,
      type: type,
      title: title,
      message: message,
    );
  }
}

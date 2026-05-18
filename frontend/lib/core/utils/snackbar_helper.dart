import 'package:flutter/material.dart';
import 'package:teste/features/notifications/domain/entities/session_notification_item.dart';
import 'package:teste/features/notifications/presentation/notification_navigation.dart';
import 'package:teste/features/notifications/presentation/notification_visuals.dart';
import '../presentation/widgets/app_notice.dart';
import '../presentation/widgets/push_notification_card.dart';

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
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint(
        'Cannot show push notification: ScaffoldMessenger is null. Message: ${notification.body}',
      );
      return;
    }

    final context = messenger.context;
    final bottomInset = MediaQuery.maybeOf(context)?.viewPadding.bottom ?? 0;
    final visuals = resolveNotificationVisuals(context, notification);
    final footerLabel = buildNotificationFooterLabel(
      context,
      notification,
      _localizedNow(context),
    );

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
        padding: EdgeInsets.zero,
        content: PushNotificationCard(
          title: notification.title,
          message: notification.body,
          footerLabel: footerLabel,
          tone: visuals.tone,
          leadingIcon: visuals.icon,
          maxMessageLines: 3,
          onClose: messenger.hideCurrentSnackBar,
          onTap: notification.isActionable
              ? () {
                  messenger.hideCurrentSnackBar();
                  final navigator = navigatorKey.currentState;
                  if (navigator != null) {
                    NotificationNavigation.openWithNavigator(
                      notification,
                      navigator,
                    );
                  }
                }
              : null,
        ),
      ),
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
}

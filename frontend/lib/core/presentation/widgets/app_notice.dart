import 'package:flutter/material.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';

enum AppNoticeType { success, error, info, warning }

class AppNotice {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      type: AppNoticeType.success,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      type: AppNoticeType.error,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      type: AppNoticeType.info,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      type: AppNoticeType.warning,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required AppNoticeType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    showOn(
      messenger,
      type: type,
      message: message,
      title: title,
      duration: duration,
    );
  }

  static void showOn(
    ScaffoldMessengerState messenger, {
    required AppNoticeType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = messenger.context;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      _buildSnackBar(
        context,
        type: type,
        message: message,
        title: title,
        duration: duration,
        onClose: messenger.hideCurrentSnackBar,
      ),
    );
  }

  static SnackBar _buildSnackBar(
    BuildContext context, {
    required AppNoticeType type,
    required String message,
    String? title,
    required Duration duration,
    VoidCallback? onClose,
  }) {
    final bottomInset = MediaQuery.maybeOf(context)?.viewPadding.bottom ?? 0;

    return SnackBar(
      duration: duration,
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
      padding: EdgeInsets.zero,
      content: AppNotificationSurface(
        tone: _toneFor(type),
        title: title ?? _defaultTitle(context, type),
        message: message,
        onClose: onClose,
      ),
    );
  }

  static AppNotificationTone _toneFor(AppNoticeType type) {
    return switch (type) {
      AppNoticeType.success => AppNotificationTone.success,
      AppNoticeType.error => AppNotificationTone.error,
      AppNoticeType.info => AppNotificationTone.info,
      AppNoticeType.warning => AppNotificationTone.warning,
    };
  }

  static String _defaultTitle(BuildContext context, AppNoticeType type) {
    final languageCode = Localizations.localeOf(context).languageCode;

    switch (type) {
      case AppNoticeType.success:
        return languageCode == 'pt'
            ? 'Tudo certo'
            : languageCode == 'es'
                ? 'Todo listo'
                : 'All set';
      case AppNoticeType.error:
        return languageCode == 'pt'
            ? 'Não foi possível concluir'
            : languageCode == 'es'
                ? 'No fue posible completar'
                : 'Could not complete';
      case AppNoticeType.info:
        return languageCode == 'pt'
            ? 'Aviso'
            : languageCode == 'es'
                ? 'Aviso'
                : 'Notice';
      case AppNoticeType.warning:
        return languageCode == 'pt'
            ? 'Atenção'
            : languageCode == 'es'
                ? 'Atención'
                : 'Attention';
    }
  }
}

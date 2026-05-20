import 'dart:async';

import 'package:flutter/material.dart';

enum AppNoticeType { success, error, info, warning }

class AppScreenFeedbackMessage {
  final int sequence;
  final AppNoticeType type;
  final String title;
  final String message;

  const AppScreenFeedbackMessage({
    required this.sequence,
    required this.type,
    required this.title,
    required this.message,
  });
}

class AppScreenFeedbackBus {
  static final ValueNotifier<AppScreenFeedbackMessage?> current =
      ValueNotifier<AppScreenFeedbackMessage?>(null);

  static int _nextSequence = 0;
  static Timer? _timer;

  static void show({
    required AppNoticeType type,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _timer?.cancel();
    final next = AppScreenFeedbackMessage(
      sequence: ++_nextSequence,
      type: type,
      title: title,
      message: message,
    );
    current.value = next;

    if (duration > Duration.zero) {
      _timer = Timer(duration, () => clear(sequence: next.sequence));
    }
  }

  static void clear({int? sequence}) {
    if (sequence != null && current.value?.sequence != sequence) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    current.value = null;
  }
}

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
    AppScreenFeedbackBus.show(
      type: type,
      title: title ?? _defaultTitle(context, type),
      message: message,
      duration: duration,
    );
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

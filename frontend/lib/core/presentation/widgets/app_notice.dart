import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';

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
    Duration duration = KeroseneMotion.noticeHold,
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
    Duration duration = KeroseneMotion.noticeHold,
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
    Duration duration = KeroseneMotion.noticeExtendedHold,
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
    Duration duration = KeroseneMotion.noticeHold,
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
    Duration duration = KeroseneMotion.noticeExtendedHold,
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
    Duration duration = KeroseneMotion.noticeHold,
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
    Duration duration = KeroseneMotion.noticeHold,
  }) {
    final context = messenger.context;
    final defaultTitle = _defaultTitle(context, type);
    AppScreenFeedbackBus.show(
      type: type,
      title: _cleanNoticeText(
        title ?? defaultTitle,
        fallback: defaultTitle,
        maxLength: 72,
      ),
      message: _cleanNoticeText(
        message,
        fallback: _fallbackMessage(context, type),
        maxLength: 180,
      ),
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

  static String _fallbackMessage(BuildContext context, AppNoticeType type) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (type == AppNoticeType.success) {
      return languageCode == 'pt'
          ? 'Operação concluída.'
          : languageCode == 'es'
              ? 'Operación completada.'
              : 'Operation completed.';
    }

    if (type == AppNoticeType.info) {
      return languageCode == 'pt'
          ? 'Atualização recebida.'
          : languageCode == 'es'
              ? 'Actualización recibida.'
              : 'Update received.';
    }

    return languageCode == 'pt'
        ? 'Não conseguimos concluir agora. Tente novamente em instantes.'
        : languageCode == 'es'
            ? 'No pudimos completar la acción ahora. Inténtalo de nuevo en unos instantes.'
            : 'We could not complete this right now. Try again shortly.';
  }

  static String _cleanNoticeText(
    String value, {
    required String fallback,
    required int maxLength,
  }) {
    var text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text
        .replaceFirst(
          RegExp(
            r'^(ServerException|ValidationException|AuthException|NetworkException|AppException|Exception|Erro):\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (text.isEmpty || _looksTechnical(text)) {
      return fallback;
    }

    if (text.length <= maxLength) {
      return text;
    }

    final end = (maxLength - 3).clamp(0, text.length).toInt();
    return '${text.substring(0, end).trimRight()}...';
  }

  static bool _looksTechnical(String value) {
    final lower = value.toLowerCase();
    final technicalPattern = RegExp(
      r'(statuscode|status code|status_code|status=|http\s*\d{3}|errorcode|error code|error_code|dioexception|serverexception|validationexception|authexception|appexception|stack trace|traceback|requestoptions|response\.data|/api/|<!doctype html|<html|socketexception|handshakeexception|xmlhttprequest)',
      caseSensitive: false,
    );

    if (technicalPattern.hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\bERR_[A-Z0-9_]+\b').hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\b[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+\b').hasMatch(value)) {
      return true;
    }

    if (RegExp(r'\b[45]\d{2}\b').hasMatch(value) &&
        (lower.contains('http') ||
            lower.contains('status') ||
            lower.contains('code'))) {
      return true;
    }

    return value.length > 220 && RegExp(r'[{}\[\]"]|=>|#\d+').hasMatch(value);
  }
}

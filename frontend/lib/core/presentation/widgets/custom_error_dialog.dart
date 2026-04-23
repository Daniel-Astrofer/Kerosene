import 'package:flutter/material.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/l10n/app_localizations.dart';

void showCustomErrorDialog(
  BuildContext context,
  String message, {
  String title = 'ERRO',
  VoidCallback? onRetry,
  VoidCallback? onGoBack,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CustomErrorDialog(
      title: title,
      message: message,
      onRetry: onRetry,
      onGoBack: onGoBack,
    ),
  );
}

class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const CustomErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final config = _DialogConfig.fromMessage(context, message, title);
    final l10n = AppLocalizations.of(context)!;
    final actions = <AppNotificationAction>[
      if (onRetry != null)
        AppNotificationAction(
          label: _titleCase(l10n.retry),
          icon: Icons.refresh_rounded,
          onPressed: () {
            Navigator.pop(context);
            onRetry!();
          },
        ),
      if (onGoBack != null)
        AppNotificationAction(
          label: _titleCase(l10n.goBack),
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            Navigator.pop(context);
            onGoBack!();
          },
        ),
      if (onRetry == null && onGoBack == null)
        AppNotificationAction(
          label: _acknowledgeLabel(context),
          onPressed: () => Navigator.pop(context),
        ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: AppNotificationSurface(
        title: config.title,
        message: message,
        tone: config.tone,
        maxMessageLines: 4,
        onClose: () => Navigator.pop(context),
        actions: actions,
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _acknowledgeLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'pt') {
      return 'Entendi';
    }
    if (languageCode == 'es') {
      return 'Entendido';
    }
    return 'Understood';
  }
}

class _DialogConfig {
  final String title;
  final AppNotificationTone tone;

  const _DialogConfig({
    required this.title,
    required this.tone,
  });

  factory _DialogConfig.fromMessage(
    BuildContext context,
    String message,
    String fallbackTitle,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final lower = message.toLowerCase();

    if (_containsAny(lower, [
      'server',
      'servidor',
      'network',
      'rede',
      'timeout',
      'connection',
      'conex',
      'offline',
    ])) {
      return _DialogConfig(
        title: _resolveLabel(
          languageCode,
          pt: 'Não foi possível falar com o servidor',
          en: 'Could not reach the server',
          es: 'No fue posible conectar con el servidor',
        ),
        tone: AppNotificationTone.warning,
      );
    }

    if (_containsAny(lower, [
      'password',
      'senha',
      'passphrase',
      'totp',
      'token',
      'auth',
      'autent',
      'passkey',
      'código',
      'codigo',
    ])) {
      return _DialogConfig(
        title: _resolveLabel(
          languageCode,
          pt: 'Não foi possível validar o acesso',
          en: 'Could not validate access',
          es: 'No fue posible validar el acceso',
        ),
        tone: AppNotificationTone.error,
      );
    }

    if (_containsAny(lower, [
      'insufficient',
      'insuficiente',
      'limit',
      'limite',
      'saldo',
      'balance',
    ])) {
      return _DialogConfig(
        title: _resolveLabel(
          languageCode,
          pt: 'Revise os valores antes de continuar',
          en: 'Please review the amounts',
          es: 'Revisa los importes antes de continuar',
        ),
        tone: AppNotificationTone.warning,
      );
    }

    final title = fallbackTitle.toUpperCase() == 'ERRO'
        ? _resolveLabel(
            languageCode,
            pt: 'Não foi possível concluir esta ação',
            en: 'Could not complete this action',
            es: 'No fue posible completar esta acción',
          )
        : fallbackTitle;

    return _DialogConfig(
      title: title,
      tone: AppNotificationTone.error,
    );
  }

  static bool _containsAny(String message, List<String> values) {
    for (final value in values) {
      if (message.contains(value)) {
        return true;
      }
    }
    return false;
  }

  static String _resolveLabel(
    String languageCode, {
    required String pt,
    required String en,
    required String es,
  }) {
    if (languageCode == 'es') {
      return es;
    }
    if (languageCode == 'en') {
      return en;
    }
    return pt;
  }
}

import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/presentation/widgets/animated_notice_icon.dart';

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
      ),
    );
  }

  static SnackBar _buildSnackBar(
    BuildContext context, {
    required AppNoticeType type,
    required String message,
    String? title,
    required Duration duration,
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
      content: _NoticeCard(
        type: type,
        title: title ?? _defaultTitle(context, type),
        message: message,
      ),
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

class _NoticeCard extends StatelessWidget {
  final AppNoticeType type;
  final String title;
  final String message;

  const _NoticeCard({
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final config = _NoticeConfig.fromType(type);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101217),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: config.color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: config.color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: config.color.withValues(alpha: 0.22)),
              ),
              child: Center(
                child: AnimatedNoticeIcon(
                  kind: config.iconKind,
                  color: config.color,
                  size: 22,
                  strokeWidth: 2.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeConfig {
  final Color color;
  final AnimatedNoticeIconKind iconKind;

  const _NoticeConfig({
    required this.color,
    required this.iconKind,
  });

  factory _NoticeConfig.fromType(AppNoticeType type) {
    switch (type) {
      case AppNoticeType.success:
        return const _NoticeConfig(
          color: AppColors.success,
          iconKind: AnimatedNoticeIconKind.success,
        );
      case AppNoticeType.error:
        return const _NoticeConfig(
          color: AppColors.error,
          iconKind: AnimatedNoticeIconKind.error,
        );
      case AppNoticeType.info:
        return const _NoticeConfig(
          color: AppColors.secondary,
          iconKind: AnimatedNoticeIconKind.info,
        );
      case AppNoticeType.warning:
        return const _NoticeConfig(
          color: AppColors.warning,
          iconKind: AnimatedNoticeIconKind.warning,
        );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_typography.dart';

enum AppNotificationTone { neutral, success, error, info, warning }

class AppNotificationAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const AppNotificationAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });
}

class AppNotificationStyle {
  static const Color surfaceColor = Color(0xFF151A21);
  static const Color borderColor = Color(0xFF2A323D);
  static const Color buttonColor = Color(0xFF252C35);
  static const Color closeButtonColor = Color(0xFF303844);
  static const Color titleColor = Color(0xFFF5F7FB);
  static const Color bodyColor = Color(0xFFD9DEE8);
  static const Color metaColor = Color(0xFFB7BEC9);

  static Color accentFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.success => const Color(0xFF26E88D),
      AppNotificationTone.error => const Color(0xFFFF6D7A),
      AppNotificationTone.warning => const Color(0xFFFF9F43),
      AppNotificationTone.info => const Color(0xFFEAF0F7),
      AppNotificationTone.neutral => const Color(0xFFDDE3EC),
    };
  }

  static IconData iconFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.success => Icons.check_circle_rounded,
      AppNotificationTone.error => Icons.error_rounded,
      AppNotificationTone.warning => Icons.warning_rounded,
      AppNotificationTone.info => Icons.info_rounded,
      AppNotificationTone.neutral => Icons.notifications_rounded,
    };
  }
}

class AppNotificationSurface extends StatelessWidget {
  final String title;
  final String? message;
  final AppNotificationTone tone;
  final VoidCallback? onClose;
  final List<AppNotificationAction> actions;
  final String? footerLabel;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? minHeight;
  final int maxMessageLines;
  final bool showLeadingIcon;

  const AppNotificationSurface({
    super.key,
    required this.title,
    this.message,
    this.tone = AppNotificationTone.neutral,
    this.onClose,
    this.actions = const [],
    this.footerLabel,
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 14, 14),
    this.borderRadius = 14,
    this.minHeight,
    this.maxMessageLines = 3,
    this.showLeadingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTitle =
        _normalize(title, fallback: _fallbackTitle(context));
    final normalizedMessage = _normalize(message ?? '', fallback: '');
    final normalizedFooter = _normalize(footerLabel ?? '', fallback: '');
    final accent = AppNotificationStyle.accentFor(tone);

    return Container(
      constraints:
          minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
      decoration: BoxDecoration(
        color: AppNotificationStyle.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppNotificationStyle.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showLeadingIcon) ...[
                  Icon(
                    leadingIcon ?? AppNotificationStyle.iconFor(tone),
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    normalizedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppNotificationStyle.titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 10),
                  _NotificationCloseButton(onPressed: onClose!),
                ],
              ],
            ),
            if (normalizedMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                normalizedMessage,
                maxLines: maxMessageLines,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppNotificationStyle.bodyColor,
                  fontSize: 14,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ],
            if (actions.isNotEmpty || normalizedFooter.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (actions.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final action in actions)
                            _NotificationActionButton(action: action),
                        ],
                      ),
                    )
                  else
                    const Spacer(),
                  if (normalizedFooter.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      normalizedFooter,
                      style: AppTypography.caption.copyWith(
                        color: AppNotificationStyle.metaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _normalize(String value, {required String fallback}) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.isEmpty ? fallback : collapsed;
  }

  static String _fallbackTitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return 'Update';
      case 'es':
        return 'Actualizacion';
      default:
        return 'Atualização';
    }
  }
}

class _NotificationCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NotificationCloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
        color: Colors.white.withValues(alpha: 0.86),
        iconSize: 15,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppNotificationStyle.closeButtonColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  final AppNotificationAction action;

  const _NotificationActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final child = action.icon == null
        ? Text(action.label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon!, size: 14),
              const SizedBox(width: 6),
              Text(action.label),
            ],
          );

    return TextButton(
      onPressed: action.onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: Colors.white.withValues(alpha: 0.92),
        backgroundColor: AppNotificationStyle.buttonColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: AppTypography.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      child: child,
    );
  }
}

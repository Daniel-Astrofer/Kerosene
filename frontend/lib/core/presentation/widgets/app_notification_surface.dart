import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';

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
  static const Color surfaceColor = KeroseneBrandTokens.surface;
  static const Color borderColor = KeroseneBrandTokens.border;
  static const Color buttonColor = KeroseneBrandTokens.surfaceHigh;
  static const Color closeButtonColor = KeroseneBrandTokens.surfaceElevated;
  static const Color titleColor = KeroseneBrandTokens.textPrimary;
  static const Color bodyColor = KeroseneBrandTokens.textSecondary;
  static const Color metaColor = KeroseneBrandTokens.textMuted;

  static Color accentFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.success => KeroseneBrandTokens.success,
      AppNotificationTone.error => KeroseneBrandTokens.error,
      AppNotificationTone.warning => KeroseneBrandTokens.warning,
      AppNotificationTone.info => KeroseneBrandTokens.info,
      AppNotificationTone.neutral => KeroseneBrandTokens.textSecondary,
    };
  }

  static IconData iconFor(AppNotificationTone tone) {
    return switch (tone) {
      AppNotificationTone.success => KeroseneIcons.success,
      AppNotificationTone.error => KeroseneIcons.error,
      AppNotificationTone.warning => KeroseneIcons.warning,
      AppNotificationTone.info => KeroseneIcons.info,
      AppNotificationTone.neutral => KeroseneIcons.pending,
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
    this.borderRadius = 0,
    this.minHeight,
    this.maxMessageLines = 3,
    this.showLeadingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = _normalize(
      title,
      fallback: _fallbackTitle(context),
    );
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
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 6),
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
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: KeroseneBrandTokens.surfaceMuted,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      leadingIcon ?? AppNotificationStyle.iconFor(tone),
                      color: accent,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    normalizedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppNotificationStyle.titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: 0,
                      decoration: TextDecoration.none,
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
                  fontSize: 13,
                  height: 1.42,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
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
                    Flexible(
                      child: Text(
                        normalizedFooter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.caption.copyWith(
                          color: AppNotificationStyle.metaColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
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
        icon: const Icon(KeroseneIcons.close),
        color: Colors.white.withValues(alpha: 0.86),
        iconSize: 15,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppNotificationStyle.closeButtonColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(),
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
        ? Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon!, size: 14),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        shape: const RoundedRectangleBorder(),
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

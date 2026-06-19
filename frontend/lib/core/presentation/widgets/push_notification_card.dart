import 'package:flutter/material.dart';
import 'package:kerosene/core/presentation/widgets/app_notification_surface.dart';
import 'package:kerosene/design_system/icons.dart';

class PushNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String footerLabel;
  final AppNotificationTone tone;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;
  final int? maxMessageLines;
  final double borderRadius;
  final double? minHeight;
  final VoidCallback? onClose;
  final VoidCallback? onTap;

  const PushNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.footerLabel,
    this.tone = AppNotificationTone.neutral,
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 14, 14),
    this.maxMessageLines = 3,
    this.borderRadius = 0,
    this.minHeight,
    this.onClose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = AppNotificationSurface(
      title: title,
      message: message,
      footerLabel: footerLabel,
      tone: tone,
      leadingIcon: leadingIcon ?? KeroseneIcons.info,
      padding: padding,
      borderRadius: borderRadius,
      minHeight: minHeight,
      maxMessageLines: maxMessageLines ?? 3,
      onClose: onClose,
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

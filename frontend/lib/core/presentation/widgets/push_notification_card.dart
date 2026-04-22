import 'package:flutter/material.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';

class PushNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String footerLabel;
  final EdgeInsetsGeometry padding;
  final int? maxMessageLines;
  final double borderRadius;
  final double? minHeight;
  final VoidCallback? onClose;

  const PushNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.footerLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 14, 14),
    this.maxMessageLines = 3,
    this.borderRadius = 14,
    this.minHeight,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AppNotificationSurface(
      title: title,
      message: message,
      footerLabel: footerLabel,
      tone: AppNotificationTone.neutral,
      leadingIcon: Icons.notifications_rounded,
      padding: padding,
      borderRadius: borderRadius,
      minHeight: minHeight,
      maxMessageLines: maxMessageLines ?? 3,
      onClose: onClose,
    );
  }
}

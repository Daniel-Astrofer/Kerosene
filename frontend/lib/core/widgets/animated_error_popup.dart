import 'package:flutter/material.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/l10n/l10n_extension.dart';

class AnimatedErrorPopup extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const AnimatedErrorPopup({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = false,
    this.onRetry,
    this.onGoBack,
  });

  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
  }) {
    final l10n = context.l10n;
    String title = isSuccess
        ? l10n.errorPopupSuccessTitle
        : l10n.errorPopupTransactionTitle;
    final lower = message.toLowerCase();
    if (lower.contains('saldo') ||
        lower.contains('fundos') ||
        lower.contains('insuficiente')) {
      title = l10n.errorPopupBalanceTitle;
    } else if (lower.contains('conexão') || lower.contains('servidor')) {
      title = l10n.errorPopupNetworkTitle;
    } else if (lower.contains('autenticação') ||
        lower.contains('senha') ||
        lower.contains('código')) {
      title = l10n.errorPopupAccessTitle;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Error',
      barrierColor: Colors.black.withValues(alpha: 0.68),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedErrorPopup(
              title: title,
              message: message,
              isSuccess: isSuccess,
              onRetry: onRetry,
              onGoBack: onGoBack,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final split = _splitMessage(message);
    final details =
        split.extra == null ? split.main : '${split.main}\n${split.extra}';
    final actions = <AppNotificationAction>[
      if (onRetry != null)
        AppNotificationAction(
          label: l10n.tryAgain,
          icon: Icons.refresh_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            onRetry!();
          },
        ),
      if (onGoBack != null)
        AppNotificationAction(
          label: l10n.goBack,
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            onGoBack!();
          },
        ),
      if (onRetry == null && onGoBack == null)
        AppNotificationAction(
          label: l10n.done,
          onPressed: () => Navigator.of(context).pop(),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AppNotificationSurface(
          title: title,
          message: details,
          tone: isSuccess
              ? AppNotificationTone.success
              : AppNotificationTone.error,
          maxMessageLines: 4,
          onClose: () => Navigator.of(context).pop(),
          actions: actions,
        ),
      ),
    );
  }

  static ({String main, String? extra}) _splitMessage(String value) {
    if (value.contains('. Faltam ')) {
      final parts = value.split('. Faltam ');
      return (main: parts.first, extra: 'Faltam ${parts.last}');
    }
    if (value.contains('\nFaltam ')) {
      final parts = value.split('\nFaltam ');
      return (main: parts.first, extra: 'Faltam ${parts.last}');
    }
    return (main: value, extra: null);
  }
}

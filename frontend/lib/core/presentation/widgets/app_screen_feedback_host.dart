import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/theme/app_typography.dart';

class AppScreenFeedbackHost extends StatelessWidget {
  final Widget child;

  const AppScreenFeedbackHost({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppScreenFeedbackMessage?>(
      valueListenable: AppScreenFeedbackBus.current,
      builder: (context, message, _) {
        return Column(
          children: [
            AnimatedSize(
              duration: KeroseneMotion.medium,
              curve: KeroseneMotion.standard,
              alignment: Alignment.topCenter,
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : SafeArea(
                      bottom: false,
                      child: _ScreenFeedbackPanel(message: message),
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _ScreenFeedbackPanel extends StatelessWidget {
  final AppScreenFeedbackMessage message;

  const _ScreenFeedbackPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(message.type);
    final icon = _iconFor(message.type);
    final size = MediaQuery.sizeOf(context);
    final maxPanelHeight = math.min(164.0, math.max(88.0, size.height * 0.28));

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxPanelHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KeroseneBrandTokens.background,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: KeroseneBrandTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.16,
                            letterSpacing: 0,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.message,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: KeroseneBrandTokens.textSecondary,
                            fontSize: 12,
                            height: 1.34,
                            letterSpacing: 0,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Fechar',
                    child: IconButton(
                      onPressed: () => AppScreenFeedbackBus.clear(
                        sequence: message.sequence,
                      ),
                      icon: const Icon(KeroseneIcons.close),
                      color: Colors.white.withValues(alpha: 0.58),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AppNoticeType type) {
    return switch (type) {
      AppNoticeType.success => KeroseneIcons.success,
      AppNoticeType.error => KeroseneIcons.error,
      AppNoticeType.info => KeroseneIcons.info,
      AppNoticeType.warning => KeroseneIcons.warning,
    };
  }

  static Color _accentFor(AppNoticeType type) {
    return switch (type) {
      AppNoticeType.success => KeroseneBrandTokens.success,
      AppNoticeType.error => KeroseneBrandTokens.error,
      AppNoticeType.info => KeroseneBrandTokens.info,
      AppNoticeType.warning => KeroseneBrandTokens.warning,
    };
  }
}

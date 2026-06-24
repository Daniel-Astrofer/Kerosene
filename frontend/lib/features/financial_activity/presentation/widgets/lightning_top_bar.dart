import 'package:flutter/material.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_typography.dart';

/// The top navigation bar for the Lightning transaction flow.
///
/// This widget provides a back button and a title specifically styled
/// for the Lightning network interface. It is detached from state logic
/// to ensure efficient rendering.
class LightningTopBar extends StatelessWidget {
  /// Callback triggered when the back button is pressed.
  final VoidCallback onBack;

  /// The main color for text elements.
  final Color textColor;

  /// The background color for surface elements like the back button.
  final Color surfaceColor;

  /// The color used for borders and outlines.
  final Color outlineColor;

  const LightningTopBar({
    super.key,
    required this.onBack,
    required this.textColor,
    required this.surfaceColor,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(KeroseneIcons.back, size: 22),
              tooltip: context.tr.authBackAction,
              style: IconButton.styleFrom(
                foregroundColor: textColor,
                backgroundColor: surfaceColor,
                side: BorderSide(color: outlineColor),
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Text(
            context.tr.send,
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 40, height: 40),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/theme/app_typography.dart';

/// A custom keypad for the Lightning network flow.
///
/// This widget provides a numeric keypad with a backspace button. It is used
/// primarily during the Lightning withdraw process to input the desired amount.
class LightningKeypad extends StatelessWidget {
  /// Callback triggered when a key is pressed. The [String] passed is the key value.
  final ValueChanged<String> onKeyTap;

  /// The main color for the text of the keys.
  final Color textColor;

  /// The color used for secondary or muted keys, such as the backspace button.
  final Color mutedColor;

  const LightningKeypad({
    super.key,
    required this.onKeyTap,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '←'],
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            for (final row in rows)
              Row(
                children: [
                  for (final keyStr in row)
                    Expanded(
                      child: _LightningKeypadButton(
                        keyStr: keyStr,
                        onTap: () => onKeyTap(keyStr),
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// An individual button within the [LightningKeypad].
class _LightningKeypadButton extends StatelessWidget {
  /// The string value representing this key (e.g., '1', '2', '.', '←').
  final String keyStr;

  /// Callback triggered when the button is tapped.
  final VoidCallback onTap;

  /// The text color of the button.
  final Color textColor;

  /// The color used if the button is a muted action, like backspace.
  final Color mutedColor;

  const _LightningKeypadButton({
    required this.keyStr,
    required this.onTap,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isBackspace = keyStr == '←';
    final label = keyStr == '.' ? ',' : keyStr;

    return SizedBox(
      height: 56,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: isBackspace ? mutedColor : textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        child: isBackspace
            ? const Icon(KeroseneIcons.backspace, size: 22)
            : Text(label),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';

import 'bitcoin_accounts_presentation_support.dart';

class BitcoinAccountsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const BitcoinAccountsHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundHeaderButton(
              icon: KeroseneIcons.back,
              onTap: onBack,
              backgroundColor: colors.background,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 58),
            child: Text(
              'Carteira Interna',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.newsreader(
                color: colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 48, height: 48),
          ),
        ],
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const _RoundHeaderButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Material(
      color: backgroundColor ?? colors.headerButtonBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.text, size: 22),
        ),
      ),
    );
  }
}

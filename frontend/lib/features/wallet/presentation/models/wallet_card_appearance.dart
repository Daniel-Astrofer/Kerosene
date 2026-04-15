import 'package:flutter/material.dart';

import '../../domain/entities/wallet.dart';

enum WalletCardLevel {
  bronze,
  white,
  black,
}

@immutable
class WalletCardAppearance {
  final WalletCardLevel level;
  final int paletteIndex;
  final int levelNumber;
  final String label;
  final Color baseColor;
  final Color cardTextColor;
  final Color cardHighlightColor;
  final Color cardShadowColor;
  final List<Color> backgroundGradient;
  final Color surfaceColor;
  final Color surfaceMutedColor;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color lineColor;
  final Color accentColor;
  final Color heroGlowColor;
  final bool isDark;

  const WalletCardAppearance({
    required this.level,
    required this.paletteIndex,
    required this.levelNumber,
    required this.label,
    required this.baseColor,
    required this.cardTextColor,
    required this.cardHighlightColor,
    required this.cardShadowColor,
    required this.backgroundGradient,
    required this.surfaceColor,
    required this.surfaceMutedColor,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.lineColor,
    required this.accentColor,
    required this.heroGlowColor,
    required this.isDark,
  });

  static const int defaultIndex = 1;

  static int normalizeIndex(int index) {
    const paletteCount = 3;
    return ((index % paletteCount) + paletteCount) % paletteCount;
  }

  static WalletCardAppearance fromIndex(int index) {
    return all[normalizeIndex(index)];
  }

  static WalletCardAppearance fromCardType(WalletCardType cardType) {
    return all[indexForCardType(cardType)];
  }

  static int indexForCardType(WalletCardType cardType) {
    return switch (cardType) {
      WalletCardType.bronze => 0,
      WalletCardType.white => 1,
      WalletCardType.black => 2,
    };
  }

  static const List<WalletCardAppearance> all = [
    WalletCardAppearance(
      level: WalletCardLevel.bronze,
      paletteIndex: 0,
      levelNumber: 1,
      label: 'Bronze',
      baseColor: Color(0xFFAE7144),
      cardTextColor: Color(0xFFFBECDD),
      cardHighlightColor: Color(0xFFFFF5EA),
      cardShadowColor: Color(0xFF2B170B),
      backgroundGradient: [
        Color(0xFFFFF8F2),
        Color(0xFFF0D5BB),
        Color(0xFFCB894A),
      ],
      surfaceColor: Color(0xFFFFFBF7),
      surfaceMutedColor: Color(0xFFF5E4D1),
      inkPrimary: Color(0xFF24150D),
      inkSecondary: Color(0xFF7F6048),
      lineColor: Color(0xFFE4C5A7),
      accentColor: Color(0xFFB66A2D),
      heroGlowColor: Color(0xFFB66A2D),
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.white,
      paletteIndex: 1,
      levelNumber: 2,
      label: 'White',
      baseColor: Color(0xFFD3DAE3),
      cardTextColor: Color(0xFF132033),
      cardHighlightColor: Color(0xFFFDFEFF),
      cardShadowColor: Color(0xFF738095),
      backgroundGradient: [
        Color(0xFFF3F6FA),
        Color(0xFFE5EBF3),
        Color(0xFFD6DEE8),
      ],
      surfaceColor: Color(0xFFF9FBFD),
      surfaceMutedColor: Color(0xFFEAF0F6),
      inkPrimary: Color(0xFF0F1728),
      inkSecondary: Color(0xFF5D6B82),
      lineColor: Color(0xFFD7DEE8),
      accentColor: Color(0xFF2563EB),
      heroGlowColor: Color(0xFF2563EB),
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.black,
      paletteIndex: 2,
      levelNumber: 3,
      label: 'Black',
      baseColor: Color(0xFF181D24),
      cardTextColor: Color(0xFFE8EDF5),
      cardHighlightColor: Color(0xFFFFFFFF),
      cardShadowColor: Color(0xFF000000),
      backgroundGradient: [
        Color(0xFF05070A),
        Color(0xFF0D1218),
        Color(0xFF151B22),
      ],
      surfaceColor: Color(0xFF0F141B),
      surfaceMutedColor: Color(0xFF161D25),
      inkPrimary: Color(0xFFF5F7FA),
      inkSecondary: Color(0xFF9AA8BB),
      lineColor: Color(0xFF283341),
      accentColor: Color(0xFFCBD5E1),
      heroGlowColor: Color(0xFF7C8EA6),
      isDark: true,
    ),
  ];
}

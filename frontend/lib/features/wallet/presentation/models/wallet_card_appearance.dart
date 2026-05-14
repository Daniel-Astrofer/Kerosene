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
      baseColor: Color(0xFFC99736),
      cardTextColor: Color(0xFF2F1904),
      cardHighlightColor: Color(0xFFFFE3A2),
      cardShadowColor: Color(0xFF4A2A07),
      backgroundGradient: [
        Color(0xFFFFE7A7),
        Color(0xFFE4BE64),
        Color(0xFFC5851E),
      ],
      surfaceColor: Color(0xFFF7E5BE),
      surfaceMutedColor: Color(0xFFE7CB88),
      inkPrimary: Color(0xFF241305),
      inkSecondary: Color(0xFF715128),
      lineColor: Color(0xFFD9B66A),
      accentColor: Color(0xFFD19B2F),
      heroGlowColor: Color(0xFFE0B04D),
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.white,
      paletteIndex: 1,
      levelNumber: 2,
      label: 'White',
      baseColor: Color(0xFFD9C08A),
      cardTextColor: Color(0xFF2A1A08),
      cardHighlightColor: Color(0xFFFFF1C9),
      cardShadowColor: Color(0xFF7A6542),
      backgroundGradient: [
        Color(0xFFF8ECD0),
        Color(0xFFE5D19F),
        Color(0xFFCDB076),
      ],
      surfaceColor: Color(0xFFF4E7C8),
      surfaceMutedColor: Color(0xFFE6D5AE),
      inkPrimary: Color(0xFF241608),
      inkSecondary: Color(0xFF755E34),
      lineColor: Color(0xFFD6BF87),
      accentColor: Color(0xFFE0B85B),
      heroGlowColor: Color(0xFFE8C56E),
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.black,
      paletteIndex: 2,
      levelNumber: 3,
      label: 'Black',
      baseColor: Color(0xFF1E170D),
      cardTextColor: Color(0xFFF7E4AF),
      cardHighlightColor: Color(0xFFFFD983),
      cardShadowColor: Color(0xFF000000),
      backgroundGradient: [
        Color(0xFF130E08),
        Color(0xFF241B10),
        Color(0xFF392915),
      ],
      surfaceColor: Color(0xFF181109),
      surfaceMutedColor: Color(0xFF241A0F),
      inkPrimary: Color(0xFFF8E6B7),
      inkSecondary: Color(0xFFC9AA68),
      lineColor: Color(0xFF4A3520),
      accentColor: Color(0xFFFFCC6E),
      heroGlowColor: Color(0xFFE0B04D),
      isDark: true,
    ),
  ];
}

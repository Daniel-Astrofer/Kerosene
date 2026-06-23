import 'package:kerosene/core/theme/app_colors.dart';

import 'package:flutter/material.dart';

import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';

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
      baseColor: AppColors.hexFFC99736,
      cardTextColor: AppColors.hexFF2F1904,
      cardHighlightColor: AppColors.hexFFFFE3A2,
      cardShadowColor: AppColors.hexFF4A2A07,
      backgroundGradient: [
        AppColors.hexFFFFE7A7,
        AppColors.hexFFE4BE64,
        AppColors.hexFFC5851E,
      ],
      surfaceColor: AppColors.hexFFF7E5BE,
      surfaceMutedColor: AppColors.hexFFE7CB88,
      inkPrimary: AppColors.hexFF241305,
      inkSecondary: AppColors.hexFF715128,
      lineColor: AppColors.hexFFD9B66A,
      accentColor: AppColors.hexFFD19B2F,
      heroGlowColor: AppColors.hexFFE0B04D,
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.white,
      paletteIndex: 1,
      levelNumber: 2,
      label: 'White',
      baseColor: AppColors.hexFFD9C08A,
      cardTextColor: AppColors.hexFF2A1A08,
      cardHighlightColor: AppColors.hexFFFFF1C9,
      cardShadowColor: AppColors.hexFF7A6542,
      backgroundGradient: [
        AppColors.hexFFF8ECD0,
        AppColors.hexFFE5D19F,
        AppColors.hexFFCDB076,
      ],
      surfaceColor: AppColors.hexFFF4E7C8,
      surfaceMutedColor: AppColors.hexFFE6D5AE,
      inkPrimary: AppColors.hexFF241608,
      inkSecondary: AppColors.hexFF755E34,
      lineColor: AppColors.hexFFD6BF87,
      accentColor: AppColors.hexFFE0B85B,
      heroGlowColor: AppColors.hexFFE8C56E,
      isDark: false,
    ),
    WalletCardAppearance(
      level: WalletCardLevel.black,
      paletteIndex: 2,
      levelNumber: 3,
      label: 'Black',
      baseColor: AppColors.hexFF1E170D,
      cardTextColor: AppColors.hexFFF7E4AF,
      cardHighlightColor: AppColors.hexFFFFD983,
      cardShadowColor: AppColors.hexFF000000,
      backgroundGradient: [
        AppColors.hexFF130E08,
        AppColors.hexFF241B10,
        AppColors.hexFF392915,
      ],
      surfaceColor: AppColors.hexFF181109,
      surfaceMutedColor: AppColors.hexFF241A0F,
      inkPrimary: AppColors.hexFFF8E6B7,
      inkSecondary: AppColors.hexFFC9AA68,
      lineColor: AppColors.hexFF4A3520,
      accentColor: AppColors.hexFFFFCC6E,
      heroGlowColor: AppColors.hexFFE0B04D,
      isDark: true,
    ),
  ];
}

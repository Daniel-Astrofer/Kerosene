import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kerosene brand color tokens.
///
/// Predominant visual language: black/white, warm graphite and a restrained
/// gold accent. Bitcoin orange is reserved for Bitcoin-specific contexts.
class KeroseneBrandTokens {
  const KeroseneBrandTokens._();

  static const Color background = AppColors.hexFF030405;
  static const Color backgroundSoft = AppColors.hexFF0A0D10;
  static const Color backgroundElevated = AppColors.hexFF111111;

  static const Color surface = AppColors.hexFF111111;
  static const Color surfaceHigh = AppColors.hexFF181A17;
  static const Color surfaceElevated = AppColors.hexFF1D2328;
  static const Color surfaceMuted = AppColors.hexFF0A0A0A;

  static const Color border = AppColors.hexFF2F3131;
  static const Color borderStrong = AppColors.hexFF3A3A3A;
  static const Color borderSubtle = AppColors.hex14FFFFFF;

  static const Color textPrimary = AppColors.hexFFF7F7F1;
  static const Color textSecondary = AppColors.hexFFB8B8BC;
  static const Color textMuted = AppColors.hexFF7D838A;
  static const Color textDisabled = AppColors.hexFF555550;
  static const Color textInverse = AppColors.hexFF030405;

  static const Color brand = AppColors.hexFFD6A84F;
  static const Color keroseneGold = brand;
  static const Color bitcoin = AppColors.hexFFF59E0B;
  static const Color bitcoinOrange = bitcoin;
  static const Color amberDeep = AppColors.hexFF715128;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.hexFF60A5FA;
  static const Color lightning = AppColors.hexFF7B61FF;

  static const Color railInternal = keroseneGold;
  static const Color railOnchain = bitcoinOrange;
  static const Color railLightning = lightning;
  static const Color railSettlement = success;
  static const Color railPending = warning;
  static const Color railFailed = error;
}

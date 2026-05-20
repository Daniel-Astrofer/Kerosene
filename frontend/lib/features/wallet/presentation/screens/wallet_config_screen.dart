import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/safe_display_text.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';

import '../../domain/entities/wallet.dart';
import '../models/wallet_card_appearance.dart';
import '../widgets/wallet_credit_card.dart';

class WalletConfigScreen extends StatefulWidget {
  final Wallet wallet;
  final int initialColorIndex;

  const WalletConfigScreen({
    super.key,
    required this.wallet,
    this.initialColorIndex = WalletCardAppearance.defaultIndex,
  });

  @override
  State<WalletConfigScreen> createState() => _WalletConfigScreenState();
}

class _WalletConfigScreenState extends State<WalletConfigScreen> {
  static const _successColor = Color(0xFF16A34A);
  static const _warningColor = Color(0xFFF59E0B);
  static const _dangerColor = Color(0xFFDC2626);

  bool _isBlocked = false;
  bool _hideBalance = false;

  WalletCardAppearance get _appearance {
    return WalletCardAppearance.fromCardType(widget.wallet.cardType);
  }

  String get _walletAddress {
    return widget.wallet.address.trim();
  }

  String get _walletTypeLabel {
    switch (widget.wallet.type) {
      case WalletType.legacy:
        return 'Bitcoin Legacy';
      case WalletType.segwit:
        return 'Bitcoin SegWit';
      case WalletType.nativeSegwit:
        return 'Bitcoin Native SegWit';
      case WalletType.taproot:
        return 'Bitcoin Taproot';
    }
  }

  void _copyAddress() {
    if (widget.wallet.address.trim().isEmpty) {
      SnackbarHelper.showWarning(context.tr.apiDisplayAddressUnavailable);
      return;
    }

    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.wallet.address));
    SnackbarHelper.showSuccess(
      context.tr.walletConfigAddressCopiedMessage,
      title: context.tr.walletConfigAddressCopiedTitle,
    );
  }

  void _showExportNotice() {
    HapticFeedback.mediumImpact();
    SnackbarHelper.showInfo(
      context.tr.walletConfigExportNoticeMessage,
      title: context.tr.walletConfigExportNoticeTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _appearance;
    final panelColor = appearance.surfaceColor.withValues(
      alpha: appearance.isDark ? 0.92 : 0.96,
    );
    const screenBackground = authenticatedSurfaceBackgroundColor;
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: screenBackground,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        color: screenBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              AppSpacing.md,
              responsive.horizontalPadding,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.mobileContentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppBar(appearance),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeroSection(appearance, panelColor)
                        .animate()
                        .fade(duration: 280.ms)
                        .slideY(begin: 0.03, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: context.tr.walletConfigAddressTitle,
                      subtitle: context.tr.walletConfigAddressSubtitle,
                      trailing: TextButton.icon(
                        onPressed: _copyAddress,
                        style: TextButton.styleFrom(
                          foregroundColor: appearance.accentColor,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(context.tr.walletConfigCopy),
                      ),
                      child: _AddressPanel(
                        appearance: appearance,
                        address: _walletAddress,
                      ),
                    ).animate(delay: 80.ms).fade().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: context.tr.walletConfigFeesTitle,
                      subtitle: context.tr.walletConfigFeesSubtitle,
                      child: _FeeGrid(
                        appearance: appearance,
                        wallet: widget.wallet,
                      ),
                    ).animate(delay: 120.ms).fade().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: context.tr.walletConfigControlsTitle,
                      subtitle: context.tr.walletConfigControlsSubtitle,
                      child: Column(
                        children: [
                          _FinanceActionRow(
                            appearance: appearance,
                            title: context.tr.walletConfigFreezeCardTitle,
                            subtitle: context.tr.walletConfigFreezeCardSubtitle,
                            icon: Icons.lock_outline_rounded,
                            iconColor: _warningColor,
                            trailing: Switch.adaptive(
                              value: _isBlocked,
                              activeThumbColor: appearance.accentColor,
                              activeTrackColor: appearance.accentColor
                                  .withValues(alpha: 0.28),
                              onChanged: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _isBlocked = value);
                              },
                            ),
                          ),
                          Divider(height: 1, color: appearance.lineColor),
                          _FinanceActionRow(
                            appearance: appearance,
                            title: context.tr.walletConfigHideBalanceTitle,
                            subtitle:
                                context.tr.walletConfigHideBalanceSubtitle,
                            icon: Icons.visibility_off_outlined,
                            iconColor: appearance.inkSecondary,
                            trailing: Switch.adaptive(
                              value: _hideBalance,
                              activeThumbColor: appearance.accentColor,
                              activeTrackColor: appearance.accentColor
                                  .withValues(alpha: 0.28),
                              onChanged: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _hideBalance = value);
                              },
                            ),
                          ),
                          Divider(height: 1, color: appearance.lineColor),
                          _FinanceActionRow(
                            appearance: appearance,
                            title: context.tr.walletConfigExportKeyTitle,
                            subtitle: context.tr.walletConfigExportKeySubtitle,
                            icon: Icons.key_outlined,
                            iconColor: _dangerColor,
                            onTap: _showExportNotice,
                          ),
                        ],
                      ),
                    ).animate(delay: 160.ms).fade().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: context.tr.walletConfigCardRuleTitle,
                      subtitle: context.tr.walletConfigCardRuleSubtitle,
                      child: _CardRulesPanel(
                        appearance: appearance,
                        currentType: widget.wallet.cardType,
                      ),
                    ).animate(delay: 200.ms).fade().slideY(begin: 0.04, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(WalletCardAppearance appearance) {
    final responsive = context.responsive;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: appearance.surfaceColor.withValues(
              alpha: appearance.isDark ? 0.90 : 0.96,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appearance.lineColor),
            boxShadow: [
              BoxShadow(
                color: appearance.heroGlowColor.withValues(
                  alpha: appearance.isDark ? 0.10 : 0.08,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: appearance.inkPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.walletConfigTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h2.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: responsive.compactFontSize(
                    tiny: 21,
                    compact: 23,
                    regular: 24,
                  ),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr.walletConfigSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.64),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(WalletCardAppearance appearance, Color panelColor) {
    final responsive = context.responsive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(
        responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: appearance.lineColor),
        boxShadow: [
          BoxShadow(
            color: appearance.heroGlowColor.withValues(
              alpha: appearance.isDark ? 0.18 : 0.12,
            ),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: appearance.isDark ? 0.26 : 0.06,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.wallet.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h1.copyWith(
              color: appearance.inkPrimary,
              fontSize: responsive.compactFontSize(
                tiny: 24,
                compact: 26,
                regular: 28,
              ),
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr.walletConfigHeroSummary(
              appearance.levelNumber,
              widget.wallet.cardType.label,
              WalletCardType.formatRate(widget.wallet.withdrawalFeeRate),
              WalletCardType.formatRate(widget.wallet.depositFeeRate),
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: appearance.inkSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: appearance.heroGlowColor.withValues(
                      alpha: appearance.isDark ? 0.20 : 0.16,
                    ),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: WalletCreditCard(
                wallet: widget.wallet,
                colorIndex: appearance.paletteIndex,
                showDetails: true,
                onLongPress: () {},
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                appearance: appearance,
                label: context.tr.walletConfigNetworkLabel,
                value: _walletTypeLabel,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _SummaryPill(
                appearance: appearance,
                label: context.tr.walletConfigPathLabel,
                value: widget.wallet.derivationPath,
                icon: Icons.alt_route_rounded,
              ),
              _SummaryPill(
                appearance: appearance,
                label: context.tr.walletConfigStatusLabel,
                value: _isBlocked
                    ? context.tr.walletConfigStatusFrozen
                    : context.tr.walletConfigStatusActive,
                icon: _isBlocked
                    ? Icons.pause_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              _SummaryPill(
                appearance: appearance,
                label: context.tr.walletConfigLevelLabel,
                value:
                    '${widget.wallet.cardType.label} ${appearance.levelNumber}',
                icon: Icons.layers_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final WalletCardAppearance appearance;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.appearance,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(
        responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: appearance.surfaceColor.withValues(
          alpha: appearance.isDark ? 0.92 : 0.95,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appearance.lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: appearance.isDark ? 0.16 : 0.04,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(
                        color: appearance.inkPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: appearance.inkSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.isTinyPhone ? 124 : 180,
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _AddressPanel extends StatelessWidget {
  final WalletCardAppearance appearance;
  final String address;

  const _AddressPanel({required this.appearance, required this.address});

  @override
  Widget build(BuildContext context) {
    final visibleAddress = SafeDisplayText.displayAddress(context, address);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: appearance.surfaceMutedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appearance.lineColor),
      ),
      child: SelectableText(
        visibleAddress,
        style: AppTypography.bodyMedium.copyWith(
          color: appearance.inkPrimary,
          fontFamily: 'JetBrainsMono',
          height: 1.7,
        ),
      ),
    );
  }
}

class _FeeGrid extends StatelessWidget {
  final WalletCardAppearance appearance;
  final Wallet wallet;

  const _FeeGrid({required this.appearance, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isCompact ? 1 : 3,
          childAspectRatio: isCompact ? 3.8 : 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _FeeTile(
              appearance: appearance,
              label: context.tr.walletConfigWithdrawLabel,
              value: WalletCardType.formatRate(wallet.withdrawalFeeRate),
              helper: context.tr.walletConfigWithdrawHelper,
              accent: _WalletConfigScreenState._dangerColor,
            ),
            _FeeTile(
              appearance: appearance,
              label: context.tr.walletConfigDepositLabel,
              value: WalletCardType.formatRate(wallet.depositFeeRate),
              helper: context.tr.walletConfigDepositHelper,
              accent: appearance.accentColor,
            ),
            _FeeTile(
              appearance: appearance,
              label: context.tr.walletConfigInternalLabel,
              value: '0%',
              helper: context.tr.walletConfigInternalHelper,
              accent: _WalletConfigScreenState._successColor,
            ),
          ],
        );
      },
    );
  }
}

class _FeeTile extends StatelessWidget {
  final WalletCardAppearance appearance;
  final String label;
  final String value;
  final String helper;
  final Color accent;

  const _FeeTile({
    required this.appearance,
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: appearance.surfaceMutedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appearance.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: appearance.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h2.copyWith(
              color: appearance.inkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: appearance.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceActionRow extends StatelessWidget {
  final WalletCardAppearance appearance;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FinanceActionRow({
    required this.appearance,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: responsive.isTinyPhone ? 40 : 46,
              height: responsive.isTinyPhone ? 40 : 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: appearance.inkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: appearance.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: appearance.inkSecondary,
                ),
          ],
        ),
      ),
    );
  }
}

class _CardRulesPanel extends StatelessWidget {
  final WalletCardAppearance appearance;
  final WalletCardType currentType;

  const _CardRulesPanel({required this.appearance, required this.currentType});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CardRuleRow(
          appearance: appearance,
          type: WalletCardType.bronze,
          rule: 'Padrão inicial',
          selected: currentType == WalletCardType.bronze,
        ),
        Divider(height: 1, color: appearance.lineColor),
        _CardRuleRow(
          appearance: appearance,
          type: WalletCardType.white,
          rule: 'Conta >= 6 meses e movimentação > 1500 em 30 dias',
          selected: currentType == WalletCardType.white,
        ),
        Divider(height: 1, color: appearance.lineColor),
        _CardRuleRow(
          appearance: appearance,
          type: WalletCardType.black,
          rule: 'Conta >= 6 meses e movimentação > 3000 em 30 dias',
          selected: currentType == WalletCardType.black,
        ),
      ],
    );
  }
}

class _CardRuleRow extends StatelessWidget {
  final WalletCardAppearance appearance;
  final WalletCardType type;
  final String rule;
  final bool selected;

  const _CardRuleRow({
    required this.appearance,
    required this.type,
    required this.rule,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final option = WalletCardAppearance.fromCardType(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: option.baseColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? appearance.accentColor : appearance.lineColor,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, color: option.cardTextColor)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${type.label} • ${WalletCardType.formatRate(type.defaultFeeRate)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: appearance.inkPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rule,
                  style: AppTypography.bodySmall.copyWith(
                    color: appearance.inkSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            selected ? 'Atual' : '',
            style: AppTypography.caption.copyWith(
              color: appearance.accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final WalletCardAppearance appearance;
  final String label;
  final String value;
  final IconData icon;

  const _SummaryPill({
    required this.appearance,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appearance.surfaceMutedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appearance.lineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: appearance.inkSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: appearance.inkSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: appearance.inkPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

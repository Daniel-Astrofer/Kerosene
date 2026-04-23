import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/snackbar_helper.dart';

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
  int _materialIndex = 0; // 0=Metal, 1=Wood, 2=Diamond, 3=Ruby (Debug Only)

  WalletCardAppearance get _appearance {
    return WalletCardAppearance.fromCardType(widget.wallet.cardType);
  }

  String get _walletAddress {
    final address = widget.wallet.address.trim();
    return address.isEmpty ? 'Endereço indisponível' : address;
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
      SnackbarHelper.showWarning('Esta wallet ainda não possui endereço.');
      return;
    }

    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.wallet.address));
    SnackbarHelper.showSuccess(
      'O endereço da wallet foi copiado com sucesso.',
      title: 'Endereço copiado',
    );
  }

  void _showExportNotice() {
    HapticFeedback.mediumImpact();
    SnackbarHelper.showInfo(
      'A exportação da chave privada depende da verificação de segurança do dispositivo.',
      title: 'Validação necessária',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _appearance;
    final panelColor = appearance.surfaceColor.withValues(
      alpha: appearance.isDark ? 0.92 : 0.96,
    );
    const screenBackground = authenticatedSurfaceBackgroundColor;

    return Scaffold(
      backgroundColor: screenBackground,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        color: screenBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
                      title: 'Endereço da wallet',
                      subtitle:
                          'Use este endereço para depósitos on-chain desta carteira.',
                      trailing: TextButton.icon(
                        onPressed: _copyAddress,
                        style: TextButton.styleFrom(
                          foregroundColor: appearance.accentColor,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copiar'),
                      ),
                      child: _AddressPanel(
                        appearance: appearance,
                        address: _walletAddress,
                      ),
                    ).animate(delay: 80.ms).fade().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: 'Taxas da carteira',
                      subtitle:
                          'Taxa dinâmica retornada pela API para movimentações externas.',
                      child: _FeeGrid(
                        appearance: appearance,
                        wallet: widget.wallet,
                      ),
                    ).animate(delay: 120.ms).fade().slideY(begin: 0.04, end: 0),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      appearance: appearance,
                      title: 'Controles',
                      subtitle:
                          'Ajustes de uso e proteção visual da carteira na aplicação.',
                      child: Column(
                        children: [
                          _FinanceActionRow(
                            appearance: appearance,
                            title: 'Congelar cartão',
                            subtitle:
                                'Desativa temporariamente o uso desta carteira no fluxo visual.',
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
                            title: 'Ocultar saldo na home',
                            subtitle:
                                'Mantém a carteira visível, mas reduz a exposição do saldo.',
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
                            title: 'Exportar chave privada',
                            subtitle:
                                'Exige verificação adicional antes de revelar material sensível.',
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
                      title: 'Regra do cartão',
                      subtitle:
                          'O backend classifica a carteira por idade da conta e volume elegível nos últimos 30 dias.',
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
                'Cartão da carteira',
                style: AppTypography.h2.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configuração visual, endereço e taxas da wallet.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.64),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(
    WalletCardAppearance appearance,
    Color panelColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            color:
                Colors.black.withValues(alpha: appearance.isDark ? 0.26 : 0.06),
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
            style: AppTypography.h1.copyWith(
              color: appearance.inkPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nível ${appearance.levelNumber} • ${widget.wallet.cardType.label}. Saques externos usam ${WalletCardType.formatRate(widget.wallet.withdrawalFeeRate)} e depósitos externos usam ${WalletCardType.formatRate(widget.wallet.depositFeeRate)}.',
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
                label: 'Rede',
                value: _walletTypeLabel,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _SummaryPill(
                appearance: appearance,
                label: 'Path',
                value: widget.wallet.derivationPath,
                icon: Icons.alt_route_rounded,
              ),
              _SummaryPill(
                appearance: appearance,
                label: 'Status',
                value: _isBlocked ? 'Congelado' : 'Ativo',
                icon: _isBlocked
                    ? Icons.pause_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              _SummaryPill(
                appearance: appearance,
                label: 'Nível',
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: appearance.surfaceColor.withValues(
          alpha: appearance.isDark ? 0.92 : 0.95,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appearance.lineColor),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: appearance.isDark ? 0.16 : 0.04),
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
                      style: AppTypography.h3.copyWith(
                        color: appearance.inkPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
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
                trailing!,
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

  const _AddressPanel({
    required this.appearance,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
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
        address,
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

  const _FeeGrid({
    required this.appearance,
    required this.wallet,
  });

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
              label: 'Saque',
              value: WalletCardType.formatRate(wallet.withdrawalFeeRate),
              helper: 'Saída externa',
              accent: _WalletConfigScreenState._dangerColor,
            ),
            _FeeTile(
              appearance: appearance,
              label: 'Depósito',
              value: WalletCardType.formatRate(wallet.depositFeeRate),
              helper: 'Entrada externa',
              accent: appearance.accentColor,
            ),
            _FeeTile(
              appearance: appearance,
              label: 'Interno',
              value: '0%',
              helper: 'Entre wallets Kerosene',
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
            style: AppTypography.bodySmall.copyWith(
              color: appearance.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: appearance.inkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
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
                    style: AppTypography.bodyMedium.copyWith(
                      color: appearance.inkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

  const _CardRulesPanel({
    required this.appearance,
    required this.currentType,
  });

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
          Icon(
            icon,
            size: 16,
            color: appearance.inkSecondary,
          ),
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

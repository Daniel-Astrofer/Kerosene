import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import '../../domain/entities/wallet.dart';
import '../widgets/wallet_credit_card.dart';

class WalletConfigScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletConfigScreen({super.key, required this.wallet});

  @override
  State<WalletConfigScreen> createState() => _WalletConfigScreenState();
}

class _WalletConfigScreenState extends State<WalletConfigScreen> {
  bool _isBlocked = false;
  bool _hideBalance = false;
  int _materialIndex = 0; // 0=Metal, 1=Wood, 2=Diamond, 3=Ruby (Debug Only)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        child: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  
                  // ── Wallet Card Preview ──────────────────────────────────────
                  Hero(
                    tag: 'card_hero_${widget.wallet.address}',
                    child: WalletCreditCard(
                      wallet: widget.wallet,
                      colorIndex: _materialIndex, 
                      showDetails: true,
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // ── Settings List ──────────────────────────────────────────
                  GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    borderRadius: BorderRadius.circular(AppSpacing.xl),
                    child: Column(
                      children: [
                        _CyberActionTile(
                          title: 'Copiar Endereço',
                          subtitle: 'Copia o endereço BTC para o clipboard',
                          icon: LucideIcons.copy,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(ClipboardData(text: widget.wallet.address));
                            SnackbarHelper.showSuccess('Endereço copiado com sucesso');
                          },
                        ),
                        Divider(height: AppSpacing.xl, color: AppColors.white10),
                        _CyberActionTile(
                          title: 'Bloquear Cartão',
                          subtitle: 'Desativa temporariamente este card',
                          icon: LucideIcons.lock,
                          isDestructive: true,
                          trailing: Switch(
                            value: _isBlocked,
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              setState(() => _isBlocked = val);
                            },
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        Divider(height: AppSpacing.xl, color: AppColors.white10),
                        _CyberActionTile(
                          title: 'Ocultar Saldo',
                          subtitle: 'Não mostrar detalhes na tela inicial',
                          icon: LucideIcons.eyeOff,
                          trailing: Switch(
                            value: _hideBalance,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _hideBalance = val);
                            },
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        Divider(height: AppSpacing.xl, color: AppColors.white10),
                        _CyberActionTile(
                          title: 'Exportar Chave Privada',
                          subtitle: 'Visualizar semente/mnemônico',
                          icon: LucideIcons.key,
                          isDestructive: true,
                          onTap: () {
                             // Security verify logic
                          },
                        ),
                        Divider(height: AppSpacing.xl, color: AppColors.white10),
                        _CyberActionTile(
                          title: 'Configurações de Tor',
                          subtitle: 'Gerenciar conexão para este nó',
                          icon: LucideIcons.shield,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xl),

                  // ── DEBUG Area ──────────────────────────────────────────────
                  _buildDebugSection().animate(delay: 400.ms).fade(),
                  
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'CONFIGURAÇÃO',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildDebugSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bug, color: AppColors.warning, size: 14),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "DEBUG: TEXTURA DO CARD",
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DebugMaterialBtn(label: "METAL", index: 0, selectedIndex: _materialIndex, onTap: (idx) => setState(() => _materialIndex = idx)),
              _DebugMaterialBtn(label: "WOOD", index: 1, selectedIndex: _materialIndex, onTap: (idx) => setState(() => _materialIndex = idx)),
              _DebugMaterialBtn(label: "DIAMOND", index: 2, selectedIndex: _materialIndex, onTap: (idx) => setState(() => _materialIndex = idx)),
              _DebugMaterialBtn(label: "RUBY", index: 3, selectedIndex: _materialIndex, onTap: (idx) => setState(() => _materialIndex = idx)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugMaterialBtn extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  const _DebugMaterialBtn({required this.label, required this.index, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warning : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isSelected ? Theme.of(context).colorScheme.onSurface : AppColors.warning,
          ),
        ),
      ),
    );
  }
}

class _CyberActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _CyberActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: accentColor.withOpacity(0.1)),
              ),
              child: Icon(icon, color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) 
              trailing! 
            else 
              Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1), size: 16),
          ],
        ),
      ),
    );
  }
}

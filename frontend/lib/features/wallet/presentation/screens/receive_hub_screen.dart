import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

import 'deposit/deposit_amount_screen.dart';
import 'receive_screen.dart';

class ReceiveHubScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const ReceiveHubScreen({
    super.key,
    this.initialWallet,
  });

  @override
  ConsumerState<ReceiveHubScreen> createState() => _ReceiveHubScreenState();
}

class _ReceiveHubScreenState extends ConsumerState<ReceiveHubScreen> {
  bool _isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNfcAvailability());
  }

  Future<void> _loadNfcAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (!mounted) {
        return;
      }
      setState(() => _isNfcAvailable = availability == NfcAvailability.enabled);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isNfcAvailable = false);
    }
  }

  Wallet? _resolveWallet(WalletState walletState) {
    if (widget.initialWallet != null) {
      return widget.initialWallet;
    }

    if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
      return walletState.selectedWallet ?? walletState.wallets.first;
    }

    return null;
  }

  Route<T> _bottomUpRoute<T>(WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.78, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openDeposit(Wallet wallet) {
    HapticFeedback.lightImpact();
    unawaited(
      Navigator.of(context).push<void>(
        _bottomUpRoute((_) => DepositAmountScreen(wallet: wallet)),
      ),
    );
  }

  void _openReceive(Wallet wallet, ReceiveFlowMode mode) {
    if (mode == ReceiveFlowMode.nfc && !_isNfcAvailable) {
      AppNotice.showInfo(
        context,
        title: 'NFC',
        message: 'NFC não está disponível neste dispositivo no momento.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    unawaited(
      Navigator.of(context).push<void>(
        _bottomUpRoute(
          (_) => ReceiveScreen(
            initialWallet: wallet,
            initialMode: mode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final wallet = _resolveWallet(walletState);
    final bottomClearance =
        AppPrimaryNavigationBar.scaffoldBottomClearance(context);

    return Stack(
      children: [
        ReceiveFlowScaffold(
          title: 'Receber',
          subtitle: 'Fluxo único para depósito, cobrança e geração de QR.',
          bodyPadding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            bottomClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReceiveFlowSectionLabel('Ações disponíveis'),
              const SizedBox(height: 8),
              ReceiveFlowPanel(
                child: Text(
                  'Todas as opções de recebimento seguem o mesmo visual: layout compacto, leitura rápida e foco no dado principal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.35,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (wallet == null)
                const _ReceiveHubEmptyState()
              else ...[
                _ReceiveHubAction(
                  icon: LucideIcons.banknote,
                  label: 'Depositar',
                  subtitle: 'Adicionar saldo via onramp, Lightning ou on-chain',
                  onTap: () => _openDeposit(wallet),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.network,
                  label: 'Receber On-chain',
                  subtitle: 'Gerar payload Bitcoin com valor opcional',
                  onTap: () => _openReceive(
                    wallet,
                    ReceiveFlowMode.onChain,
                  ),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.zap,
                  label: 'Receber Lightning',
                  subtitle: 'Criar invoice instantânea para a carteira',
                  onTap: () => _openReceive(
                    wallet,
                    ReceiveFlowMode.lightning,
                  ),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.link2,
                  label: 'Link de pagamento',
                  subtitle: 'Cobrança rastreada com destino travado',
                  onTap: () => _openReceive(
                    wallet,
                    ReceiveFlowMode.paymentLink,
                  ),
                ),
                if (_isNfcAvailable)
                  _ReceiveHubAction(
                    icon: LucideIcons.smartphoneNfc,
                    label: 'Receber por NFC',
                    subtitle: 'Preparar cobrança por aproximação',
                    onTap: () => _openReceive(
                      wallet,
                      ReceiveFlowMode.nfc,
                    ),
                  ),
              ],
            ],
          ),
        ),
        AppPrimaryNavigationBar.overlay(
          currentDestination: AppPrimaryDestination.home,
        ),
      ],
    );
  }
}

class _ReceiveHubAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ReceiveHubAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ReceiveFlowActionTile(
        icon: icon,
        title: label,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}

class _ReceiveHubEmptyState extends StatelessWidget {
  const _ReceiveHubEmptyState();

  @override
  Widget build(BuildContext context) {
    return const ReceiveFlowStatePanel(
      icon: LucideIcons.wallet,
      title: 'Nenhuma carteira disponível',
      message:
          'Crie ou selecione uma carteira antes de iniciar um fluxo de recebimento.',
    );
  }
}

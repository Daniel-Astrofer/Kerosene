import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:teste/core/navigation/app_page_transitions.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

import 'deposit/deposit_amount_screen.dart';
import 'receive_screen.dart';

class ReceiveHubScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const ReceiveHubScreen({super.key, this.initialWallet});

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
    return keroseneHorizontalRoute<T>(builder: builder);
  }

  void _openDeposit(Wallet wallet) {
    HapticFeedback.lightImpact();
    unawaited(
      Navigator.of(
        context,
      ).push<void>(_bottomUpRoute((_) => DepositAmountScreen(wallet: wallet))),
    );
  }

  void _openReceive(Wallet wallet, ReceiveFlowMode mode) {
    if (mode == ReceiveFlowMode.nfc && !_isNfcAvailable) {
      AppNotice.showInfo(
        context,
        title: 'NFC',
        message: context.l10n.receiveHubNfcUnavailable,
      );
      return;
    }

    HapticFeedback.lightImpact();
    unawaited(
      Navigator.of(context).push<void>(
        _bottomUpRoute(
          (_) => ReceiveScreen(initialWallet: wallet, initialMode: mode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final wallet = _resolveWallet(walletState);
    final bottomClearance = AppPrimaryNavigationBar.scaffoldBottomClearance(
      context,
    );

    return Stack(
      children: [
        ReceiveFlowScaffold(
          title: context.l10n.receiveHubTitle,
          subtitle: context.l10n.receiveHubSubtitle,
          bodyPadding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            bottomClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReceiveFlowSectionLabel(context.l10n.receiveHubActions),
              const SizedBox(height: 8),
              ReceiveFlowPanel(
                child: Text(
                  context.l10n.receiveHubIntro,
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
                  label: context.l10n.receiveHubDeposit,
                  subtitle: context.l10n.receiveHubDepositSubtitle,
                  onTap: () => _openDeposit(wallet),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.network,
                  label: context.l10n.receiveHubOnchain,
                  subtitle: context.l10n.receiveHubOnchainSubtitle,
                  onTap: () => _openReceive(wallet, ReceiveFlowMode.onChain),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.zap,
                  label: context.l10n.receiveHubLightning,
                  subtitle: context.l10n.receiveHubLightningSubtitle,
                  onTap: () => _openReceive(wallet, ReceiveFlowMode.lightning),
                ),
                _ReceiveHubAction(
                  icon: LucideIcons.link2,
                  label: context.l10n.receiveHubPaymentLink,
                  subtitle: context.l10n.receiveHubPaymentLinkSubtitle,
                  onTap: () =>
                      _openReceive(wallet, ReceiveFlowMode.paymentLink),
                ),
                if (_isNfcAvailable)
                  _ReceiveHubAction(
                    icon: LucideIcons.smartphoneNfc,
                    label: context.l10n.receiveHubNfc,
                    subtitle: context.l10n.receiveHubNfcSubtitle,
                    onTap: () => _openReceive(wallet, ReceiveFlowMode.nfc),
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
    return ReceiveFlowStatePanel(
      icon: LucideIcons.wallet,
      title: context.l10n.receiveHubNoWalletTitle,
      message: context.l10n.receiveHubNoWalletMessage,
    );
  }
}

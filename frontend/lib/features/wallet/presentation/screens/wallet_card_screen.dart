import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/wallet/presentation/widgets/wallet_credit_card.dart';

const Color _walletCardScreenBackground = Color(0xFF080A0D);

class WalletCardScreen extends ConsumerStatefulWidget {
  const WalletCardScreen({super.key});

  @override
  ConsumerState<WalletCardScreen> createState() => _WalletCardScreenState();
}

class _WalletCardScreenState extends ConsumerState<WalletCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(walletProvider) is WalletInitial) {
        ref.read(walletProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final navigationClearance =
        AppPrimaryNavigationBar.scaffoldBottomClearance(context);

    return Scaffold(
      backgroundColor: _walletCardScreenBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, navigationClearance),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _WalletCardContent(walletState: walletState),
                ),
              ),
            ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.card,
          ),
        ],
      ),
    );
  }
}

class _WalletCardContent extends StatelessWidget {
  final WalletState walletState;

  const _WalletCardContent({required this.walletState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (walletState is WalletLoading || walletState is WalletInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8FA0B2)),
      );
    }

    if (walletState is WalletError) {
      return _SolidMessage(
        icon: LucideIcons.alertCircle,
        title: 'Cartao indisponivel',
        message: (walletState as WalletError).message,
      );
    }

    final loaded = walletState as WalletLoaded;
    final wallet = loaded.selectedWallet ??
        (loaded.wallets.isNotEmpty ? loaded.wallets.first : null);

    if (wallet == null) {
      return const _SolidMessage(
        icon: LucideIcons.creditCard,
        title: 'Nenhum cartao ativo',
        message: 'Crie uma carteira para habilitar o cartao da conta.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cartao',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          wallet.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.56),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: WalletCreditCard(
            wallet: wallet,
            colorIndex: 0,
            isSelected: true,
            showDetails: true,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _CardInfoRow(
          label: 'Nivel',
          value: wallet.cardType.label,
        ),
        _CardInfoRow(
          label: 'Deposito externo',
          value: WalletCardType.formatRate(wallet.depositFeeRate),
        ),
        _CardInfoRow(
          label: 'Saque externo',
          value: WalletCardType.formatRate(wallet.withdrawalFeeRate),
        ),
      ],
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF111418),
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.52),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SolidMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF111418),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8FA0B2), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

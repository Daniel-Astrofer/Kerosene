import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_statement_insights.dart';
import 'package:kerosene/shared/widgets/bitcoin_refresh_indicator.dart';

class TransactionStatementScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const TransactionStatementScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<TransactionStatementScreen> createState() =>
      _TransactionStatementScreenState();
}

class _TransactionStatementScreenState
    extends ConsumerState<TransactionStatementScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(walletProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    ref.invalidate(transactionHistoryProvider);
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(transactionHistoryProvider.future),
    ]);
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final walletState = ref.watch(walletProvider);
    final wallets =
        walletState is WalletLoaded ? walletState.wallets : const <Wallet>[];
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 132.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth >= 900 ? 980.0 : 430.0;

    if (historyAsync.isLoading && !historyAsync.hasValue) {
      return const KeroseneLogoLoadingView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    BitcoinRefreshIndicator(onRefresh: _refreshData),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: _StatementTopBar(onBack: _handleBack),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Text(
                          context.tr.financialStatementReportTitle,
                          style: AppTypography.newsreader(
                            color: Colors.white,
                            fontSize: screenWidth >= 720 ? 40 : 34,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    historyAsync.when(
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: SizedBox.shrink(),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StatementMessage(
                          icon: KeroseneIcons.warning,
                          title: context.tr.financialStatementLoadErrorTitle,
                          message: ErrorTranslator.translate(
                            context.tr,
                            error.toString(),
                          ),
                        ),
                      ),
                      data: (transactions) {
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            bottomPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: TransactionStatementInsights(
                              transactions: transactions,
                              wallets: wallets,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.history,
          ),
        ],
      ),
    );
  }
}

class _StatementTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _StatementTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: KeroseneIcons.back, onPressed: onBack),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.hexFF1C1C1E,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StatementMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.64), size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: AppColors.hexFF8A8A8E,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

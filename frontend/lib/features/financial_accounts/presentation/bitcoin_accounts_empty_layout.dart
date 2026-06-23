import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';

import 'bitcoin_accounts_presentation_support.dart';

class BitcoinAccountsEmptyLayout extends StatelessWidget {
  final double bottomClearance;
  final VoidCallback onBack;
  final VoidCallback onCreateInternalAccount;
  final VoidCallback onCreateColdWallet;
  final Future<void> Function() onRefresh;

  const BitcoinAccountsEmptyLayout({
    super.key,
    required this.bottomClearance,
    required this.onBack,
    required this.onCreateInternalAccount,
    required this.onCreateColdWallet,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colors = BitcoinAccountsColors.of(context);

    return RefreshIndicator(
      color: colors.text,
      backgroundColor: colors.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              responsive.isTinyPhone ? 14 : 18,
              responsive.horizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.mobileContentMaxWidth,
                  ),
                  child: _BitcoinAccountsEmptyHeader(onBack: onBack),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              0,
              responsive.horizontalPadding,
              bottomClearance,
            ),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.mobileContentMaxWidth,
                  ),
                  child: Column(
                    children: [
                      const Expanded(
                        child: Center(
                          child: _BitcoinAccountsEmptyContent(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(56),
                          textStyle: AppTypography.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onCreateInternalAccount,
                        child: Text(context.tr.bitcoinAccountsNewKeroseneCard),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.text,
                          side: BorderSide(
                            color: colors.text.withValues(alpha: 0.22),
                          ),
                          minimumSize: const Size.fromHeight(54),
                          textStyle: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onCreateColdWallet,
                        child: const Text('Criar Cold Wallet'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BitcoinAccountsEmptyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _BitcoinAccountsEmptyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BitcoinAccountsEmptyBackButton(onTap: onBack),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              context.tr.bitcoinAccountsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.newsreader(
                color: colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BitcoinAccountsEmptyBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BitcoinAccountsEmptyBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(KeroseneIcons.back, color: colors.text, size: 24),
        ),
      ),
    );
  }
}

class _BitcoinAccountsEmptyContent extends StatelessWidget {
  const _BitcoinAccountsEmptyContent();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.text.withValues(alpha: 0.05),
            border: Border.all(color: colors.text.withValues(alpha: 0.10)),
          ),
          child: Icon(KeroseneIcons.wallet, color: colors.text, size: 32),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                context.tr.bitcoinAccountsEmptyTitle,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.bitcoinAccountsEmptyMessage,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: colors.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

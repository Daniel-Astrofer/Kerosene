// ignore_for_file: unused_element, unused_import, use_key_in_widget_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';
import 'package:kerosene/features/financial_accounts/domain/services/cold_wallet_public_material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';

import 'bitcoin_accounts_empty_layout.dart';
import 'bitcoin_accounts_header.dart';
import 'bitcoin_accounts_presentation_support.dart';

import 'bitcoin_screens/cold_wallet_creation_screen.dart';
import 'bitcoin_screens/internal_account_creation_screen.dart';
import 'bitcoin_widgets/receive_sheet.dart';
import 'bitcoin_widgets/bottom_sheets.dart';
import 'bitcoin_accounts_details.dart';
import 'bitcoin_accounts_internal_sections.dart';
import 'bitcoin_accounts_advanced_sections.dart';

class BitcoinAccountsScreen extends ConsumerStatefulWidget {
  const BitcoinAccountsScreen({super.key});

  @override
  ConsumerState<BitcoinAccountsScreen> createState() =>
      BitcoinAccountsScreenState();
}

class BitcoinAccountsScreenState extends ConsumerState<BitcoinAccountsScreen> {
  int selectedAccountIndex = 0;
  final Map<String, ReceivingRequestView> receiveAddressOverrides = {};

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(bitcoinAccountsProvider);
    final bottom = AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final responsive = context.responsive;
    final colors = BitcoinAccountsColors.of(context);
    final authState = ref.watch(authControllerProvider);
    final userDisplayName =
        authState is AuthAuthenticated ? authState.user.name.trim() : '';

    return accounts.when(
      loading: () => const Center(child: TorLoadingDots()),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.hexFF000000,
        body: Stack(
          children: [
            SafeArea(
              child: BitcoinAccountsEmptyLayout(
                bottomClearance: bottom,
                onBack: handleHeaderBack,
                onCreateInternalAccount: openInternalAccountFlow,
                onCreateColdWallet: openColdWalletFlow,
                onRefresh: () =>
                    ref.read(bitcoinAccountsProvider.notifier).refresh(),
              ),
            ),
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.card,
            ),
          ],
        ),
      ),
      data: (visibleAccounts) {
        final isEmptyState = visibleAccounts.isEmpty;

        return Scaffold(
          backgroundColor:
              isEmptyState ? AppColors.hexFF000000 : colors.background,
          body: Stack(
            children: [
              SafeArea(
                child: isEmptyState
                    ? BitcoinAccountsEmptyLayout(
                        bottomClearance: bottom,
                        onBack: handleHeaderBack,
                        onCreateInternalAccount: openInternalAccountFlow,
                        onCreateColdWallet: openColdWalletFlow,
                        onRefresh: () => ref
                            .read(bitcoinAccountsProvider.notifier)
                            .refresh(),
                      )
                    : RefreshIndicator(
                        color: colors.text,
                        backgroundColor: colors.surface,
                        onRefresh: () => ref
                            .read(bitcoinAccountsProvider.notifier)
                            .refresh(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            responsive.horizontalPadding,
                            responsive.isTinyPhone ? 14 : 18,
                            responsive.horizontalPadding,
                            bottom,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: responsive.mobileContentMaxWidth,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    BitcoinAccountsHeader(
                                      onBack: handleHeaderBack,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AccountsContent(
                                      accounts: visibleAccounts,
                                      userDisplayName: userDisplayName,
                                      selectedAccountIndex:
                                          selectedAccountIndex,
                                      receiveAddressOverrides:
                                          receiveAddressOverrides,
                                      onAccountChanged: (index) => setState(() {
                                        selectedAccountIndex = index;
                                      }),
                                      onReceiveAddressRotated: (request) {
                                        setState(() {
                                          receiveAddressOverrides[
                                              request.accountId] = request;
                                        });
                                      },
                                      onCreateInternalAccount:
                                          openInternalAccountFlow,
                                      onCreateColdWallet: openColdWalletFlow,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              AppPrimaryNavigationBar.overlay(
                currentDestination: AppPrimaryDestination.card,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> openInternalAccountFlow() async {
    final changed = await Navigator.of(context).push<bool>(
      keroseneHorizontalRoute<bool>(
        builder: (_) => const InternalAccountCreationFlow(),
      ),
    );
    await reloadAccountsAfterChildFlow(force: changed == true);
  }

  Future<void> openColdWalletFlow() async {
    final changed = await Navigator.of(context).push<bool>(
      keroseneHorizontalRoute<bool>(
        builder: (_) => const ColdWalletCreationScreen(),
      ),
    );
    await reloadAccountsAfterChildFlow(force: changed == true);
  }

  Future<void> reloadAccountsAfterChildFlow({bool force = false}) async {
    if (!mounted) return;
    receiveAddressOverrides.clear();
    await ref.read(bitcoinAccountsProvider.notifier).refresh();
    if (!mounted) return;
    setState(() {
      if (force) {
        selectedAccountIndex = 0;
      }
    });
  }

  void handleHeaderBack() {
    AppPrimaryNavigationBar.backOrHome(context);
  }
}

class AccountsContent extends ConsumerWidget {
  final List<BitcoinAccount> accounts;
  final String userDisplayName;
  final int selectedAccountIndex;
  final Map<String, ReceivingRequestView> receiveAddressOverrides;
  final ValueChanged<int> onAccountChanged;
  final ValueChanged<ReceivingRequestView> onReceiveAddressRotated;
  final VoidCallback onCreateInternalAccount;
  final VoidCallback onCreateColdWallet;

  const AccountsContent({
    required this.accounts,
    required this.userDisplayName,
    required this.selectedAccountIndex,
    required this.receiveAddressOverrides,
    required this.onAccountChanged,
    required this.onReceiveAddressRotated,
    required this.onCreateInternalAccount,
    required this.onCreateColdWallet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accounts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatePanel(
            icon: KeroseneIcons.wallet,
            title: context.tr.bitcoinAccountsEmptyTitle,
            message: context.tr.bitcoinAccountsEmptyMessage,
            actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
            onAction: onCreateInternalAccount,
          ),
          const SizedBox(height: 14),
          CreateWalletActionChip(
            label: 'Cold Wallet',
            icon: KeroseneIcons.security,
            onTap: onCreateColdWallet,
          ),
        ],
      );
    }

    final selectedIndex = selectedAccountIndex.clamp(0, accounts.length - 1);
    final selectedAccount = accounts[selectedIndex];
    final canCreateKeroseneWallet = canCreateKeroseneWalletAccount(accounts);
    final canCreateColdWallet = canCreateColdWalletAccount(accounts);
    final txAsync = ref.watch(transactionHistoryProvider);
    final requestsAsync = selectedAccount.isWatchOnly
        ? const AsyncValue<List<ReceivingRequestView>>.data(
            <ReceivingRequestView>[],
          )
        : ref.watch(bitcoinAccountReceiveRequestsProvider(selectedAccount.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusedAccountPager(
          accounts: accounts,
          userDisplayName: userDisplayName,
          selectedIndex: selectedIndex,
          onChanged: onAccountChanged,
          selectedReceiveRequest: receiveAddressOverrides[selectedAccount.id] ??
              firstBitcoinReceiveRequest(requestsAsync),
        ),
        const SizedBox(height: 18),
        if (canCreateKeroseneWallet || canCreateColdWallet) ...[
          CreateWalletShortcut(
            canCreateInternalAccount: canCreateKeroseneWallet,
            canCreateColdWallet: canCreateColdWallet,
            onCreateInternalAccount: onCreateInternalAccount,
            onCreateColdWallet: onCreateColdWallet,
          ),
          const SizedBox(height: 22),
        ],
        FocusedAccountOptions(
          account: selectedAccount,
          requestsAsync: requestsAsync,
          receiveAddressOverride: receiveAddressOverrides[selectedAccount.id],
          onReceiveAddressRotated: onReceiveAddressRotated,
        ),
        const SizedBox(height: 28),
        FocusedAccountHistory(
          account: selectedAccount,
          transactionsAsync: txAsync,
          requestsAsync: requestsAsync,
        ),
      ],
    );
  }
}

bool canCreateInternalKeroseneAccount(List<BitcoinAccount> accounts) {
  return !accounts.any(
    (account) =>
        account.isActive && account.isInternal && !account.isCustodialOnchain,
  );
}

bool canCreateCustodialOnchainAccount(List<BitcoinAccount> accounts) {
  return !accounts.any(
    (account) => account.isActive && account.isCustodialOnchain,
  );
}

bool canCreateKeroseneWalletAccount(List<BitcoinAccount> accounts) {
  return canCreateInternalKeroseneAccount(accounts) ||
      canCreateCustodialOnchainAccount(accounts);
}

bool canCreateColdWalletAccount(List<BitcoinAccount> accounts) {
  final activeColdWallets = accounts
      .where((account) => account.isActive && account.isWatchOnly)
      .length;
  return activeColdWallets < maxActiveColdWallets;
}

class _AccountCardPalette {
  final Color top;
  final Color middle;
  final Color bottom;
  final Color accent;
  final Color glow;

  const _AccountCardPalette({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.accent,
    required this.glow,
  });
}

_AccountCardPalette _accountCardPalette(BitcoinAccount account) {
  if (account.isWatchOnly) {
    return const _AccountCardPalette(
      top: AppColors.hexFF242424,
      middle: AppColors.hexFF151515,
      bottom: AppColors.hexFF050505,
      accent: AppColors.hexFFC4C4C4,
      glow: AppColors.hexFF8A8A8E,
    );
  }

  if (account.isCustodialOnchain) {
    return const _AccountCardPalette(
      top: AppColors.hexFF222222,
      middle: AppColors.hexFF111111,
      bottom: AppColors.hexFF020303,
      accent: AppColors.hexFF63FEA7,
      glow: AppColors.hexFF63FEA7,
    );
  }

  return const _AccountCardPalette(
    top: AppColors.hexFF1F1F1F,
    middle: AppColors.hexFF101010,
    bottom: AppColors.hexFF000000,
    accent: AppColors.hexFFFFFFFF,
    glow: AppColors.hexFFC4C4C4,
  );
}

class FocusedAccountPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final String userDisplayName;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ReceivingRequestView? selectedReceiveRequest;

  const FocusedAccountPager({
    required this.accounts,
    required this.userDisplayName,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedReceiveRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.96,
              initialPage: selectedIndex,
            ),
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FocusedAccountCard(
                  account: accounts[index],
                  userDisplayName: userDisplayName,
                  receiveRequest:
                      index == selectedIndex ? selectedReceiveRequest : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < accounts.length; index++)
              AnimatedContainer(
                duration: KeroseneMotion.fast,
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == selectedIndex
                      ? colors.text
                      : colors.text.withValues(alpha: 0.18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class FocusedAccountCard extends StatelessWidget {
  final BitcoinAccount account;
  final String userDisplayName;
  final ReceivingRequestView? receiveRequest;

  const FocusedAccountCard({
    required this.account,
    required this.userDisplayName,
    this.receiveRequest,
  });

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final identifier = bitcoinAccountCardIdentifier(
      account,
      receiveRequest: receiveRequest,
    );
    final displayIdentifier = identifier.isEmpty ? account.id : identifier;
    final ownerName = userDisplayName.trim().isEmpty
        ? context.tr.homeFallbackUser
        : userDisplayName.trim();
    final networkLabel = bitcoinAccountCardNetworkLabel(account);
    final balanceLabel = formatSats(bitcoinAccountVisibleBalance(account));
    final colors = BitcoinAccountsColors.of(context);
    final cardPalette = _accountCardPalette(account);

    return Align(
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow,
                blurRadius: 26,
                spreadRadius: -20,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0, 0.46, 1],
                        colors: [
                          cardPalette.top,
                          cardPalette.middle,
                          cardPalette.bottom,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -78,
                  right: -58,
                  width: 210,
                  height: 210,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cardPalette.glow.withValues(alpha: 0.22),
                          cardPalette.glow.withValues(alpha: 0.035),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -72,
                  bottom: -116,
                  width: 260,
                  height: 260,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cardPalette.accent.withValues(alpha: 0.22),
                          cardPalette.accent.withValues(alpha: 0.045),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: const Alignment(-1.25, -0.95),
                        end: const Alignment(0.85, 1.15),
                        stops: const [0, 0.23, 0.26, 0.56, 1],
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.035),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.30),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  color: colors.text,
                                  fontSize: 14,
                                  letterSpacing: -0.1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.text.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colors.text.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  networkLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    color: colors.text.withValues(alpha: 0.82),
                                    fontSize: 10.5,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.newsreader(
                                    color: colors.text,
                                    fontSize: 29,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  kKeroseneBrandLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    color: colors.mutedText,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  balanceLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    color: colors.text,
                                    fontSize: 18,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.text.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.text.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayIdentifier,
                                    softWrap: false,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.technicalMono(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.text
                                                .withValues(alpha: 0.68),
                                            fontSize: 10.5,
                                            height: 1.2,
                                            letterSpacing: -0.15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InlineCopyButton(
                                  value: displayIdentifier,
                                  semanticLabel: 'Copiar endereço da carteira',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InlineCopyButton extends StatelessWidget {
  final String value;
  final String semanticLabel;

  const InlineCopyButton({
    required this.value,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: colors.text.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: value.trim().isEmpty
              ? null
              : () => copyText(
                    context,
                    value,
                    title: 'Copiado',
                    message: 'Dado disponível na área de transferência.',
                  ),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              KeroseneIcons.copy,
              color: colors.text,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class CreateWalletShortcut extends StatelessWidget {
  final bool canCreateInternalAccount;
  final bool canCreateColdWallet;
  final VoidCallback onCreateInternalAccount;
  final VoidCallback onCreateColdWallet;

  const CreateWalletShortcut({
    required this.canCreateInternalAccount,
    required this.canCreateColdWallet,
    required this.onCreateInternalAccount,
    required this.onCreateColdWallet,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (canCreateInternalAccount)
        Expanded(
          child: CreateWalletActionChip(
            label: context.tr.bitcoinAccountsNewKeroseneCard,
            icon: KeroseneIcons.plus,
            onTap: onCreateInternalAccount,
          ),
        ),
      if (canCreateInternalAccount && canCreateColdWallet)
        const SizedBox(width: 12),
      if (canCreateColdWallet)
        Expanded(
          child: CreateWalletActionChip(
            label: 'Cold Wallet',
            icon: KeroseneIcons.security,
            onTap: onCreateColdWallet,
          ),
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(children: actions);
  }
}

class CreateWalletActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const CreateWalletActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.text, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletLockSwitchRow extends StatelessWidget {
  final BitcoinAccount account;
  final bool busy;
  final VoidCallback onEnableLock;

  const WalletLockSwitchRow({
    required this.account,
    required this.busy,
    required this.onEnableLock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final locked = walletIsLocked(account);
    final label =
        account.isWatchOnly ? 'Arquivar acompanhamento' : 'Bloquear carteira';
    final hint = locked
        ? 'A carteira já está bloqueada para uso.'
        : 'Ative para bloquear esta carteira.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.text.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: AppTypography.inter(
                    color: colors.mutedText,
                    fontSize: 11,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (busy)
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: locked,
              activeThumbColor: colors.text,
              onChanged: locked
                  ? null
                  : (enabled) {
                      if (!enabled) return;
                      HapticFeedback.selectionClick();
                      onEnableLock();
                    },
            ),
        ],
      ),
    );
  }
}

bool walletIsLocked(BitcoinAccount account) {
  return switch (account.status.trim().toUpperCase()) {
    'DISABLED' || 'BLOCKED' || 'FROZEN' || 'ARCHIVED' => true,
    _ => false,
  };
}

class FocusedAccountOptions extends ConsumerStatefulWidget {
  final BitcoinAccount account;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final ReceivingRequestView? receiveAddressOverride;
  final ValueChanged<ReceivingRequestView> onReceiveAddressRotated;

  const FocusedAccountOptions({
    required this.account,
    required this.requestsAsync,
    required this.receiveAddressOverride,
    required this.onReceiveAddressRotated,
  });

  @override
  ConsumerState<FocusedAccountOptions> createState() =>
      FocusedAccountOptionsState();
}

class FocusedAccountOptionsState extends ConsumerState<FocusedAccountOptions> {
  String? expandedKey;
  String? busyAction;

  @override
  void didUpdateWidget(covariant FocusedAccountOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      expandedKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final hasPublicMaterial = bitcoinAccountHasPublicMaterial(account);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountExpansionItem(
          title: 'STATUS DA CARTEIRA',
          expanded: expandedKey == 'status',
          onTap: () => toggle('status'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountDetailRows(
                rows: [
                  AccountDetail(
                    'Situação',
                    friendlyStatus(context, account.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              WalletLockSwitchRow(
                account: account,
                busy: busyAction == 'archive',
                onEnableLock: () => archiveWallet(account),
              ),
            ],
          ),
        ),
        AccountExpansionItem(
          title: 'ENDEREÇO DE RECEBIMENTO',
          expanded: expandedKey == 'receive',
          onTap: () => toggle('receive'),
          child: ReceiveMaterialDetails(
            account: account,
            requestsAsync: widget.requestsAsync,
            receiveAddressOverride: widget.receiveAddressOverride,
            rotating: busyAction == 'rotate',
            onRotate: account.isWatchOnly
                ? null
                : () => rotateReceiveAddress(account),
          ),
        ),
        AccountExpansionItem(
          title: 'NOME DA CARTEIRA',
          expanded: expandedKey == 'name',
          onTap: () => toggle('name'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountDetailRows(
                rows: [
                  AccountDetail(
                    'Nome',
                    account.label.trim().isEmpty
                        ? context.tr.bitcoinAccountsUnnamedAccount
                        : account.label.trim(),
                  ),
                  AccountDetail('ID da conta', account.id, copyable: true),
                  if ((account.cardId ?? '').trim().isNotEmpty)
                    AccountDetail('Card ID', account.cardId!, copyable: true),
                  if ((account.coldWalletId ?? '').trim().isNotEmpty)
                    AccountDetail(
                      'Cold wallet ID',
                      account.coldWalletId!,
                      copyable: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AccountOptionActionButton(
                label: 'Trocar nome',
                icon: KeroseneIcons.edit,
                busy: busyAction == 'rename',
                onPressed: () => renameWallet(account),
              ),
            ],
          ),
        ),
        if (hasPublicMaterial)
          AccountExpansionItem(
            title: 'MATERIAL PÚBLICO',
            expanded: expandedKey == 'public',
            onTap: () => toggle('public'),
            child: AccountDetailRows(
              rows: [
                AccountDetail(
                  'Fingerprint',
                  bitcoinAccountDisplayValue(account.xpubFingerprint),
                  copyable: (account.xpubFingerprint ?? '').trim().isNotEmpty,
                ),
                AccountDetail(
                  'Derivação',
                  bitcoinAccountDisplayValue(account.derivationPath),
                  copyable: (account.derivationPath ?? '').trim().isNotEmpty,
                ),
                AccountDetail(
                  'Script policy',
                  bitcoinAccountDisplayValue(account.scriptPolicy),
                  copyable: (account.scriptPolicy ?? '').trim().isNotEmpty,
                ),
              ],
            ),
          ),
        if (account.isWatchOnly)
          ColdWalletBackendOptions(
            account: account,
            expandedKey: expandedKey,
            onToggle: toggle,
          ),
      ],
    );
  }

  void toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => expandedKey = expandedKey == key ? null : key);
  }

  String archiveActionLabel(BitcoinAccount account) {
    if (account.isWatchOnly) return 'Arquivar acompanhamento';
    if (account.isCustodialOnchain) return 'Bloquear carteira';
    return 'Bloquear cartão';
  }

  Future<void> rotateReceiveAddress(BitcoinAccount account) async {
    setState(() => busyAction = 'rotate');
    try {
      final rotated = await ref
          .read(bitcoinAccountsProvider.notifier)
          .rotateReceiveAddress(accountId: account.id);
      widget.onReceiveAddressRotated(rotated);
      ref.invalidate(bitcoinAccountReceiveRequestsProvider(account.id));
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: 'Endereço rotacionado',
        message: bitcoinAccountDisplayValue(rotated.address),
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Endereço não rotacionado',
        message: 'A Kerosene não conseguiu gerar um novo endereço agora.',
      );
    } finally {
      if (mounted) {
        setState(() => busyAction = null);
      }
    }
  }

  Future<void> renameWallet(BitcoinAccount account) async {
    final nextLabel = await askWalletName(context, account);
    if (nextLabel == null) return;
    setState(() => busyAction = 'rename');
    try {
      await ref.read(bitcoinAccountsProvider.notifier).renameWallet(
            accountId: account.id,
            label: nextLabel,
          );
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: 'Nome atualizado',
        message: nextLabel,
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Nome não atualizado',
        message: 'Revise o nome da carteira e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => busyAction = null);
      }
    }
  }

  Future<void> archiveWallet(BitcoinAccount account) async {
    final confirmed = await confirmWalletArchive(context, account);
    if (!confirmed) return;
    setState(() => busyAction = 'archive');
    try {
      await ref.read(bitcoinAccountsProvider.notifier).archiveWallet(
            accountId: account.id,
          );
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: account.isWatchOnly
            ? 'Acompanhamento arquivado'
            : 'Carteira bloqueada',
        message: account.isWatchOnly
            ? 'A carteira saiu da lista ativa.'
            : 'A carteira saiu da lista ativa de movimentação.',
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Ação não concluída',
        message: 'A carteira não pode ser alterada neste momento.',
      );
    } finally {
      if (mounted) {
        setState(() => busyAction = null);
      }
    }
  }
}

class ColdWalletBackendOptions extends ConsumerWidget {
  final BitcoinAccount account;
  final String? expandedKey;
  final ValueChanged<String> onToggle;

  const ColdWalletBackendOptions({
    required this.account,
    required this.expandedKey,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coldWalletId = coldWalletIdForAccount(account);
    final utxosAsync = ref.watch(bitcoinColdWalletUtxosProvider(coldWalletId));
    final psbtsAsync = ref.watch(bitcoinColdWalletPsbtsProvider(coldWalletId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountExpansionItem(
          title: 'UTXOS MONITORADOS',
          expanded: expandedKey == 'utxos',
          onTap: () => onToggle('utxos'),
          child: utxosAsync.when(
            loading: () => const InlineLoadingState(),
            error: (_, __) => MiniEmptyState(
              text: context.tr.bitcoinAdvancedUtxosUnavailableMessage,
            ),
            data: (utxos) => UtxoPreviewList(utxos: utxos),
          ),
        ),
        AccountExpansionItem(
          title: 'PSBT WORKFLOWS',
          expanded: expandedKey == 'psbts',
          onTap: () => onToggle('psbts'),
          child: psbtsAsync.when(
            loading: () => const InlineLoadingState(),
            error: (_, __) => MiniEmptyState(
              text: context.tr.bitcoinAdvancedPsbtsUnavailableMessage,
            ),
            data: (workflows) => ReadOnlyPsbtWorkflowList(
              workflows: workflows,
              onCopyUnsigned: (workflow) => copyText(
                context,
                workflow.unsignedPsbt,
                title: context.tr.bitcoinAdvancedPsbtCopiedTitle,
                message: context.tr.bitcoinAdvancedSignExternallyMessage,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReadOnlyPsbtWorkflowList extends StatelessWidget {
  final List<PsbtWorkflowView> workflows;
  final ValueChanged<PsbtWorkflowView> onCopyUnsigned;

  const ReadOnlyPsbtWorkflowList({
    required this.workflows,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return MiniEmptyState(text: context.tr.bitcoinAdvancedNoPsbts);
    }

    final visible = workflows.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visible.length; index++)
          ReadOnlyPsbtWorkflowRow(
            workflow: visible[index],
            showDivider: index != visible.length - 1,
            onCopyUnsigned: () => onCopyUnsigned(visible[index]),
          ),
        if (workflows.length > visible.length)
          MiniHint(
            text: context.tr.bitcoinAdvancedHiddenPsbts(
              workflows.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class ReadOnlyPsbtWorkflowRow extends StatelessWidget {
  final PsbtWorkflowView workflow;
  final bool showDivider;
  final VoidCallback onCopyUnsigned;

  const ReadOnlyPsbtWorkflowRow({
    required this.workflow,
    required this.showDivider,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: KeroseneBrandTokens.borderSubtle),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shortText(workflow.destinationAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: KeroseneBrandTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(text: psbtStatusLabel(context, workflow.status)),
            ],
          ),
          const SizedBox(height: 8),
          AccountDetailRows(
            rows: [
              AccountDetail('Valor', formatSats(workflow.amountSats)),
              AccountDetail('Taxa', formatSats(workflow.estimatedFeeSats)),
              if ((workflow.broadcastTxidRef ?? '').trim().isNotEmpty)
                AccountDetail(
                  'Broadcast',
                  workflow.broadcastTxidRef!,
                  copyable: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: BitcoinAccountsColors.of(context)
                  .outlinedButtonStyle(minHeight: 38),
              onPressed: onCopyUnsigned,
              icon: const Icon(KeroseneIcons.copy, size: 15),
              label: Text(context.tr.bitcoinAdvancedCopyUnsignedAction),
            ),
          ),
        ],
      ),
    );
  }
}

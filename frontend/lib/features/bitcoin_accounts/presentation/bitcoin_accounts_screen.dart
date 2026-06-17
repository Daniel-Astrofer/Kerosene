import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/bitcoin_accounts/data/cold_wallet_public_material.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

part 'screens/cold_wallet_creation_screen.dart';
part 'screens/internal_account_creation_screen.dart';
part 'widgets/receive_sheet.dart';
part 'widgets/create_psbt_sheet.dart';
part 'widgets/bottom_sheets.dart';

class _BitcoinAccountsColors {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color text;
  final Color mutedText;
  final Color faintText;

  const _BitcoinAccountsColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.text,
    required this.mutedText,
    required this.faintText,
  });

  factory _BitcoinAccountsColors.of(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return const _BitcoinAccountsColors(
        isLight: true,
        background: Color(0xFFF7F7F5),
        surface: Color(0xFFFFFFFF),
        surfaceAlt: Color(0xFFF0F1EE),
        surfaceRaised: Color(0xFFE5E7E3),
        border: Color(0xFFDDE0D8),
        borderStrong: Color(0xFFC8CDC3),
        divider: Color(0xFFE2E4DE),
        text: Color(0xFF181A17),
        mutedText: Color(0xFF62675F),
        faintText: Color(0xFF8B9087),
      );
    }

    return const _BitcoinAccountsColors(
      isLight: false,
      background: monoBackgroundColor,
      surface: monoSurfaceColor,
      surfaceAlt: monoSurfaceAltColor,
      surfaceRaised: monoSurfaceRaisedColor,
      border: monoBorderColor,
      borderStrong: monoBorderStrongColor,
      divider: monoDividerColor,
      text: monoTextColor,
      mutedText: monoMutedTextColor,
      faintText: monoFaintTextColor,
    );
  }

  Color get filledButtonForeground => isLight ? Colors.white : Colors.black;
  Color get headerButtonBackground =>
      text.withValues(alpha: isLight ? 0.08 : 0.10);
  Color get selectedDot => text;
  Color get idleDot => text.withValues(alpha: isLight ? 0.24 : 0.30);
  Color get rowDivider => text.withValues(alpha: isLight ? 0.08 : 0.05);
  Color get skeleton => text.withValues(alpha: isLight ? 0.08 : 0.05);
  Color get cardShadow => Colors.black.withValues(alpha: isLight ? 0.10 : 0.50);
  Color get panelShadow =>
      Colors.black.withValues(alpha: isLight ? 0.08 : 0.28);
  BorderRadius get panelRadius =>
      isLight ? BorderRadius.circular(18) : monoRadius;
  BorderRadius get controlRadius =>
      isLight ? BorderRadius.circular(14) : monoRadius;
  BorderRadius get pillRadius =>
      isLight ? BorderRadius.circular(999) : monoRadius;
  BorderRadius get iconRadius =>
      isLight ? BorderRadius.circular(12) : monoRadius;

  BoxDecoration panelDecoration({
    Color? color,
    Color? borderColor,
    bool showShadow = true,
    BorderRadius? borderRadius,
  }) {
    if (!isLight) {
      return monochromePanelDecoration(
        color: color ?? surface,
        borderColor: borderColor ?? border,
        showShadow: showShadow,
      );
    }

    return BoxDecoration(
      color: color ?? surface,
      borderRadius: borderRadius ?? panelRadius,
      border: Border.all(color: borderColor ?? border),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: panelShadow,
                blurRadius: 24,
                spreadRadius: -18,
                offset: const Offset(0, 14),
              ),
            ]
          : null,
    );
  }

  InputDecoration inputDecoration({
    required String label,
    String? hintText,
    String? counterText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    if (!isLight) {
      return monochromeInputDecoration(
        label: label,
        hintText: hintText,
        counterText: counterText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      );
    }

    final radius = controlRadius;
    final borderSide = BorderSide(color: borderStrong);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: borderSide,
    );

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      counterText: counterText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(color: mutedText),
      hintStyle: AppTypography.bodySmall.copyWith(color: faintText),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: text),
      ),
    );
  }

  ButtonStyle filledButtonStyle({
    bool emphasis = true,
    bool destructive = false,
    double minHeight = 52,
  }) {
    if (!isLight) {
      return monochromeFilledButtonStyle(
        emphasis: emphasis,
        destructive: destructive,
        minHeight: minHeight,
      );
    }

    final background = destructive
        ? surfaceAlt
        : emphasis
            ? text
            : surfaceAlt;
    final foreground = destructive
        ? text
        : emphasis
            ? filledButtonForeground
            : text;
    final outline = destructive || emphasis ? borderStrong : border;

    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: surfaceRaised,
      disabledForegroundColor: faintText,
      minimumSize: Size.fromHeight(minHeight),
      textStyle: AppTypography.buttonText.copyWith(
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
      side: BorderSide(color: outline),
    );
  }

  ButtonStyle outlinedButtonStyle({
    double minHeight = 48,
    Color? foregroundColor,
  }) {
    if (!isLight) {
      return monochromeOutlinedButtonStyle(
        minHeight: minHeight,
        foregroundColor: foregroundColor ?? monoTextColor,
      );
    }

    return OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(minHeight),
      foregroundColor: foregroundColor ?? text,
      disabledForegroundColor: faintText,
      side: BorderSide(color: borderStrong),
      backgroundColor: surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
      textStyle: AppTypography.buttonText.copyWith(
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  ButtonStyle textButtonStyle() {
    if (!isLight) {
      return monochromeTextButtonStyle();
    }

    return TextButton.styleFrom(
      foregroundColor: mutedText,
      disabledForegroundColor: faintText,
      textStyle: AppTypography.caption.copyWith(
        color: mutedText,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class BitcoinAccountsScreen extends ConsumerStatefulWidget {
  const BitcoinAccountsScreen({super.key});

  @override
  ConsumerState<BitcoinAccountsScreen> createState() =>
      _BitcoinAccountsScreenState();
}

class _BitcoinAccountsScreenState extends ConsumerState<BitcoinAccountsScreen> {
  int _selectedInternalIndex = 0;
  String? _managedAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(bitcoinAccountsProvider);
    final bottom = AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final responsive = context.responsive;
    final colors = _BitcoinAccountsColors.of(context);
    final isEmptyState = accounts.asData?.value.isEmpty == true;

    return Scaffold(
      backgroundColor:
          isEmptyState ? const Color(0xFF000000) : colors.background,
      body: Stack(
        children: [
          SafeArea(
            child: isEmptyState
                ? _BitcoinAccountsEmptyLayout(
                    bottomClearance: bottom,
                    onBack: _handleHeaderBack,
                    onCreateInternalAccount: _openInternalAccountFlow,
                    onRefresh: () =>
                        ref.read(bitcoinAccountsProvider.notifier).refresh(),
                  )
                : RefreshIndicator(
                    color: colors.text,
                    backgroundColor: colors.surface,
                    onRefresh: () =>
                        ref.read(bitcoinAccountsProvider.notifier).refresh(),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Header(
                                  onAdd: _openInternalAccountFlow,
                                  managing: _managedAccountId != null,
                                  onBack: _managedAccountId == null
                                      ? null
                                      : () => setState(
                                            () => _managedAccountId = null,
                                          ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                accounts.when(
                                  loading: () => const _AccountsSkeleton(),
                                  error: (_, __) => _StatePanel(
                                    icon: LucideIcons.alertTriangle,
                                    title: context.tr.bitcoinAccountsErrorTitle,
                                    message:
                                        context.tr.bitcoinAccountsErrorMessage,
                                    actionLabel: context.tr.tryAgain,
                                    onAction: () => ref
                                        .read(bitcoinAccountsProvider.notifier)
                                        .refresh(),
                                  ),
                                  data: (items) => _AccountsContent(
                                    accounts: items,
                                    selectedInternalIndex:
                                        _selectedInternalIndex,
                                    managedAccountId: _managedAccountId,
                                    onInternalChanged: (index) => setState(() {
                                      _selectedInternalIndex = index;
                                      _managedAccountId = null;
                                    }),
                                    onManageAccount: (account) => setState(() {
                                      _managedAccountId = account.id;
                                    }),
                                    onCreateColdWallet: _openColdWalletFlow,
                                    onCreateInternalAccount:
                                        _openInternalAccountFlow,
                                    onReceive: (account) =>
                                        _showReceiveSheet(context, account),
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
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.card,
          ),
        ],
      ),
    );
  }

  void _openColdWalletFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ColdWalletCreationScreen(),
      ),
    );
  }

  void _openInternalAccountFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _InternalAccountCreationFlow(),
      ),
    );
  }

  void _handleHeaderBack() {
    AppPrimaryNavigationBar.backOrHome(context);
  }
}

class _BitcoinAccountsEmptyLayout extends StatelessWidget {
  final double bottomClearance;
  final VoidCallback onBack;
  final VoidCallback onCreateInternalAccount;
  final Future<void> Function() onRefresh;

  const _BitcoinAccountsEmptyLayout({
    required this.bottomClearance,
    required this.onBack,
    required this.onCreateInternalAccount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colors = _BitcoinAccountsColors.of(context);

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
                          textStyle: GoogleFonts.inter(
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
    final colors = _BitcoinAccountsColors.of(context);

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
              style: GoogleFonts.ibmPlexSerif(
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
    final colors = _BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(LucideIcons.arrowLeft, color: colors.text, size: 24),
        ),
      ),
    );
  }
}

class _BitcoinAccountsEmptyContent extends StatelessWidget {
  const _BitcoinAccountsEmptyContent();

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

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
          child: Icon(LucideIcons.walletCards, color: colors.text, size: 32),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                context.tr.bitcoinAccountsEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onBack;
  final bool managing;

  const _Header({
    required this.onAdd,
    required this.managing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Row(
      children: [
        if (onBack != null) ...[
          _RoundHeaderButton(icon: LucideIcons.chevronLeft, onTap: onBack!),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            'Carteira interna',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSerif(
              color: colors.text,
              fontSize: managing ? 32 : 36,
              fontWeight: FontWeight.w500,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RoundHeaderButton(icon: LucideIcons.plus, onTap: onAdd),
      ],
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Material(
      color: colors.headerButtonBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.text, size: 22),
        ),
      ),
    );
  }
}

class _AccountsContent extends ConsumerWidget {
  final List<BitcoinAccount> accounts;
  final int selectedInternalIndex;
  final String? managedAccountId;
  final ValueChanged<int> onInternalChanged;
  final ValueChanged<BitcoinAccount> onManageAccount;
  final VoidCallback onCreateColdWallet;
  final VoidCallback onCreateInternalAccount;
  final ValueChanged<BitcoinAccount> onReceive;

  const _AccountsContent({
    required this.accounts,
    required this.selectedInternalIndex,
    required this.managedAccountId,
    required this.onInternalChanged,
    required this.onManageAccount,
    required this.onCreateColdWallet,
    required this.onCreateInternalAccount,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internal = accounts.where((account) => account.isInternal).toList();
    final watchOnly = accounts.where((account) => account.isWatchOnly).toList();
    final selectedIndex = internal.isEmpty
        ? 0
        : selectedInternalIndex.clamp(0, internal.length - 1);
    final selectedInternal = internal.isEmpty ? null : internal[selectedIndex];
    BitcoinAccount? managedAccount;
    if (managedAccountId != null) {
      for (final account in internal) {
        if (account.id == managedAccountId) {
          managedAccount = account;
          break;
        }
      }
    }

    if (accounts.isEmpty) {
      return _StatePanel(
        icon: LucideIcons.walletCards,
        title: context.tr.bitcoinAccountsEmptyTitle,
        message: context.tr.bitcoinAccountsEmptyMessage,
        actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
        onAction: onCreateInternalAccount,
      );
    }

    if (managedAccount != null) {
      final account = managedAccount;
      return _InternalAccountManagementView(
        account: account,
        onReceive: () => onReceive(account),
      );
    }

    final txAsync = ref.watch(transactionHistoryProvider);
    final requestsAsync = selectedInternal == null
        ? const AsyncValue<List<ReceivingRequestView>>.data(
            <ReceivingRequestView>[],
          )
        : ref.watch(bitcoinAccountReceiveRequestsProvider(selectedInternal.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedInternal == null)
          _StatePanel(
            icon: LucideIcons.creditCard,
            title: context.tr.bitcoinAccountsNoKeroseneCard,
            message: context.tr.bitcoinAccountsEmptyMessage,
            actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
            onAction: onCreateInternalAccount,
          )
        else ...[
          _InternalCardPager(
            accounts: internal,
            selectedIndex: selectedIndex,
            onChanged: onInternalChanged,
            onTapCard: () => onManageAccount(selectedInternal),
          ),
          const SizedBox(height: 30),
          _InternalBalanceSection(account: selectedInternal),
          const SizedBox(height: 30),
          _ReceiveRequestsSection(
            requestsAsync: requestsAsync,
            onRetry: () => ref.invalidate(
              bitcoinAccountReceiveRequestsProvider(selectedInternal.id),
            ),
          ),
          const SizedBox(height: 30),
          _InternalTransactionsSection(
            account: selectedInternal,
            transactionsAsync: txAsync,
            requestsAsync: requestsAsync,
          ),
        ],
        const SizedBox(height: 32),
        _ColdWalletSection(
          accounts: watchOnly,
          onCreateColdWallet: onCreateColdWallet,
        ),
      ],
    );
  }
}

class _InternalCardPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapCard;

  const _InternalCardPager({
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.96,
              initialPage: selectedIndex,
            ),
            onPageChanged: onChanged,
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _InternalWalletCard(
                  account: accounts[index],
                  onTap: onTapCard,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < accounts.length; index++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == selectedIndex
                      ? colors.selectedDot
                      : colors.idleDot,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InternalWalletCard extends StatelessWidget {
  final BitcoinAccount account;
  final VoidCallback onTap;

  const _InternalWalletCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? 'Carteira Global'
        : account.walletTypeDescription.trim();
    final colors = _BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 224,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B38), Color(0xFF141414)],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSerif(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      _cardExpiryLabel(account),
                      style: GoogleFonts.ibmPlexSerif(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(text: typeDescription),
                ),
                const Spacer(),
                Text(
                  'Kerosene',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSerif(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shortCardIdentifier(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.technicalMono(
                          textStyle:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _cardCode(account),
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InternalBalanceSection extends StatelessWidget {
  final BitcoinAccount account;

  const _InternalBalanceSection({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final available = account.balanceAvailableSats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: context.tr.bitcoinAccountsKeroseneCardBadge),
            _Pill(text: _friendlyStatus(context, account.status)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsAvailableBalance,
                style: GoogleFonts.inter(
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              _formatSats(available),
              style: GoogleFonts.inter(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.bitcoinAccountsKeroseneCardNote,
          style: GoogleFonts.inter(
            color: colors.mutedText,
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ReceiveRequestsSection extends ConsumerWidget {
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final VoidCallback onRetry;

  const _ReceiveRequestsSection({
    required this.requestsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return _TransactionsPanel(
      title: context.tr.bitcoinReceiveRequestsTitle,
      children: requestsAsync.when(
        loading: () => const [
          _DarkSkeletonRow(),
          _DarkSkeletonRow(),
        ],
        error: (_, __) => [
          _DarkActionMessage(
            icon: LucideIcons.alertTriangle,
            title: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorTitle
                : context.tr.bitcoinReceiveRequestsOfflineTitle,
            message: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorMessage
                : context.tr.bitcoinReceiveRequestsOfflineMessage,
            actionLabel: context.tr.retry,
            onAction: onRetry,
          ),
        ],
        data: (requests) {
          if (requests.isEmpty) {
            return [
              _DarkActionMessage(
                icon: LucideIcons.inbox,
                title: context.tr.bitcoinReceiveRequestsEmptyTitle,
                message: context.tr.bitcoinReceiveRequestsEmptyMessage,
              ),
            ];
          }

          final visible = requests.take(5).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              _ReceiveRequestRow(
                request: visible[index],
                showDivider: index != visible.length - 1,
              ),
          ];
        },
      ),
    );
  }
}

class _ReceiveRequestRow extends StatelessWidget {
  final ReceivingRequestView request;
  final bool showDivider;

  const _ReceiveRequestRow({
    required this.request,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final title = request.amountSats == null
        ? context.tr.bitcoinReceiveRequestsFlexibleAmount
        : _formatSats(request.amountSats!);
    final subtitle = request.address.isEmpty
        ? request.id
        : '${_shortText(request.address)} | ${request.expiry.isEmpty ? context.tr.bitcoinReceiveRequestsNoExpiry : request.expiry}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Pill(text: _receiveStatusLabel(context, request.status)),
        ],
      ),
    );
  }
}

class _InternalTransactionsSection extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const _InternalTransactionsSection({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      loading: () => const _CompactLoadingPanel(),
      error: (_, __) => _TransactionsPanel(
        title: 'Transactions',
        children: [
          _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
        ],
      ),
      data: (requests) => transactionsAsync.when(
        loading: () => const _CompactLoadingPanel(),
        error: (_, __) => _TransactionsPanel(
          title: 'Transactions',
          children: [
            _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
          ],
        ),
        data: (transactions) {
          final rows = _transactionsForAccount(
            account: account,
            transactions: transactions,
            requests: requests,
          ).take(3).toList(growable: false);

          return _TransactionsPanel(
            title: 'Transactions',
            children: rows.isEmpty
                ? [_DarkListMessage(text: 'Sem transações desta carteira.')]
                : [
                    for (var index = 0; index < rows.length; index++)
                      _TransactionSummaryRow(
                        transaction: rows[index],
                        showDivider: index != rows.length - 1,
                      ),
                  ],
          );
        },
      ),
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _TransactionsPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.ibmPlexSerif(
            color: colors.text,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _TransactionSummaryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const _TransactionSummaryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : _transactionTitle(transaction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _relativeTransactionDate(transaction.timestamp),
                  style: GoogleFonts.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _signedSats(transaction),
            style: GoogleFonts.inter(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkListMessage extends StatelessWidget {
  final String text;

  const _DarkListMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: colors.mutedText,
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DarkActionMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DarkActionMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkSkeletonRow extends StatelessWidget {
  const _DarkSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Container(
      height: 58,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _CompactLoadingPanel extends StatelessWidget {
  const _CompactLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return SizedBox(
      height: 88,
      child: Center(
        child: CircularProgressIndicator(color: colors.text, strokeWidth: 2),
      ),
    );
  }
}

class _ColdWalletSection extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final VoidCallback onCreateColdWallet;

  const _ColdWalletSection({
    required this.accounts,
    required this.onCreateColdWallet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsColdWalletSection,
                style: GoogleFonts.ibmPlexSerif(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            IconButton(
              onPressed: onCreateColdWallet,
              icon: Icon(LucideIcons.plus, color: colors.text),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          _MutedPanel(text: context.tr.bitcoinAccountsNoColdWallet)
        else ...[
          for (final account in accounts) _ColdWalletTile(account: account),
          const SizedBox(height: 16),
          const _TaxEventsSection(),
        ],
      ],
    );
  }
}

class _ColdWalletTile extends StatelessWidget {
  final BitcoinAccount account;

  const _ColdWalletTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? context.tr.bitcoinAccountsColdWalletBadge
        : account.walletTypeDescription.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.snowflake, color: colors.text, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(text: typeDescription),
                        _Pill(text: context.tr.bitcoinAccountsReviewBalance),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.bitcoinAccountsObservedBalance,
                      style: GoogleFonts.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatSats(account.observedBalanceSats),
                      style: GoogleFonts.inter(
                        color: colors.mutedText,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.bitcoinAccountsColdWalletNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                account.xpubFingerprint ?? account.coldWalletId ?? '',
                style: AppTypography.technicalMono(
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ],
          ),
          _ColdWalletAdvancedPanel(account: account),
        ],
      ),
    );
  }
}

class _ColdWalletAdvancedPanel extends ConsumerWidget {
  final BitcoinAccount account;

  const _ColdWalletAdvancedPanel({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = _BitcoinAccountsColors.of(context);
    final coldWalletId = _coldWalletIdForAccount(account);
    final utxosAsync = ref.watch(bitcoinColdWalletUtxosProvider(coldWalletId));
    final workflowsAsync = ref.watch(
      bitcoinColdWalletPsbtsProvider(coldWalletId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Divider(color: colors.rowDivider, height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(LucideIcons.fileText, color: colors.text, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr.bitcoinAdvancedTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: colors.outlinedButtonStyle(minHeight: 42),
              onPressed: () => _showCreatePsbtSheet(context, account),
              icon: const Icon(LucideIcons.fileText, size: 16),
              label: Text(context.tr.bitcoinAdvancedNewPsbtAction),
            ),
            OutlinedButton.icon(
              style: colors.outlinedButtonStyle(minHeight: 42),
              onPressed: () {
                ref.invalidate(bitcoinColdWalletUtxosProvider(coldWalletId));
                ref.invalidate(bitcoinColdWalletPsbtsProvider(coldWalletId));
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.tr.bitcoinAdvancedRefreshAction),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AdvancedSubsection(
          title: context.tr.bitcoinAdvancedUtxosTitle,
          icon: LucideIcons.coins,
          child: utxosAsync.when(
            loading: () => const _MiniLoadingRows(),
            error: (_, __) => _MiniActionState(
              icon: LucideIcons.alertTriangle,
              title: context.tr.bitcoinAdvancedUtxosUnavailableTitle,
              message: context.tr.bitcoinAdvancedUtxosUnavailableMessage,
              onRetry: () =>
                  ref.invalidate(bitcoinColdWalletUtxosProvider(coldWalletId)),
            ),
            data: (utxos) => _UtxoPreviewList(utxos: utxos),
          ),
        ),
        const SizedBox(height: 14),
        _AdvancedSubsection(
          title: context.tr.bitcoinAdvancedPsbtsTitle,
          icon: LucideIcons.fileText,
          child: workflowsAsync.when(
            loading: () => const _MiniLoadingRows(),
            error: (_, __) => _MiniActionState(
              icon: LucideIcons.alertTriangle,
              title: context.tr.bitcoinAdvancedPsbtsUnavailableTitle,
              message: context.tr.bitcoinAdvancedPsbtsUnavailableMessage,
              onRetry: () =>
                  ref.invalidate(bitcoinColdWalletPsbtsProvider(coldWalletId)),
            ),
            data: (workflows) => _PsbtPreviewList(
              workflows: workflows,
              onSubmitSigned: (workflow) => _showSubmitPsbtSheet(
                context,
                account,
                workflow,
              ),
              onCopyUnsigned: (workflow) => _copyText(
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

class _AdvancedSubsection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AdvancedSubsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return DecoratedBox(
      decoration: colors.panelDecoration(
        color: colors.surface,
        showShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.text, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _UtxoPreviewList extends StatelessWidget {
  final List<ColdWalletUtxoView> utxos;

  const _UtxoPreviewList({required this.utxos});

  @override
  Widget build(BuildContext context) {
    if (utxos.isEmpty) {
      return _MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoUtxos,
      );
    }

    final visible = utxos.take(4).toList(growable: false);
    final spendable = utxos.where((utxo) => utxo.isSpendable).fold<int>(
          0,
          (total, utxo) => total + utxo.amountSats,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedSpendableForPsbt,
          value: _formatSats(spendable),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < visible.length; index++)
          _UtxoRow(
            utxo: visible[index],
            showDivider: index != visible.length - 1,
          ),
        if (utxos.length > visible.length)
          _MiniHint(
            text: context.tr.bitcoinAdvancedHiddenUtxos(
              utxos.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class _UtxoRow extends StatelessWidget {
  final ColdWalletUtxoView utxo;
  final bool showDivider;

  const _UtxoRow({
    required this.utxo,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${utxo.txidRef}:${utxo.vout}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedText,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatSats(utxo.amountSats),
            style: GoogleFonts.inter(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          _Pill(text: _utxoStatusLabel(context, utxo.status)),
        ],
      ),
    );
  }
}

class _PsbtPreviewList extends StatelessWidget {
  final List<PsbtWorkflowView> workflows;
  final ValueChanged<PsbtWorkflowView> onSubmitSigned;
  final ValueChanged<PsbtWorkflowView> onCopyUnsigned;

  const _PsbtPreviewList({
    required this.workflows,
    required this.onSubmitSigned,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return _MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoPsbts,
      );
    }

    final visible = workflows.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visible.length; index++)
          _PsbtWorkflowRow(
            workflow: visible[index],
            showDivider: index != visible.length - 1,
            onCopyUnsigned: () => onCopyUnsigned(visible[index]),
            onSubmitSigned: visible[index].awaitsSignature
                ? () => onSubmitSigned(visible[index])
                : null,
          ),
        if (workflows.length > visible.length)
          _MiniHint(
            text: context.tr.bitcoinAdvancedHiddenPsbts(
              workflows.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class _PsbtWorkflowRow extends StatelessWidget {
  final PsbtWorkflowView workflow;
  final bool showDivider;
  final VoidCallback onCopyUnsigned;
  final VoidCallback? onSubmitSigned;

  const _PsbtWorkflowRow({
    required this.workflow,
    required this.showDivider,
    required this.onCopyUnsigned,
    this.onSubmitSigned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
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
                  _shortText(workflow.destinationAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(text: _psbtStatusLabel(context, workflow.status)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: _formatSats(workflow.amountSats)),
              _Pill(
                text:
                    '${context.tr.bitcoinAdvancedFeePrefix} ${_formatSats(workflow.estimatedFeeSats)}',
              ),
              if ((workflow.broadcastTxidRef ?? '').isNotEmpty)
                _Pill(text: workflow.broadcastTxidRef!),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(minHeight: 38),
                onPressed: onCopyUnsigned,
                icon: const Icon(LucideIcons.copy, size: 15),
                label: Text(context.tr.bitcoinAdvancedCopyUnsignedAction),
              ),
              if (onSubmitSigned != null)
                OutlinedButton.icon(
                  style: colors.outlinedButtonStyle(minHeight: 38),
                  onPressed: onSubmitSigned,
                  icon: const Icon(LucideIcons.send, size: 15),
                  label: Text(context.tr.bitcoinAdvancedSubmitSignatureAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxEventsSection extends ConsumerWidget {
  const _TaxEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(bitcoinTaxEventsProvider);
    return _TransactionsPanel(
      title: context.tr.bitcoinTaxReportsTitle,
      children: eventsAsync.when(
        loading: () => const [
          _DarkSkeletonRow(),
          _DarkSkeletonRow(),
        ],
        error: (_, __) => [
          _DarkActionMessage(
            icon: LucideIcons.alertTriangle,
            title: context.tr.bitcoinTaxEventsUnavailableTitle,
            message: context.tr.bitcoinTaxEventsUnavailableMessage,
            actionLabel: context.tr.retry,
            onAction: () => ref.invalidate(bitcoinTaxEventsProvider),
          ),
        ],
        data: (events) {
          if (events.isEmpty) {
            return [
              _DarkActionMessage(
                icon: LucideIcons.receipt,
                title: context.tr.bitcoinTaxNoEventsTitle,
                message: context.tr.bitcoinTaxNoEventsMessage,
              ),
              _TaxExportActions(),
            ];
          }

          final visible = events.take(4).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              _TaxEventRow(
                event: visible[index],
                showDivider: index != visible.length - 1,
              ),
            if (events.length > visible.length)
              _DarkListMessage(
                text: context.tr.bitcoinTaxHiddenEvents(
                  events.length - visible.length,
                ),
              ),
            _TaxExportActions(),
          ];
        },
      ),
    );
  }
}

class _TaxEventRow extends ConsumerWidget {
  final TaxEventView event;
  final bool showDivider;

  const _TaxEventRow({
    required this.event,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = _BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.receipt, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _taxEventTypeLabel(context, event.eventType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatSats(event.quantitySats)} | ${event.sourceRef.isEmpty ? event.asset : event.sourceRef}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: context.tr.bitcoinTaxClassifyTooltip,
            color: colors.surfaceRaised,
            icon: Icon(
              LucideIcons.chevronDown,
              color: colors.text,
              size: 18,
            ),
            onSelected: (classification) async {
              try {
                final service = ref.read(bitcoinAccountsServiceProvider);
                await service.classifyTaxEvent(
                  eventId: event.id,
                  classification: classification,
                );
                ref.invalidate(bitcoinTaxEventsProvider);
                if (!context.mounted) return;
                AppNotice.showSuccess(
                  context,
                  title: context.tr.bitcoinTaxClassificationUpdatedTitle,
                  message: _taxClassificationLabel(context, classification),
                );
              } catch (_) {
                if (!context.mounted) return;
                AppNotice.showError(
                  context,
                  title: context.tr.bitcoinTaxClassificationNotSavedTitle,
                  message: context.tr.bitcoinTaxRetryLaterMessage,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'SELF_TRANSFER',
                child: Text(context.tr.bitcoinTaxClassSelfTransfer),
              ),
              PopupMenuItem(
                value: 'THIRD_PARTY_DEPOSIT',
                child: Text(context.tr.bitcoinTaxClassThirdPartyDeposit),
              ),
              PopupMenuItem(
                value: 'SPEND',
                child: Text(context.tr.bitcoinTaxClassSpend),
              ),
              PopupMenuItem(
                value: 'FEE',
                child: Text(context.tr.bitcoinTaxClassFee),
              ),
              PopupMenuItem(
                value: 'UNKNOWN',
                child: Text(context.tr.bitcoinTaxClassUnknown),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxExportActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _exportTaxEvents(context, ref, 'json'),
            icon: const Icon(LucideIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportJsonAction),
          ),
          OutlinedButton.icon(
            onPressed: () => _exportTaxEvents(context, ref, 'csv'),
            icon: const Icon(LucideIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportCsvAction),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTaxEvents(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final exported = await service.exportTaxEvents(format: format);
      final content = exported.content ??
          const JsonEncoder.withIndent('  ').convert(
            exported.toJson(),
          );
      await Clipboard.setData(ClipboardData(text: content));
      if (!context.mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinTaxReportCopiedTitle,
        message: exported.filename,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinTaxExportUnavailableTitle,
        message: context.tr.bitcoinTaxExportUnavailableMessage,
      );
    }
  }
}

class _MiniLoadingRows extends StatelessWidget {
  const _MiniLoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DarkSkeletonRow(),
        _DarkSkeletonRow(),
      ],
    );
  }
}

class _MiniActionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MiniActionState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkActionMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: context.tr.retry,
      onAction: onRetry,
    );
  }
}

class _MiniEmptyState extends StatelessWidget {
  final String text;

  const _MiniEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return _MiniHint(text: text);
  }
}

class _MiniHint extends StatelessWidget {
  final String text;

  const _MiniHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: colors.mutedText,
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MiniMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: colors.mutedText,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _InternalAccountManagementView extends StatefulWidget {
  final BitcoinAccount account;
  final VoidCallback onReceive;

  const _InternalAccountManagementView({
    required this.account,
    required this.onReceive,
  });

  @override
  State<_InternalAccountManagementView> createState() =>
      _InternalAccountManagementViewState();
}

class _InternalAccountManagementViewState
    extends State<_InternalAccountManagementView> {
  String? _expandedKey = 'balance';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InternalWalletCard(account: widget.account, onTap: () {}),
        const SizedBox(height: 18),
        _ManagementItem(
          title: 'Saldo disponível',
          expanded: _expandedKey == 'balance',
          onTap: () => _toggle('balance'),
          rows: [
            ('Disponível', _formatSats(widget.account.balanceAvailableSats)),
          ],
        ),
        _ManagementItem(
          title: 'Endereço de recebimento',
          expanded: _expandedKey == 'receive',
          onTap: () {
            _toggle('receive');
            widget.onReceive();
          },
          rows: const [
            ('Ação', 'Gerar ou visualizar endereço'),
          ],
        ),
        _ManagementItem(
          title: 'Data de validade',
          expanded: _expandedKey == 'expiry',
          onTap: () => _toggle('expiry'),
          rows: [
            ('Validade', _cardExpiryLabel(widget.account)),
          ],
        ),
      ],
    );
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expandedKey = _expandedKey == key ? null : key);
  }
}

class _ManagementItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<(String, String)> rows;

  const _ManagementItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: expanded ? 0.5 : 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.chevronDown,
                          color: colors.text,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                children: [
                  Divider(color: colors.rowDivider),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: GoogleFonts.inter(
                                color: colors.mutedText,
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Text(
                            row.$2,
                            style: GoogleFonts.inter(
                              color: colors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

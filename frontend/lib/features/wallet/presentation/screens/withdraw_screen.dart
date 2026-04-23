import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/presentation/screens/withdraw_receipt_screen.dart';
import '../../domain/entities/wallet.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../presentation/state/wallet_state.dart';
import '../widgets/withdraw_review_popup.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  final String walletId;

  const WithdrawScreen({super.key, required this.walletId});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  Wallet? _selectedWallet;

  int _selectedTabIndex = 0; // 0: On-chain, 1: Lightning
  String _amount = '0';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletState = ref.read(walletProvider);
      if (walletState is WalletLoaded) {
        _selectedWallet = walletState.wallets.firstWhere(
          (w) => w.name == widget.walletId,
          orElse: () => walletState.wallets.first,
        );
        setState(() {});
      }
    });
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '←') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = "0";
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == "0") {
          _amount = key;
        } else {
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts.length > 1 && parts[1].length >= 8) {
              return;
            }
          }
          if (_amount.length < 16) {
            _amount += key;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CyberBackground.authenticated(
      useScroll: true,
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          _buildTabs().animate().fade().slideY(begin: 0.1, end: 0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Column(
              children: [
                _buildAmountDisplay()
                    .animate()
                    .scale(curve: Curves.easeOutBack),
              ],
            ),
          ),
          _buildKeypad()
              .animate(delay: 200.ms)
              .fade()
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CyberButton(
              text: context.l10n.continueButton.toUpperCase(),
              isLoading: _isProcessing,
              onTap:
                  (double.tryParse(_amount) ?? 0) > 0 ? _showReviewPopup : null,
            ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.saqueAction.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildTabItem("ON-CHAIN", 0, LucideIcons.link),
          _buildTabItem("LIGHTNING", 1, LucideIcons.zap),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.4),
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w600,
                      letterSpacing: 2,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          "VALOR DO SAQUE".toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900),
            ),
            Text(
              _amount,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2.0,
                    fontFamily: 'JetBrainsMono',
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              _buildKey('.'),
              _buildKey('0'),
              _buildKey('←'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 68,
          margin: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(LucideIcons.delete,
                  color: Theme.of(context).colorScheme.onPrimary, size: 22)
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFamily: 'JetBrainsMono',
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
        ),
      ),
    );
  }

  void _showReviewPopup() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WithdrawReviewPopup(
        amount: double.tryParse(_amount) ?? 0,
        isLightning: _selectedTabIndex == 1,
        walletName: _selectedWallet?.name ?? widget.walletId,
        onConfirm: (address, totp, shamirVerified) {
          Navigator.pop(context);
          _executeWithdraw(address, totp);
        },
      ),
    );
  }

  Future<void> _executeWithdraw(String address, String totp) async {
    setState(() => _isProcessing = true);

    final result = await ref.read(withdrawProvider.notifier).withdraw(
          fromWalletName: _selectedWallet?.name ?? widget.walletId,
          toAddress: address,
          amount: double.tryParse(_amount) ?? 0,
          totpCode: totp,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WithdrawReceiptScreen(
              amountBtc: _amount,
              toAddress: address,
              txId: result.txid,
              feeBtc: "0.00001000", // Placeholder if not provided by result
              walletName: _selectedWallet?.name ?? widget.walletId,
              timestamp: DateTime.now(),
              isLightning: _selectedTabIndex == 1,
            ),
          ),
        );
      } else {
        final error = ref.read(withdrawProvider).error;
        if (error != null) {
          SnackbarHelper.showError(error);
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/utils/currency_logic.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/utils/qr_payment_parser.dart'; // [NEW]
import '../../domain/entities/wallet.dart';
import '../../domain/entities/payment_request.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../presentation/state/wallet_state.dart';
import 'nfc_interaction_screen.dart';
import 'receive_qr_screen.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const ReceiveScreen({super.key, this.initialWallet});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  Wallet? _selectedWallet;
  Currency _selectedCurrency = Currency.btc;
  
  int _selectedTabIndex = 0; // 0: NFC, 1: QR Code
  String _amount = '0';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.initialWallet;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalCurrency = ref.read(currencyProvider);
      setState(() {
        _selectedCurrency = globalCurrency;
      });

      if (_selectedWallet == null) {
        final walletState = ref.read(walletProvider);
        if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
          setState(() {
            _selectedWallet = walletState.wallets.first;
          });
        }
      }
    });
  }

  PaymentRequest get _paymentRequest {
    double? amount;
    if (_amount != '0' && _amount.isNotEmpty) {
      double inputAmount = double.tryParse(_amount) ?? 0.0;
      if (_selectedCurrency != Currency.btc) {
        final btcUsd = ref.read(latestBtcPriceProvider);
        final btcEur = ref.read(btcEurPriceProvider);
        final btcBrl = ref.read(btcBrlPriceProvider);
        amount = CurrencyLogic.convertToBtc(
          amount: inputAmount,
          fromCurrency: _selectedCurrency,
          btcUsdPrice: btcUsd,
          btcEurPrice: btcEur,
          btcBrlPrice: btcBrl,
        );
      } else {
        amount = inputAmount;
      }
    }

    return PaymentRequest(
      address: _selectedWallet?.address ?? '',
      amountBtc: amount != null && amount > 0 ? amount : null,
    );
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
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
                  _buildAmountDisplay().animate().scale(curve: Curves.easeOutBack),
                ],
              ),
            ),

            _buildKeypad().animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: AppSpacing.xl),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CyberButton(
                text: context.l10n.continueButton.toUpperCase(),
                isLoading: _isGenerating,
                onTap: (double.tryParse(_amount) ?? 0) > 0 ? _generateAndNavigate : null,
              ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.receive.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
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
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildTabItem(context.l10n.nfc, 0),
          _buildTabItem(context.l10n.qrCode, 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
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
            color: isSelected ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              if (isSelected)
                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 10, spreadRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          context.l10n.howMuchToReceive.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900),
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
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(LucideIcons.delete, color: Theme.of(context).colorScheme.onPrimary, size: 22)
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

  Future<void> _generateAndNavigate() async {
    HapticFeedback.mediumImpact();
    setState(() => _isGenerating = true);

    final String address = _selectedWallet?.address ?? '';
    final double amountBtc = _paymentRequest.amountBtc ?? 0;

    // Use unified parser to generate compliant URI
    final String paymentUri = QrPaymentParser.encode(
         address: address, 
         amountBtc: amountBtc,
         label: _selectedWallet?.name,
    );

    if (mounted) {
      setState(() => _isGenerating = false);
      
      if (_selectedTabIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfcInteractionScreen(amountDisplay: _amount, paymentUri: paymentUri),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiveQrScreen(
              amountDisplay: _amount,
              paymentUri: paymentUri,
              label: _selectedWallet?.name,
            ),
          ),
        );
      }
    }
  }
}

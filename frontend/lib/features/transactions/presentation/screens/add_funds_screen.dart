import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../providers/add_funds_notifier.dart';
import '../providers/transaction_provider.dart';
import '../state/add_funds_state.dart';
import '../../../../core/utils/currency_logic.dart';
import '../../../../l10n/app_localizations.dart';

class AddFundsScreen extends ConsumerStatefulWidget {
  const AddFundsScreen({super.key});

  @override
  ConsumerState<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends ConsumerState<AddFundsScreen> {
  final _amountController = TextEditingController();
  Wallet? _selectedSourceWallet;
  String? _depositAddress;
  double? _estimatedFee;
  double? _finalAmount;
  Currency _selectedCurrency = Currency.usd; // Default, will be updated
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Sync with global currency preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalCurrency = ref.read(currencyProvider);
      setState(() {
        _selectedCurrency = globalCurrency;
      });
    });

    // Load Deposit Address on init
    Future.microtask(
      () => ref.read(addFundsProvider.notifier).loadDepositAddress(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _estimateFee();
    });
  }

  Future<void> _estimateFee() async {
    if (_amountController.text.isEmpty) {
      setState(() {
        _estimatedFee = null;
        _finalAmount = null;
      });
      return;
    }

    try {
      // Parse amount based on selected currency
      double amount = CurrencyLogic.parseAmount(_amountController.text);

      // Convert to BTC if not already
      if (_selectedCurrency != Currency.btc) {
        final btcUsdPrice = ref.read(latestBtcPriceProvider);
        final btcEurPrice = ref.read(btcEurPriceProvider);
        final btcBrlPrice = ref.read(btcBrlPriceProvider);

        amount = CurrencyLogic.convertToBtc(
          amount: amount,
          fromCurrency: _selectedCurrency,
          btcUsdPrice: btcUsdPrice,
          btcEurPrice: btcEurPrice,
          btcBrlPrice: btcBrlPrice,
        );
      }

      if (amount <= 0) return;

      final feeEstimate = await ref.read(feeEstimateProvider(amount).future);

      setState(() {
        _estimatedFee = feeEstimate.estimatedStandardBtc;
        _finalAmount = feeEstimate.amountReceived;
      });
    } catch (e) {
      // Silently fail - user might still be typing
    }
  }

  @override
  Widget build(BuildContext context) {
    final addFundsState = ref.watch(addFundsProvider);
    final walletState = ref.watch(walletProvider);

    // Listen for state changes
    ref.listen<AddFundsState>(addFundsProvider, (previous, next) {
      if (next is AddFundsLoadedDepositAddress) {
        setState(() {
          _depositAddress = next.depositAddress;
        });
      } else if (next is AddFundsError) {
        showCustomErrorDialog(context, next.message);
      } else if (next is AddFundsSuccess) {
        _showSuccessDialog(next.txid);
      } else if (next is AddFundsPaymentLinkCreated) {
        // Payment link created successfully, show payment instructions
        final amount = CurrencyLogic.parseAmount(_amountController.text);

        // If currency is NOT BTC, we must convert the original amount to BTC for the dialog
        double amountBtc = amount;
        if (_selectedCurrency != Currency.btc) {
          final btcUsd = ref.read(latestBtcPriceProvider);
          final btcEur = ref.read(btcEurPriceProvider);
          final btcBrl = ref.read(btcBrlPriceProvider);
          amountBtc = CurrencyLogic.convertToBtc(
            amount: amount,
            fromCurrency: _selectedCurrency,
            btcUsdPrice: btcUsd,
            btcEurPrice: btcEur,
            btcBrlPrice: btcBrl,
          );
        }

        _showPaymentInstructionsDialog(amountBtc);
      }
    });

    // Auto-select first wallet if not selected
    if (_selectedSourceWallet == null &&
        walletState is WalletLoaded &&
        walletState.wallets.isNotEmpty) {
      _selectedSourceWallet = walletState.wallets.first;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF0A0A0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addFundsState is AddFundsLoading ||
                          addFundsState is AddFundsSigning ||
                          addFundsState is AddFundsBroadcasting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF00FF94),
                            ),
                          ),
                        ),

                      if (_depositAddress != null) ...[
                        _buildDepositAddressCard(_depositAddress!),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 32),
                        _buildDepositButton(addFundsState),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.addFunds,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositAddressCard(String address) {
    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.platformDepositAddress,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.qr_code_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Address copied!"),
                      backgroundColor: Color(0xFF00FF94),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    final btcUsdPrice = ref.watch(latestBtcPriceProvider);
    final btcEurPrice = ref.watch(btcEurPriceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.amount,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(
              maxDigits: 20,
              symbol: '',
              decimals: _selectedCurrency == Currency.btc ? 8 : 2,
            ),
          ],
          onChanged: _onAmountChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            hintText: _selectedCurrency == Currency.btc ? "0.00000000" : "0.00",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 24,
            ),
            suffixIcon: _buildCurrencySelector(),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        // Show conversion hint AND quotation
        if (_amountController.text.isNotEmpty &&
            _selectedCurrency != Currency.btc) ...[
          const SizedBox(height: 8),
          Text(
            _getConversionHint(
              btcUsdPrice,
              btcEurPrice,
              ref.watch(btcBrlPriceProvider),
            ),
            style: TextStyle(
              color: const Color(0xFF00FF94).withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
        // CURRENCY QUOTATION DISPLAY
        if (_selectedCurrency != Currency.btc) ...[
          const SizedBox(height: 8),
          _buildCurrencyQuotation(
            _selectedCurrency,
            btcUsdPrice,
            btcEurPrice,
            ref.watch(btcBrlPriceProvider),
          ),
        ],
        if (_estimatedFee != null && _finalAmount != null) ...[
          const SizedBox(height: 16),
          _buildFeeInformation(),
        ],
      ],
    );
  }

  Widget _buildFeeInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF94).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF94).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildFeeRow(
            AppLocalizations.of(context)!.networkFee,
            '${_estimatedFee!.toStringAsFixed(8)} BTC',
            Icons.network_check,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          _buildFeeRow(
            AppLocalizations.of(context)!.youWillReceive,
            '${_finalAmount!.toStringAsFixed(8)} BTC',
            Icons.account_balance_wallet,
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          _buildFeeRow(
            AppLocalizations.of(context)!.confirmationTime,
            '~10 minutes (1 conf)',
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlighted
              ? const Color(0xFF00FF94)
              : Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF00FF94) : Colors.white,
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildDepositButton(AddFundsState state) {
    final isLoading =
        state is AddFundsLoading ||
        state is AddFundsSigning ||
        state is AddFundsBroadcasting;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleDeposit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF94),
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Generate Payment Link",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  void _handleDeposit() async {
    if (_amountController.text.isEmpty || _depositAddress == null) {
      showCustomErrorDialog(context, "Please enter an amount.");
      return;
    }

    // Parse amount using robust logic
    double inputAmount = CurrencyLogic.parseAmount(_amountController.text);
    double amountInBtc = inputAmount;

    // Convert to BTC if not already
    if (_selectedCurrency != Currency.btc) {
      final btcUsd = ref.read(latestBtcPriceProvider);
      final btcEur = ref.read(btcEurPriceProvider);
      final btcBrl = ref.read(btcBrlPriceProvider);
      amountInBtc = CurrencyLogic.convertToBtc(
        amount: inputAmount,
        fromCurrency: _selectedCurrency,
        btcUsdPrice: btcUsd,
        btcEurPrice: btcEur,
        btcBrlPrice: btcBrl,
      );
    }

    if (amountInBtc <= 0) {
      showCustomErrorDialog(context, "Invalid amount.");
      return;
    }

    // Call backend to create payment link and start monitoring
    await ref
        .read(addFundsProvider.notifier)
        .createPaymentLink(
          amount: amountInBtc,
          receiverWalletName: _selectedSourceWallet?.name ?? 'main',
        );
  }

  void _showSuccessDialog(String txid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF94).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF00FF94),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Deposit Initiated!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your deposit transaction has been broadcasted. It will be credited once confirmed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      txid,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to Home
                  // Trigger refresh of balances/history
                  ref.read(walletProvider.notifier).refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF94),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Currency selector dropdown widget
  Widget _buildCurrencySelector() {
    return PopupMenuButton<Currency>(
      initialValue: _selectedCurrency,
      onSelected: (Currency newCurrency) {
        if (_selectedCurrency == newCurrency) return;

        final startCurrency = _selectedCurrency;
        final currentText = _amountController.text;

        setState(() {
          _selectedCurrency = newCurrency;
        });

        if (currentText.isEmpty) return;

        // Perform conversion
        try {
          // Perform conversion
          final double amount = CurrencyLogic.parseAmount(currentText);

          if (amount <= 0) return;

          final btcUsd = ref.read(latestBtcPriceProvider);
          final btcEur = ref.read(btcEurPriceProvider);
          final btcBrl = ref.read(btcBrlPriceProvider);

          // 1. Convert to BTC first (base)
          double amountInBtc = 0;
          if (startCurrency == Currency.btc) {
            amountInBtc = amount;
          } else {
            amountInBtc = CurrencyLogic.convertToBtc(
              amount: amount,
              fromCurrency: startCurrency,
              btcUsdPrice: btcUsd,
              btcEurPrice: btcEur,
              btcBrlPrice: btcBrl,
            );
          }

          // 2. Convert BTC to target currency
          double finalAmount = 0;
          switch (newCurrency) {
            case Currency.btc:
              finalAmount = amountInBtc;
              break;
            case Currency.usd:
              finalAmount = amountInBtc * (btcUsd ?? 0);
              break;
            case Currency.eur:
              finalAmount = amountInBtc * (btcEur ?? 0);
              break;
            case Currency.brl:
              finalAmount = amountInBtc * (btcBrl ?? 0);
              break;
          }

          // 3. Update text field with appropriate formatting
          final formatter = NumberFormat.currency(
            locale: 'pt_BR',
            customPattern: newCurrency == Currency.btc
                ? '#,##0.00000000'
                : '#,##0.00',
            symbol: '',
            decimalDigits: newCurrency == Currency.btc ? 8 : 2,
          );
          _amountController.text = formatter.format(finalAmount).trim();

          // 4. Trigger fee estimation with new values
          _estimateFee();
        } catch (e) {
          debugPrint('Error converting currency: $e');
        }
      },
      offset: const Offset(0, 40),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      itemBuilder: (context) => Currency.values.map((currency) {
        final isSelected = currency == _selectedCurrency;
        return PopupMenuItem<Currency>(
          value: currency,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00FF94)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currency.code,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCurrency.code,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Get conversion hint text
  String _getConversionHint(
    double? btcUsdPrice,
    double? btcEurPrice,
    double? btcBrlPrice,
  ) {
    if (_amountController.text.isEmpty) return '';

    if (_amountController.text.isEmpty) return '';

    try {
      double amount = CurrencyLogic.parseAmount(_amountController.text);

      // If selected is already BTC, no need to show hint
      if (_selectedCurrency == Currency.btc) return '';

      final btcAmount = CurrencyLogic.convertToBtc(
        amount: amount,
        fromCurrency: _selectedCurrency,
        btcUsdPrice: btcUsdPrice,
        btcEurPrice: btcEurPrice,
        btcBrlPrice: btcBrlPrice,
      );

      if (btcAmount == 0) return 'Loading price...';

      return '≈ ${btcAmount.toStringAsFixed(8)} BTC';
    } catch (e) {
      return '';
    }
  }

  void _showPaymentInstructionsDialog(double amountBtc) {
    final btcUsdPrice = ref.read(latestBtcPriceProvider);
    final btcEurPrice = ref.read(btcEurPriceProvider);

    // Get original amount in selected currency
    String originalAmount = '';
    if (_selectedCurrency == Currency.usd && btcUsdPrice != null) {
      originalAmount = '\$${(amountBtc * btcUsdPrice).toStringAsFixed(2)} USD';
    } else if (_selectedCurrency == Currency.eur && btcEurPrice != null) {
      originalAmount = '€${(amountBtc * btcEurPrice).toStringAsFixed(2)} EUR';
    } else if (_selectedCurrency == Currency.brl) {
      final btcBrlPrice = ref.read(btcBrlPriceProvider);
      if (btcBrlPrice != null) {
        originalAmount =
            'R\$${(amountBtc * btcBrlPrice).toStringAsFixed(2)} BRL';
      }
    }

    // Fee calculations
    final feeBtc = _estimatedFee ?? 0.00001;
    final amountToReceive = (amountBtc - feeBtc).clamp(0.0, double.infinity);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          blur: 30,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF94).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF00FF94),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Payment Link Created",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount Information
                if (originalAmount.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          originalAmount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '≈ ${amountBtc.toStringAsFixed(8)} BTC',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${amountBtc.toStringAsFixed(8)} BTC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Detailed Info Block (Fee, Time, Confirmations)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Network Fee',
                        '${feeBtc.toStringAsFixed(8)} BTC',
                        Icons.network_check,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'You Receive',
                        '${amountToReceive.toStringAsFixed(8)} BTC',
                        Icons.arrow_downward,
                        valueColor: const Color(0xFF00FF94),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Est. Time',
                        '~10-30 mins',
                        Icons.timer_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Confirmations',
                        '3 required',
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Deposit Address
                if (_depositAddress != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit Address',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: _depositAddress!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _depositAddress!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.copy,
                                color: Color(0xFF00FF94),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)!.close),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Back to home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF94),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.done,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: value.contains('BTC') ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyQuotation(
    Currency currency,
    double? btcUsdPrice,
    double? btcEurPrice,
    double? btcBrlPrice,
  ) {
    if (btcUsdPrice == null) return const SizedBox.shrink();

    double rate = 0.0;
    String target = "USD";

    switch (currency) {
      case Currency.brl:
        // 1 BRL = X USD
        final brlPrice = btcBrlPrice ?? 0;
        if (brlPrice > 0) {
          rate = (btcUsdPrice / brlPrice);
        }
        target = "USD";
        break;
      case Currency.eur:
        // 1 EUR = X USD
        final eurPrice = btcEurPrice ?? 0;
        if (eurPrice > 0) {
          rate = (btcUsdPrice / eurPrice);
        }
        target = "USD";
        break;
      case Currency.usd:
        // 1 USD = X BRL
        final brlPrice = btcBrlPrice ?? 0;
        if (brlPrice > 0) {
          rate = (brlPrice / btcUsdPrice);
        }
        target = "BRL";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF94).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00FF94).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        "1 ${currency.code} ≈ ${rate.toStringAsFixed(2)} $target",
        style: const TextStyle(
          color: Color(0xFF00FF94),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

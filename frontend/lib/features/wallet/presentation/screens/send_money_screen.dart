import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import 'package:flutter/services.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/cyber_icons.dart';
import '../../../home/presentation/screens/qr_scanner_screen.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart'; // Just in case, though might cause collision if NdefRecord is in both?
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_logic.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/services/audio_service.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? walletId;
  final String? initialAddress;

  /// Pre-fill amount in BTC (e.g. from QR or NFC payment request).
  final double? initialAmountBtc;

  const SendMoneyScreen({
    super.key,
    this.walletId,
    this.initialAddress,
    this.initialAmountBtc,
  });

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  double _lockedAmountBtc = 0.0;

  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();
  final _contextController = TextEditingController();
  Currency _selectedCurrency = Currency.btc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalCurrency = ref.read(currencyProvider);
      setState(() {
        _selectedCurrency = globalCurrency;
      });
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _parsePaymentRequest(widget.initialAddress!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiverController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncActionState>(sendTransactionProvider, (previous, next) {
      if (next.result != null) {
        // Success handled by HomeScreen with a dialog
        final result = next.result;
        AudioService.instance.playTransaction();
        ref.read(sendTransactionProvider.notifier).reset();
        Navigator.pop(context, result);
      } else if (next.error != null) {
        AudioService.instance.playError();
        String errorMsg = next.error!;

        if (errorMsg.contains('ERR_LEDGER_INSUFFICIENT_BALANCE') ||
            errorMsg.contains('ERR_LEDGER_NOT_FOUND')) {
          final walletState = ref.read(walletProvider);
          if (walletState is WalletLoaded &&
              walletState.selectedWallet != null) {
            final currentBalance = walletState.selectedWallet!.balance;
            final attemptedAmountBtc = _lockedAmountBtc;

            final missingCount = (attemptedAmountBtc - currentBalance).clamp(
              0.0,
              double.infinity,
            );
            errorMsg =
                'Saldo insuficiente. Faltam ${missingCount.toStringAsFixed(8)} BTC para completar este envio.';
          } else {
            errorMsg = ErrorTranslator.translate(errorMsg);
          }
        } else {
          errorMsg = ErrorTranslator.translate(errorMsg);
        }

        SnackbarHelper.showError(errorMsg);
        ref.read(sendTransactionProvider.notifier).reset();
      }
    });

    // Listen for payment link payments
    ref.listen<AsyncActionState>(paymentLinkNotifierProvider, (previous, next) {
      if (next.result != null) {
        AudioService.instance.playTransaction();
        SnackbarHelper.showSuccess("Payment successful!");
        Navigator.pop(context, true);
      } else if (next.error != null) {
        AudioService.instance.playError();
        SnackbarHelper.showError(next.error!);
      }
    });

    final walletState = ref.watch(walletProvider);
    final sendState = ref.watch(sendTransactionProvider);
    final selectedWallet = walletState is WalletLoaded
        ? walletState.selectedWallet
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
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
              // Header minimalista
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.send,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Value Input with Currency Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        (_pendingPaymentLinkId != null ||
                                _lockedRecipientAddress.isNotEmpty)
                            ? _buildLockedAmountDisplay()
                            : _buildManualInputCard(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Scan & NFC Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildScanButton(
                        context,
                        icon: const CyberQrIcon(isActive: true, size: 24),
                        label: AppLocalizations.of(context)!.qrCode,
                        onTap: _handleScanQr,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildScanButton(
                        context,
                        icon: const CyberNfcIcon(isActive: true, size: 24),
                        label: AppLocalizations.of(context)!.nfc,
                        onTap: _handleReadNfc,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recipient card minimalista
              _buildRecipientInput(),

              const SizedBox(height: 10),

              // Description / Context field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _contextController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLength: 100,
                          decoration: InputDecoration(
                            hintText:
                                "Descrição (opcional, ex: Pagamento da pizza)",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Wallet selector minimalista
              if (selectedWallet != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GestureDetector(
                    onTap: () => walletState is WalletLoaded
                        ? _showWalletSelector(context, walletState)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.fromWallet(selectedWallet.name),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "${selectedWallet.balance.toStringAsFixed(8)} BTC",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.2),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              const SizedBox(height: 12),

              // Botão Send minimalista
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sendState.isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: sendState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.send,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortenAddress(String address, {int length = 8}) {
    if (address.length <= length * 2) return address;
    return "${address.substring(0, length)}...${address.substring(address.length - length)}";
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    if (walletState is! WalletLoaded || walletState.selectedWallet == null) {
      return;
    }

    if (_pendingPaymentLinkId != null || _lockedRecipientAddress.isNotEmpty) {
      _showConfirmationDialog(
        context,
        _lockedAmountBtc,
        0,
        _lockedAmountBtc,
        walletState.selectedWallet!.id,
        walletState.selectedWallet!.address,
        _lockedRecipientAddress,
        _contextController.text.trim(),
      );
    } else {
      // Flow manual
      final toAddress = _receiverController.text.trim();
      if (toAddress.isEmpty) {
        SnackbarHelper.showError(
          "Please enter a valid recipient username or address",
        );
        return;
      }

      double inputAmount = CurrencyLogic.parseAmount(_amountController.text);
      if (inputAmount <= 0) {
        SnackbarHelper.showError("Please enter a valid amount");
        return;
      }

      double amountBtc = inputAmount;
      if (_selectedCurrency != Currency.btc) {
        amountBtc = CurrencyLogic.convertToBtc(
          amount: inputAmount,
          fromCurrency: _selectedCurrency,
          btcUsdPrice: ref.read(latestBtcPriceProvider),
          btcEurPrice: ref.read(btcEurPriceProvider),
          btcBrlPrice: ref.read(btcBrlPriceProvider),
        );
      }

      _showConfirmationDialog(
        context,
        amountBtc,
        0,
        amountBtc,
        walletState.selectedWallet!.id,
        walletState.selectedWallet!.address,
        toAddress,
        _contextController.text.trim(),
      );
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    double amount,
    double fee,
    double total,
    String fromWalletId,
    String fromAddress,
    String toAddress,
    String txContext,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                blur: 40,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (_pendingPaymentLinkId != null ||
                              _lockedRecipientAddress.isNotEmpty)
                          ? "Confirm Tracked Payment"
                          : "Review Transaction",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildConfirmRow("Recipient", toAddress, isSmall: true),
                    const Divider(color: Colors.white10, height: 32),
                    if (txContext.isNotEmpty) ...[
                      _buildConfirmRow("Descrição", txContext, isSmall: true),
                      const SizedBox(height: 12),
                    ],
                    _buildConfirmRow(
                      "Amount",
                      "${amount.toStringAsFixed(8)} BTC",
                    ),
                    const SizedBox(height: 12),
                    _buildConfirmRow(
                      "Network Fee",
                      "Free",
                      valueColor: const Color(0xFF00FF94),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _buildConfirmRow(
                      "Total",
                      "${total.toStringAsFixed(8)} BTC",
                      isBold: true,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              if (_pendingPaymentLinkId != null) {
                                _handlePayPaymentLink();
                              } else {
                                final satoshiFee = (fee * 100000000).toInt();
                                ref
                                    .read(sendTransactionProvider.notifier)
                                    .send(
                                      fromWalletId: fromWalletId,
                                      fromAddress: fromAddress,
                                      toAddress: toAddress,
                                      amount: amount,
                                      feeSatoshis: satoshiFee,
                                      context: txContext.isNotEmpty
                                          ? txContext
                                          : null,
                                    );
                              }
                            },
                            child: Text(
                              (_pendingPaymentLinkId != null ||
                                      _lockedRecipientAddress.isNotEmpty)
                                  ? "Pay Now"
                                  : "Confirm",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
      },
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value, {
    bool isSmall = false,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isSmall ? 13 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontFamily: isSmall ? null : 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showWalletSelector(BuildContext context, WalletLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Select Wallet",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: state.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = state.wallets[index];
                    final isSelected = wallet.id == state.selectedWallet?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(walletProvider.notifier)
                              .selectWallet(wallet);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${wallet.balance.toStringAsFixed(8)} BTC",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _handleReadNfc() {
    showDialog(
      context: context,
      builder: (_) => _NfcReadDialog(onRead: _parsePaymentRequest),
    );
  }

  void _parsePaymentRequest(String data) {
    if (data.startsWith('kerosene:link:')) {
      final linkId = data.replaceFirst('kerosene:link:', '');
      _fetchPaymentLinkDetails(linkId);
      return;
    }

    if (data.startsWith('kerosene:pay?')) {
      try {
        final uri = Uri.parse(data);
        final address = uri.queryParameters['address'];
        final amountStr = uri.queryParameters['amount'];

        if (address != null && address.isNotEmpty) {
          setState(() {
            _lockedRecipientAddress = address;
            _lockedAmountBtc = double.tryParse(amountStr ?? '0') ?? 0;
            _pendingPaymentLinkId = null; // Local locked flow
          });
          return;
        }
      } catch (e) {
        debugPrint("Error parsing kerosene:pay link: $e");
      }
    }

    // Completely strict mode - only kerosene links are allowed.
    SnackbarHelper.showError("Please scan a valid Kerosene Payment Link.");
  }

  Future<void> _fetchPaymentLinkDetails(String linkId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF7931A)),
      ),
    );

    try {
      final link = await ref.read(paymentLinkDetailProvider(linkId).future);
      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _pendingPaymentLinkId = link.id;
        _lockedRecipientAddress = link.depositAddress;
        _lockedAmountBtc = link.amountBtc;
      });

      SnackbarHelper.showSuccess("Tracked payment request loaded.");
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      SnackbarHelper.showError("Failed to fetch payment link details.");
    }
  }

  Future<void> _handlePayPaymentLink() async {
    final walletState = ref.read(walletProvider);
    if (walletState is! WalletLoaded || walletState.selectedWallet == null) {
      return;
    }

    // Biometric / PIN confirmation before sending (same logic as _handleContinue)
    final biometricService = BiometricService();
    final canAuth = await biometricService.canAuthenticate();
    final iEnrolled = await biometricService.isBiometricEnrolled();

    bool authenticated = false;
    if (canAuth && iEnrolled) {
      authenticated = await biometricService.authenticate(
        localizedReason: 'Confirm tracked payment',
      );
    } else {
      final pinService = AppPinService();
      final hasPinSet = await pinService.hasPinSet();
      if (!mounted) return;
      authenticated = await PinDialog.show(context, isSetup: !hasPinSet);
    }

    if (!mounted) return;
    if (!authenticated) {
      SnackbarHelper.showError("Authentication failed.");
      return;
    }

    await ref
        .read(paymentLinkNotifierProvider.notifier)
        .pay(
          linkId: _pendingPaymentLinkId!,
          payerWalletName: walletState.selectedWallet!.name,
        );
  }

  Widget _buildScanButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputCard() {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: _amountController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            CurrencyInputFormatter(
              maxDigits: 20,
              symbol: '',
              decimals: _selectedCurrency == Currency.btc ? 8 : 2,
            ),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _selectedCurrency == Currency.btc ? "0.00000000" : "0.00",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 32,
            ),
            border: InputBorder.none,
          ),
        ),
        _buildCurrencySelector(),
        if (_amountController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildConversionHint(btcUsd, btcEur, btcBrl),
        ],
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return GestureDetector(
      onTap: () {
        setState(() {
          final values = Currency.values;
          final nextIndex = (_selectedCurrency.index + 1) % values.length;
          _selectedCurrency = values[nextIndex];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7931A).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCurrency.name.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFF7931A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.swap_vert_rounded,
              color: Color(0xFFF7931A),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionHint(double? btcUsd, double? btcEur, double? btcBrl) {
    double inputAmount = CurrencyLogic.parseAmount(_amountController.text);
    String hint = "";

    if (_selectedCurrency == Currency.btc) {
      double usd = inputAmount * (btcUsd ?? 0);
      hint = "≈ \$${usd.toStringAsFixed(2)} USD";
    } else {
      double btc = CurrencyLogic.convertToBtc(
        amount: inputAmount,
        fromCurrency: _selectedCurrency,
        btcUsdPrice: btcUsd,
        btcEurPrice: btcEur,
        btcBrlPrice: btcBrl,
      );
      hint = "≈ ${btc.toStringAsFixed(8)} BTC";
    }

    return Text(
      hint,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 13,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildLockedAmountDisplay() {
    return Consumer(
      builder: (context, ref, child) {
        final btcUsd = ref.watch(latestBtcPriceProvider);
        return Column(
          children: [
            Text(
              "${_lockedAmountBtc.toStringAsFixed(8)} BTC",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            if (btcUsd != null && btcUsd > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "≈ \$${(_lockedAmountBtc * btcUsd).toStringAsFixed(2)} USD",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecipientInput() {
    if (_pendingPaymentLinkId != null) {
      return _buildLockedRecipientCard();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _receiverController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Recipient username or address",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedRecipientCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment Destination (Locked)",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_lockedRecipientAddress.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _shortenAddress(_lockedRecipientAddress, length: 12),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcReadDialog extends StatefulWidget {
  final Function(String) onRead;

  const _NfcReadDialog({required this.onRead});

  @override
  State<_NfcReadDialog> createState() => _NfcReadDialogState();
}

class _NfcReadDialogState extends State<_NfcReadDialog> {
  String _status = "Searching...";
  final bool _reading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _status = AppLocalizations.of(context)!.approachPhoneToNfc;
        });
      }
    });
    _startReadSession();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  void _startReadSession() {
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        if (!_reading) return;

        final ndef = Ndef.from(tag);
        if (ndef != null && ndef.cachedMessage != null) {
          final message = ndef.cachedMessage!;
          for (final record in message.records) {
            final payload = record.payload;
            if (record.typeNameFormat == TypeNameFormat.wellKnown) {
              if (payload.isNotEmpty) {
                final text = String.fromCharCodes(payload.skip(1));
                if (!mounted) return;
                widget.onRead(text);
                NfcManager.instance.stopSession();
                Navigator.pop(context);
                return;
              }
            }
          }
        }
        NfcManager.instance.stopSession();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CyberNfcIcon(isActive: true, size: 48),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

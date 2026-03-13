import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

import '../../../../core/providers/price_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/cyber_icons.dart';
import '../../../home/presentation/screens/qr_scanner_screen.dart';
import 'nfc_interaction_screen.dart';
import '../../domain/entities/wallet.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart'; // Just in case, though might cause collision if NdefRecord is in both?
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/services/audio_service.dart';
import 'package:teste/l10n/l10n_extension.dart';

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

  final _receiverController = TextEditingController();
  final _contextController = TextEditingController();

  int _selectedTabIndex = 1; // 0: NFC, 1: Manual, 2: QR Code
  String _amount = '0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _parsePaymentRequest(widget.initialAddress!);
      }
    });
  }

  @override
  void dispose() {
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
            errorMsg = ErrorTranslator.translate(context.l10n, errorMsg);
          }
        } else {
          errorMsg = ErrorTranslator.translate(context.l10n, errorMsg);
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

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              if (_pendingPaymentLinkId == null && _lockedRecipientAddress.isEmpty) ...[
                _buildTabs(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAmountDisplay(),
                      const SizedBox(height: 12),
                      _buildLiveQuote(),
                    ],
                  ),
                ),
                _buildKeypad(),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${_lockedAmountBtc.toStringAsFixed(8)} BTC",
                          style: const TextStyle(
                           color: Colors.white,
                           fontSize: 48,
                           fontWeight: FontWeight.w300,
                           fontFamily: 'Inter',
                           letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Amount Locked by Request",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildContinueButton(),
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
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.send,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTabItem("NFC", 0),
          _buildTabItem("Manual", 1),
          _buildTabItem("QR Code", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? Colors.white.withAlpha(30) : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
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
          AppLocalizations.of(context)!.amount.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              "₿ ",
              style: TextStyle(
                color: Color(0xFF00FFA3),
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w300,
                fontFamily: 'Inter',
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveQuote() {
    final btcUsdPrice = ref.watch(latestBtcPriceProvider);
    final amt = double.tryParse(_amount) ?? 0.0;
    final value = amt * (btcUsdPrice ?? 0);
    return Text(
      "~ \$ ${value.toStringAsFixed(2)} USD",
      style: TextStyle(
        color: Colors.white.withAlpha(120),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 22)
              : Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
        ),
      ),
    );
  }

  void _onKeyTap(String key) {
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

  Widget _buildContinueButton() {
    final sendState = ref.watch(sendTransactionProvider);
    final canContinue = (double.tryParse(_amount) ?? 0.0) > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (sendState.isLoading || !canContinue) ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0033FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: const Color(0xFF0033FF).withValues(alpha: 0.2),
              ),
              child: sendState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "CONTINUE",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    if (walletState is! WalletLoaded || walletState.selectedWallet == null) return;
    
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
      return;
    }

    double inputAmount = double.tryParse(_amount) ?? 0.0;
    if (inputAmount <= 0) {
      SnackbarHelper.showError("Please enter a valid amount");
      return;
    }

    if (_selectedTabIndex == 0) {
      _handleReadNfc();
    } else if (_selectedTabIndex == 2) {
      _handleScanQr();
    } else {
      _showManualAddressInput(inputAmount, walletState.selectedWallet!);
    }
  }

  void _showManualAddressInput(double amountBtc, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Manual Entry",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: TextField(
                    controller: _receiverController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Recipient username or address",
                      hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                      border: InputBorder.none,
                      icon: Icon(Icons.person_outline_rounded, color: Colors.white.withAlpha(200), size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: TextField(
                    controller: _contextController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: "Description (optional)",
                      hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                      border: InputBorder.none,
                      counterText: '',
                      icon: Icon(Icons.edit_note_rounded, color: Colors.white.withAlpha(200), size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final toAddress = _receiverController.text.trim();
                      if (toAddress.isEmpty) {
                        SnackbarHelper.showError("Please enter a valid recipient");
                        return;
                      }
                      Navigator.pop(context);
                      _showConfirmationDialog(
                        context,
                        amountBtc,
                        0,
                        amountBtc,
                        wallet.id,
                        wallet.address,
                        toAddress,
                        _contextController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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

  void _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _handleReadNfc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NfcInteractionScreen(amountDisplay: _amount)),
    );
    if (result != null && result is String && mounted) {
      _parsePaymentRequest(result);
    }
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


}

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

  void _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _handleReadNfc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NfcInteractionScreen(amountDisplay: _amount)),
    );
    if (result != null && result is String && mounted) {
      _parsePaymentRequest(result);
    }
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
          color: const Color(0xFF1A1A24).withAlpha(230),
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

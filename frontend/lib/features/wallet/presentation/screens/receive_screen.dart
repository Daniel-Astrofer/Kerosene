import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/payment_request.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/cyber_icons.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../../../core/utils/currency_logic.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../presentation/state/wallet_state.dart';
import 'package:teste/l10n/l10n_extension.dart';

/// Tela de recebimento: dados da carteira + valor em BTC, com opção QR Code ou NFC.
class ReceiveScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const ReceiveScreen({super.key, this.initialWallet});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amountController = TextEditingController();
  Wallet? _selectedWallet;
  Currency _selectedCurrency = Currency.btc;
  String? _localPaymentUri;
  bool _isNfcActive = false;
  int? _expiresInMinutes;
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  PaymentRequest get _paymentRequest {
    double? amount;
    if (_amountController.text.isNotEmpty) {
      double inputAmount = CurrencyLogic.parseAmount(_amountController.text);
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

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final btcUsdPrice = ref.watch(latestBtcPriceProvider);
    final btcEurPrice = ref.watch(btcEurPriceProvider);
    final btcBrlPrice = ref.watch(btcBrlPriceProvider);

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
                      // 1. Wallet Selector
                      if (walletState is WalletLoaded)
                        _buildWalletSelector(context, walletState),

                      const SizedBox(height: 24),

                      // 2. Amount Input Card
                      _buildAmountInputCard(
                        btcUsdPrice,
                        btcEurPrice,
                        btcBrlPrice,
                      ),

                      const SizedBox(height: 32),

                      // 3. Expiration & Generate Action
                      _buildPaymentLinkGenerator(),

                      if (_localPaymentUri != null) ...[
                        const SizedBox(height: 32),
                        // 4. Method Selection (QR/NFC)
                        _buildMethodSelectionToggle(),
                        const SizedBox(height: 24),
                        // 5. Display Area (QR Code or NFC Prompt)
                        _buildDisplayArea(),
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
            AppLocalizations.of(context)!.receive,
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

  Widget _buildWalletSelector(BuildContext context, WalletLoaded state) {
    final wallet =
        _selectedWallet ??
        (state.wallets.isNotEmpty ? state.wallets.first : null);

    return GestureDetector(
      onTap: () => _showWalletSelectorModal(context, state),
      child: GlassContainer(
        blur: 20,
        opacity: 0.05,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFF7931A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.receiveReceivingWallet,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    wallet?.name ?? context.l10n.sendSelectWallet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInputCard(double? btcUsd, double? btcEur, double? btcBrl) {
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
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
          onChanged: (_) => setState(() {
            _localPaymentUri = null;
          }),
          decoration: InputDecoration(
            hintText: _selectedCurrency == Currency.btc ? "0.00000000" : "0.00",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 32,
            ),
            suffixIcon: _buildCurrencySelector(),
            border: InputBorder.none,
          ),
        ),
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
          // Cycle through currencies
          final values = Currency.values;
          final nextIndex = (_selectedCurrency.index + 1) % values.length;
          _selectedCurrency = values[nextIndex];
          _localPaymentUri = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
      // Show USD value
      double usd = inputAmount * (btcUsd ?? 0);
      hint = "≈ $usd USD";
    } else {
      // Show BTC value
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

  Widget _buildPaymentLinkGenerator() {
    if (_amountController.text.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.receiveExpirationLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _expiresInMinutes,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E28),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.l10n.receiveNoExpiration),
                  ),
                  DropdownMenuItem(
                    value: 15,
                    child: Text(context.l10n.receive15Min),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text(context.l10n.receive1Hour),
                  ),
                  DropdownMenuItem(
                    value: 1440,
                    child: Text(context.l10n.receive24Hours),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _expiresInMinutes = val;
                    _localPaymentUri = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _generateTrackedLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7931A).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFFF7931A),
                side: const BorderSide(color: Color(0xFFF7931A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF7931A),
                      ),
                    )
                  : Text(
                      context.l10n.receiveGenAction,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelectionToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleItem(
            label: context.l10n.receiveQrMethod,
            isActive: !_isNfcActive,
            onTap: () => setState(() => _isNfcActive = false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildToggleItem(
            label: context.l10n.receiveNfcMethod,
            isActive: _isNfcActive,
            onTap: () => setState(() => _isNfcActive = true),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFF7931A) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayArea() {
    if (_isNfcActive) {
      return _buildNfcBeamArea();
    } else {
      return _buildQrCodeArea();
    }
  }

  Widget _buildQrCodeArea() {
    final qrData = _localPaymentUri ?? _paymentRequest.toBitcoinUri();

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7931A).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF000000),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF000000),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.receiveScanToPay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedWallet?.address ?? "",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNfcBeamArea() {
    return Center(
      child: Column(
        children: [
          const CyberNfcIcon(isActive: true, size: 80),
          const SizedBox(height: 24),
          Text(
            context.l10n.receiveReadyToBeam,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showNfcWrite(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7931A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.l10n.receiveWriteNfc),
          ),
        ],
      ),
    );
  }

  void _showWalletSelectorModal(BuildContext context, WalletLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        blur: 30,
        opacity: 0.1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.receiveReceivingWallet,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.wallets.length,
                itemBuilder: (context, index) {
                  final w = state.wallets[index];
                  return ListTile(
                    title: Text(
                      w.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "${w.balance.toStringAsFixed(8)} BTC",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedWallet = w;
                        _localPaymentUri = null;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNfcWrite(BuildContext context) {
    final request = _paymentRequest;
    final uri = _localPaymentUri ?? request.toBitcoinUri();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NfcWriteDialog(
        paymentRequestUri: uri,
        walletName: _selectedWallet?.name ?? "",
        amountBtc: request.amountBtc,
      ),
    );
  }

  Future<void> _generateTrackedLink() async {
    final double inputAmount = CurrencyLogic.parseAmount(
      _amountController.text,
    );
    if (inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sendEnterAmountError)),
      );
      return;
    }

    final String address = _selectedWallet?.address ?? '';
    final double amountBtc = _paymentRequest.amountBtc ?? 0;

    // 1. Construct LOCAL payment URI immediately (Architectural Alignment)
    // Format: kerosene:pay?address=...&amount=...&expiresIn=...&label=...
    final queryParams = <String, String>{
      'address': address,
      'amount': amountBtc.toStringAsFixed(8),
    };
    if (_expiresInMinutes != null) {
      queryParams['expiresIn'] = _expiresInMinutes.toString();
    }
    if (_selectedWallet != null) {
      queryParams['label'] = _selectedWallet!.name;
    }

    final localUri = Uri(
      scheme: 'kerosene',
      path: 'pay',
      queryParameters: queryParams,
    ).toString();

    setState(() {
      _localPaymentUri = localUri;
      _isGenerating = true;
    });

    // 2. BACKGROUND Sync with API (fire-and-forget or handled gracefully)
    try {
      ref
          .read(paymentLinkNotifierProvider.notifier)
          .create(
            amount: amountBtc,
            receiverWalletName: _selectedWallet?.name ?? 'main',
            expiresIn: _expiresInMinutes,
          )
          .then((result) {
            // Background sync complete
          });
    } catch (e) {
      debugPrint("API background sync failed: $e");
    } finally {
      // We stop the spinner because the QR is already visible via localUri
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

/// Dialog that writes the payment request URI to an NFC tag.
class _NfcWriteDialog extends StatefulWidget {
  final String paymentRequestUri;
  final String walletName;
  final double? amountBtc;

  const _NfcWriteDialog({
    required this.paymentRequestUri,
    required this.walletName,
    this.amountBtc,
  });

  @override
  State<_NfcWriteDialog> createState() => _NfcWriteDialogState();
}

class _NfcWriteDialogState extends State<_NfcWriteDialog> {
  String _status = "Aproxime o celular da tag NFC";
  bool _writing = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer localized string initialization to allow context access or use didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _status = AppLocalizations.of(context)!.approachPhoneToNfc;
        });
      }
    });

    _startWriteSession();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  void _startWriteSession() {
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        if (_writing) return;
        setState(() => _writing = true);

        final ndef = Ndef.from(tag); // from nfc_manager_ndef (has write)
        if (ndef == null) {
          setState(() {
            _error = AppLocalizations.of(context)!.nfcTagNotSupported;
            _writing = false;
          });
          return;
        }
        if (!ndef.isWritable) {
          setState(() {
            _error = AppLocalizations.of(context)!.nfcTagNotWritable;
            _writing = false;
          });
          return;
        }

        // NDEF URI record: type U (0x55), payload = [0x00] + utf8(uri) (0 = no prefix)
        final uriBytes = utf8.encode(widget.paymentRequestUri);
        final payload = Uint8List.fromList([0x00, ...uriBytes]);
        final record = NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown,
          type: Uint8List.fromList([0x55]),
          identifier: Uint8List(0),
          payload: payload,
        );
        final message = NdefMessage(records: [record]);

        if (message.byteLength > ndef.maxSize) {
          setState(() {
            _error = AppLocalizations.of(context)!.nfcTagCapacityError;
            _writing = false;
          });
          return;
        }

        try {
          await ndef.write(message: message);
          if (!mounted) return;
          setState(() {
            _status = AppLocalizations.of(context)!.nfcTagWrittenSuccess;
            _success = true;
            _writing = false;
          });
          await NfcManager.instance.stopSession();
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = AppLocalizations.of(context)!.errorWriting(e.toString());
            _writing = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassContainer(
        blur: 40,
        opacity: 0.15,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.nfc_rounded,
                  color: _success
                      ? Colors.greenAccent
                      : const Color(0xFF00D4FF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.writeNfcTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.walletName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                if (!_success && !_writing && _error == null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) => Container(
                      width: 120 + (20 * value),
                      height: 120 + (20 * value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(
                            0xFF00D4FF,
                          ).withValues(alpha: 0.3 * (1 - value)),
                          width: 2,
                        ),
                      ),
                    ),
                    onEnd:
                        () {}, // Handled by repeating logic in a real app, here it's static pulse
                  ),
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_success
                                    ? Colors.greenAccent
                                    : _error != null
                                    ? Colors.redAccent
                                    : const Color(0xFF00D4FF))
                                .withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                    color: Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Center(
                    child: _success
                        ? const Icon(
                            Icons.check_rounded,
                            size: 64,
                            color: Colors.greenAccent,
                          )
                        : _writing
                        ? const CircularProgressIndicator(
                            color: Color(0xFF00D4FF),
                            strokeWidth: 3,
                          )
                        : Icon(
                            Icons.contactless_rounded,
                            size: 56,
                            color: _error != null
                                ? Colors.redAccent
                                : const Color(0xFF00D4FF),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              _error ?? _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _error != null
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _success ? "Pronto" : "Cancelar",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'nfc_interaction_screen.dart';
import 'receive_qr_screen.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/payment_request.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../../../core/utils/currency_logic.dart';
import '../../presentation/state/wallet_state.dart';
import '../../../../l10n/app_localizations.dart';

/// Tela de recebimento: dados da carteira + valor em BTC, com opção QR Code ou NFC.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildTabs(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAmountDisplay(),
                ],
              ),
            ),
            _buildKeypad(),
            const SizedBox(height: 24),
            _buildContinueButton(),
          ],
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
            AppLocalizations.of(context)!.receive,
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
          _buildTabItem("QR Code", 1),
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
          AppLocalizations.of(context)!.howMuchToReceive.toUpperCase(),
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
    final canContinue = (double.tryParse(_amount) ?? 0.0) > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isGenerating || !canContinue) ? null : _generateAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0033FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: const Color(0xFF0033FF).withValues(alpha: 0.2),
              ),
              child: _isGenerating
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

  Future<void> _generateAndNavigate() async {
    setState(() {
      _isGenerating = true;
    });

    final String address = _selectedWallet?.address ?? '';
    final double amountBtc = _paymentRequest.amountBtc ?? 0;

    final queryParams = <String, String>{
      'address': address,
      'amount': amountBtc.toStringAsFixed(8),
    };
    if (_selectedWallet != null) {
      queryParams['label'] = _selectedWallet!.name;
    }

    final localUri = Uri(
      scheme: 'kerosene',
      path: 'pay',
      queryParameters: queryParams,
    ).toString();

    // Background sync
    try {
      ref.read(paymentLinkNotifierProvider.notifier).create(
        amount: amountBtc,
        receiverWalletName: _selectedWallet?.name ?? 'main',
        expiresIn: null,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
      
      if (_selectedTabIndex == 0) {
        // NFC mode
        // For now push to the UI screen. The actual NFC write logic will be handled inside that screen.
        // Or we pass the URI to it. We need to update NfcInteractionScreen to accept the URI!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfcInteractionScreen(amountDisplay: _amount, paymentUri: localUri), // Will update NfcInteractionScreen
          ),
        );
      } else {
        // QR Code mode
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiveQrScreen(
              amountDisplay: _amount,
              paymentUri: localUri,
            ),
          ),
        );
      }
    }
  }
}

/// Dialog that writes the payment request URI to an NFC tag.
class _NfcWriteDialog extends StatefulWidget {
  final String paymentRequestUri;
  final String walletName;

  const _NfcWriteDialog({
    required this.paymentRequestUri,
    required this.walletName,
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

        final ndef = Ndef.from(tag); // from nfc_manager
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

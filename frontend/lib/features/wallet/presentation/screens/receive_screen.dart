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

/// Tela de recebimento: dados da carteira + valor em BTC, com opção QR Code ou NFC.
class ReceiveScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const ReceiveScreen({super.key, required this.wallet});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _amountController = TextEditingController();
  static const _defaultAmount = '';

  @override
  void initState() {
    super.initState();
    _amountController.text = _defaultAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amountBtc {
    final s = _amountController.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  PaymentRequest get _paymentRequest {
    return PaymentRequest(
      address: widget.wallet.address,
      amountBtc: _amountBtc != null && _amountBtc! > 0 ? _amountBtc : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF101018)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Premium Styled App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Receber",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SFProDisplay',
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer to balance leading
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),

                      // Wallet & Address Card
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: GlassContainer(
                          blur: 30,
                          opacity: 0.08,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.all(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF7931A,
                                      ).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFFF7931A),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.wallet.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Seu Endereço Bitcoin",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      widget.wallet.address.isEmpty
                                          ? "Endereço não disponível"
                                          : widget.wallet.address,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (widget.wallet.address.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: widget.wallet.address,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            "Endereço copiado!",
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF7931A,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 16,
                                      color: Color(0xFFF7931A),
                                    ),
                                    label: const Text(
                                      "Copiar Endereço",
                                      style: TextStyle(
                                        color: Color(0xFFF7931A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amount Section
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quanto você quer receber?",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassContainer(
                              blur: 30,
                              opacity: 0.08,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '₿',
                                    style: TextStyle(
                                      color: Color(0xFFF7931A),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      onChanged: (_) => setState(() {}),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "0.00000000",
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        "Método de Recebimento",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SFProDisplay',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code Option
                      _ReceiveOptionCard(
                        icon: Icons.qr_code_2_rounded,
                        title: "QR Code",
                        subtitle: "Gere um código para ser escaneado",
                        color: const Color(0xFFF7931A),
                        onTap: () => _showQrReceive(context),
                      ),
                      const SizedBox(height: 12),

                      // NFC Option
                      _ReceiveOptionCard(
                        icon: Icons.nfc_rounded,
                        title: "NFC Beam",
                        subtitle: "Grave o pedido em uma tag NFC",
                        color: const Color(0xFF00D4FF),
                        onTap: () => _showNfcWrite(context),
                      ),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrReceive(BuildContext context) {
    final request = _paymentRequest;
    final qrData = request.toBitcoinUri();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        blur: 40,
        opacity: 0.15,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFFF7931A),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Escanear para Pagar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SFProDisplay',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (widget.wallet.address.isNotEmpty)
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
                  size: 240,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF000000),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF000000),
                  ),
                ),
              )
            else
              const Icon(Icons.qr_code_2, size: 240, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              widget.wallet.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (request.amountBtc != null && request.amountBtc! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "${request.amountBtc!.toStringAsFixed(8)} BTC",
                  style: const TextStyle(
                    color: Color(0xFFF7931A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Fechar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNfcWrite(BuildContext context) {
    final request = _paymentRequest;
    final uri = request.toBitcoinUri();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NfcWriteDialog(
        paymentRequestUri: uri,
        walletName: widget.wallet.name,
        amountBtc: request.amountBtc,
      ),
    );
  }
}

class _ReceiveOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReceiveOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          blur: 20,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
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
            _error = "Tag não suporta NDEF";
            _writing = false;
          });
          return;
        }
        if (!ndef.isWritable) {
          setState(() {
            _error = "Tag não pode ser gravada";
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
            _error = "Pedido maior que a capacidade da tag";
            _writing = false;
          });
          return;
        }

        try {
          await ndef.write(message: message);
          if (!mounted) return;
          setState(() {
            _status = "Tag gravada com sucesso!";
            _success = true;
            _writing = false;
          });
          await NfcManager.instance.stopSession();
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = "Erro ao gravar: $e";
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
                const Text(
                  "Gravar Tag NFC",
                  style: TextStyle(
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

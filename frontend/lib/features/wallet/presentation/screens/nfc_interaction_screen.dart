import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';

import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/services/audio_service.dart';

class NfcInteractionScreen extends StatefulWidget {
  final String amountDisplay;
  final String? paymentUri;

  const NfcInteractionScreen({
    super.key,
    required this.amountDisplay,
    this.paymentUri,
  });

  @override
  State<NfcInteractionScreen> createState() => _NfcInteractionScreenState();
}

class _NfcInteractionScreenState extends State<NfcInteractionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  bool _isProcessing = false;
  String _statusMessage = 'Ready to connect...';

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNfcSession();
  }

  void _startNfcSession() async {
    // ignore: deprecated_member_use
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _statusMessage = "NFC not available on this device";
        });
      }
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        if (!mounted) return;
        setState(() {
          _isProcessing = true;
          _statusMessage = "Processing...";
        });

        try {
          if (widget.paymentUri != null) {
            // WRITE MODE
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              _handleError("Tag is not NDEF writable");
              return;
            }

            final uriBytes = utf8.encode(widget.paymentUri!);
            final payload = Uint8List.fromList([0x00, ...uriBytes]);
            final record = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x55]),
              identifier: Uint8List(0),
              payload: payload,
            );
            final message = NdefMessage(records: [record]);

            await ndef.write(message: message);
            _handleSuccess("Payment request beamed successfully!");
          } else {
            // READ MODE
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              _handleError("Tag is not NDEF formatted");
              return;
            }

            final message = ndef.cachedMessage;
            if (message != null && message.records.isNotEmpty) {
              for (var record in message.records) {
                if (record.typeNameFormat == TypeNameFormat.wellKnown &&
                    record.type.length == 1 &&
                    record.type.first == 0x55) {
                  final payload = record.payload;
                  if (payload.length > 1) {
                    final uriString = utf8.decode(payload.sublist(1));
                    _handleSuccessRead(uriString);
                    return;
                  }
                }
              }
            }
            _handleError("No valid payment request found on tag");
          }
        } catch (e) {
          _handleError("NFC Error: $e");
        }
      },
    );
  }

  void _handleError(String msg) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playError();
    setState(() {
      _isProcessing = false;
      _statusMessage = msg;
    });
    SnackbarHelper.showError(msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _statusMessage = 'Ready to connect...');
        _startNfcSession();
      }
    });
  }

  void _handleSuccess(String msg) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playTransaction();
    SnackbarHelper.showSuccess(msg);
    Navigator.pop(context, true);
  }

  void _handleSuccessRead(String uri) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playTransaction();
    Navigator.pop(context, uri);
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 48),
            _buildAmount(),
            Expanded(child: Center(child: _buildNfcRipple())),
            _buildInstructions(),
            const SizedBox(height: 48),
            _buildCancelButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
          Text(
            widget.paymentUri != null ? 'Beam Payment' : 'Read Payment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildAmount() {
    return Text(
      widget.amountDisplay,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w300,
        fontFamily: 'Inter',
        letterSpacing: -1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNfcRipple() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (_rippleController.value * 0.5),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A5CFF).withOpacity(0.2 * (1.0 - _rippleController.value)),
                ),
              ),
            ),
            Transform.scale(
              scale: 1.0 + (_rippleController.value * 0.25),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A5CFF).withOpacity(0.4 * (1.0 - _rippleController.value)),
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A5CFF).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF1A5CFF).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A5CFF).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.contactless_outlined,
                color: Color(0xFF1A5CFF),
                size: 56,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            widget.paymentUri != null ? 'Tap to Beam' : 'Tap to Read',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Hold your device near the reader or another phone to initiate transfer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5CFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A5CFF).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: Color(0xFF1A5CFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcScanDialog extends StatefulWidget {
  const NfcScanDialog({super.key});

  @override
  State<NfcScanDialog> createState() => _NfcScanDialogState();
}

class _NfcScanDialogState extends State<NfcScanDialog> {
  String _status = "Ready to Scan";
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startNfcSession();
  }

  String? _payloadFromTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef == null) return null;

    final message = ndef.cachedMessage;
    if (message == null) return null;

    for (final record in message.records) {
      final payload = record.payload;
      if (payload.isEmpty) continue;

      final full = utf8.decode(payload, allowMalformed: true);
      if (_looksLikePaymentRequest(full)) return full;

      if (payload.length > 1) {
        final withoutFirst = utf8.decode(
          payload.sublist(1),
          allowMalformed: true,
        );
        if (_looksLikePaymentRequest(withoutFirst)) return withoutFirst;
      }
    }
    return null;
  }

  bool _looksLikePaymentRequest(String s) {
    final t = s.trim();
    return t.toLowerCase().startsWith('bitcoin:') ||
        (t.startsWith('{') && t.contains('"address"'));
  }

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.checkAvailability() ==
        NfcAvailability.enabled;
    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _status = "NFC not available on this device";
        });
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Hold your device near the NFC tag";
    });

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        String? paymentRequestString = _payloadFromTag(tag);
        if (paymentRequestString == null && Ndef.from(tag) != null) {
          try {
            final ndef = Ndef.from(tag)!;
            final message = await ndef.read();
            if (message != null) {
              for (final record in message.records) {
                final payload = record.payload;
                if (payload.isEmpty) continue;
                final full = utf8.decode(payload, allowMalformed: true);
                if (_looksLikePaymentRequest(full)) {
                  paymentRequestString = full;
                  break;
                }
              }
            }
          } catch (_) {}
        }

        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _status = paymentRequestString != null
              ? "Payment request read!"
              : "Tag Detected!";
        });

        await NfcManager.instance.stopSession();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.of(context).pop(paymentRequestString);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "NFC Scanner",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05),
              ),
              child: _isScanning
                  ? const Icon(Icons.nfc, size: 80, color: Color(0xFF00D4FF))
                  : const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.greenAccent,
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.54)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

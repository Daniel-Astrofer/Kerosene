import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';

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
    bool isAvailable =
        await NfcManager.instance.checkAvailability() ==
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
    final responsive = context.responsive;
    final dialogWidth = responsive.clampWidth(360);
    final visualSize = dialogWidth < 300 ? 124.0 : 150.0;
    final iconSize = visualSize * 0.54;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(responsive.horizontalPadding),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(responsive.isTinyPhone ? 18 : 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.1),
          ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: responsive.isTinyPhone ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.isTinyPhone ? 24 : 32),
            Container(
              height: visualSize,
              width: visualSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.05),
              ),
              child: _isScanning
                  ? Icon(
                      Icons.nfc,
                      size: iconSize,
                      color: const Color(0xFF00D4FF),
                    )
                  : Icon(
                      Icons.check_circle,
                      size: iconSize,
                      color: Colors.greenAccent,
                    ),
            ),
            SizedBox(height: responsive.isTinyPhone ? 24 : 32),
            Text(
              _status,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.7),
                fontSize: responsive.isTinyPhone ? 14 : 16,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

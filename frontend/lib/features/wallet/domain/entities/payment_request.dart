import 'dart:convert';

/// Represents a payment request (value + address) from QR code or NFC.
/// Used for both scanning and writing: QR/NFC payload can be Bitcoin URI or JSON.
class PaymentRequest {
  final String address;
  final double? amountBtc;

  const PaymentRequest({
    required this.address,
    this.amountBtc,
  });

  /// Parse from raw string (QR or NFC payload).
  /// Supports:
  /// - Bitcoin URI: bitcoin:ADDRESS or bitcoin:ADDRESS?amount=0.001
  /// - JSON: {"address":"...", "amount": 0.001} (amount in BTC)
  static PaymentRequest? tryParse(String raw) {
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();

    // Bitcoin URI (BIP-21)
    if (trimmed.toLowerCase().startsWith('bitcoin:')) {
      final withoutScheme = trimmed.substring(8).trim();
      final queryIndex = withoutScheme.indexOf('?');
      String address;
      double? amountBtc;
      if (queryIndex >= 0) {
        address = withoutScheme.substring(0, queryIndex).trim();
        final query = withoutScheme.substring(queryIndex + 1);
        for (final part in query.split('&')) {
          final eq = part.indexOf('=');
          if (eq > 0) {
            final key = part.substring(0, eq).toLowerCase();
            final value = Uri.decodeComponent(part.substring(eq + 1).trim());
            if (key == 'amount') {
              amountBtc = double.tryParse(value);
              break;
            }
          }
        }
      } else {
        address = withoutScheme;
      }
      if (address.isNotEmpty) {
        return PaymentRequest(address: address, amountBtc: amountBtc);
      }
      return null;
    }

    // JSON: {"address":"...", "amount": 0.001}
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>?;
        if (decoded == null) return null;
        final addr = decoded['address'];
        if (addr is! String || addr.isEmpty) return null;
        double? amountBtc;
        final am = decoded['amount'];
        if (am != null) {
          if (am is num) amountBtc = am.toDouble();
          if (am is String) amountBtc = double.tryParse(am);
        }
        return PaymentRequest(address: addr, amountBtc: amountBtc);
      } catch (_) {
        return null;
      }
    }

    // Plain address (e.g. long base58 or bech32)
    if (trimmed.length >= 26 && trimmed.length <= 62) {
      return PaymentRequest(address: trimmed, amountBtc: null);
    }

    return null;
  }

  /// Encode as Bitcoin URI for QR code or NFC tag writing.
  String toBitcoinUri() {
    if (amountBtc != null && amountBtc! > 0) {
      return 'bitcoin:$address?amount=${amountBtc!.toStringAsFixed(8)}';
    }
    return 'bitcoin:$address';
  }

  /// Encode as JSON for NFC tag (same logic as QR).
  String toJson() {
    if (amountBtc != null) {
      return '{"address":"$address","amount":$amountBtc}';
    }
    return '{"address":"$address"}';
  }
}

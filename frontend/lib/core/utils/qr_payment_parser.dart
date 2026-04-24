/// Represents a decoded payment request from QR or NFC.
class PaymentData {
  final String address;
  final String? paymentLinkId;
  final double? amountBtc;
  final String? label;
  final String? message;

  const PaymentData({
    required this.address,
    this.paymentLinkId,
    this.amountBtc,
    this.label,
    this.message,
  });

  /// Whether this data has enough info to pre-fill a send form.
  bool get isComplete => address.isNotEmpty || isPaymentLink;

  bool get isPaymentLink => paymentLinkId != null && paymentLinkId!.isNotEmpty;
}

/// Encodes and decodes payment request URIs used in QR codes and NFC tags.
///
/// Supported formats:
///   `bitcoin:<address>?amount=<btc>&label=<label>&message=<msg>`
///   `kerosene:pay?address=<address>&amount=<btc>&label=<label>`
///   `kerosene://pay/<id>`
///   `kerosene:link:<id>`
class QrPaymentParser {
  /// Encodes a payment request into a bitcoin: BIP-21 URI.
  static String encode({
    required String address,
    double? amountBtc,
    String? label,
    String? message,
  }) {
    final params = <String, String>{};

    if (amountBtc != null && amountBtc > 0) {
      // BIP-21 requires fixed-point, no trailing zeros
      params['amount'] = amountBtc
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    if (label != null && label.isNotEmpty) {
      params['label'] = Uri.encodeQueryComponent(label);
    }
    if (message != null && message.isNotEmpty) {
      params['message'] = Uri.encodeQueryComponent(message);
    }

    if (params.isEmpty) return 'bitcoin:$address';

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'bitcoin:$address?$query';
  }

  /// Encodes a kerosene-internal payment URI.
  static String encodeKerosene({
    required String address,
    double? amountBtc,
    String? label,
  }) {
    final params = <String, String>{'address': address};

    if (amountBtc != null && amountBtc > 0) {
      params['amount'] = amountBtc.toStringAsFixed(8);
    }
    if (label != null && label.isNotEmpty) {
      params['label'] = Uri.encodeQueryComponent(label);
    }

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'kerosene:pay?$query';
  }

  /// Encodes a locked Kerosene payment request. The id is resolved by the
  /// backend; amount and destination are intentionally not encoded in the QR.
  static String encodePaymentLink(String linkId) {
    return 'kerosene://payment/pay/${Uri.encodeComponent(linkId)}';
  }

  static String? extractPaymentLinkId(String raw) {
    if (raw.isEmpty) return null;

    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower.startsWith('kerosene:link:')) {
      final id = trimmed.substring('kerosene:link:'.length).trim();
      return id.isEmpty ? null : id;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.scheme.isEmpty && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first.toLowerCase() == 'pay' &&
          uri.pathSegments.length > 1) {
        final id = uri.pathSegments[1].trim();
        return id.isEmpty ? null : id;
      }
    }

    if (uri.scheme.toLowerCase() == 'kerosene') {
      if (uri.host.toLowerCase() == 'pay' && uri.pathSegments.isNotEmpty) {
        final id = uri.pathSegments.first.trim();
        return id.isEmpty ? null : id;
      }

      if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'pay' &&
          uri.pathSegments.length > 1) {
        final id = uri.pathSegments[1].trim();
        return id.isEmpty ? null : id;
      }
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.pathSegments.isNotEmpty) {
      final payIndex = uri.pathSegments.indexWhere(
        (segment) => segment.toLowerCase() == 'pay',
      );
      if (payIndex >= 0 && payIndex + 1 < uri.pathSegments.length) {
        final id = uri.pathSegments[payIndex + 1].trim();
        return id.isEmpty ? null : id;
      }
    }

    return null;
  }

  /// Decodes any payment URI into a [PaymentData] object.
  /// Returns null if the data cannot be parsed.
  static PaymentData? decode(String raw) {
    if (raw.isEmpty) return null;

    final trimmed = raw.trim();
    final paymentLinkId = extractPaymentLinkId(trimmed);
    if (paymentLinkId != null) {
      return PaymentData(
        address: '',
        paymentLinkId: paymentLinkId,
      );
    }

    // bitcoin: BIP-21 URI
    if (trimmed.toLowerCase().startsWith('bitcoin:')) {
      return _parseBitcoinUri(trimmed);
    }

    // kerosene:pay?...
    if (trimmed.toLowerCase().startsWith('kerosene:pay')) {
      return _parseKeroseneUri(trimmed);
    }

    // Plain address (no scheme) — looks like a bitcoin address
    if (_looksLikeBitcoinAddress(trimmed)) {
      return PaymentData(address: trimmed);
    }

    // Could be a username for internal transfer
    if (_looksLikeUsername(trimmed)) {
      return PaymentData(address: trimmed);
    }

    return null;
  }

  static PaymentData? _parseBitcoinUri(String uri) {
    try {
      // bitcoin:<address>?params
      final withoutScheme = uri.substring('bitcoin:'.length);
      final questionIdx = withoutScheme.indexOf('?');

      final address = questionIdx >= 0
          ? withoutScheme.substring(0, questionIdx)
          : withoutScheme;

      if (address.isEmpty) return null;

      double? amount;
      String? label;
      String? message;

      if (questionIdx >= 0) {
        final query = withoutScheme.substring(questionIdx + 1);
        final params = Uri.splitQueryString(query);
        amount = double.tryParse(params['amount'] ?? '');
        label = params['label'];
        message = params['message'];
      }

      return PaymentData(
        address: address,
        amountBtc: amount,
        label: label,
        message: message,
      );
    } catch (_) {
      return null;
    }
  }

  static PaymentData? _parseKeroseneUri(String uri) {
    try {
      final questionIdx = uri.indexOf('?');
      if (questionIdx < 0) return null;

      final query = uri.substring(questionIdx + 1);
      final params = Uri.splitQueryString(query);

      final address = params['address'] ?? '';
      if (address.isEmpty) return null;

      final amount = double.tryParse(params['amount'] ?? '');
      final label = params['label'];

      return PaymentData(
        address: address,
        amountBtc: amount,
        label: label,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeBitcoinAddress(String s) {
    // Mainnet: start with 1, 3, or bc1
    // Testnet/regtest: start with m, n, 2, tb1, or bcrt1
    return RegExp(r'^(1|3|bc1|m|n|2|tb1|bcrt1)[a-zA-HJ-NP-Z0-9]{20,90}$')
        .hasMatch(s);
  }

  static bool _looksLikeUsername(String s) {
    // Internal usernames: alphanumeric + underscore, 3-30 chars
    return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(s);
  }
}

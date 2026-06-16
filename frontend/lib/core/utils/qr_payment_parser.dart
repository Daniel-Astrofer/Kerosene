import 'bitcoin_network.dart';

/// Represents a decoded payment request from QR or NFC.
class PaymentData {
  final String address;
  final String? paymentLinkId;
  final String? lightningRequest;
  final double? amountBtc;
  final String? label;
  final String? message;

  const PaymentData({
    required this.address,
    this.paymentLinkId,
    this.lightningRequest,
    this.amountBtc,
    this.label,
    this.message,
  });

  /// Whether this data has enough info to pre-fill a send form.
  bool get isComplete =>
      address.isNotEmpty || isPaymentLink || hasLightningRequest;

  bool get isPaymentLink => paymentLinkId != null && paymentLinkId!.isNotEmpty;

  bool get hasLightningRequest =>
      lightningRequest != null && lightningRequest!.isNotEmpty;

  /// Lightning is preferred when a unified BIP-21 URI carries both rails.
  String get preferredDestination =>
      hasLightningRequest ? lightningRequest! : address;
}

/// Encodes and decodes payment request URIs used in QR codes and NFC tags.
///
/// Supported formats:
///   `bitcoin:<address>?amount=<btc>&label=<label>&message=<msg>`
///   `web+bitcoin:<address>?amount=<btc>&label=<label>&message=<msg>`
///   `bitcoin:<address>?amount=<btc>&lightning=<bolt11-or-lnurl>`
///   `kerosene:pay?address=<address>&amount=<btc>&label=<label>`
///   `kerosene://pay/<id>`
///   `kerosene:link:<id>`
class QrPaymentParser {
  static const double _maxBitcoinSupply = 21000000;

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

    // bitcoin: / web+bitcoin: BIP-21 URI
    if (_isBitcoinUri(trimmed)) {
      return _parseBitcoinUri(trimmed);
    }

    // lightning: BOLT11/LNURL URI
    if (trimmed.toLowerCase().startsWith('lightning:')) {
      final request = trimmed.substring('lightning:'.length).trim();
      if (_looksLikeLightningRequest(request)) {
        return PaymentData(address: request, lightningRequest: request);
      }
      return null;
    }

    // kerosene:pay?...
    if (trimmed.toLowerCase().startsWith('kerosene:pay')) {
      return _parseKeroseneUri(trimmed);
    }

    if (_looksLikeLightningRequest(trimmed)) {
      return PaymentData(address: trimmed, lightningRequest: trimmed);
    }

    // Plain address (no scheme) — looks like a bitcoin address
    if (_looksLikeBitcoinAddress(trimmed)) {
      return PaymentData(address: _normalizeAddress(trimmed));
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
      final withoutScheme = _stripBitcoinUriScheme(uri);
      final questionIdx = withoutScheme.indexOf('?');

      final rawAddress = questionIdx >= 0
          ? withoutScheme.substring(0, questionIdx)
          : withoutScheme;
      final address = _normalizeBitcoinUriAddress(rawAddress);
      if (address.isNotEmpty && !_looksLikeBitcoinAddress(address)) {
        return null;
      }

      double? amount;
      String? label;
      String? message;
      String? lightningRequest;

      if (questionIdx >= 0) {
        final query = withoutScheme.substring(questionIdx + 1);
        final params = Uri.splitQueryString(query);
        if (_hasUnsupportedRequiredParams(params)) {
          return null;
        }
        amount = _parseAmountBtc(params['amount']);
        if (params.containsKey('amount') &&
            params['amount']!.trim().isNotEmpty &&
            amount == null) {
          return null;
        }
        label = params['label'];
        message = params['message'];
        lightningRequest = _normalizeLightningRequest(params['lightning']);
      }

      if (address.isEmpty && lightningRequest == null) return null;

      return PaymentData(
        address: address,
        lightningRequest: lightningRequest,
        amountBtc: amount,
        label: label,
        message: message,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isBitcoinUri(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('bitcoin:') || lower.startsWith('web+bitcoin:');
  }

  static String _stripBitcoinUriScheme(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('web+bitcoin:')) {
      return value.substring('web+bitcoin:'.length);
    }
    return value.substring('bitcoin:'.length);
  }

  static bool _hasUnsupportedRequiredParams(Map<String, String> params) {
    return params.keys.any((key) => key.toLowerCase().startsWith('req-'));
  }

  static PaymentData? _parseKeroseneUri(String uri) {
    try {
      final questionIdx = uri.indexOf('?');
      if (questionIdx < 0) return null;

      final query = uri.substring(questionIdx + 1);
      final params = Uri.splitQueryString(query);

      final address = _normalizeAddress(params['address'] ?? '');
      if (address.isEmpty) return null;

      final amount = _parseAmountBtc(params['amount']);
      if (params.containsKey('amount') &&
          params['amount']!.trim().isNotEmpty &&
          amount == null) {
        return null;
      }
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

  static String _normalizeBitcoinUriAddress(String address) {
    final trimmed = address.trim();
    final withoutDeepLinkSlashes =
        trimmed.startsWith('//') ? trimmed.substring(2).trim() : trimmed;
    return _normalizeAddress(withoutDeepLinkSlashes);
  }

  static String _normalizeAddress(String address) {
    final trimmed = address.trim();
    if (_looksLikeBitcoinAddress(trimmed)) {
      return normalizeBitcoinAddressForDisplay(trimmed);
    }
    return trimmed;
  }

  static double? _parseAmountBtc(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (!_hasValidBitcoinAmountPrecision(trimmed)) {
      return null;
    }

    final amount = double.tryParse(trimmed);
    if (amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        amount > _maxBitcoinSupply) {
      return null;
    }
    return amount;
  }

  static bool _hasValidBitcoinAmountPrecision(String value) {
    final match = RegExp(r'^\d+(?:\.(\d{1,8}))?$').firstMatch(value);
    return match != null;
  }

  static String? _normalizeLightningRequest(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final withoutScheme = trimmed.toLowerCase().startsWith('lightning:')
        ? trimmed.substring('lightning:'.length).trim()
        : trimmed;

    return _looksLikeLightningRequest(withoutScheme) ? withoutScheme : null;
  }

  static bool _looksLikeBitcoinAddress(String s) {
    return looksLikeBitcoinAddress(s);
  }

  static bool _looksLikeLightningRequest(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    return RegExp(r'^(lnbc|lntb|lnbcrt)[0-9][0-9a-z]+$').hasMatch(lower) ||
        RegExp(r'^lnurl[0-9a-z]+$').hasMatch(lower) ||
        _looksLikeLightningAddress(trimmed);
  }

  static bool _looksLikeLightningAddress(String s) {
    final trimmed = s.trim();
    if (trimmed.length > 254 || trimmed.contains(RegExp(r'\s'))) {
      return false;
    }
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]{1,64}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$',
    ).hasMatch(trimmed);
  }

  static bool _looksLikeUsername(String s) {
    // Internal usernames: alphanumeric + underscore, 3-30 chars
    return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(s);
  }
}

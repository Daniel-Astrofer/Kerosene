enum BitcoinNetworkKind { mainnet, testnet, regtest, unknown }

const _bech32AddressPayloadPattern =
    r'[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{20,90}';
final _bech32AddressPattern = RegExp(
  '^(bc1|tb1|bcrt1)$_bech32AddressPayloadPattern\$',
);
final _legacyAddressPattern = RegExp(
  r'^(1|3|m|n|2)[a-zA-HJ-NP-Z0-9]{20,90}$',
);

BitcoinNetworkKind inferBitcoinNetworkFromAddress(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return BitcoinNetworkKind.unknown;
  }

  if (normalized.startsWith('bc1') ||
      normalized.startsWith('1') ||
      normalized.startsWith('3')) {
    return BitcoinNetworkKind.mainnet;
  }

  if (normalized.startsWith('bcrt1')) {
    return BitcoinNetworkKind.regtest;
  }

  if (normalized.startsWith('tb1') ||
      normalized.startsWith('m') ||
      normalized.startsWith('n') ||
      normalized.startsWith('2')) {
    return BitcoinNetworkKind.testnet;
  }

  return BitcoinNetworkKind.unknown;
}

BitcoinNetworkKind parseBitcoinNetwork(
  String? value, {
  String? fallbackAddress,
}) {
  final normalized = value?.trim().toLowerCase() ?? '';

  switch (normalized) {
    case 'mainnet':
    case 'bitcoin':
    case 'btc':
      return BitcoinNetworkKind.mainnet;
    case 'regtest':
    case 'regressiontest':
      return BitcoinNetworkKind.regtest;
    case 'testnet':
    case 'testnet3':
    case 'test':
      return BitcoinNetworkKind.testnet;
    default:
      return inferBitcoinNetworkFromAddress(fallbackAddress);
  }
}

bool looksLikeBitcoinAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final lower = trimmed.toLowerCase();
  if (_startsWithBech32NetworkPrefix(lower)) {
    return !_hasMixedCase(trimmed) && _bech32AddressPattern.hasMatch(lower);
  }

  return _legacyAddressPattern.hasMatch(trimmed);
}

String normalizeBitcoinAddressForDisplay(String value) {
  final trimmed = value.trim();
  final lower = trimmed.toLowerCase();
  if (_startsWithBech32NetworkPrefix(lower) &&
      looksLikeBitcoinAddress(trimmed)) {
    return lower;
  }
  return trimmed;
}

bool isBitcoinAddressCompatibleWithNetwork(
  String value,
  BitcoinNetworkKind network,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !looksLikeBitcoinAddress(trimmed)) {
    return false;
  }
  final normalized = normalizeBitcoinAddressForDisplay(trimmed).toLowerCase();

  switch (network) {
    case BitcoinNetworkKind.mainnet:
      return normalized.startsWith('bc1') ||
          normalized.startsWith('1') ||
          normalized.startsWith('3');
    case BitcoinNetworkKind.testnet:
      return normalized.startsWith('tb1') ||
          normalized.startsWith('m') ||
          normalized.startsWith('n') ||
          normalized.startsWith('2');
    case BitcoinNetworkKind.regtest:
      return normalized.startsWith('bcrt1') ||
          normalized.startsWith('m') ||
          normalized.startsWith('n') ||
          normalized.startsWith('2');
    case BitcoinNetworkKind.unknown:
      return true;
  }
}

bool _startsWithBech32NetworkPrefix(String value) {
  return value.startsWith('bc1') ||
      value.startsWith('tb1') ||
      value.startsWith('bcrt1');
}

bool _hasMixedCase(String value) {
  return value.contains(RegExp(r'[a-z]')) &&
      value.contains(RegExp(r'[A-Z]'));
}

String bitcoinNetworkDisplayName(BitcoinNetworkKind network) {
  switch (network) {
    case BitcoinNetworkKind.mainnet:
      return 'Mainnet';
    case BitcoinNetworkKind.testnet:
      return 'Testnet';
    case BitcoinNetworkKind.regtest:
      return 'Regtest';
    case BitcoinNetworkKind.unknown:
      return 'Rede indefinida';
  }
}

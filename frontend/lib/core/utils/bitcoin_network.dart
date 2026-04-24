enum BitcoinNetworkKind { mainnet, testnet, regtest, unknown }

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
  return RegExp(r'^(1|3|bc1|m|n|2|tb1|bcrt1)[a-zA-HJ-NP-Z0-9]{20,90}$')
      .hasMatch(value.trim());
}

bool isBitcoinAddressCompatibleWithNetwork(
  String value,
  BitcoinNetworkKind network,
) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || !looksLikeBitcoinAddress(normalized)) {
    return false;
  }

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

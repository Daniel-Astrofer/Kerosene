import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/utils/bitcoin_network.dart';

void main() {
  group('bitcoin_network', () {
    const lowerBech32 = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';
    const upperBech32 = 'BC1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH';
    const mixedBech32 = 'bc1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH';
    const legacyBase58 = '1BoatSLRHtKNngkdXEeobR76b53LETtpyT';

    test('accepts and normalizes uppercase bech32 addresses', () {
      expect(looksLikeBitcoinAddress(upperBech32), isTrue);
      expect(normalizeBitcoinAddressForDisplay(upperBech32), lowerBech32);
      expect(
        isBitcoinAddressCompatibleWithNetwork(
          upperBech32,
          BitcoinNetworkKind.mainnet,
        ),
        isTrue,
      );
    });

    test('rejects mixed-case bech32 addresses', () {
      expect(looksLikeBitcoinAddress(mixedBech32), isFalse);
      expect(
        isBitcoinAddressCompatibleWithNetwork(
          mixedBech32,
          BitcoinNetworkKind.mainnet,
        ),
        isFalse,
      );
    });

    test('preserves legacy base58 address casing', () {
      expect(looksLikeBitcoinAddress(legacyBase58), isTrue);
      expect(
        normalizeBitcoinAddressForDisplay(legacyBase58),
        legacyBase58,
      );
    });
  });
}

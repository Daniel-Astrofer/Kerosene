import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';

void main() {
  group('Wallet.fromJson', () {
    test('parses card type and dynamic fee rates from the API payload', () {
      final wallet = Wallet.fromJson(const {
        'id': 1,
        'name': 'MAIN',
        'depositAddress': 'bc1qmainwallet0001',
        'createdAt': '2026-04-07T00:00:00',
        'updatedAt': '2026-04-08T00:00:00',
        'isActive': true,
        'xpubConfigured': true,
        'cardType': 'BLACK',
        'withdrawalFeeRate': 0.0070,
        'depositFeeRate': '0.0070',
      });

      expect(wallet.id, '1');
      expect(wallet.name, 'MAIN');
      expect(wallet.address, 'bc1qmainwallet0001');
      expect(wallet.createdAt, DateTime.parse('2026-04-07T00:00:00'));
      expect(wallet.updatedAt, DateTime.parse('2026-04-08T00:00:00'));
      expect(wallet.isActive, isTrue);
      expect(wallet.cardType, WalletCardType.black);
      expect(wallet.withdrawalFeeRate, 0.007);
      expect(wallet.depositFeeRate, 0.007);
      expect(WalletCardType.formatRate(wallet.withdrawalFeeRate), '0.7%');
    });

    test('defaults legacy wallet payloads to bronze rates', () {
      final wallet = Wallet.fromJson(const {
        'id': 2,
        'name': 'SAVINGS',
      });

      expect(wallet.cardType, WalletCardType.bronze);
      expect(wallet.withdrawalFeeRate, 0.009);
      expect(wallet.depositFeeRate, 0.009);
      expect(WalletCardType.formatRate(wallet.depositFeeRate), '0.9%');
    });

    test('falls back to legacy address field when depositAddress is absent',
        () {
      final wallet = Wallet.fromJson(const {
        'id': 3,
        'name': 'LEGACY',
        'address': '1LegacyAddress',
        'isActive': 'false',
      });

      expect(wallet.address, '1LegacyAddress');
      expect(wallet.isActive, isFalse);
    });
  });
}

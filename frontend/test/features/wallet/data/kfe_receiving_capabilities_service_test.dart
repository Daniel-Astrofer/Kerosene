import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/wallet/data/kfe_receiving_capabilities_service.dart';

void main() {
  group('KfeReceivingCapabilities.fromJson', () {
    test('parses the flattened KFE capabilities payload', () {
      final capabilities = KfeReceivingCapabilities.fromJson(const {
        'canReceiveInternal': true,
        'canReceiveLightning': false,
        'canReceiveOnchain': true,
        'preferredRail': 'INTERNAL',
        'missingRequirements': ['KFE_LIGHTNING_RECEIVE_NOT_CONFIGURED'],
        'receiverDisplayName': '@minecraft',
        'internalWalletId': '4b5a98c6-fefa-4f57-b5fe-1fe6f8957df1',
        'availableRails': ['INTERNAL', 'ONCHAIN'],
      });

      expect(capabilities.canReceiveInternal, isTrue);
      expect(capabilities.canReceiveLightning, isFalse);
      expect(capabilities.canReceiveOnchain, isTrue);
      expect(capabilities.preferredRail, 'INTERNAL');
      expect(
        capabilities.missingRequirements,
        ['KFE_LIGHTNING_RECEIVE_NOT_CONFIGURED'],
      );
      expect(capabilities.receiverDisplayName, '@minecraft');
      expect(
        capabilities.internalWalletId,
        '4b5a98c6-fefa-4f57-b5fe-1fe6f8957df1',
      );
      expect(capabilities.availableRails, ['INTERNAL', 'ONCHAIN']);
    });

    test('unwraps the backend ApiResponse envelope when it reaches the service',
        () {
      final capabilities = KfeReceivingCapabilities.fromJson(const {
        'success': true,
        'message': 'KFE receiving capabilities retrieved.',
        'data': {
          'canReceiveInternal': true,
          'canReceiveLightning': false,
          'canReceiveOnchain': false,
          'preferredRail': 'INTERNAL',
          'missingRequirements': [
            'KFE_LIGHTNING_RECEIVE_NOT_CONFIGURED',
            'KFE_ONCHAIN_ADDRESS_NOT_FOUND',
          ],
          'receiverDisplayName': '@minecraft',
          'internalWalletId': '4b5a98c6-fefa-4f57-b5fe-1fe6f8957df1',
          'availableRails': ['INTERNAL'],
        },
        'errorCode': null,
      });

      expect(capabilities.canReceiveInternal, isTrue);
      expect(
        capabilities.internalWalletId,
        '4b5a98c6-fefa-4f57-b5fe-1fe6f8957df1',
      );
      expect(capabilities.receiverDisplayName, '@minecraft');
      expect(capabilities.availableRails, ['INTERNAL']);
    });

    test('keeps backend not-ready reasons when the receiver has no wallet', () {
      final capabilities = KfeReceivingCapabilities.fromJson(const {
        'success': true,
        'data': {
          'canReceiveInternal': false,
          'canReceiveLightning': false,
          'canReceiveOnchain': false,
          'preferredRail': null,
          'missingRequirements': [
            'KFE_INTERNAL_WALLET_NOT_FOUND',
            'KFE_LIGHTNING_RECEIVE_NOT_CONFIGURED',
            'KFE_ONCHAIN_ADDRESS_NOT_FOUND',
          ],
          'receiverDisplayName': '@minecraft',
          'internalWalletId': null,
          'availableRails': [],
        },
      });

      expect(capabilities.canReceiveInternal, isFalse);
      expect(capabilities.internalWalletId, isNull);
      expect(
        capabilities.missingRequirements,
        contains('KFE_INTERNAL_WALLET_NOT_FOUND'),
      );
    });
  });
}

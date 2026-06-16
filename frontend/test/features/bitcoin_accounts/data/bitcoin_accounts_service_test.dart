import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:test/test.dart';

void main() {
  test('maps KFE dashboard active address to receive request', () {
    final requests =
        RemoteBitcoinAccountsService.receiveRequestsFromKfeDashboard(
      const {
        'wallets': [
          {
            'walletId': 'wallet-1',
            'activeAddress': ' bcrt1qactive0000000000000000000000000000000 ',
            'updatedAt': '2026-06-15T12:30:00Z',
          },
        ],
      },
      'wallet-1',
    );

    expect(requests, hasLength(1));
    expect(requests.single.id,
        'kfe:wallet-1:bcrt1qactive0000000000000000000000000000000');
    expect(requests.single.accountId, 'wallet-1');
    expect(
        requests.single.address, 'bcrt1qactive0000000000000000000000000000000');
    expect(requests.single.bip21,
        'bitcoin:bcrt1qactive0000000000000000000000000000000');
    expect(requests.single.createdAt, DateTime.parse('2026-06-15T12:30:00Z'));
  });

  test('returns no receive requests when KFE wallet has no active address', () {
    final requests =
        RemoteBitcoinAccountsService.receiveRequestsFromKfeDashboard(
      const {
        'wallets': [
          {'walletId': 'wallet-1', 'activeAddress': ''},
        ],
      },
      'wallet-1',
    );

    expect(requests, isEmpty);
  });
}

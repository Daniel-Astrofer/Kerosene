import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_account_models.dart';
import 'package:test/test.dart';

void main() {
  test('builds KFE receive view from active address', () {
    final view = ReceivingRequestView.fromKfeActiveAddress(
      accountId: 'wallet-1',
      address: ' bcrt1qactive0000000000000000000000000000000 ',
      createdAt: DateTime.utc(2026, 6, 15, 12),
    );

    expect(
      view.id,
      'kfe:wallet-1:bcrt1qactive0000000000000000000000000000000',
    );
    expect(view.accountId, 'wallet-1');
    expect(view.address, 'bcrt1qactive0000000000000000000000000000000');
    expect(
      view.bip21,
      'bitcoin:bcrt1qactive0000000000000000000000000000000',
    );
    expect(view.status, 'ACTIVE');
    expect(view.amountSats, isNull);
    expect(view.expiry, isEmpty);
    expect(view.oneTime, isFalse);
    expect(view.createdAt, DateTime.utc(2026, 6, 15, 12));
  });

  test('builds KFE receive view with amount in BIP21', () {
    final view = ReceivingRequestView.fromKfeActiveAddress(
      accountId: 'wallet-1',
      address: 'bcrt1qactive0000000000000000000000000000000',
      amountSats: 50000,
      expiry: '15M',
      oneTime: true,
    );

    expect(
      view.bip21,
      'bitcoin:bcrt1qactive0000000000000000000000000000000?amount=0.00050000',
    );
    expect(view.amountSats, 50000);
    expect(view.expiry, '15M');
    expect(view.oneTime, isTrue);
  });

  test('parses cold wallet UTXO view', () {
    final utxo = ColdWalletUtxoView.fromJson(const {
      'id': 'utxo-1',
      'txidRef': 'abcdef12...34567890',
      'vout': 1,
      'amountSats': '250000',
      'confirmations': 6,
      'status': 'UNSPENT',
    });

    expect(utxo.id, 'utxo-1');
    expect(utxo.vout, 1);
    expect(utxo.amountSats, 250000);
    expect(utxo.isSpendable, isTrue);
  });

  test('parses PSBT workflow view', () {
    final workflow = PsbtWorkflowView.fromJson(const {
      'id': 'psbt-1',
      'coldWalletId': 'cold-1',
      'unsignedPsbt': 'cHNidP8BAHECAAAAA',
      'status': 'WAITING_EXTERNAL_SIGNATURE',
      'destinationAddress': 'bc1qrecipient000000000000000000000000000000',
      'amountSats': 100000,
      'estimatedFeeSats': 400,
      'expiresAt': '2026-05-29T00:00:00Z',
      'createdAt': '2026-05-28T00:00:00Z',
    });

    expect(workflow.id, 'psbt-1');
    expect(workflow.awaitsSignature, isTrue);
    expect(workflow.amountSats, 100000);
  });

  test('parses tax export view with nested events', () {
    final export = TaxEventsExportView.fromJson(const {
      'format': 'json',
      'filename': 'kerosene-tax-events.json',
      'educationalNotice': 'notice',
      'events': [
        {
          'id': 'tax-1',
          'eventType': 'DEPOSIT_INTERNAL',
          'asset': 'BTC',
          'quantitySats': '50000',
          'classification': 'SELF_TRANSFER',
          'sourceRef': 'abcdef12...34567890',
          'createdAt': '2026-05-28T00:00:00Z',
        }
      ],
    });

    expect(export.filename, 'kerosene-tax-events.json');
    expect(export.events, hasLength(1));
    expect(export.events.first.quantitySats, 50000);
  });
}

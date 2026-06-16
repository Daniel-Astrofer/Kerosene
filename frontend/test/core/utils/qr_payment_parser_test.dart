import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';

void main() {
  group('QrPaymentParser', () {
    test('decodes Kerosene payment links', () {
      final data = QrPaymentParser.decode(
        'https://app.kerosene.local/pay/link-123',
      );

      expect(data, isNotNull);
      expect(data!.isPaymentLink, isTrue);
      expect(data.paymentLinkId, 'link-123');
    });

    test('decodes bitcoin uri with amount and label', () {
      final data = QrPaymentParser.decode(
        'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.05&label=Reserva',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
      expect(data.amountBtc, 0.05);
      expect(data.label, 'Reserva');
    });

    test('decodes browser web+bitcoin payment links', () {
      final data = QrPaymentParser.decode(
        'web+bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.025&message=Invoice%2042',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
      expect(data.amountBtc, 0.025);
      expect(data.message, 'Invoice 42');
    });

    test(
      'normalizes uppercase bech32 bitcoin uri addresses from QR payloads',
      () {
        final data = QrPaymentParser.decode(
          'bitcoin:BC1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH?amount=0.05',
        );

        expect(data, isNotNull);
        expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
        expect(data.amountBtc, 0.05);
      },
    );

    test('normalizes bitcoin deep-link address variant', () {
      final data = QrPaymentParser.decode(
        'bitcoin://bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.05',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
      expect(data.amountBtc, 0.05);
    });

    test('rejects mixed-case bech32 bitcoin uri addresses', () {
      expect(
        QrPaymentParser.decode(
          'bitcoin:bc1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH?amount=0.05',
        ),
        isNull,
      );
    });

    test('rejects unsafe bitcoin uri amounts', () {
      const address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

      final zeroAmount = QrPaymentParser.decode('bitcoin:$address?amount=0');
      expect(zeroAmount, isNotNull);
      expect(zeroAmount!.amountBtc, 0);

      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=-0.01'),
        isNull,
      );
      expect(QrPaymentParser.decode('bitcoin:$address?amount=NaN'), isNull);
      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=Infinity'),
        isNull,
      );
      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=21000000.00000001'),
        isNull,
      );
      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=0.000000001'),
        isNull,
      );
      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=1e-8'),
        isNull,
      );
    });

    test('rejects bitcoin uris with unsupported required params', () {
      const address = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

      expect(
        QrPaymentParser.decode('bitcoin:$address?amount=0.01&req-extra=1'),
        isNull,
      );
    });

    test('decodes unified bitcoin uri with lightning request', () {
      final invoice = 'lnbc10u1p5exampleinvoice';
      final data = QrPaymentParser.decode(
        'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'
        '?amount=0.05&label=Reserva&lightning=$invoice',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
      expect(data.lightningRequest, invoice);
      expect(data.preferredDestination, invoice);
      expect(data.amountBtc, 0.05);
      expect(data.label, 'Reserva');
    });

    test('accepts bitcoin uri with only lightning request', () {
      final invoice = 'lnbc10u1p5exampleinvoice';
      final data = QrPaymentParser.decode('bitcoin:?lightning=$invoice');

      expect(data, isNotNull);
      expect(data!.address, isEmpty);
      expect(data.lightningRequest, invoice);
      expect(data.isComplete, isTrue);
    });

    test('decodes plain on-chain address', () {
      final data = QrPaymentParser.decode(
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
    });

    test('normalizes plain uppercase bech32 addresses', () {
      final data = QrPaymentParser.decode(
        'BC1QXY2KGDYGJRSQTZQ2N0YRF2493P83KKFJHX0WLH',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
    });

    test('decodes lightning invoices and lightning scheme', () {
      final invoice = 'lnbc10u1p5exampleinvoice';

      final plain = QrPaymentParser.decode(invoice);
      final schemed = QrPaymentParser.decode('lightning:$invoice');

      expect(plain?.address, invoice);
      expect(plain?.lightningRequest, invoice);
      expect(plain?.preferredDestination, invoice);
      expect(schemed?.address, invoice);
      expect(schemed?.lightningRequest, invoice);
      expect(schemed?.preferredDestination, invoice);
    });

    test('decodes LNURL and lightning address', () {
      expect(
        QrPaymentParser.decode('lnurl1dp68gurn8ghj7')?.address,
        'lnurl1dp68gurn8ghj7',
      );
      expect(
        QrPaymentParser.decode('alice@example.com')?.address,
        'alice@example.com',
      );
    });

    test('keeps internal username support', () {
      final data = QrPaymentParser.decode('usuario_123');

      expect(data, isNotNull);
      expect(data!.address, 'usuario_123');
    });

    test('rejects unsafe Kerosene payment amounts', () {
      expect(
        QrPaymentParser.decode('kerosene:pay?address=usuario_123&amount=-1'),
        isNull,
      );
      expect(
        QrPaymentParser.decode(
          'kerosene:pay?address=usuario_123&amount=21000001',
        ),
        isNull,
      );
    });
  });
}

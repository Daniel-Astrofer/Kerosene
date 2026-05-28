import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';

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

    test('decodes plain on-chain address', () {
      final data = QrPaymentParser.decode(
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      );

      expect(data, isNotNull);
      expect(data!.address, 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
    });

    test('decodes lightning invoices and lightning scheme', () {
      final invoice = 'lnbc10u1p5exampleinvoice';

      expect(QrPaymentParser.decode(invoice)?.address, invoice);
      expect(QrPaymentParser.decode('lightning:$invoice')?.address, invoice);
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
  });
}

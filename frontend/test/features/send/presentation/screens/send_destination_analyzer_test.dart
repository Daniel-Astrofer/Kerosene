import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_analyzer.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';

void main() {
  group('internal destination validation', () {
    test('accepts canonical KFE wallet UUIDs for internal transfers', () {
      const destination = '61a8bb23-e18e-4f32-8414-9844e7300c14';

      expect(isValidInternalDestination(destination), isTrue);
      expect(analyzeSendDestination(destination).type,
          SendDestinationType.internal);
    });

    test('accepts usernames and @usernames for internal transfers', () {
      for (final destination in const [
        'nycollas',
        '@nycollas',
      ]) {
        expect(isValidInternalDestination(destination), isTrue);
        expect(analyzeSendDestination(destination).type,
            SendDestinationType.internal);
      }
    });

    test('does not classify wallet hashes as internal transfers', () {
      const destination = 'abcdef1234567890abcdef1234567890';
      expect(isValidInternalDestination(destination), isFalse);
      expect(analyzeSendDestination(destination).type,
          SendDestinationType.invalid);
    });
  });
}

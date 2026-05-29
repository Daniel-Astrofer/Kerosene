import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/logging/app_log.dart';

void main() {
  test('sanitizeLogMessage masks financial and session secrets', () {
    final sanitized = sanitizeLogMessage(
      'Bearer eyJhbGciOi.fake.jwt token=abc123 '
      'mnemonic=abandon abandon abandon secret=JBSWY3DPEHPK3PXP '
      'challenge=0123456789abcdef0123456789abcdef0123456789abcdef '
      'address bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh '
      'invoice lnbc2500u1p3abcdefghijklmnoqrstuvwxyz1234567890 '
      'otpauth://totp/Kerosene?secret=JBSWY3DPEHPK3PXP',
    );

    expect(sanitized, contains('Bearer [REDACTED]'));
    expect(sanitized, contains('token=[REDACTED]'));
    expect(sanitized, contains('mnemonic=[REDACTED]'));
    expect(sanitized, contains('secret=[REDACTED]'));
    expect(sanitized, contains('challenge=[REDACTED]'));
    expect(sanitized, contains('bc1...[REDACTED]'));
    expect(sanitized, contains('lnbc...[REDACTED]'));
    expect(sanitized, isNot(contains('eyJhbGciOi.fake.jwt')));
    expect(sanitized, isNot(contains('JBSWY3DPEHPK3PXP')));
    expect(sanitized, isNot(contains('bc1qxy2kgdy')));
  });
}

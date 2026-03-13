import 'dart:math';
import 'package:crypto/crypto.dart';

class TotpUtil {
  static const _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Generates a random base32 encoded TOTP secret
  static String generateSecret({int length = 16}) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_base32Chars[random.nextInt(_base32Chars.length)]);
    }
    return buffer.toString();
  }

  /// Verifies a 6-digit TOTP code against a base32 encoded secret
  static bool verify(String secret, String code, {int timeStep = 30}) {
    if (code.length != 6) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currentWindow = currentTime ~/ timeStep;

    // Verify current window and previous/next windows to account for clock drift
    for (var i = -1; i <= 1; i++) {
      if (_generateTOTP(secret, currentWindow + i) == code) {
        return true;
      }
    }
    return false;
  }

  static String _generateTOTP(String secret, int window) {
    try {
      final key = _base32Decode(secret);
      final msg = _intToBytes(window);
      final hmac = Hmac(sha1, key);
      final digest = hmac.convert(msg);
      final hash = digest.bytes;

      final offset = hash[hash.length - 1] & 0xf;
      final binary =
          ((hash[offset] & 0x7f) << 24) |
          ((hash[offset + 1] & 0xff) << 16) |
          ((hash[offset + 2] & 0xff) << 8) |
          (hash[offset + 3] & 0xff);

      final otp = binary % 1000000;
      return otp.toString().padLeft(6, '0');
    } catch (e) {
      return '';
    }
  }

  static List<int> _base32Decode(String input) {
    input = input.toUpperCase().replaceAll('=', '');
    final bytes = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final val = _base32Chars.indexOf(char);
      if (val < 0) throw Exception('Invalid base32 character');

      buffer = (buffer << 5) | val;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bytes.add((buffer >> (bitsLeft - 8)) & 0xFF);
        bitsLeft -= 8;
      }
    }
    return bytes;
  }

  static List<int> _intToBytes(int value) {
    var bytes = List<int>.filled(8, 0);
    for (var i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }
}

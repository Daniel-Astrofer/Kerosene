import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Minimal TOTP (RFC 6238) generator for integration tests.
/// Uses only 'crypto' package.
class TotpGenerator {
  /// Generates a 6-digit TOTP code for a given Base32 secret.
  static String generate(String secret, {int? timeMs}) {
    final key = _base32Decode(secret);
    final time = timeMs ?? DateTime.now().millisecondsSinceEpoch;
    int counter = (time ~/ 30000); // Removido 'final' para permitir bit-shift

    // Counter to 8-byte big-endian
    final msg = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      msg[i] = counter & 0xff;
      counter >>= 8;
    }

    // HMAC-SHA1
    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(msg).bytes;

    // Dynamic Truncation
    final offset = hash[hash.length - 1] & 0xf;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  /// Simple Base32 decoder (handles standard alphabet A-Z, 2-7)
  static Uint8List _base32Decode(String base32) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = base32.toUpperCase().replaceAll('=', '');
    final bits = clean.split('').map((c) => alphabet.indexOf(c)).toList();

    final bytes = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (final val in bits) {
      if (val == -1) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bytes.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return Uint8List.fromList(bytes);
  }
}

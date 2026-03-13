import 'dart:typed_data';

/// Wrapper for sensitive data that encourages manual clearing/disposing.
/// Note: In Dart, Strings are immutable and cannot be zeroed out.
/// This class helps tracking lifecycle and zeroing out mutable buffers (Uint8List).
class SecureData {
  String? _stringData;
  Uint8List? _bytesData;

  SecureData.fromString(String string) : _stringData = string;
  SecureData.fromBytes(Uint8List bytes) : _bytesData = bytes;

  String get string => _stringData ?? ''; // Use with caution
  Uint8List get bytes => _bytesData ?? Uint8List(0);

  bool get isEmpty =>
      (_stringData == null || _stringData!.isEmpty) &&
      (_bytesData == null || _bytesData!.isEmpty);

  void dispose() {
    if (_bytesData != null) {
      // Zero out the bytes
      for (int i = 0; i < _bytesData!.length; i++) {
        _bytesData![i] = 0;
      }
      _bytesData = null;
    }
    _stringData = null; // Help GC
  }
}

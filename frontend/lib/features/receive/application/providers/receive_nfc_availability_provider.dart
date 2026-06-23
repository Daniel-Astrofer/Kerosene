import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// Returns whether the current device has NFC hardware support.
///
/// `NfcAvailability.disabled` still means the device is compatible; the user may
/// need to enable NFC in system settings before an active session can start.
Future<bool> keroseneDeviceSupportsNfc() async {
  try {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled ||
        availability == NfcAvailability.disabled;
  } catch (_) {
    return false;
  }
}

final receiveNfcCompatibilityProvider = FutureProvider<bool>((ref) async {
  return keroseneDeviceSupportsNfc();
});

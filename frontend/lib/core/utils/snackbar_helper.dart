import 'package:flutter/material.dart';
import '../presentation/widgets/animated_error_popup.dart';

class SnackbarHelper {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showError(String message) {
    _showPopup(message, isSuccess: false);
  }

  static void showSuccess(String message) {
    _showPopup(message, isSuccess: true);
  }

  static void _showPopup(String message, {required bool isSuccess}) {
    // ScaffoldMessenger context does not have a Navigator. We must use a NavigatorKey to show Dialogs natively.
    final context = navigatorKey.currentContext;
    if (context != null) {
      AnimatedErrorPopup.show(context, message: message, isSuccess: isSuccess);
    } else {
      debugPrint(
        '⚠️ Cannot show Animated Popup: Context is null. Message: $message',
      );
    }
  }
}

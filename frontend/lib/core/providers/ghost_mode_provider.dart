import 'package:flutter_riverpod/flutter_riverpod.dart';

class GhostModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    state = enabled;
  }

  void toggle() {
    state = !state;
  }
}

final ghostModeProvider = NotifierProvider<GhostModeNotifier, bool>(
  GhostModeNotifier.new,
);

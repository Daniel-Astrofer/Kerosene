import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monotonic signal emitted when the HTTP layer confirms the local session
/// cannot be trusted anymore.
final sessionInvalidationProvider =
    NotifierProvider<SessionInvalidationNotifier, int>(
  SessionInvalidationNotifier.new,
);

class SessionInvalidationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void emit() {
    state += 1;
  }
}

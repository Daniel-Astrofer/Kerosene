import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/features/auth/controller/auth_local_provider.dart';
import '../../../../core/services/balance_websocket_service.dart';
import '../../../../core/providers/tor_providers.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../../core/utils/device_helper.dart';
import 'wallet_provider.dart';

class ReceivedTxEvent {
  final String id;
  final double amount;
  final String walletName;
  final String? sender;
  final String? receiver;

  const ReceivedTxEvent({
    required this.id,
    required this.amount,
    required this.walletName,
    this.sender,
    this.receiver,
  });
}

const double _balanceChangeEpsilon = 0.000000001;
final RegExp _nonAddressCharacterPattern = RegExp(r'[^a-zA-Z0-9]');

class ReceivedTxEventNotifier extends Notifier<ReceivedTxEvent?> {
  static const int _maxRememberedEvents = 64;
  final ListQueue<String> _handledEventIds = ListQueue<String>();

  @override
  ReceivedTxEvent? build() => null;

  void updateEvent(ReceivedTxEvent? event) {
    if (event == null) {
      state = null;
      return;
    }

    if (state?.id == event.id || _handledEventIds.contains(event.id)) {
      return;
    }

    state = event;
  }

  void consumeEvent([String? eventId]) {
    final id = eventId ?? state?.id;
    if (id != null && id.isNotEmpty) {
      _rememberHandled(id);
    }
    state = null;
  }

  void _rememberHandled(String id) {
    if (_handledEventIds.contains(id)) {
      return;
    }

    _handledEventIds.addLast(id);
    while (_handledEventIds.length > _maxRememberedEvents) {
      _handledEventIds.removeFirst();
    }
  }
}

final receivedTxEventProvider =
    NotifierProvider<ReceivedTxEventNotifier, ReceivedTxEvent?>(
        ReceivedTxEventNotifier.new);

/// Provider do serviço WebSocket para atualizações de saldo em tempo real
final balanceWebSocketServiceProvider =
    FutureProvider.autoDispose<BalanceWebSocketService?>((
  ref,
) async {
  final authState = ref.watch(authControllerProvider);

  if (authState is! AuthAuthenticated) {
    debugPrint('BalanceWebSocket: authenticated session required.');
    return null;
  }

  // Watch the reactive Tor API URL
  final baseUrl = ref.watch(torApiUrlProvider);

  final userId = authState.user.id;
  debugPrint('BalanceWebSocket: preparing balance stream.');

  // Obter token JWT do armazenamento seguro
  String? token;
  try {
    token = await ref.read(authLocalDataSourceProvider).getToken();
    debugPrint('BalanceWebSocket: session credential lookup completed.');
    token = _normalizeSessionToken(token);
    if (token != null && token.length < 10) {
      debugPrint('BalanceWebSocket: session credential was rejected locally.');
    }
  } catch (_) {
    debugPrint('BalanceWebSocket: session credential unavailable.');
  }

  final deviceHash = await DeviceHelper.getDeviceHash();

  final service = BalanceWebSocketService(
    baseUrl: baseUrl,
    userId: userId.toString(),
    authToken: token,
    deviceHash: deviceHash,
    onBalanceUpdate: (update) {
      debugPrint('BalanceWebSocket: balance update received.');

      // ── Detect balance increase and record synthetic transaction ──
      final currentWalletState = ref.read(walletProvider);
      if (currentWalletState is WalletLoaded) {
        final wallet = currentWalletState.wallets.firstWhere(
          (w) => w.name == update.walletName,
          orElse: () => currentWalletState.wallets.first,
        );

        final oldBalance = wallet.balance;
        final newBalance = update.newBalance;
        final delta = newBalance - oldBalance;
        final hasMeaningfulChange = delta.abs() > _balanceChangeEpsilon;

        if (hasMeaningfulChange) {
          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(pagedTransactionHistoryProvider);
          ref.invalidate(depositsProvider);
          ref.invalidate(depositBalanceProvider);
          ref.invalidate(externalTransfersProvider);
        }

        // Use the amount from the update if available, otherwise use delta
        final receivedAmount = update.amount > 0 ? update.amount : delta;

        if (receivedAmount > _balanceChangeEpsilon) {
          final extractedSender = _extractSenderAddress(update);

          // Balance increased — trigger history refresh from server
          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(pagedTransactionHistoryProvider);

          // ── NOTIFICATIONS & FEEDBACK ──
          // 1. Local Notification - DISABLED to avoid confusion with Backend Pushes
          // NotificationService().showSubtleNotification(
          //   id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          //   title: 'Payment Received',
          //   body: 'You received ${receivedAmount.toStringAsFixed(8)} BTC',
          // );

          // 2. In-App Dialog Trigger
          ref
              .read(receivedTxEventProvider.notifier)
              .updateEvent(ReceivedTxEvent(
                id: _buildReceivedEventId(
                  update: update,
                  amount: receivedAmount,
                  sender: extractedSender,
                ),
                amount: receivedAmount,
                walletName: update.walletName,
                sender: extractedSender,
                receiver: update.receiver,
              ));
        }
      }

      // Update wallet balance in state
      ref
          .read(walletProvider.notifier)
          .updateBalanceFromWebSocket(update.walletName, update.newBalance);
    },
    onNotification: (event) {
      final notification = SessionNotificationItem(
        id: event.id,
        title: event.title,
        body: event.body,
        timestamp: event.timestamp,
        kind: event.kind,
        severity: event.severity,
        deeplink: event.deeplink,
        entityType: event.entityType,
        entityId: event.entityId,
        metadata: event.metadata,
      );

      final alertPreferences = ref.read(alertPreferencesProvider);
      if (!_shouldKeepNotification(notification, alertPreferences)) {
        return;
      }

      ref.read(sessionNotificationFeedProvider.notifier).add(notification);
      ref.invalidate(paymentLinksProvider);
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(pagedTransactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      unawaited(ref.read(walletProvider.notifier).refresh());

      if (alertPreferences.inAppBannersEnabled) {
        ref.read(notificationBannerProvider.notifier).show(notification);
      }
    },
  );

  // Conectar ao WebSocket
  await service.connect();

  // Desconectar quando o provider for descartado
  ref.onDispose(() {
    debugPrint('BalanceWebSocket: disconnecting.');
    service.disconnect();
  });

  return service;
});

String? _normalizeSessionToken(String? token) {
  if (token == null) {
    return null;
  }

  var normalized = token.trim();
  if (normalized.startsWith('"') && normalized.endsWith('"')) {
    normalized = normalized.substring(1, normalized.length - 1).trim();
  }
  if (normalized.startsWith('Bearer ')) {
    normalized = normalized.substring(7).trim();
  }
  if (normalized.contains('eyJ')) {
    normalized = normalized.substring(normalized.indexOf('eyJ'));
  }
  return normalized;
}

String? _extractSenderAddress(BalanceUpdate update) {
  final sender = update.sender;
  if (sender != null && sender.isNotEmpty) {
    return sender;
  }
  if (update.context.isEmpty) {
    return null;
  }

  for (final word in update.context.split(' ')) {
    final clean = word.replaceAll(_nonAddressCharacterPattern, '');
    if (_looksLikeBitcoinAddress(clean)) {
      return clean;
    }
  }
  return null;
}

bool _looksLikeBitcoinAddress(String value) {
  return value.length >= 26 &&
      (value.startsWith('1') ||
          value.startsWith('3') ||
          value.startsWith('bc1'));
}

String _buildReceivedEventId({
  required BalanceUpdate update,
  required double amount,
  required String? sender,
}) {
  return [
    update.walletId,
    update.walletName,
    update.userId,
    update.timestamp,
    amount.toStringAsFixed(8),
    update.newBalance.toStringAsFixed(8),
    sender ?? '',
    update.receiver ?? '',
    update.context,
  ].join('|');
}

bool _shouldKeepNotification(
  SessionNotificationItem notification,
  AlertPreferencesState preferences,
) {
  if (_isSecurityNotification(notification)) {
    return preferences.securityAlertsEnabled;
  }

  if (_isTransactionNotification(notification)) {
    return preferences.transactionAlertsEnabled;
  }

  return true;
}

bool _isSecurityNotification(SessionNotificationItem notification) {
  return notification.kind ==
          SessionNotificationItem.kindSecurityLoginDetected ||
      notification.kind ==
          SessionNotificationItem.kindSecurityAdminAccessAttempt ||
      notification.kind ==
          SessionNotificationItem.kindSecurityRecoveryCompleted;
}

bool _isTransactionNotification(SessionNotificationItem notification) {
  return {
    SessionNotificationItem.kindTransferReceived,
    SessionNotificationItem.kindTransferSent,
    SessionNotificationItem.kindPaymentRequestCreated,
    SessionNotificationItem.kindPaymentRequestPaid,
    SessionNotificationItem.kindDepositDetected,
    SessionNotificationItem.kindDepositConfirmed,
    SessionNotificationItem.kindPaymentSent,
  }.contains(notification.kind);
}

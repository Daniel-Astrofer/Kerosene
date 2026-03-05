import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/balance_websocket_service.dart';
import '../../../../main.dart' show sharedPreferencesProvider;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../../core/utils/device_helper.dart';
import 'wallet_provider.dart';

class ReceivedTxEvent {
  final double amount;
  final String walletName;
  final String? sender;
  final String? receiver;

  ReceivedTxEvent({
    required this.amount,
    required this.walletName,
    this.sender,
    this.receiver,
  });
}

final receivedTxEventProvider = StateProvider<ReceivedTxEvent?>((ref) => null);

/// Provider do serviço WebSocket para atualizações de saldo em tempo real
final balanceWebSocketServiceProvider = FutureProvider.autoDispose<BalanceWebSocketService?>((
  ref,
) async {
  final authState = ref.watch(authProvider);

  // Só conecta se usuário está autenticado
  if (authState is! AuthAuthenticated) {
    debugPrint('⚠️ WebSocket: Usuário não autenticado, não conectando');
    return null;
  }

  final userId = authState.user.id;
  debugPrint(
    '🔌 Iniciando WebSocket para userId: $userId (DEV MODE: BYPASSED)',
  );

  // DEV MODE: Don't connect
  return null;

  // Obter token JWT de forma síncrona do SharedPreferences
  String? token;
  try {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    token = sharedPrefs.getString('auth_token');
    debugPrint(
      '🔑 Token JWT obtido: ${token != null ? "✅ sim (len: ${token.length})" : "❌ não"}',
    );
    if (token != null) {
      if (token.startsWith('"') && token.endsWith('"')) {
        token = token.substring(1, token.length - 1).trim();
      }
      if (token.startsWith('Bearer ')) {
        token = token.substring(7).trim();
      }
      // Garante que o Token comece exclusivamente com 'eyJ' (Assinatura JWT Padrão)
      // Isso limpa qualquer prefixo corrompido no SharedPreferences local do cache antigo
      if (token.contains('eyJ')) {
        token = token.substring(token.indexOf('eyJ'));
      }
    }
    if (token != null && token.length < 10) {
      debugPrint('⚠️ Token JWT parece inválido/curto demais');
    }
  } catch (e) {
    debugPrint('⚠️ Erro ao obter token do SharedPreferences: $e');
  }

  final deviceHash = await DeviceHelper.getDeviceHash();

  final service = BalanceWebSocketService(
    baseUrl: AppConfig.apiUrl,
    userId: userId.toString(),
    authToken: token,
    deviceHash: deviceHash,
    onBalanceUpdate: (update) {
      debugPrint(
        '📨 WebSocket: Recebendo atualização para ${update.walletName}',
      );

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

        // Use the amount from the update if available, otherwise use delta
        final receivedAmount = update.amount > 0 ? update.amount : delta;

        if (receivedAmount > 0.000000001) {
          // Heuristic to find address in context if sender is missing
          String? extractedSender =
              (update.sender != null && update.sender!.isNotEmpty)
              ? update.sender
              : null;

          if (extractedSender == null && update.context.isNotEmpty) {
            final words = update.context.split(' ');
            for (final word in words) {
              final clean = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
              if (clean.length >= 26 &&
                  (clean.startsWith('1') ||
                      clean.startsWith('3') ||
                      clean.startsWith('bc1'))) {
                extractedSender = clean;
                break;
              }
            }
          }

          // Balance increased — trigger history refresh from server
          ref.invalidate(transactionHistoryProvider);

          // ── NOTIFICATIONS & FEEDBACK ──
          // 1. Local Notification - DISABLED to avoid confusion with Backend Pushes
          // NotificationService().showSubtleNotification(
          //   id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          //   title: 'Payment Received',
          //   body: 'You received ${receivedAmount.toStringAsFixed(8)} BTC',
          // );

          // 2. In-App Dialog Trigger
          ref.read(receivedTxEventProvider.notifier).state = ReceivedTxEvent(
            amount: receivedAmount,
            walletName: update.walletName,
            sender: extractedSender,
            receiver: update.receiver,
          );
        }
      }

      // Update wallet balance in state
      ref
          .read(walletProvider.notifier)
          .updateBalanceFromWebSocket(update.walletName, update.newBalance);
    },
  );

  // Conectar ao WebSocket
  await service.connect();

  // Desconectar quando o provider for descartado
  ref.onDispose(() {
    debugPrint('🔌 Desconectando WebSocket');
    service.disconnect();
  });

  return service;
});

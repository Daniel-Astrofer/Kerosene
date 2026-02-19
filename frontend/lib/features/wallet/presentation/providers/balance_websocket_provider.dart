import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/balance_websocket_service.dart';
import '../../../../main.dart' show sharedPreferencesProvider;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import 'wallet_provider.dart';
import '../../../../core/services/notification_service.dart';

class ReceivedTxEvent {
  final double amount;
  final String walletName;
  ReceivedTxEvent({required this.amount, required this.walletName});
}

final receivedTxEventProvider = StateProvider<ReceivedTxEvent?>((ref) => null);

/// Provider do serviço WebSocket para atualizações de saldo em tempo real
final balanceWebSocketServiceProvider = Provider.autoDispose<BalanceWebSocketService?>((
  ref,
) {
  final authState = ref.watch(authProvider);

  // Só conecta se usuário está autenticado
  if (authState is! AuthAuthenticated) {
    debugPrint('⚠️ WebSocket: Usuário não autenticado, não conectando');
    return null;
  }

  final userId = authState.user.id;
  debugPrint('🔌 Iniciando WebSocket para userId: $userId');

  // Obter token JWT de forma síncrona do SharedPreferences
  String? token;
  try {
    final sharedPrefs = ref.read(sharedPreferencesProvider);
    token = sharedPrefs.getString('auth_token');
    debugPrint('🔑 Token JWT obtido: ${token != null ? "✅ sim" : "❌ não"}');
  } catch (e) {
    debugPrint('⚠️ Erro ao obter token: $e');
  }

  final service = BalanceWebSocketService(
    baseUrl: AppConfig.apiBaseUrl,
    userId: userId.toString(),
    authToken: token,
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

        if (delta > 0.000000001) {
          // Balance increased — record as unknown incoming transfer
          final amountSatoshis = (delta * 100000000).round();
          final syntheticTx = Transaction(
            // Unique ID: timestamp + wallet address suffix
            id: 'ws_${DateTime.now().millisecondsSinceEpoch}_${wallet.address.substring(wallet.address.length > 8 ? wallet.address.length - 8 : 0)}',
            fromAddress: 'Carteira desconhecida',
            toAddress: wallet.address,
            amountSatoshis: amountSatoshis,
            feeSatoshis: 0,
            status: TransactionStatus.confirmed,
            type: TransactionType.receive,
            confirmations: 6,
            timestamp: DateTime.now(),
            description:
                'Recebimento de carteira desconhecida — ${update.walletName}',
          );

          ref
              .read(transactionHistoryProvider.notifier)
              .addTransaction(syntheticTx);

          debugPrint(
            '📥 Transação sintética registrada: +$delta BTC em ${update.walletName}',
          );

          // ── NOTIFICATIONS & FEEDBACK ──
          // 1. Local Notification (Background/Foreground)
          NotificationService().showSubtleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Payment Received',
            body: 'You received ${delta.toStringAsFixed(8)} BTC',
          );

          // 2. In-App Dialog Trigger (via Provider)
          ref.read(receivedTxEventProvider.notifier).state = ReceivedTxEvent(
            amount: delta,
            walletName: update.walletName,
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
  service.connect();

  // Desconectar quando o provider for descartado
  ref.onDispose(() {
    debugPrint('🔌 Desconectando WebSocket');
    service.disconnect();
  });

  return service;
});

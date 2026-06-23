import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'balance_websocket_service.dart';
import '../config/app_config.dart';
import '../security/secure_storage_service.dart';
import 'notification_service.dart';
import 'tor_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for the persistent foreground service notification
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'kerosene_foreground', // id
    'Kerosene Service', // title
    description: 'Running in background to monitor transactions', // description
    importance: Importance.low, // low importance to not annoy user
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: false,

      notificationChannelId: 'kerosene_foreground',
      initialNotificationTitle: 'Kerosene',
      initialNotificationContent: 'Monitoring transactions...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  if (!(await service.isRunning())) {
    await service.startService();
  }
}

Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke("stopService");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // Initialize Notification Service
  await NotificationService().init();

  // Get Token & User Data
  final secureStorage = SecureStorageService();
  String? token = await secureStorage.read(
    key: AppConfig.authTokenKey,
  );
  final userDataJson = await secureStorage.read(key: AppConfig.userDataKey);

  String? userId;
  if (userDataJson != null) {
    try {
      final userData = jsonDecode(userDataJson);
      userId = userData['id'];
    } catch (e) {
      debugPrint('BackgroundService: Error parsing user data: $e');
    }
  }

  if (token == null || userId == null) {
    debugPrint('BackgroundService: No token/userId ($userId) found. Stopping.');
    service.stopSelf();
    return;
  }

  // 🧅 MANDATORY: Start Tor network in this isolate
  bool torReady = false;
  try {
    debugPrint('BackgroundService: Starting Tor...');
    await TorService.instance.start();

    // Start local relay to the .onion backend for the background isolate
    final host = Uri.parse(AppConfig.onionBaseUrl).host;
    final int relayPort = await TorService.instance.startRelay(host, 80);
    AppConfig.apiUrl = 'http://127.0.0.1:$relayPort';
    torReady = true;
    debugPrint(
      'BackgroundService: Unified Tor Relay Active: ${AppConfig.apiUrl} -> $host',
    );
  } catch (e) {
    debugPrint('BackgroundService: Tor start failed: $e');
  }

  // Do not start the WebSocket if the relay is not ready —
  // it would connect to the raw .onion address and fail in an infinite loop.
  if (!torReady) {
    debugPrint('BackgroundService: Tor relay unavailable. Stopping service.');
    service.stopSelf();
    return;
  }

  // Store last known balance to detect changes
  final lastBalances = <String, double>{};
  final wsService = BalanceWebSocketService(
    baseUrl: AppConfig.apiUrl,
    userId: userId,
    authToken: token,
    onBalanceUpdate: (update) async {
      debugPrint(
        'BackgroundService: Update for ${update.walletName}: ${update.newBalance}',
      );

      final lastBalance = lastBalances[update.walletName] ?? 0.0;

      // Check if balance INCREASED (received money).
      // Background updates should never open in-app screens; Android gets a
      // native notification and the foreground UI refreshes on the next sync.
      if (lastBalance > 0 && update.newBalance > lastBalance + 0.00000001) {
        final delta =
            update.amount > 0 ? update.amount : update.newBalance - lastBalance;
        await NotificationService().showTransactionNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'BTC recebido',
          body:
              'Você recebeu ${delta.toStringAsFixed(8)} BTC em ${update.walletName}.',
          summary: update.walletName,
          payload: '/home',
          incoming: true,
          dedupeKey:
              'received:${update.walletId}:${delta.toStringAsFixed(8)}:${update.walletName}',
        );
      }

      // Update stored balance regardless of increase/decrease
      lastBalances[update.walletName] = update.newBalance;
    },
  );

  await wsService.connect();

  // Listen for stop events
  service.on('stopService').listen((event) {
    wsService.disconnect(); // Terminate hanging sockets
    service.stopSelf();
  });
}

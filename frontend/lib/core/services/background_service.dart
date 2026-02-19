import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'balance_websocket_service.dart';
import '../config/app_config.dart';
import 'notification_service.dart';

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
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'kerosene_foreground',
      initialNotificationTitle: 'Kerosene',
      initialNotificationContent: 'Monitoring transactions...',
      foregroundServiceNotificationId: 888,
      // Removido foregroundServiceTypes para evitar erros de compilação com enums ausentes.
      // O tipo padrão será definido pelo manifesto do Android.
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
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
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(AppConfig.authTokenKey);
  final userDataJson = prefs.getString(AppConfig.userDataKey);

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

  // Store last known balance to detect changes
  final wsService = BalanceWebSocketService(
    baseUrl: AppConfig.apiBaseUrl,
    userId: userId,
    authToken: token,
    onBalanceUpdate: (update) async {
      debugPrint(
        'BackgroundService: Update for ${update.walletName}: ${update.newBalance}',
      );

      final prefs = await SharedPreferences.getInstance();
      final lastBalanceKey = 'last_balance_${update.walletName}';
      final lastBalance = prefs.getDouble(lastBalanceKey) ?? 0.0;

      // Check if balance INCREASED (Received money)
      if (update.newBalance > lastBalance + 0.00000001) {
        final delta = update.newBalance - lastBalance;

        // Trigger Notification
        NotificationService().showSubtleNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Payment Received',
          body:
              'You received ${delta.toStringAsFixed(8)} BTC in ${update.walletName}',
        );
      }

      // Update stored balance regardless of increase/decrease
      await prefs.setDouble(lastBalanceKey, update.newBalance);
    },
  );

  wsService.connect();

  // Listen for stop events
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

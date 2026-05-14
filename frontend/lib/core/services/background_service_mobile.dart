import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../providers/alert_preferences_provider.dart';
import '../security/secure_storage_service.dart';
import 'balance_websocket_service.dart';
import 'notification_service.dart';
import 'tor_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for the persistent foreground service notification
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'kerosene_foreground', // id
    'Kerosene Service', // title
    description:
        'Running in background to monitor transaction and security alerts', // description
    importance: Importance.low, // low importance to not annoy
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
      isForegroundMode: true,

      notificationChannelId: 'kerosene_foreground',
      initialNotificationTitle: 'Kerosene em segundo plano',
      initialNotificationContent:
          'Monitorando transações e alertas de segurança',
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

  final backgroundAlertsEnabled = await loadBackgroundAlertsEnabled();
  if (!backgroundAlertsEnabled) {
    service.stopSelf();
    return;
  }

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: 'Kerosene em segundo plano',
      content: 'Monitorando transações e alertas de segurança',
    );
  }

  // Initialize Notification Service
  await NotificationService().init();

  // Get Token & User Data
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  final token = await secureStorage.read(key: AppConfig.authTokenKey);
  final userDataJson = prefs.getString(AppConfig.userDataKey);

  String? userId;
  if (userDataJson != null) {
    try {
      final userData = jsonDecode(userDataJson);
      userId = userData['id'];
    } catch (_) {
      debugPrint('BackgroundService: cached user data could not be parsed.');
    }
  }

  if (token == null || userId == null) {
    debugPrint('BackgroundService: session data missing. Stopping.');
    service.stopSelf();
    return;
  }

  // Mandatory: Start Tor network in this isolate
  bool torReady = false;
  try {
    debugPrint('BackgroundService: Starting Tor...');
    await TorService.instance.start();

    // Start local relay to the .onion backend for the background isolate
    final host = Uri.parse(AppConfig.onionBaseUrl).host;
    final int relayPort = await TorService.instance.startRelay(host, 80);
    AppConfig.apiUrl = 'http://127.0.0.1:$relayPort';
    torReady = true;
    debugPrint('BackgroundService: relay ready.');
  } catch (_) {
    debugPrint('BackgroundService: relay start failed.');
  }

  // Do not start the WebSocket if the relay is not ready.
  if (!torReady) {
    debugPrint('BackgroundService: Tor relay unavailable. Stopping service.');
    service.stopSelf();
    return;
  }

  // Store last known balance to detect changes
  final wsService = BalanceWebSocketService(
    baseUrl: AppConfig.apiUrl,
    userId: userId,
    authToken: token,
    onBalanceUpdate: (update) async {
      debugPrint('BackgroundService: balance update received.');

      final prefs = await SharedPreferences.getInstance();
      final lastBalanceKey = 'last_balance_${update.walletName}';
      // Keep the latest balance in storage so future background sessions have
      // an accurate baseline. Human-facing alerts come from /user/queue/notifications
      // to avoid duplicate OS notifications for the same transaction.
      await prefs.setDouble(lastBalanceKey, update.newBalance);
    },
    onNotification: (event) async {
      await NotificationService().showSubtleNotification(
        id: event.systemNotificationId,
        title: event.title,
        body: event.body,
      );
    },
  );

  await wsService.connect();

  // Listen for stop events
  service.on('stopService').listen((event) {
    wsService.disconnect(); // Terminate hanging sockets
    service.stopSelf();
  });
}

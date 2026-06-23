import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const Duration _nativeDedupeWindow = Duration(seconds: 45);
  final Map<String, DateTime> _lastNativeNotificationShownAt =
      <String, DateTime>{};

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<bool> requestPermissions() async {
    final androidGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final macosGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidGranted ?? iosGranted ?? macosGranted ?? true;
  }

  Future<void> showTransactionNotification({
    required int id,
    required String title,
    required String body,
    String? summary,
    String? payload,
    bool incoming = true,
    String? dedupeKey,
  }) async {
    final nativeDedupeKey =
        dedupeKey ?? _nativeDedupeKey(title: title, body: body);
    if (_shouldSuppressNativeNotification(nativeDedupeKey)) {
      return;
    }

    final androidNotificationDetails = AndroidNotificationDetails(
      'kerosene_transactions',
      'Kerosene transactions',
      channelDescription: 'Beautiful Android alerts for sends and receives.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color:
          incoming ? KeroseneBrandTokens.success : KeroseneBrandTokens.warning,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
      ticker: title,
      subText: summary,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
      playSound: true,
      enableVibration: true,
    );

    const darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      ),
      payload: payload,
    );
  }

  String _nativeDedupeKey({required String title, required String body}) {
    final normalizedBody = _normalizeNotificationText(body);
    if (normalizedBody.isNotEmpty) {
      return normalizedBody;
    }
    return _normalizeNotificationText(title);
  }

  String _normalizeNotificationText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _shouldSuppressNativeNotification(String key) {
    if (key.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    _lastNativeNotificationShownAt.removeWhere(
      (_, shownAt) => now.difference(shownAt) > _nativeDedupeWindow,
    );

    final lastShownAt = _lastNativeNotificationShownAt[key];
    if (lastShownAt != null &&
        now.difference(lastShownAt) <= _nativeDedupeWindow) {
      return true;
    }

    _lastNativeNotificationShownAt[key] = now;
    return false;
  }

  Future<void> showSubtleNotification({
    required int id,
    required String title,
    required String body,
  }) {
    return showTransactionNotification(
      id: id,
      title: title,
      body: body,
      summary: 'Kerosene',
    );
  }
}

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // iOS permission prompt (no-op on Android).
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));

    // Foreground messages -> show local notification
    FirebaseMessaging.onMessage.listen((m) async {
      await _showLocal(m);
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    final title = n.title ?? 'My Trek Guide';
    final body = n.body ?? '';

    const android = AndroidNotificationDetails(
      'general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: jsonEncode(message.data),
    );
  }
}


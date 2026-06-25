import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:wanmac/services/auth_service.dart';

class PushNotificationService {
  static const String _savePushTokenUrl = 'https://api.wanmac.ng/me/push-token';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'wanmac_rider_orders_v4';
  static const String _channelName = 'WANMAC Notifications';
  static const String _channelDescription =
      'Notifications for Wanmac updates and deliveries';

  static bool _initialized = false;
  static bool _listeningToTokenRefresh = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _initLocalNotifications();
    await _setupForegroundNotifications();
    _listenToTokenRefresh();
  }

  static Future<void> syncTokenAfterLogin() async {
    await initialize();

    // Give Auth/Cognito time to finish after fresh login or reinstall.
    await Future.delayed(const Duration(milliseconds: 500));

    await _saveDeviceToken();
  }

  static Future<void> initializeAndSyncToken() async {
    await syncTokenAfterLogin();
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('PUSH permission: ${settings.authorizationStatus}');
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('new_order'),
        playSound: true,
      ),
    );
  }

  static Future<void> _setupForegroundNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification == null) return;

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? 'WANMAC',
        body: notification.body ?? 'You have a new update',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('new_order'),
            enableVibration: true,
            icon: '@drawable/ic_stat_wanmac',
            color: Color(0xFF2F49D1),
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  static Future<void> _saveDeviceToken() async {
    final fcmToken = await _messaging.getToken();

    debugPrint('PUSH FCM TOKEN: $fcmToken');

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('PUSH FCM token is empty');
      return;
    }

    await _sendTokenToBackend(fcmToken);
  }

  static void _listenToTokenRefresh() {
    if (_listeningToTokenRefresh) return;
    _listeningToTokenRefresh = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('PUSH token refreshed: $newToken');

      final idToken = await AuthService.getValidIdToken();

      if (idToken == null || idToken.isEmpty) {
        debugPrint('PUSH token refreshed but no authenticated user yet');
        return;
      }

      await _sendTokenToBackend(newToken);
    });
  }

  static Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final idToken = await AuthService.getValidIdToken();

      if (idToken == null || idToken.isEmpty) {
        debugPrint('PUSH no valid id token');
        return;
      }

      final response = await http.post(
        Uri.parse(_savePushTokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      debugPrint('PUSH backend status: ${response.statusCode}');
      debugPrint('PUSH backend body: ${response.body}');
    } catch (error) {
      debugPrint('PUSH backend error: $error');
    }
  }
}

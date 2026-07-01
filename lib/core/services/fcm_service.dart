import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soccer_sys/core/services/fcm/fcm_background_handler.dart';
import 'package:soccer_sys/core/services/fcm/push_navigation_handler.dart';
import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/firebase_options.dart';

class FcmService {
  FcmService(this._supabaseService);

  final SupabaseService _supabaseService;

  static const _androidChannelId = 'lifestyle_fit_default';
  static const _androidChannelName = 'Lifestyle Fit';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  RemoteMessage? _pendingLaunchMessage;

  static Future<void> bootstrap() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    _initialized = true;

    await _setupLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final launchMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (launchMessage != null) {
      _pendingLaunchMessage = launchMessage;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((_) => syncToken());

    await syncToken();
  }

  Future<void> handlePendingLaunchNavigation() async {
    final message = _pendingLaunchMessage;
    if (message == null) return;
    _pendingLaunchMessage = null;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    PushNavigationHandler.handle(message.data);
  }

  Future<void> syncToken() async {
    if (!_initialized) return;

    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final platform = _platformLabel();
      await _supabaseService.client.from('profiles').update({
        'fcm_token': token,
        'fcm_platform': platform,
        'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (error, stack) {
      debugPrint('FcmService.syncToken error: $error\n$stack');
    }
  }

  Future<void> clearToken() async {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabaseService.client.from('profiles').update({
        'fcm_token': null,
        'fcm_platform': null,
        'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      if (_initialized) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (error, stack) {
      debugPrint('FcmService.clearToken error: $error\n$stack');
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        PushNavigationHandler.handle(_payloadToMap(payload));
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] == 'call_invite') {
      PushNavigationHandler.handle(data);
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _mapToPayload(message.data),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    PushNavigationHandler.handle(message.data);
  }

  String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String _mapToPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _payloadToMap(String payload) {
    final map = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      map[part.substring(0, index)] = part.substring(index + 1);
    }
    return map;
  }
}

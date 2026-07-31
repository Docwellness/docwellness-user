import 'dart:developer';
import 'dart:io';

import 'package:docwellness/app/modules/home/views/motivation_view.dart';
import 'package:docwellness/app/routes/app_pages.dart';
import 'package:docwellness/main.dart' as main_app;
import 'package:docwellness/utils/functions/dio_function.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Background message handler must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

/// FCM push for Goal Journey Timeline nudges - modeled on
/// docwellness-dietician's notification_service.dart, but completing its
/// token-registration TODO from day one instead of leaving it, and adding
/// deep-link navigation on notification tap (parsed from the message's
/// own `data.deepLink` - see docwellness-backend's utils/push.js - rather
/// than a separate OS-level custom-URI-scheme handler, since FCM's own tap
/// callback already carries everything needed and nothing else in this app
/// constructs a docwellness:// link).
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // FirebaseMessaging.instance throws '[core/no-app] No Firebase App has
    // been created' if Firebase.initializeApp() hasn't succeeded (e.g. no
    // google-services.json configured for this build yet) - this exact bug
    // was hit and fixed reactively in docwellness-dietician's
    // NotificationService; guarded proactively here from the start.
    if (Firebase.apps.isEmpty) {
      debugPrint('PushNotificationService: Firebase not initialized, push disabled');
      return;
    }

    final fcm = FirebaseMessaging.instance;

    final settings = await fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('PushNotificationService: permission ${settings.authorizationStatus}');

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('PushNotificationService: notification tapped: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel', // must match AndroidManifest.xml
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('PushNotificationService: foreground message ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Tapped from background (app was open but backgrounded).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    // Tapped from a fully-killed state - the message that launched the app.
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) _handleDeepLink(initialMessage);

    await _registerCurrentToken(fcm);
    fcm.onTokenRefresh.listen((_) => _registerCurrentToken(fcm));
  }

  Future<void> _registerCurrentToken(FirebaseMessaging fcm) async {
    try {
      final fcmToken = await fcm.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      if (main_app.token == null || main_app.token!.isEmpty) return; // not logged in yet

      await ApiService().request(
        endPoint: '/device-token',
        method: 'POST',
        data: {
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        headers: {'Authorization': 'Bearer ${main_app.token}'},
        silent: true,
      );
    } catch (e) {
      log('PushNotificationService: token registration failed (non-fatal): $e');
    }
  }

  void _handleDeepLink(RemoteMessage message) {
    final deepLink = message.data['deepLink'] as String?;
    if (deepLink == null || deepLink.isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;

    if (uri.host == 'timeline') {
      Get.toNamed(Routes.GOAL_TIMELINE, arguments: {'focus': uri.queryParameters['focus']});
    } else if (uri.host == 'quotes') {
      Get.to(() => const MotivationScreen());
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

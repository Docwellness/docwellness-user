import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:docwellness/app/modules/home/views/motivation_view.dart';
import 'package:docwellness/app/modules/home/views/view_first_consultation_view.dart';
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

  /// A notification tapped from a fully-killed state (getInitialMessage)
  /// arrives while the app is still on the splash screen - navigating then
  /// is either dropped (no navigator yet) or immediately wiped by the
  /// splash's own Get.offNamed(HOME). Park it here and let SplashView call
  /// consumePendingLaunchLink() once it has landed on Home.
  Map<String, dynamic>? _pendingLaunchData;

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
        // Foreground taps: FCM doesn't surface a system notification while
        // the app is in front, so we show our own (see _showLocalNotification,
        // whose payload is the message's data as JSON) - this fires when the
        // user taps that one. Route it exactly like a background tap.
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handleNotificationTap(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (e) {
          log('PushNotificationService: bad notification payload: $e');
        }
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
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleNotificationTap(message.data),
    );

    // Tapped from a fully-killed state - the message that launched the app.
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage.data);

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

  /// Single entry point for every notification tap (background via
  /// onMessageOpenedApp, killed via getInitialMessage, foreground via the
  /// local-notification response). Routes now if the app is past the splash
  /// screen; otherwise parks the data for SplashView to replay.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final route = Get.currentRoute;
    final ready = main_app.appStarted && route.isNotEmpty && route != Routes.SPLASH;
    if (!ready) {
      _pendingLaunchData = data;
      return;
    }
    _routeFromData(data);
  }

  /// Called by SplashView once it has navigated to Home - replays a
  /// notification tap that arrived during launch.
  void consumePendingLaunchLink() {
    final data = _pendingLaunchData;
    if (data == null) return;
    _pendingLaunchData = null;
    _routeFromData(data);
  }

  void _routeFromData(Map<String, dynamic> data) {
    final deepLink = data['deepLink'] as String?;
    if (deepLink == null || deepLink.isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;

    if (uri.host == 'chat') {
      // Chat messages, doctor notes, and the "free for a chat?" nudge -
      // the patient always chats with their single assigned dietician, so
      // no arguments are needed (ChatController falls back to
      // _getAssignedDoctorAndStartChat when Get.arguments is null).
      Get.toNamed(Routes.CHAT);
    } else if (uri.host == 'timeline') {
      // Every other nudge/reminder (log meal, weigh-in, water goal, goal
      // check-in) - opens Goal Journey and auto-shows the relevant day's
      // milestone sheet: a specific milestone if `focus` was given (manual
      // dietician nudges), otherwise today's (cron reminders/sweeps).
      final focus = uri.queryParameters['focus'];
      Get.toNamed(Routes.GOAL_TIMELINE, arguments: {
        'openMilestone': (focus != null && focus.isNotEmpty) ? focus : null,
        'openToday': focus == null || focus.isEmpty,
      });
    } else if (uri.host == 'quotes') {
      Get.to(() => const MotivationScreen());
    } else if (uri.host == 'consultation') {
      // Dietician completed / updated the first consultation - the patient
      // needs to review it and submit consent. Same destination as tapping
      // a 'consultation' notification in the in-app list.
      Get.to(() => const ViewFirstConsultationView());
    } else if (uri.host == 'payment') {
      // Dietician requested payment - the "Send Payment Details" action
      // lives on Home, so just make sure we land there.
      Get.offAllNamed(Routes.HOME);
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
      // JSON (not Map.toString()) so onDidReceiveNotificationResponse can
      // decode it and route the tap - see initialize() above.
      payload: jsonEncode(message.data),
    );
  }
}

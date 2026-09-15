import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function required by FCM for background/terminated messages.
/// Must be a top-level function (not a method or closure).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages the full lifecycle of push notifications:
///   1. Firebase init & permission request
///   2. FCM token retrieval (stored locally, ready for backend)
///   3. Foreground notification display via flutter_local_notifications
///   4. Tap handling for navigation
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// The FCM device token. Available after [initialize] completes.
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Optional callback the app can set to navigate when a notification is tapped.
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  // ─── Android notification channel ───────────────────────────────────
  static const _channel = AndroidNotificationChannel(
    'eyes_school_notifications', // Must match AndroidManifest meta-data
    'Eyes School',
    description: 'Notificaciones de Eyes School',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Public API ─────────────────────────────────────────────────────

  /// Call once, ideally right after [Firebase.initializeApp].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (Firebase.apps.isEmpty) {
      debugPrint('[FCM] Firebase no se inicializó previamente (¿falta google-services.json en Android o firebase_options.dart en Web?). Notificaciones omitidas.');
      return;
    }

    try {
      // Register the background handler (only supported on mobile / non-web).
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // Request permission (shows the OS dialog on Android 13+ and iOS).
      await _requestPermission();

      // Setup local notifications for mobile (foreground alerts).
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          await _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(_channel);
        }

        await _localNotifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: _onLocalNotificationTapped,
        );
      }

      // Get the FCM token.
      try {
        _fcmToken = await _messaging.getToken();
        debugPrint('\n==================================================');
        debugPrint('[FCM TOKEN]: $_fcmToken');
        debugPrint('==================================================\n');
      } catch (e) {
        debugPrint('[FCM] Error obteniendo el token FCM: $e');
      }

      // Listen for token refreshes.
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[FCM] Token re-generado: $newToken');
      });

      // ── Message handlers ──────────────────────────────────────────────

      // Foreground messages → show a local notification.
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // User tapped a notification while the app was in background.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // App was terminated and opened via notification tap.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('[FCM] Error inicializando FCM: $e');
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  /// Shows a local notification when the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'Eyes School',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      // Carry the data payload so the tap handler can read it.
      payload: jsonEncode(message.data),
    );
  }

  /// Called when the user taps a notification (background open).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    onNotificationTapped?.call(message.data);
  }

  /// Called when the user taps a local notification (foreground).
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('[FCM] Local notification tapped: $data');
      onNotificationTapped?.call(data);
    } catch (_) {
      // Malformed payload – nothing to navigate to.
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:eyes_school/features/notifications/domain/device_token_repository.dart';

/// Top-level function required by FCM for background/terminated messages.
/// Must be a top-level function (not a method or closure).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages the full lifecycle of push notifications (APP-08):
///   1. Message handlers and foreground display ([initialize])
///   2. Permission + device token registered with the API after sign-in, and
///      again on every token refresh ([onSignedIn])
///   3. Token unregistered on sign-out ([onSignedOut])
///   4. Tap handling for navigation
///
/// Its collaborators arrive through the constructor so the token flow can be
/// tested with doubles. The token itself is never written to the log, not even
/// in debug builds (APP-07).
class PushNotificationService {
  PushNotificationService({
    required this._messaging,
    required this._deviceTokens,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _localNotificationsOverride = localNotifications;

  final FirebaseMessaging _messaging;
  final DeviceTokenRepository _deviceTokens;
  final FlutterLocalNotificationsPlugin? _localNotificationsOverride;
  late final FlutterLocalNotificationsPlugin _localNotifications =
      _localNotificationsOverride ?? FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  StreamSubscription<String>? _refreshSubscription;

  /// The token registered for the current session, if any.
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
      if (kDebugMode) {
        debugPrint(
          '[FCM] Firebase no se inicializó previamente (¿falta google-services.json en Android o firebase_options.dart en Web?). Notificaciones omitidas.',
        );
      }
      return;
    }

    try {
      // Register the background handler (only supported on mobile / non-web).
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // Setup local notifications for mobile (foreground alerts).
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          await _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
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

      // The token is requested and registered in [onSignedIn], after the
      // permission prompt; it is never written to the log (APP-07).

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
      if (kDebugMode) debugPrint('[FCM] Error inicializando FCM: $e');
    }
  }

  /// After sign-in: asks for permission (Android 13+ shows the OS dialog) and,
  /// if granted, registers this device's token with the API. A denied
  /// permission is not an error: the app keeps working and novedades are
  /// still visible in their screen (CA-US027.4). Never throws.
  Future<void> onSignedIn() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return;
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) await _register(token);

      await _refreshSubscription?.cancel();
      _refreshSubscription = _messaging.onTokenRefresh.listen(_register);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] No se pudo registrar el dispositivo: $e');
      }
    }
  }

  /// Before sign-out, while the session can still authenticate the call:
  /// unlinks this device so the next user of the phone gets nothing meant for
  /// the previous one. Never throws.
  Future<void> onSignedOut() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    final token = _fcmToken;
    _fcmToken = null;
    if (token == null) return;
    try {
      await _deviceTokens.unregister(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] No se pudo dar de baja el dispositivo: $e');
      }
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────

  Future<void> _register(String token) async {
    try {
      await _deviceTokens.register(token);
      _fcmToken = token;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] No se pudo registrar el token: $e');
    }
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
    onNotificationTapped?.call(message.data);
  }

  /// Called when the user taps a local notification (foreground).
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      onNotificationTapped?.call(data);
    } catch (_) {
      // Malformed payload – nothing to navigate to.
    }
  }
}

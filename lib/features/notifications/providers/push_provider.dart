import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/router/app_router.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/notifications/data/push_notification_service.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// Push notifications for the app session (APP-08).
///
/// Reading it requires Firebase to be initialised; [SessionNotifier] reads it
/// inside a try/catch so a missing Firebase setup never costs the session.
final pushNotificationProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    messaging: FirebaseMessaging.instance,
    deviceTokens: ref.watch(deviceTokenRepositoryProvider),
  );

  service.onNotificationTapped = (data) => _navigateFromNotification(data, ref);
  return service;
});

/// Translates the FCM `data` payload into a route of the signed-in user's own
/// role (the router blocks any other prefix).
///
///   • `novedad` → padre: novedades del hijo (`/parent/children`)
///                 estudiante: `/student/news` · admin: `/admin/news`
///   • `attendance` / `grades` → the role's attendance or grades screen
void _navigateFromNotification(Map<String, dynamic> data, Ref ref) {
  try {
    final router = ref.read(routerProvider);
    final role = ref.read(currentSessionProvider)?.role;
    final type = data['type'] as String? ?? 'novedad';

    final route = switch ((type, role)) {
      ('novedad', Role.parent) => '/parent/children',
      ('novedad', Role.student) => '/student/news',
      ('novedad', Role.admin) => '/admin/news',
      ('attendance', Role.parent) => '/parent/attendance',
      ('attendance', Role.student) => '/student',
      ('grades', Role.parent) => '/parent/notes',
      ('grades', Role.student) => '/student/notes',
      _ => null,
    };
    if (route != null) router.go(route);
  } catch (e) {
    if (kDebugMode) debugPrint('[FCM] Navigation error: $e');
  }
}

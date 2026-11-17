import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/router/app_router.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/notifications/data/push_notification_service.dart';
import 'package:eyes_school/providers/data_providers.dart';
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

  service.onNotificationTapped = (data) => openFromNotification(data, ref);
  service.onMessageReceived = () => refreshAfterPush(ref);
  return service;
});

/// N-33: a push announces new data. Without this, tapping the notification
/// opened the novedades list as it was before the push arrived.
void refreshAfterPush(Ref ref) {
  ref.read(dataRefreshProvider.notifier).state++;
}

/// The tap on a notification: fresh data first, then the screen.
void openFromNotification(Map<String, dynamic> data, Ref ref) {
  refreshAfterPush(ref);
  _navigateFromNotification(data, ref);
}

/// Translates the FCM `data` payload into a route of the signed-in user's own
/// role (the router blocks any other prefix).
///
///   • `novedad` → padre: novedades del hijo (`/parent/children`)
///                 estudiante: `/student/news` · admin: `/admin/news`
///   • `attendance` / `grades` → the role's attendance or grades screen
void _navigateFromNotification(Map<String, dynamic> data, Ref ref) {
  try {
    final session = ref.read(currentSessionProvider);
    final role = session?.role;
    final type = data['type'] as String? ?? 'novedad';

    // P-07 (propuesta, a confirmar por el PO): a guardian with several
    // children sees the child the notification is about, not whoever was
    // active. The API sends `id_estudiante` in the payload.
    final studentId = int.tryParse('${data['id_estudiante'] ?? ''}');
    if (role == Role.parent &&
        studentId != null &&
        session!.children.any((c) => c.id == studentId)) {
      ref.read(sessionProvider.notifier).selectChild(studentId);
    }
    final router = ref.read(routerProvider);

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

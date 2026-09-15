import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/router/app_router.dart';
import 'package:eyes_school/features/notifications/data/push_notification_service.dart';

/// Riverpod provider that initialises push notifications and wires
/// tap-navigation into go_router.
///
/// Watch this provider from the root widget (or call `ref.read` once after
/// login) so the service is initialised exactly once per app session.
final pushNotificationProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService.instance;

  // Wire the tap callback to go_router navigation.
  service.onNotificationTapped = (data) {
    _navigateFromNotification(data, ref);
  };

  return service;
});

/// Translates the FCM `data` payload into a go_router navigation.
///
/// The backend should send a `type` key to indicate the category:
///   • `novedad`     → /student/news  or  /admin/news
///   • `attendance`  → /student (home shows attendance)
///   • `grades`      → /student/notes or /parent/notes
///   • `message`     → /student/news  (fallback to novedades)
///
/// If no type is recognised, the app simply foregrounds.
void _navigateFromNotification(Map<String, dynamic> data, Ref ref) {
  try {
    final router = ref.read(routerProvider);
    final type = data['type'] as String? ?? '';

    switch (type) {
      case 'novedad':
        router.go('/student/news');
      case 'attendance':
        router.go('/student');
      case 'grades':
        router.go('/student/notes');
      default:
        debugPrint('[FCM] Unknown notification type "$type", ignoring navigation.');
    }
  } catch (e) {
    debugPrint('[FCM] Navigation error: $e');
  }
}

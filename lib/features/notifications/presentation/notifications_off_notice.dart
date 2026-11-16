import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/features/notifications/providers/push_provider.dart';

/// Whether this app may show notifications. Reading the push service needs
/// Firebase; without it (tests, another platform) the answer is «allowed»,
/// so the notice never appears for a setting nobody can change.
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    return await ref.read(pushNotificationProvider).notificationsAllowed();
  } catch (_) {
    return true;
  }
});

/// CP-ACE-088 (observación): with notifications blocked the guardian was never
/// told. The notice offers to open the system settings and, back in the app,
/// registers the device as soon as the permission is on.
class NotificationsOffNotice extends ConsumerStatefulWidget {
  const NotificationsOffNotice({super.key, this.openSettings});

  /// Opens this app's notification settings; injectable for tests.
  final Future<void> Function()? openSettings;

  @override
  ConsumerState<NotificationsOffNotice> createState() =>
      _NotificationsOffNoticeState();
}

class _NotificationsOffNoticeState extends ConsumerState<NotificationsOffNotice>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('eyesschool/settings');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Back from the settings: check again and, if allowed now, register.
    ref.invalidate(notificationsAllowedProvider);
    ref.read(notificationsAllowedProvider.future).then((allowed) async {
      if (!allowed) return;
      try {
        await ref.read(pushNotificationProvider).onSignedIn();
      } catch (_) {
        // Push is best-effort.
      }
    });
  }

  Future<void> _open() async {
    final open =
        widget.openSettings ??
        () => _channel.invokeMethod<bool>('openNotificationSettings');
    try {
      await open();
    } catch (_) {
      // No settings screen on this platform: nothing else to offer.
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(notificationsAllowedProvider).valueOrNull ?? true;
    if (allowed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Las notificaciones están desactivadas: no te avisaremos de '
                'las novedades de tu hijo.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(onPressed: _open, child: const Text('Activar')),
          ],
        ),
      ),
    );
  }
}

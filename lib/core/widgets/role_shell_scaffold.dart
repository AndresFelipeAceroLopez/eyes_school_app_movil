import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/services/update_service.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/widgets/update_dialog.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'app_bottom_nav.dart';

/// Wraps a [StatefulShellRoute.indexedStack] branch set with the shared
/// bottom navigation bar for a role (Teacher/Student/Parent/Admin).
class RoleShellScaffold extends ConsumerStatefulWidget {
  const RoleShellScaffold({
    super.key,
    required this.navigationShell,
    required this.items,
    this.elevatedIndex,
  });

  final StatefulNavigationShell navigationShell;
  final List<NavItem> items;
  final int? elevatedIndex;

  @override
  ConsumerState<RoleShellScaffold> createState() => _RoleShellScaffoldState();
}

class _RoleShellScaffoldState extends ConsumerState<RoleShellScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateService = ref.read(updateServiceProvider);
      final info = await updateService.checkForUpdates();
      if (info.hasUpdate && mounted) {
        UpdateDialog.show(context, info);
      }
    } catch (_) {
      // Ignorar errores silenciosamente para no bloquear la app
    }
  }

  void _onTap(int index, bool online) {
    final current = widget.navigationShell.currentIndex;
    // CP-ACE-058: switching tab with a connection brings the live data up to
    // date. Offline nothing is refetched, so the last data stays on screen.
    if (index != current && online) {
      ref.read(dataRefreshProvider.notifier).state++;
    }
    widget.navigationShell.goBranch(index, initialLocation: index == current);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!online) const OfflineStrip(),
          AppBottomNav(
            items: widget.items,
            currentIndex: widget.navigationShell.currentIndex,
            elevatedIndex: widget.elevatedIndex,
            onTap: (index) => _onTap(index, online),
          ),
        ],
      ),
    );
  }
}

/// CP-ACE-052: without a connection the screens keep the last data they
/// loaded; this says so, instead of passing old data off as current.
class OfflineStrip extends StatelessWidget {
  const OfflineStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: const Text(
          'Sin conexión · estás viendo los últimos datos cargados',
          textAlign: TextAlign.center,
          // Dark on orange: about 8:1 (white would be about 2:1, under AA).
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/services/update_service.dart';
import 'package:eyes_school/core/widgets/update_dialog.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: widget.items,
        currentIndex: widget.navigationShell.currentIndex,
        elevatedIndex: widget.elevatedIndex,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Wraps a [StatefulShellRoute.indexedStack] branch set with the shared
/// bottom navigation bar for a role (Teacher/Student/Parent/Admin).
class RoleShellScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: navigationShell.currentIndex,
        elevatedIndex: elevatedIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

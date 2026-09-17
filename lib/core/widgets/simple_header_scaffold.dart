import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

/// Standard "secondary screen" shell: a dark gradient bar with a back
/// button + title, off-white scrollable body below. Used by every screen
/// reached from a bottom-nav tab or a "Ver todo" link that isn't a role home.
class SimpleHeaderScaffold extends StatelessWidget {
  const SimpleHeaderScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBack = true,
    this.floatingActionButton,
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(showBack ? 4 : 20, MediaQuery.of(context).padding.top + 8, 12, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.headerGradient,
              ),
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () {
                      if (onBack != null) {
                        onBack!();
                      } else if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin');
                      }
                    },
                  ),
                Expanded(child: Text(title, style: AppTextStyles.h2.copyWith(color: Colors.white))),
                ...?actions,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

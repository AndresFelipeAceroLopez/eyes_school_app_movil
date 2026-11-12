import 'package:flutter/material.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

/// Layout of the public password screens: a back button and title on the
/// brand color, and the content on a rounded white sheet.
class AuthSheetScaffold extends StatelessWidget {
  const AuthSheetScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerGradient.first,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 24),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: onBack,
                  ),
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

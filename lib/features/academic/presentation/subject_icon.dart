import 'package:flutter/material.dart';

import 'package:eyes_school/core/theme/app_colors.dart';

/// The book badge that marks a subject in the class and subject lists.
class SubjectIcon extends StatelessWidget {
  const SubjectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.roleTeacherBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.menu_book_rounded, color: AppColors.roleTeacher),
    );
  }
}

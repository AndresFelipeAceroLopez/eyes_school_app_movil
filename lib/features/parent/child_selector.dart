import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user.dart';

/// Horizontal chip picker used by the Parent's Asistencia/Notas screens to
/// switch which child's data is shown.
class ChildSelector extends StatelessWidget {
  const ChildSelector({super.key, required this.children, required this.selectedId, required this.onSelected});

  final List<AppUser> children;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) return const SizedBox(height: 8);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(c.firstName),
                    selected: c.id == selectedId,
                    onSelected: (_) => onSelected(c.id),
                    selectedColor: AppColors.indigo,
                    labelStyle: AppTextStyles.body.copyWith(
                      color: c.id == selectedId ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

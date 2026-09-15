import 'package:flutter/material.dart';

import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/domain_styles.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/section_header.dart';

/// One subject's grade with its progress bar. Shared by the student home, the
/// grades tab, the guardian view and the admin's student card, so the 0.0–5.0
/// scale is applied in exactly one place.
class GradeRow extends StatelessWidget {
  const GradeRow({super.key, required this.grade, this.showPeriod = false});

  final Grade grade;
  final bool showPeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subject,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showPeriod) Text(grade.period, style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(grade.qualitative, style: AppTextStyles.caption),
            const SizedBox(width: 8),
            Text(
              grade.score.toStringAsFixed(1),
              style: AppTextStyles.body
                  .copyWith(color: grade.color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: grade.progress,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(grade.color),
          ),
        ),
      ],
    );
  }
}

/// A card of [GradeRow]s. Several subjects can have more than one grade in a
/// period, so rows with the same subject are averaged into one line — which is
/// what "mi nota de Matemáticas" means to a student.
class GradesCard extends StatelessWidget {
  const GradesCard({
    super.key,
    required this.grades,
    this.showPeriod = false,
    this.groupBySubject = true,
  });

  final List<Grade> grades;
  final bool showPeriod;
  final bool groupBySubject;

  static List<Grade> averageBySubject(List<Grade> grades) =>
      Grade.averageBySubject(grades);

  static double overallAverage(List<Grade> grades) => Grade.overallAverage(grades);

  @override
  Widget build(BuildContext context) {
    final rows = groupBySubject ? averageBySubject(grades) : grades;
    return SectionCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            GradeRow(grade: rows[i], showPeriod: showPeriod),
            if (i != rows.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

/// The 1–4 period selector. There is no `/periodos` endpoint, so the values
/// are a local constant and the running period comes from the dashboard.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  final List<int> periods;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: periods.map((period) {
        final isSelected = period == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.indigo : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? null
                      : const [
                          BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 12,
                              offset: Offset(0, 4)),
                        ],
                ),
                child: Text(
                  'P$period',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

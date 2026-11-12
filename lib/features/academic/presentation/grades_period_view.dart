import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/features/academic/presentation/grade_row.dart';

/// The grades of one period as the student, the guardian and the student
/// profile show them: loading, error with retry, empty state, the average card
/// and the per-subject list, plus an optional report-card button.
class GradesPeriodView extends StatelessWidget {
  const GradesPeriodView({
    super.key,
    required this.gradesAsync,
    required this.period,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    this.averageLabel = 'Promedio general',
    this.onDownloadReportCard,
    this.gap = 20,
  });

  final AsyncValue<List<Grade>> gradesAsync;
  final int period;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final String averageLabel;
  final VoidCallback? onDownloadReportCard;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return gradesAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      data: (grades) {
        if (grades.isEmpty) {
          return EmptyState(
            icon: Icons.bar_chart_rounded,
            title: emptyTitle,
            message: emptyMessage,
          );
        }
        final average = GradesCard.overallAverage(grades);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(averageLabel, style: AppTextStyles.caption),
                        Text(
                          average.toStringAsFixed(1),
                          style: AppTextStyles.h1.copyWith(
                            color: average >= 3.0
                                ? AppColors.tealDark
                                : AppColors.pink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AcademicPeriods.labelOf(period),
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            GradesCard(grades: grades),
            if (onDownloadReportCard != null) ...[
              SizedBox(height: gap),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.indigo,
                  side: const BorderSide(color: AppColors.indigo),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onDownloadReportCard,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Descargar boletín PDF'),
              ),
            ],
          ],
        );
      },
    );
  }
}

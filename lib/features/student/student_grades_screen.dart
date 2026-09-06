import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/report_card_download.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/grade_row.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import '../../domain/value_objects/severity.dart';

/// Grades by period, grouped by subject, plus the PDF report card.
class StudentGradesScreen extends ConsumerStatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  ConsumerState<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends ConsumerState<StudentGradesScreen> {
  int? _period;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final studentId = session?.subjectStudentId;
    _period ??= ref.read(currentPeriodProvider);

    if (studentId == null) {
      return SimpleHeaderScaffold(
        title: 'Mis notas',
        showBack: false,
        body: EmptyState(
          icon: Icons.school_outlined,
          title: 'Perfil de estudiante no encontrado',
          message: session?.bootstrapWarning ??
              'Tu cuenta no tiene un perfil de estudiante asociado.',
        ),
      );
    }

    final args = (studentId: studentId, period: _period);
    final gradesAsync = ref.watch(gradesForStudentProvider(args));

    return SimpleHeaderScaffold(
      title: 'Mis notas',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Boletín PDF',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
          onPressed: () => ReportCardDownloader.run(
            context,
            ref,
            studentId: studentId,
            studentName: session?.user.name ?? 'estudiante',
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(gradesForStudentProvider(args)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            PeriodSelector(
              periods: AcademicPeriods.all,
              selected: _period!,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 20),
            gradesAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(gradesForStudentProvider(args)),
              ),
              data: (grades) {
                if (grades.isEmpty) {
                  return EmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'Sin notas en el periodo ${_period!}',
                    message: 'Cuando tus docentes registren notas aparecerán aquí.',
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
                                Text('Promedio general', style: AppTextStyles.caption),
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
                            AcademicPeriods.labelOf(_period!),
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradesCard(grades: grades),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo,
                        side: const BorderSide(color: AppColors.indigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => ReportCardDownloader.run(
                        context,
                        ref,
                        studentId: studentId,
                        studentName: session?.user.name ?? 'estudiante',
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Descargar boletín PDF'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

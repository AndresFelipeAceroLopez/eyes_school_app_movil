import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/features/academic/presentation/grades_period_view.dart';
import 'package:eyes_school/core/utils/report_card_download.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/academic/presentation/grade_row.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// Grades by period, grouped by subject, plus the PDF report card.
class StudentGradesScreen extends ConsumerStatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  ConsumerState<StudentGradesScreen> createState() =>
      _StudentGradesScreenState();
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
          message:
              session?.bootstrapWarning ??
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
            GradesPeriodView(
              gradesAsync: gradesAsync,
              period: _period!,
              onRetry: () => ref.invalidate(gradesForStudentProvider(args)),
              emptyTitle: 'Sin notas en el periodo ${_period!}',
              emptyMessage:
                  'Cuando tus docentes registren notas aparecerán aquí.',
              onDownloadReportCard: () => ReportCardDownloader.run(
                context,
                ref,
                studentId: studentId,
                studentName: session?.user.name ?? 'estudiante',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/features/academic/presentation/grades_period_view.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/report_card_download.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/features/academic/presentation/grade_row.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// The linked childs grades by period, plus the PDF report card, which the
/// guardian can open or forward from the share sheet.
class ParentGradesScreen extends ConsumerStatefulWidget {
  const ParentGradesScreen({super.key});

  @override
  ConsumerState<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends ConsumerState<ParentGradesScreen> {
  int? _period;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final childId = session?.childId;
    _period ??= ref.read(currentPeriodProvider);

    if (childId == null) {
      return SimpleHeaderScaffold(
        title: 'Notas',
        showBack: false,
        body: EmptyState(
          icon: Icons.family_restroom_rounded,
          title: 'Sin estudiante vinculado',
          message:
              session?.bootstrapWarning ??
              'Tu cuenta de acudiente aún no está vinculada a un estudiante.',
        ),
      );
    }

    final name = session?.childName ?? 'Estudiante';
    final args = (studentId: childId, period: _period);
    final gradesAsync = ref.watch(gradesForStudentProvider(args));

    return SimpleHeaderScaffold(
      title: 'Notas',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Compartir boletín',
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
          onPressed: () => ReportCardDownloader.run(
            context,
            ref,
            studentId: childId,
            studentName: name,
            share: true,
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(gradesForStudentProvider(args)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            SectionCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  AvatarCircle(name: name, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  'Cuando los docentes registren notas aparecerán aquí.',
              onDownloadReportCard: () => ReportCardDownloader.run(
                context,
                ref,
                studentId: childId,
                studentName: name,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

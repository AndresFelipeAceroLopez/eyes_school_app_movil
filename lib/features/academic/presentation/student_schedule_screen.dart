import 'package:flutter/material.dart';
import 'package:eyes_school/features/academic/presentation/course_schedule_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// Weeklyy grid of the student's current course. `HorarioOut` carries only
/// ids, so the subject names come from the cached catalogs.
class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final courseId = session?.courseId;

    if (courseId == null) {
      return const SimpleHeaderScaffold(
        title: 'Mi horario',
        showBack: false,
        body: EmptyState(
          icon: Icons.calendar_month_rounded,
          title: 'Sin curso asignado',
          message: 'Tu cuenta aún no está matriculada en un curso.',
        ),
      );
    }

    return SimpleHeaderScaffold(
      title: 'Mi horario',
      showBack: false,
      body: CourseScheduleView(
        courseId: courseId,
        emptyTitle: 'Sin horario publicado',
        emptyMessage: 'Tu curso todavía no tiene bloques programados.',
      ),
    );
  }
}

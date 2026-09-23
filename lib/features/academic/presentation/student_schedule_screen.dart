import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/academic/presentation/weekly_schedule_list.dart';
import 'package:eyes_school/providers/data_providers.dart';
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

    final scheduleAsync = ref.watch(studentWeeklyScheduleProvider(courseId));

    return SimpleHeaderScaffold(
      title: 'Mi horario',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentWeeklyScheduleProvider(courseId)),
        child: scheduleAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(studentWeeklyScheduleProvider(courseId)),
            ),
          ]),
          data: (sessions) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (sessions.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Sin horario publicado',
                  message: 'Tu curso todavía no tiene bloques programados.',
                )
              else
                WeeklyScheduleList(sessions: sessions),
            ],
          ),
        ),
      ),
    );
  }
}

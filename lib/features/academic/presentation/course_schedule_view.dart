import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/academic/presentation/weekly_schedule_list.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// A course's weekly schedule with pull-to-refresh, error with retry and an
/// empty state. Shared by the student's schedule and the admin's schedules.
class CourseScheduleView extends ConsumerWidget {
  const CourseScheduleView({
    super.key,
    required this.courseId,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final int courseId;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(studentWeeklyScheduleProvider(courseId));
    void retry() => ref.invalidate(studentWeeklyScheduleProvider(courseId));

    return RefreshIndicator(
      onRefresh: () async => retry(),
      child: scheduleAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ListView(
          children: [ErrorView(error: error, onRetry: retry)],
        ),
        data: (sessions) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (sessions.isEmpty)
              EmptyState(
                icon: Icons.event_busy_rounded,
                title: emptyTitle,
                message: emptyMessage,
              )
            else
              WeeklyScheduleList(sessions: sessions),
          ],
        ),
      ),
    );
  }
}

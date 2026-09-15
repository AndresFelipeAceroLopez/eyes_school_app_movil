import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/academic/presentation/weekly_schedule_list.dart';
import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// Read-only weekly grid per course. Editing schedules is a web-panel job.
class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  int? _courseId;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return SimpleHeaderScaffold(
      title: 'Horarios',
      body: coursesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'Sin cursos activos',
              message: 'No hay cursos publicados para este año.',
            );
          }
          final selected = _courseId ?? courses.first.id;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: courses
                      .map((course) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _CourseChip(
                              course: course,
                              selected: selected == course.id,
                              onTap: () => setState(() => _courseId = course.id),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(child: _CourseSchedule(courseId: selected)),
            ],
          );
        },
      ),
    );
  }
}

class _CourseChip extends StatelessWidget {
  const _CourseChip({
    required this.course,
    required this.selected,
    required this.onTap,
  });

  final Course course;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('${course.name} · ${course.shiftLabel}'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.indigo,
      labelStyle: AppTextStyles.body.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }
}

class _CourseSchedule extends ConsumerWidget {
  const _CourseSchedule({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(studentWeeklyScheduleProvider(courseId));

    return RefreshIndicator(
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
                title: 'Sin bloques programados',
                message: 'Este curso todavía no tiene horario publicado.',
              )
            else
              WeeklyScheduleList(sessions: sessions),
          ],
        ),
      ),
    );
  }
}

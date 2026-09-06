import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/weekly_schedule_list.dart';
import '../../domain/entities/teacher_class.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

/// "Mis clases": the teacher's active assignments (`/asignaciones?
/// id_profesor=X&activo=true`), plus their weekly grid underneath.
///
/// The assignment is the unit that matters: it is what scopes every write the
/// teacher is allowed to make.
class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final classesAsync = ref.watch(teacherClassesProvider);
    final scheduleAsync = ref.watch(teacherWeeklyScheduleProvider);

    if (session?.teacherId == null) {
      return SimpleHeaderScaffold(
        title: 'Mis clases',
        showBack: false,
        body: EmptyState(
          icon: Icons.badge_outlined,
          title: 'Perfil docente no encontrado',
          message: session?.bootstrapWarning ??
              'Tu cuenta no tiene un perfil de docente asociado.',
        ),
      );
    }

    return SimpleHeaderScaffold(
      title: 'Mis clases',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherClassesProvider);
          ref.invalidate(teacherWeeklyScheduleProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: classesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(teacherClassesProvider),
                ),
                data: (classes) {
                  if (classes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: 'Sin asignaciones activas',
                      message: 'Cuando te asignen cursos y materias aparecerán aquí.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Asignaciones (${classes.length})'),
                      const SizedBox(height: 12),
                      for (final item in classes) _ClassCard(item: item),
                    ],
                  );
                },
              ),
            ),
            scheduleAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (sessions) => sessions.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: SectionHeader(title: 'Mi horario'),
                        ),
                        WeeklyScheduleList(sessions: sessions),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.item});

  final TeacherClass item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.roleTeacherBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.roleTeacher),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subjectName, style: AppTextStyles.h3),
                      Text(
                        [item.courseName, item.shift].whereType<String>().join(' · '),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.fact_check_rounded,
                    label: 'Asistencia',
                    color: AppColors.tealDark,
                    background: AppColors.statusActiveBg,
                    onTap: () =>
                        context.push('/teacher/classes/${item.assignmentId}/asistencia'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.edit_note_rounded,
                    label: 'Notas',
                    color: AppColors.roleTeacher,
                    background: AppColors.roleTeacherBg,
                    onTap: () => context.push('/teacher/classes/${item.assignmentId}/notas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

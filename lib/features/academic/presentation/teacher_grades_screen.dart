import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// Entry point to the grade sheets: one row per active assignment.
class TeacherGradesScreen extends ConsumerWidget {
  const TeacherGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);

    return SimpleHeaderScaffold(
      title: 'Notas',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(teacherClassesProvider),
        child: classesAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(error: error, onRetry: () => ref.invalidate(teacherClassesProvider)),
          ]),
          data: (classes) {
            if (classes.isEmpty) {
              return ListView(children: const [
                EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'Sin materias asignadas',
                  message: 'Cuando te asignen una materia podrás registrar sus notas.',
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text('Selecciona una clase para registrar notas.',
                    style: AppTextStyles.bodyMuted),
                const SizedBox(height: 16),
                for (final item in classes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          context.push('/teacher/classes/${item.assignmentId}/notas'),
                      child: SectionCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.roleTeacherBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.bar_chart_rounded,
                                  color: AppColors.roleTeacher),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.subjectName, style: AppTextStyles.h3),
                                  Text(
                                    [item.courseName, item.shift]
                                        .whereType<String>()
                                        .join(' · '),
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

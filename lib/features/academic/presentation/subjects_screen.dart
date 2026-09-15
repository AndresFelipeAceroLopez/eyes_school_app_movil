import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// Subject catalog, enriched with the courses each subject is taught in.
/// `MateriaOut` carries none of that, so it is joined from `/asignaciones`.
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return SimpleHeaderScaffold(
      title: 'Materias',
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(subjectsProvider),
        child: subjectsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(error: error, onRetry: () => ref.invalidate(subjectsProvider)),
          ]),
          data: (subjects) {
            if (subjects.isEmpty) {
              return ListView(children: const [
                EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'Sin materias activas',
                  message: 'El catálogo académico está vacío.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = subjects[index];
                return SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.roleTeacherBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppColors.roleTeacher),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: AppTextStyles.h3),
                            Text(s.teacherName, style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(s.groups,
                                style: AppTextStyles.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${s.studentCount}',
                              style:
                                  AppTextStyles.h3.copyWith(color: AppColors.tealDark)),
                          Text('cursos', style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

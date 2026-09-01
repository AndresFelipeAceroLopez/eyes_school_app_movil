import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/grade.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

class StudentGradesScreen extends ConsumerWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final gradesAsync = ref.watch(gradesForStudentProvider(user.id));

    return SimpleHeaderScaffold(
      title: 'Mis notas',
      showBack: false,
      body: gradesAsync.when(
        data: (grades) {
          if (grades.isEmpty) {
            return Center(child: Text('Aún no hay notas registradas.', style: AppTextStyles.bodyMuted));
          }
          final average = grades.fold<double>(0, (a, g) => a + g.score) / grades.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Promedio general', style: AppTextStyles.caption),
                          Text(average.toStringAsFixed(1),
                              style: AppTextStyles.h1.copyWith(color: AppColors.tealDark)),
                        ],
                      ),
                    ),
                    Text('Período 2 · 2024', style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  children: [
                    for (int i = 0; i < grades.length; i++) ...[
                      _GradeRow(grade: grades[i]),
                      if (i != grades.length - 1) const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudieron cargar las notas.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.subject, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                Text(grade.period, style: AppTextStyles.caption),
              ],
            ),
            Row(
              children: [
                Text(grade.qualitative, style: AppTextStyles.caption),
                const SizedBox(width: 8),
                Text(grade.score.toStringAsFixed(1),
                    style: AppTextStyles.body.copyWith(color: grade.color, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (grade.score / 10).clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(grade.color),
          ),
        ),
      ],
    );
  }
}

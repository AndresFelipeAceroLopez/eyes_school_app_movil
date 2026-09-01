import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/grade.dart';
import '../../models/user.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import 'child_selector.dart';

class ParentGradesScreen extends ConsumerStatefulWidget {
  const ParentGradesScreen({super.key});

  @override
  ConsumerState<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends ConsumerState<ParentGradesScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final childrenAsync = ref.watch(childrenOfProvider(user));

    return SimpleHeaderScaffold(
      title: 'Notas',
      showBack: false,
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return Center(child: Text('No tienes hijos vinculados.', style: AppTextStyles.bodyMuted));
          }
          final selected = children.firstWhere(
            (c) => c.id == _selectedId,
            orElse: () => children.first,
          );
          return Column(
            children: [
              ChildSelector(
                children: children,
                selectedId: selected.id,
                onSelected: (id) => setState(() => _selectedId = id),
              ),
              Expanded(child: _GradesBody(student: selected)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar la información.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}

class _GradesBody extends ConsumerWidget {
  const _GradesBody({required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesForStudentProvider(student.id));
    return gradesAsync.when(
      data: (grades) {
        if (grades.isEmpty) {
          return Center(child: Text('Aún no hay notas registradas.', style: AppTextStyles.bodyMuted));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
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
            Text(grade.subject, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
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

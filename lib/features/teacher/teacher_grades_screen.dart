import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/class_session.dart';
import '../../providers/data_providers.dart';
import 'grade_entry_screen.dart';

class TeacherGradesScreen extends ConsumerWidget {
  const TeacherGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(teacherWeeklyScheduleProvider);

    return SimpleHeaderScaffold(
      title: 'Notas',
      showBack: false,
      body: scheduleAsync.when(
        data: (sessions) {
          final groups = <String>{};
          final rows = <ClassSession>[];
          for (final s in sessions) {
            final key = '${s.subject}|${s.group}';
            if (groups.add(key)) rows.add(s);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('Selecciona un grupo para registrar notas.', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 16),
              for (final s in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      final group = s.group.split(' · ').first;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GradeEntryScreen(group: group, subject: s.subject),
                      ));
                    },
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
                            child: const Icon(Icons.bar_chart_rounded, color: AppColors.roleTeacher),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.subject, style: AppTextStyles.h3),
                                Text(s.group, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudieron cargar los grupos.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}
